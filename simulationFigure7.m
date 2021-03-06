%This Matlab script can be used to generate Figure 7 in the article:
%
%Emil Bjornson, Luca Sanguinetti, Jakob Hoydis, "Hardware Distortion
%Correlation Has Negligible Impact on UL Massive MIMO Spectral Efficiency,"
%IEEE Transactions on Communications, To appear.
%
%Download article: https://arxiv.org/abs/1811.02007
%
%This is version 1.0 (Last edited: 2018-10-18)
%
%License: This code is licensed under the GPLv2 license. If you in any way
%use this code for research that results in publications, please cite our
%original article listed above.


close all;
clear;

%Set maximum ADC resolution
max_ADCresolution = 6;

%Generate range of ADC resolutions
ADCresolutions = 1:max_ADCresolution;

%Load the quantization levels for non-uniform quantization of a standard
%Gaussian random variable, obtained using the Lloyd algorithm
load quantizationLevels;

%Number of antennas
M = 100;

%Number of UEs
K = 5;

%Number of channel realizations
nbrOfRealizations = 500;

%Number of signal transmissions, used to compute Cee by Monte-Carlo methods
signalTransmissions = 10000;

%Signal-to-noise ratio
SNR = 1;

%Compute an identity matrix
I_M = eye(M);


%Prepare to save simulation results
distortion_noise_M = zeros(M,length(ADCresolutions));


%% Go through all channel realizations
for n = 1:nbrOfRealizations
    
    %Write out the progress at every iterations
    disp(['Progress: ' num2str(n) ' out of ' num2str(nbrOfRealizations) ' realizations']);
    
    
    %Scaling factor that is used to make the real and imaginary part of
    %the received signal standard Gaussian random variables
    scaling = (SNR*K)/2*eye(M);
    
    %Generate channel realization
    H = (randn(M,K)+1i*randn(M,K))/sqrt(2);
    
    %Generate the signals to be transmitted in the Monte-Carlo transmission
    S = (randn(K,signalTransmissions)+1i*randn(K,signalTransmissions))/sqrt(2);
    
    %Compute %Compute C_{uu} for the given channel realization
    Cuu = SNR*(H*H');
    
    %Compute the noise-free received signal
    U = sqrt(SNR)*H*S;
    
    %Normalize the received signal so that the real and imaginary parts
    %have unit variance, not for the given channel realization but on the
    %average
    U_normalized = sqrtm(scaling)\U;
    
    
    %Go through all ADC resolutions
    for itr = 1:length(ADCresolutions)
        
        
        %Compute the vector with diagonal elements of D using (38)
        dvec = zeros(M,1);
        
        for m = 1:M
            
            rhomm = Cuu(m,m)/scaling(m,m);
            
            dvec(m) = sum((codebooks{ADCresolutions(itr)}/sqrt(pi*rhomm)).*( exp(-[-Inf; partitions{ADCresolutions(itr)}].^2/rhomm) - exp(-[partitions{ADCresolutions(itr)}; Inf].^2/rhomm) ));
            
        end
        
        D = diag(dvec);
        
        
        %Compute C_{eta eta} for the given channel realization using
        %Monte-Carlo methods
        Cee = zeros(M,M);
        
        for l = 1:signalTransmissions
            
            %Quantization of real and imaginary parts of received signal
            real_index = quantiz(real(U_normalized(:,l)),partitions{ADCresolutions(itr)});
            imag_index = quantiz(imag(U_normalized(:,l)),partitions{ADCresolutions(itr)});
            
            %Reconstruct the quantized signal using the quantization levels
            U_quant = sqrtm(scaling)*(codebooks{ADCresolutions(itr)}(real_index+1)+1i*codebooks{ADCresolutions(itr)}(imag_index+1));
            
            %Approximate C_{eta eta} by a sample correlation matrix
            Cee = Cee + ((U_quant-D*U(:,l))*(U_quant-D*U(:,l))')/signalTransmissions;
            
        end
        
        %Compute the distortion power with MR for different number of anternnas
        for m = 1:M
            
            distortion_noise_M(m,itr) = distortion_noise_M(m,itr) + real(H(1:m,1)'*Cee(1:m,1:m)*H(1:m,1))/(m*nbrOfRealizations);
            
        end
        
    end
    
    
end


%% Plot Figure 7
figure;
hold on; box on;

plot(1:M,distortion_noise_M(1:M,1,1),'k--','LineWidth',1);
plot(1:M,distortion_noise_M(1:M,2,1),'r-','LineWidth',1);
plot(1:M,distortion_noise_M(1:M,4,1),'b--','LineWidth',1);
plot(1:M,distortion_noise_M(1:M,6,1),'k:','LineWidth',1);
xlabel('Number of antennas $(M)$','Interpreter','Latex');
ylabel('BS distortion power over noise','Interpreter','Latex');
legend({'$b=1$','$b=2$','$b=4$','$b=6$'},'Location','NorthWest','Interpreter','Latex');

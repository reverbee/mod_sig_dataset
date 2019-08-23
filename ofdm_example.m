function [] = ofdm_example
% ofdm example
%
% modified from "OFDMvsFBMCExample_copy.m" matlab example

% s = rng(211);            % Set RNG state for repeatability

% System Parameters

% Number of FFT points
numFFT = 1024;
% Guard bands on both sides
numGuards = 212; 
% Simulation length in symbols
numSymbols = 100; 
% 2: 4QAM, 4: 16QAM, 6: 64QAM, 8: 256QAM
bitsPerSubCarrier = 2;   

% QAM symbol mapper
qamMapper = comm.RectangularQAMModulator(...
    'ModulationOrder', 2^bitsPerSubCarrier, ...
    'BitInput', true, ...
    'NormalizationMethod', 'Average power');

% Transmit-end processing
% Initialize arrays

% Number of complex symbols per OFDM symbol
L = numFFT - 2 * numGuards;  

sumOFDMSpec = zeros(numFFT * 2, 1);

% OFDM Modulation with Corresponding Parameters
%
% For comparison, we review the existing OFDM modulation technique, 
% using the full occupied band, however, without a cyclic prefix.

for symIdx = 1 : numSymbols
    
    inpData2 = randi([0 1], bitsPerSubCarrier * L, 1);
    modData = qamMapper(inpData2);
        
    symOFDM = [zeros(numGuards, 1); modData; zeros(numGuards, 1)];
    ifftOut = sqrt(numFFT) .* ifft(ifftshift(symOFDM));

    [specOFDM, fOFDM] = periodogram(ifftOut, rectwin(length(ifftOut)), ...
        numFFT * 2, 1, 'centered'); 
    sumOFDMSpec = sumOFDMSpec + specOFDM;
    
end

% Plot power spectral density (PSD) over all subcarriers
sumOFDMSpec = sumOFDMSpec / mean(sumOFDMSpec(1 + 2 * numGuards : end - 2 * numGuards));
figure; 
plot(fOFDM, 10 * log10(sumOFDMSpec)); 
grid on
axis([-0.5 0.5 -180 10]);
xlabel('Normalized frequency'); 
ylabel('PSD (dBW/Hz)')
title(['OFDM, numFFT = ' num2str(numFFT)])
set(gcf, 'Position', figposition([46 50 30 30]));

% Restore RNG state
% rng(s);

end


% function [] = learn_qpsk_carrier_recovery()
% learn qpsk carrier recovery
%
% [usage]
% learn_qpsk_carrier_recovery
%
% ##### [example: how to use comm.phasefrequencyoffset in awgn channel]
% https://kr.mathworks.com/help/comm/ref/comm.pskcoarsefrequencyestimator-system-object.html
%
% Estimate and correct for a -250 Hz frequency offset in a QPSK signal 
% using the PSK Coarse Frequency Estimator System object

% Create a square root raised cosine transmit filter System object.
txfilter = comm.RaisedCosineTransmitFilter;

% Create a phase frequency offset object, 
% where the FrequencyOffset property is set to -250 Hz 
% and SampleRate is set to 4000 Hz using name-value pairs.
pfo = comm.PhaseFrequencyOffset(...
    'FrequencyOffset', -250, ...
    'SampleRate', 4000);

% Create a PSK coarse frequency estimator System object 
% with a sample rate of 4 kHz and a frequency resolution of 1 Hz.
frequencyEst = comm.PSKCoarseFrequencyEstimator(...
    'SampleRate', 4000, ...
    'FrequencyResolution', 1);

% Create a second phase frequency offset object to correct the offset. 
% Set the FrequencyOffsetSource property to Input port 
% so that the frequency correction estimate is an input argument.
pfoCorrect = comm.PhaseFrequencyOffset(...
    'FrequencyOffsetSource', 'Input port', ...
    'SampleRate', 4000);

% Generate a QPSK signal, filter the signal, apply the frequency offset, 
% and pass the signal through the AWGN channel.
modData = pskmod(randi([0 3], 4096, 1), 4, pi/4);     % Generate QPSK signal
txFiltData = step(txfilter, modData);                   % Apply Tx filter
% #### below is valid from r2016b
% txFiltData = txfilter(modData);                   % Apply Tx filter
offsetData = step(pfo, txFiltData);                     % Apply frequency offset
% #### below is valid from r2016b
% offsetData = pfo(txFiltData);                     % Apply frequency offset
noisyData = awgn(offsetData, 25);                  % Pass through AWGN channel

% Estimate the frequency offset by using frequencyEst. 
% Observe that the estimate is close to the -250 Hz target.
estFreqOffset = step(frequencyEst, noisyData);
% #### below is valid from r2016b
% estFreqOffset = frequencyEst(noisyData)

% Correct for the frequency offset using pfoCorrect and the inverse of the estimated frequency offset.
compensatedData = step(pfoCorrect, noisyData, -estFreqOffset);
% #### below is valid from r2016b
% compensatedData = pfoCorrect(noisyData,-estFreqOffset);

% Create a spectrum analyzer object to view the frequency response of the signals.
spectrum = dsp.SpectrumAnalyzer('SampleRate', 4000, 'ShowLegend', true);
% spectrum = dsp.SpectrumAnalyzer('SampleRate', 4000, 'ShowLegend', true, ...
%     'ChannelNames', {'Received Signal' 'Compensated Signal'});

% Plot the frequency response of the received signal, 
% which is shifted 250 Hz to the left, and of the compensated signal using the spectrum analyzer. 
% The compensated signal is now properly centered.
% ###### spectrum analyzer is shown in a second, and disppeared!!! no solution
step(spectrum, [noisyData compensatedData]);
% #### below is valid from r2016b
% spectrum([noisyData compensatedData]);

% plot_signal(noisyData, 4000, 'noisy');
% plot_signal(compensatedData, 4000, 'compensated');


%%
% hMod = comm.QPSKModulator;
% 
% hTxFilter = comm.RaisedCosineTransmitFilter(...
%     'RolloffFactor',          0.2, ...
%     'FilterSpanInSymbols',    8,   ...
%     'OutputSamplesPerSymbol', 4);
% 
% hPFOError = comm.PhaseFrequencyOffset(...
%     'FrequencyOffset', -150, ...
%     'SampleRate',      4000);
% 
% hAWGN = comm.AWGNChannel(...
%     'NoiseMethod', 'Signal to noise ratio (SNR)', ...
%     'SNR', 30);
% 
% hRxFilter = comm.RaisedCosineReceiveFilter(...
%     'RolloffFactor',         0.5, ...
%     'FilterSpanInSymbols',   8,   ...
%     'InputSamplesPerSymbol', 4,   ...
%     'DecimationFactor',      2);
% 
% hFreqEst = comm.PSKCoarseFrequencyEstimator(...
%     'SampleRate',          4000/2, ...
%     'FrequencyResolution', 1);
% 
% hPFOCorrect = comm.PhaseFrequencyOffset(...
%     'FrequencyOffsetSource', 'Input port', ...
%     'SampleRate',            4000/2);
% 
% modData    = step(hMod, randi([0 3], 2048, 1));  % generate QPSK signal
% txFiltData = step(hTxFilter, modData);           % tx filter
% noisyData  = step(hAWGN, txFiltData);            % add noise
% offsetData = step(hPFOError, noisyData);         % generate offset
% rxFiltData = step(hRxFilter, offsetData);        % rx filter
% 
% % scatterplot(rxFiltData);
% 
% FFTRxData  = fftshift(10*log10(abs(fft(rxFiltData))));
% df = 2000/4096;  freqRangeRx = (-1000:df:1000-df)';
% figure; plot(freqRangeRx, FFTRxData);
% title('Received Data'); xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
% pos = get(gcf, 'Position');
% 
% estFreqOffset   = step(hFreqEst, rxFiltData)     % estimate offset
% compensatedData = step(hPFOCorrect, rxFiltData, ...
%     -estFreqOffset);
% 
% % scatterplot(compensatedData);
% 
% FFTCompData     = fftshift(10*log10(abs(fft(compensatedData))));
% figure; plot(freqRangeRx, FFTCompData);
% title('Frequency Compensated Data')
% xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
% set(gcf, 'Position', pos+[30 -30 0 0]);

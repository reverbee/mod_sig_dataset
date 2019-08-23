% learn qpsk carrier recovery
%
% Estimate and correct for a -250 Hz frequency offset in a QPSK signal 
% using the PSK Coarse Frequency Estimator System object
% #### carrier phase offset is NOT considered ####
%
% https://kr.mathworks.com/help/comm/ref/comm.pskcoarsefrequencyestimator-system-object.html
%

% #######################################################################
% ### to include function inside script, you need r2016b or above
% ### so this must be script not including function (current = r2014a)
% #######################################################################

clear all;

fs = 4e3;
snr_db = 10;
symbol_length = 2^13;
freq_offset = -250;
[noisyData, compensatedData, est_freq_offset] = ...
    qpsk_carrier_recovery(symbol_length, snr_db, fs, freq_offset);
fprintf('#### freq offset = %g hz, estimated freq offset = %g hz\n', freq_offset, est_freq_offset);

% ###### when spectrum analyzer is in function,
% ###### spectrum analyzer is shown in a second, and disppeared!
% ###### so must locate it inside script

% Create a spectrum analyzer object to view the frequency response of the signals.
spectrum = dsp.SpectrumAnalyzer('SampleRate', fs, 'ShowLegend', true);
% spectrum = dsp.SpectrumAnalyzer('SampleRate', 4000, 'ShowLegend', true, ...
%     'ChannelNames', {'Received Signal' 'Compensated Signal'});

% Plot the frequency response of the received signal, 
% which is shifted 250 Hz to the left, and of the compensated signal using the spectrum analyzer. 
% The compensated signal is now properly centered.
step(spectrum, [noisyData compensatedData]);
% #### below is valid from r2016b
% spectrum([noisyData compensatedData]);

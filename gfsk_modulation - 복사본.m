function [] = ...
    gfsk_modulation(M, freq_sep, symbol_length, snr_db, fs, plot_modulated, plot_stella)
% #################### failed!!! rewrite later ######################
% ##### idea: analog fm + fsk with pulse shaping filter 
% #####
% ##### try vco
% ###################################################################
%
% gaussian fsk modulation 
% gaussian pulse shaping
%
% [usage]
% gfsk_modulation(2, .01, 2^10, 10, 44.1e3, 1, 1);
%

sample_per_symbol = 8;

use_gaussian_filter = 0;

% symbol
x = randi([0, M-1], symbol_length, 1);

% pam modulation
ini_phase = 0;
y = pammod(x, M, ini_phase);

if use_gaussian_filter
    % design gaussian filter
    bt = 0.3;
    span = 4;
    pulse_shaping_filter = gaussdesign(bt, span, sample_per_symbol);
else
    rolloff = 0.25; % Filter rolloff
    span = 6;       % Filter span
    pulse_shaping_filter = rcosdesign(rolloff, span, sample_per_symbol);
end

% upsample and filter modulated signal
y = upfirdn(y, pulse_shaping_filter, sample_per_symbol);
length(y);

% remove filter transient
transient_length = (span / 2) * sample_per_symbol;
y = y(transient_length + 1 : end - transient_length);
length(y);

if plot_modulated
    plot_signal(y, fs, 'modulated');
end

fc = 10e3;
freq_dev = .5e3;
max_freq_of_source_signal = 3e3;
occupied_fm_bw = 2 * (freq_dev + max_freq_of_source_signal);
y = fmmod(y, fc, fs, freq_dev);
size(y);

if plot_modulated
    plot_signal(y, fs, 'modulated');
end

t = (0 : length(y) - 1)' / fs;
y = y .* exp(-1i * 2 * pi * fc * t);

if plot_modulated
    plot_signal(y, fs, 'baseband');
end

% design low pass fir filter
filter_order = 74;
pass_freq = occupied_fm_bw / 2;
filter_coeff = fir1(filter_order, pass_freq / fs * 2);

% low pass filtering
a = 1;
y = filter(filter_coeff, a, y);

% add awgn noise to signal
if ~isempty(snr_db)
    y = awgn(y, snr_db, 'measured', 'db');
end

if plot_modulated
    plot_signal(y, fs, 'modulated');
end

end




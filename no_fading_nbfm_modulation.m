function [] = no_fading_nbfm_modulation(source_sample_length, freq_dev, snr_db, plot_modulated_signal, sound_demod)
% narrow band fm modulation
%
% [input]
% - source_sample_length:
% - freq_dev: frequency deviation in hz. max freq_dev = 1e3
%   when max_freq_of_source_signal = 5e3, recommend = 1e3, this make fm modulation index = 0.2
% - snr_db: snr in db. if empty, noise is NOT added to signal
% - plot_modulated_signal: boolean
% - sound_demod: boolean
%
% [usage]
% no_fading_nbfm_modulation(8192, 1e3, 10, 1, 0)
% no_fading_nbfm_modulation(8192, 1e3, '', 1, 0)
% no_fading_nbfm_modulation(2^18, 1e3, 10, 1, 1)
% no_fading_nbfm_modulation(2^18, 1e3, '', 1, 1)
% 

% ###############################################################
% fm modulation index = freq_dev / max_freq_of_source_signal
% narrow band fm: less than 0.5, 0.2 is often used when audio or data bandwidth is small
% wide band fm: above 0.5
% https://www.electronics-notes.com/articles/radio/modulation/fm-frequency-modulation-index-deviation-ratio.php

% max_freq_of_source_signal = 5e3, fm_modulation_index= 0.2
% frequency deviation = max_freq_of_source_signal * fm_modulation_index = 5e3 * 0.2 = 1e3
if freq_dev > 1e3
    error('[nbfm] max freq_dev = 1e3 hz\n');
end

plot_source_signal = 0;
sound_source = 0;
max_freq_of_source_signal = 5e3; % recommend = 5e3
[x, fs] = analog_source(source_sample_length, max_freq_of_source_signal, plot_source_signal, sound_source);

% narrow band fm. 
% see carson's rule, https://en.wikipedia.org/wiki/Frequency_modulation
% fm_bandwidth = 2 * (freq_dev + max_freq_of_source_signal)
% fm modulation index = freq_dev / max_freq_of_source_signal
% freq_dev: peak deviation of instantaneous freq from fc
% [example]
% when max_freq_of_source_signal = 5e3, freq_dev = 1e3 (modulation index = 0.2)
% occupied(98%) fm_bandwidth = 12e3
occupied_fm_bw = 2 * (freq_dev + max_freq_of_source_signal);
fc = 10e3;
y = fmmod(x, fc, fs, freq_dev);
size(y);

% add awgn noise to signal
if ~isempty(snr_db)
    y = awgn(y, snr_db, 'measured', 'db');
end

if plot_modulated_signal
    plot_signal(y, fs, 'modulated');
end

% simulate rf receiver: change to baseband(freq down conversion)
t = (0 : length(y) - 1)' / fs;
y = y .* exp(-1i * 2 * pi * fc * t);

if plot_modulated_signal
    plot_signal(y, fs, 'baseband');
end

% design low pass fir filter
filter_order = 74;
pass_freq = occupied_fm_bw / 2;
filter_coeff = fir1(filter_order, pass_freq / fs * 2);

% low pass filtering
a = 1;
y = filter(filter_coeff, a, y);

if plot_modulated_signal
    plot_signal(y, fs, 'after baseband filter');
end

% you must hear mozart
if sound_demod
    % fm demodulation, coding hint from matlab fmdemod.m
    z = (1 / (2 * pi * freq_dev)) * diff(unwrap(angle(y))) * fs;
    
%     sound(z, fs);
    soundsc(z, fs);
end

end

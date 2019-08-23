function [] = wbfm_modulation(source_sample_length, freq_dev, snr_db, plot_modulated_signal, sound_demod)
% wide band fm modulation
%
% [input]
% - source_sample_length:
% - freq_dev: frequency deviation in hz. max freq_dev = 30e3
%   when max_freq_of_source_signal = 5e3, recommend = 30e3, this make fm modulation index = 6
% - snr_db: snr in db. if empty, noise is NOT added to signal
% - plot_modulated_signal: boolean
% - sound_demod: boolean
%
% [usage]
% wbfm_modulation(8192, 30e3, 10, 1, 0)
% wbfm_modulation(8192, 30e3, '', 1, 0)
% wbfm_modulation(2^18, 30e3, 10, 1, 1)
% wbfm_modulation(2^18, 30e3, '', 1, 1)
% 
% ###################################
% ### sound is NOT OK, need repair
% ###################################

% ###############################################################
% fm modulation index = freq_dev / max_freq_of_source_signal
% narrow band fm: less than 0.5, 0.2 is often used when audio or data bandwidth is small
% wide band fm: above 0.5
% https://www.electronics-notes.com/articles/radio/modulation/fm-frequency-modulation-index-deviation-ratio.php

% max_freq_of_source_signal = 5e3, fm_modulation_index= 6
% frequency deviation = max_freq_of_source_signal * fm_modulation_index = 5e3 * 6 = 30e3
if freq_dev > 30e3
    error('[wbfm] max freq_dev = 30e3 hz\n');
end

source_upsample_ratio = 5;

plot_source_signal = 0;
sound_source = 0;
max_freq_of_source_signal = 5e3; % recommend = 5e3
[x, fs_source] = analog_source(source_sample_length, max_freq_of_source_signal, plot_source_signal, sound_source);

% wide band fm. 
% see carson's rule, https://en.wikipedia.org/wiki/Frequency_modulation
% fm_bandwidth = 2 * (freq_dev + max_freq_of_source_signal)
% fm modulation index = freq_dev / max_freq_of_source_signal
% freq_dev: peak deviation of instantaneous freq from fc
% [example]
% max_freq_of_source_signal = 5e3, freq_dev = 30e3 (modulation index = 6)
% occupied(98%) fm_bandwidth = 70e3
occupied_fm_bw = 2 * (freq_dev + max_freq_of_source_signal);
fc = 40e3;
fs = fs_source * source_upsample_ratio; % (220.5e3 = 44.1e3 * 5)
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

% ########################################################
% ### below comment out: sound is NOT OK, why?
% ########################################################
% % fm demodulation, coding hint from matlab fmdemod.m
% y_demod = (1 / (2 * pi * freq_dev)) * diff(unwrap(angle(double(y)))) * fs;
% 
% if plot_modulated_signal
%     plot_signal(y_demod, fs, 'demodulated');
% end
% 
% % decimation: no sound card can support 220.5e3 sample rate
% filter_order = 74;
% y_decim = decimate(y_demod, source_upsample_ratio, filter_order, 'fir');
% fs_decim = fs / source_upsample_ratio;
% 
% if plot_modulated_signal
%     plot_signal(y_decim, fs_decim, 'decimated');
% end
% 
% % you must hear mozart
% if sound_demod
% %     sound(y_decim, fs_decim);
%     soundsc(y_decim, fs_decim);
% end

end

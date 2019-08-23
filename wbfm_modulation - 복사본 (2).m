function [y, fs] = ...
    wbfm_modulation(source_sample_length, freq_dev, snr_db, plot_modulated_signal, sound_demod, ...
    chan_type, chan_fs, fd, save_iq)
% wide band fm modulation
%
% [input]
% - source_sample_length:
% - freq_dev: frequency deviation in hz. max freq_dev = 30e3
%   when max_freq_of_source_signal = 5e3, recommend = 30e3, this make fm modulation index = 6
% - snr_db: snr in db. if empty, noise is NOT added to signal
% - plot_modulated_signal: boolean
% - sound_demod: boolean
% - chan_type: standard fading channel(rician). one of 'gsmRAx6c1', 'gsmRAx4c2', 'cost207RAx6', 'cost207RAx4'
%   for details, use "help stdchan" in matlab command window
%   if empty, no fading channel
% - chan_fs: channel fs. used for sample period in constructing fading channel object.
%   ##### set to 220.5e3 ((audio source sample rate = 44.1e3) * source_upsample_ratio (= 5))
%   if chan_type is empty, dont care
% - fd: max doppler freq in hz. used in constructing fading channel object. 
%   recommend = 0. dont use fd > 0 (##### you may restart matlab program)
%   if chan_type is empty, dont care
% - save_iq: 0 = no save, 1 = save iq into 'wbfm_modulation.mat' file.
%
% [usage]
% wbfm_modulation(8192, 30e3, 10, 1, 0, 'gsmRAx6c1', 220.5e3, 0, 0);
% wbfm_modulation(8192, 30e3, '', 1, 0, '', 220.5e3, 0, 0);
% wbfm_modulation(2^18, 30e3, 10, 1, 1, 'gsmRAx4c2', 220.5e3, 0, 1);
% wbfm_modulation(2^18, 30e3, '', 1, 1, '', 220.5e3, 0, 1);
% 

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

% wide band fm bandwidth is much larger than source signal bandwidth,
% so interpolate source signal by upsample ratio
% increase sample rate by upsample ratio
x = interp(double(x), source_upsample_ratio);

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

% ####### move to after baseband low pass filtering
% % add awgn noise to signal
% if ~isempty(snr_db)
%     y = awgn(y, snr_db, 'measured', 'db');
% end

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

% apply fading channel
if ~isempty(chan_type)
    ts = 1 / chan_fs;
    % create standard channel
    chan = stdchan(ts, fd, chan_type);
    % pass signal through channel
    y = filter(chan, y);
end

% add awgn noise to signal
if ~isempty(snr_db)
    y = awgn(y, snr_db, 'measured', 'db');
end

% save iq into mat file
if save_iq
    mat_filename = sprintf('%s.mat', mfilename);
    save(mat_filename, 'y', 'fs', 'source_sample_length', 'freq_dev', 'snr_db', 'chan_type', 'chan_fs', 'fd');
end

if plot_modulated_signal
    plot_signal(y, fs, 'after baseband filter');
end

% fm demodulation, coding hint from matlab fmdemod.m
y_demod = (1 / (2 * pi * freq_dev)) * diff(unwrap(angle(y))) * fs;
% remove filter transient part 
y_demod = y_demod(filter_order : end);

if plot_modulated_signal
    plot_signal(y_demod, fs, 'demodulated');
end

% decimation: no sound card can support 220.5e3 sample rate
y_decim = downsample(y_demod, source_upsample_ratio);
fs_decim = fs / source_upsample_ratio;

% % decimation: no sound card can support 220.5e3 sample rate
% filter_order = 74;
% y_decim = decimate(double(y_demod), source_upsample_ratio, filter_order, 'fir');
% fs_decim = fs / source_upsample_ratio;

if plot_modulated_signal
    plot_signal(y_decim, fs_decim, 'decimated');
end

% you must hear mozart
if sound_demod
%     sound(y_decim, fs_decim);
    soundsc(y_decim, fs_decim);
end

end

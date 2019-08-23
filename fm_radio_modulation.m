function [y, fs] = ...
    fm_radio_modulation(source_sample_length, freq_dev, snr_db, plot_modulated_signal, sound_demod, ...
    chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg)
% fm broadcasting radio modulation
%
% #### modified from "fm_radio_modulation(copy).m" (180408)
% #### (1) fs: 400e3 => 500e3 
% #### (2) decimation_ratio = 2 
% #### (3) chan_fs = 500e3 / decimation_ratio = 250e3 (set to be same as real fm radio fs)
% #### (4) input of analog_source function: source_sample_length => source_sample_length * decimation_ratio
%
% [input]
% - source_sample_length:
% - freq_dev: frequency deviation in hz.
%   when max_freq_of_source_signal = 15e3, recommend = 75e3, this make fm modulation index = 5
% - snr_db: snr in db. if empty, noise is NOT added to signal
% - plot_modulated_signal: boolean
% - sound_demod: boolean
% - chan_type: standard fading channel(rician). one of 'gsmRAx6c1', 'gsmRAx4c2', 'cost207RAx6', 'cost207RAx4'
%   for details, use "help stdchan" in matlab command window
%   if empty, no fading channel
% - chan_fs: channel fs. used for sample period in constructing fading channel object.
%   ##### set to 250e3
%   if chan_type is empty, dont care
% - fd: max doppler freq in hz. used in constructing fading channel object. 
%   recommend = 0. dont use fd > 0 (##### you may restart matlab program)
%   if chan_type is empty, dont care
% - save_iq: 0 = no save, 1 = save iq into 'wbfm_modulation.mat' file.
% - max_freq_offset_hz: freq offset = randi([-max_freq_offset_hz, max_freq_offset_hz]). 
%   if 0, no freq offset
% - max_phase_offset_deg: phase offset = randi([-max_phase_offset_deg, max_phase_offset_deg]). 
%   if 0, no phase offset
%
% [usage]
% fm_radio_modulation(8192, 75e3, 10, 1, 0, 'gsmRAx6c1', 250e3, 0, 0, 100, 180);
% fm_radio_modulation(8192, 75e3, '', 1, 0, '', 250e3, 0, 0, 100, 180);
% fm_radio_modulation(2^18, 75e3, 10, 1, 1, 'gsmRAx4c2', 250e3, 0, 1, 100, 180);
% fm_radio_modulation(2^18, 75e3, '', 1, 1, '', 250e3, 0, 1, 100, 180);
% 

% ###############################################################
% fm modulation index = freq_dev / max_freq_of_source_signal
% narrow band fm: less than 0.5, 0.2 is often used when audio or data bandwidth is small
% wide band fm: above 0.5
% https://www.electronics-notes.com/articles/radio/modulation/fm-frequency-modulation-index-deviation-ratio.php

% max_freq_of_source_signal = 75e3, fm_modulation_index = 5
% frequency deviation = max_freq_of_source_signal * fm_modulation_index = 15e3 * 5 = 75e3
if freq_dev > 75e3
    error('[fm radio] max freq_dev = 75e3 hz\n');
end

decimation_ratio = 2;

plot_source_signal = 0;
sound_source = 0;
max_freq_of_source_signal = 15e3; % for fm radio broadcasting, recommend = 15e3
[x, fs_source] = ...
    analog_source(source_sample_length * decimation_ratio, max_freq_of_source_signal, plot_source_signal, sound_source);

% wide band fm bandwidth is much larger than source signal bandwidth,
% so interpolate source signal by upsample ratio
% increase sample rate by upsample ratio
% x = interp(x, source_upsample_ratio, 8, .5);
% x = interp(x, source_upsample_ratio);
% x = interp(double(x), source_upsample_ratio);

% wide band fm. 
% see carson's rule, https://en.wikipedia.org/wiki/Frequency_modulation
% fm_bandwidth = 2 * (freq_dev + max_freq_of_source_signal)
% fm modulation index = freq_dev / max_freq_of_source_signal
% freq_dev: peak deviation of instantaneous freq from fc
% [example]
% max_freq_of_source_signal = 15e3, freq_dev = 75e3 (modulation index = 5)
% occupied(98%) fm_bandwidth = 180e3
occupied_fm_bw = 2 * (freq_dev + max_freq_of_source_signal);
fc = 100e3;
fs = 500e3;
y = fmmod(x, fc, fs, freq_dev);
size(y);

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

% remove filter transient (180407)
y = y(round(filter_order / 2) : end);

% apply fading channel
if ~isempty(chan_type)
    y = apply_fading_channel(y, chan_type, chan_fs, fd);
end

% apply carrier offset
if max_freq_offset_hz || max_phase_offset_deg
    y = apply_carrier_offset(y, chan_fs, max_freq_offset_hz, max_phase_offset_deg);
end

% add awgn noise to signal
if ~isempty(snr_db)
    y = awgn(y, snr_db, 'measured', 'db');
end

% decimate
y = downsample(y, decimation_ratio);
fs = fs / 2;

% save iq into mat file
if save_iq
    mat_filename = sprintf('%s.mat', mfilename);
    save(mat_filename, 'y', 'fs', 'source_sample_length', 'freq_dev', 'snr_db', 'chan_type', 'chan_fs', 'fd');
end

if plot_modulated_signal
    plot_signal(y, fs, 'after baseband filter');
end

% % fm demodulation, coding hint from matlab fmdemod.m
% y_demod = (1 / (2 * pi * freq_dev)) * diff(unwrap(angle(y))) * fs;
% 
% % % remove filter transient part 
% % y_demod = y_demod(filter_order : end);
% 
% if plot_modulated_signal
%     plot_signal(y_demod, fs, 'demodulated');
% end

% % decimation: no sound card can support 220.5e3 sample rate
% y_decim = downsample(y_demod, source_upsample_ratio);
% fs_decim = fs / source_upsample_ratio;

% % decimation: no sound card can support 220.5e3 sample rate
% filter_order = 74;
% y_decim = decimate(double(y_demod), source_upsample_ratio, filter_order, 'fir');
% fs_decim = fs / source_upsample_ratio;

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

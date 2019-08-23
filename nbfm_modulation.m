function [y, fs] = ...
    nbfm_modulation(source_sample_length, freq_dev, snr_db, plot_modulated_signal, sound_demod, ...
    chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg)
% narrow band fm modulation
%
% [input]
% - source_sample_length:
% - freq_dev: frequency deviation in hz. max freq_dev = 1e3
%   when max_freq_of_source_signal = 5e3, recommend = 1e3, this make fm modulation index = 0.2
% - snr_db: snr in db. if empty, noise is NOT added to signal
% - plot_modulated_signal: boolean
% - sound_demod: boolean
% - chan_type: standard fading channel(rician). one of 'gsmRAx6c1', 'gsmRAx4c2', 'cost207RAx6', 'cost207RAx4'
%   for details, use "help stdchan" in matlab command window
%   if empty, no fading channel
% - chan_fs: channel fs. used for sample period in constructing fading channel object.
%   ##### set to be same as audio source sample rate (wav file sample rate = 44.1e3)
%   even if chan_type is empty, "apply_carrier_offset" function use it.
% - fd: max doppler freq in hz. used in constructing fading channel object. 
%   recommend = 0. dont use fd > 0 (##### you may restart matlab program)
%   if chan_type is empty, dont care
% - save_iq: 0 = no save, 1 = save iq into 'nbfm_modulation.mat' file.
% - max_freq_offset_hz: freq offset = randi([-max_freq_offset_hz, max_freq_offset_hz]). 
%   if 0, no freq offset
% - max_phase_offset_deg: phase offset = randi([-max_phase_offset_deg, max_phase_offset_deg]). 
%   if 0, no phase offset
%
% [usage]
% nbfm_modulation(8192, 1e3, 10, 1, 0, 'gsmRAx6c1', 44.1e3, 0, 0, 100, 180);
% nbfm_modulation(8192, 1e3, '', 1, 0, '', 44.1e3, 0, 0, 100, 180);
% nbfm_modulation(2^18, 1e3, 10, 1, 1, 'gsmRAx4c2', 44.1e3, 0, 1, 100, 180);
% nbfm_modulation(2^18, 1e3, '', 1, 1, '', 44.1e3, 0, 1, 100, 180);
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

% save iq into mat file
if save_iq
    mat_filename = sprintf('%s.mat', mfilename);
    save(mat_filename, 'y', 'fs', 'source_sample_length', 'freq_dev', 'snr_db', 'chan_type', 'chan_fs', 'fd');
end

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

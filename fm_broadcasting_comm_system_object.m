function [y, fs] = ...
    fm_broadcasting_comm_system_object(modulated_sample_length, snr_db, plot_modulated_signal, ...
    sound_demod, chan_type, chan_fs, fd, max_freq_offset_hz, max_phase_offset_deg)
% fm broadcasting radio modulation using comm system object
% ##### "fm_radio_modulation.m" was replaced with this function in "gen_wbfm_mod_iq.m" (180720)
% ##### only good from matlab r2017b
%
% #### difference from "fm_radio_modulation.m"
% #### 'comm.FMBroadcastModulator', 'comm.FMBroadcastDemodulator' system object is used:
% #### this make code very nice because system object is for baseband, not passband
% #### chan_fs: 250e3 => 200e3
%
% [input]
% - source_sample_length:
% - snr_db: snr in db. if empty, noise is NOT added to signal
% - plot_modulated_signal: boolean
% - sound_demod: boolean
% - chan_type: standard fading channel(rician). one of 'gsmRAx6c1', 'gsmRAx4c2', 'cost207RAx6', 'cost207RAx4'
%   for details, use "help stdchan" in matlab command window
%   if empty, no fading channel
% - chan_fs: channel fs. used for sample period in constructing fading channel object.
%   ##### set to 200e3
%   if chan_type is empty, dont care
% - fd: max doppler freq in hz. used in constructing fading channel object. 
%   recommend = 0. dont use fd > 0 (##### you may restart matlab program)
%   if chan_type is empty, dont care
% - max_freq_offset_hz: freq offset = randi([-max_freq_offset_hz, max_freq_offset_hz]). 
%   if 0, no freq offset
% - max_phase_offset_deg: phase offset = randi([-max_phase_offset_deg, max_phase_offset_deg]). 
%   if 0, no phase offset
%
% [usage]
% fm_broadcasting_comm_system_object(8192, 10, 1, 0, 'gsmRAx6c1', 250e3, 0, 0, 100, 180);
% fm_broadcasting_comm_system_object(8192, '', 1, 0, '', 250e3, 0, 0, 100, 180);
% fm_broadcasting_comm_system_object(2^18, 10, 1, 1, 'gsmRAx4c2', 250e3, 0, 1, 100, 180);
% fm_broadcasting_comm_system_object(2^18, '', 1, 1, '', 250e3, 0, 1, 100, 180);
% 

% ###############################################################
% fm modulation index = freq_dev / max_freq_of_source_signal
% narrow band fm: less than 0.5, 0.2 is often used when audio or data bandwidth is small
% wide band fm: above 0.5
% https://www.electronics-notes.com/articles/radio/modulation/fm-frequency-modulation-index-deviation-ratio.php

% % max_freq_of_source_signal = 75e3, fm_modulation_index = 5
% % frequency deviation = max_freq_of_source_signal * fm_modulation_index = 15e3 * 5 = 75e3
% if freq_dev > 75e3
%     error('[fm radio] max freq_dev = 75e3 hz\n');
% end

wav_filename = 'mozart_mono.wav';
[x, audio_sample_rate] = audioread(wav_filename);

% ##### there is length limit in input of fmbMod ("comm.FMBroadcastModulator" system object)
% ##### when 'mozart_mono.wav', 'length(x) / 441 / 6' is good, 'length(x) / 441 / 5' is bad
frame_length = fix(length(x) / 441 / 6);
x = x(1 : frame_length * 441);
size(x);

% fm broadcasting signal sample rate
fs = 200e3;

% Create FM broadcast modulator and demodulator objects. 
% Set the "AudioSampleRate" property to match the sample rate of the input signal.
% Set the "SampleRate" property of the demodulator 
% to match the specified sample rate of the modulator.
fmbMod = comm.FMBroadcastModulator('AudioSampleRate', audio_sample_rate, 'SampleRate', fs);
fmbDemod = comm.FMBroadcastDemodulator('AudioSampleRate', audio_sample_rate, 'SampleRate', fs);

% % Use the "info" method to determine the audio decimation factor of the filter in the modulator object. 
% % The length of the sequence input to the object must be an integer multiple of the object's decimation factor.
% info(fmbMod);
% 
% % Use the "info" method to determine the audio decimation factor of the filter in the demodulator object.
% info(fmbDemod);

% The audio decimation factor of the modulator is a multiple of the audio frame length of 44100. 
% The audio decimation factor of the demodulator is
% an integer multiple of the 200000 samples data sequence length of the modulator output.

% Modulate the audio signal and plot its spectrum.
% "comm.FMBroadcastModulator" output sample rate is same as 'SampleRate' input of "comm.FMBroadcastModulator"
y = fmbMod(x);
size(y);
min(abs(y));
max(abs(y));

if plot_modulated_signal
    title_text = 'after modulation';
    plot_signal(y, fs, title_text);
%     plot_signal(y(4096:4096 * 10), fs, title_text);
end

if sound_demod
    % Demodulate "y"
    z = fmbDemod(y);
    size(z);
    
    if plot_modulated_signal
        title_text = 'after demodulation';
        plot_signal(z, audio_sample_rate, title_text); % ### this is right, below is wrong (maybe)
        %     plot_signal(z, fs, title_text);
    end
    
    soundsc(z, audio_sample_rate);
end

% select randomly samples as many as "modulated_sample_length" from modulated signal, "y"
sample_length = length(y);
idx = randi(sample_length - modulated_sample_length, 1);
y = y(idx : idx + modulated_sample_length - 1);

% decimation_ratio = 2;
% 
% plot_source_signal = 0;
% sound_source = 0;
% max_freq_of_source_signal = 15e3; % for fm radio broadcasting, recommend = 15e3
% [x, fs_source] = ...
%     analog_source(source_sample_length * decimation_ratio, max_freq_of_source_signal, plot_source_signal, sound_source);
% 
% % wide band fm bandwidth is much larger than source signal bandwidth,
% % so interpolate source signal by upsample ratio
% % increase sample rate by upsample ratio
% % x = interp(x, source_upsample_ratio, 8, .5);
% % x = interp(x, source_upsample_ratio);
% % x = interp(double(x), source_upsample_ratio);
% 
% % wide band fm. 
% % see carson's rule, https://en.wikipedia.org/wiki/Frequency_modulation
% % fm_bandwidth = 2 * (freq_dev + max_freq_of_source_signal)
% % fm modulation index = freq_dev / max_freq_of_source_signal
% % freq_dev: peak deviation of instantaneous freq from fc
% % [example]
% % max_freq_of_source_signal = 15e3, freq_dev = 75e3 (modulation index = 5)
% % occupied(98%) fm_bandwidth = 180e3
% occupied_fm_bw = 2 * (freq_dev + max_freq_of_source_signal);
% fc = 100e3;
% fs = 500e3;
% y = fmmod(x, fc, fs, freq_dev);
% size(y);
% 
% if plot_modulated_signal
%     plot_signal(y, fs, 'modulated');
% end
% 
% % simulate rf receiver: change to baseband(freq down conversion)
% t = (0 : length(y) - 1)' / fs;
% y = y .* exp(-1i * 2 * pi * fc * t);
% 
% if plot_modulated_signal
%     plot_signal(y, fs, 'baseband');
% end
% 
% % design low pass fir filter
% filter_order = 74;
% pass_freq = occupied_fm_bw / 2;
% filter_coeff = fir1(filter_order, pass_freq / fs * 2);
% 
% % low pass filtering
% a = 1;
% y = filter(filter_coeff, a, y);
% 
% % remove filter transient (180407)
% y = y(round(filter_order / 2) : end);

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

% % decimate
% y = downsample(y, decimation_ratio);
% fs = fs / 2;

% % save iq into mat file
% if save_iq
%     mat_filename = sprintf('%s.mat', mfilename);
%     save(mat_filename, 'y', 'fs', 'source_sample_length', 'freq_dev', 'snr_db', 'chan_type', 'chan_fs', 'fd');
% end
% 
% if plot_modulated_signal
%     plot_signal(y, fs, 'after baseband filter');
% end

end

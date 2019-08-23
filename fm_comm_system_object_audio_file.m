function [] = fm_comm_system_object_audio_file(wav_filename, wide_band_fm)
% frequency modulation using comm system object
% ##### only good from r2016b communication system toolbox
%
% [input]
% - wav_filename: 'wav' filename, mono channel (not tested for stereo channel)
% - wide_band_fm: 1 = wide band fm, 0 = narrow band fm
%
% [usage]
% fm_comm_system_object_audio_file('guitartune.wav', 1)
% fm_comm_system_object_audio_file('guitartune.wav', 0)
%
 
% see carson's rule, https://en.wikipedia.org/wiki/Frequency_modulation
% fm_bandwidth = 2 * (freq_dev + max_freq_of_source_signal)
% fm modulation index = freq_dev / max_freq_of_source_signal

% ##### wide band fm (large freq deviation) example: fm radio broadcasting
% max_freq_of_source_signal = 15e3, freq_dev = 75e3 (modulation index = 5)
% occupied(98%) fm_bandwidth = 180e3

% ##### narrow band fm (small freq devation) example: 
% max_freq_of_source_signal = 5e3, freq_dev = 1e3 (modulation index = 0.2)
% occupied(98%) fm_bandwidth = 12e3

% wav_filename = 'guitartune.wav';
% wav_filename = 'mozart_mono.wav';

% read audio sample from audio file
[x, audio_sample_rate] = audioread(wav_filename);
audio_sample_rate;
audioinfo(wav_filename)

% create fm modulator system object
if wide_band_fm
%     MOD = comm.FMModulator('FrequencyDeviation', 75e3, 'SampleRate', 240e3); %default
    MOD = comm.FMModulator;
else
    MOD = comm.FMModulator('FrequencyDeviation', 1e3, 'SampleRate', 12e3);
%     MOD = comm.FMModulator('FrequencyDeviation', 1e3, 'SampleRate', 44.1e3);
end
MOD

% create fm demodulator system object
if wide_band_fm
%     DEMOD = comm.FMDemodulator('FrequencyDeviation', 75e3, 'SampleRate', 240e3); %default
    DEMOD = comm.FMDemodulator;
else
    DEMOD = comm.FMDemodulator('FrequencyDeviation', 1e3, 'SampleRate', 12e3);
%     DEMOD = comm.FMDemodulator('FrequencyDeviation', 1e3, 'SampleRate', 44.1e3);
end
DEMOD

% fm modulation
y = MOD(x);

% fm demodulation
z = DEMOD(y);

% play sound
soundsc(z, audio_sample_rate);
% to stop sound, use "clear sound" command

end


function [] = sound_fm_radio_iq_sample(mat_filename, freq_dev)
% 
% [usage]
% sound_fm_radio_iq_sample('E:\fsq_iq\data\fsq_iq_180706164550_98.5_0.2_0.25.mat', 75e3)

load(mat_filename);

fs = sample_rate_mhz * 1e6;

% z = fmdemod(iq, fc, fs, freq_dev);

% fm demodulation, coding hint from matlab fmdemod.m
z = (1 / (2 * pi * freq_dev)) * diff(unwrap(angle(iq))) * fs;

sound_fs = 44.1e3;
%     sound(z, fs);
soundsc(z, sound_fs);


end

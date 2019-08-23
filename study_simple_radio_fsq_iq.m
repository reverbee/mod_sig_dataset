function [] = study_simple_radio_fsq_iq(mat_filename, sound_audio)
% study simple radio signal got from r&s fsq26
%
% [input]
% - mat_filename: mat filename
% - sound_audio: boolean. 1 = playing sound, 0 = no playing
%
% [usage]
% study_simple_radio_fsq_iq('E:\real_signal\simple\fsq_iq_190102133150_146.512500_0.008500_0.015000.mat', 1)
% study_simple_radio_fsq_iq('\\P6X58D-W10\test\fsq_iq_190724101750_146.512500_0.012000.mat', 1)

% fm freq deviation
freq_dev_hz = 2.5e3; % see "simple licensed radio technical spec[final] ver1.hwp"
% freq_dev_hz = 7e3;
% freq_dev_hz = 1e3;

% audio_sample_rate = 44.1e3 / 3; % ### get this by only playing sound many times

% ########## reminder: what is in mat file 
% ########## see "simple_radio_get_iq.py"
%
% # for backward compatibility: see "get_iq_from_fsq_181122.m" and "plot_fsq_iq.m"
%     savemat(mat_filepath,
%             dict([('iq', iq), ('center_freq_mhz', fsq_freq_mhz), ('signal_bw_mhz', bw_mhz),
%                   ('sample_rate_mhz', sample_rate_mhz), ('sample_length', iq_length)]))
%
% ########## also see "get_iq_from_fsq.m"
%
% % save iq into file
%     save(filename, 'iq', 'center_freq_mhz', 'signal_bw_mhz', 'sample_rate_mhz', 'sample_length', 'timestamp');

load(mat_filename);
center_freq_mhz;
% ### comment out 'signal_bw_mhz' because (sample rate * .8) is (signal bw)
% signal_bw_mhz;
sample_rate_mhz;
% sure shot for column vector, "get_iq_from_fsq.py" save iq array with row vector format
iq = iq(:);
size(iq)

fs_hz = sample_rate_mhz * 1e6;
[~, filename, ~] = fileparts(mat_filename);
% remove 'fsq_iq_' string from filename to see y-axis of plot (signal level order)
title_text = erase(filename, 'fsq_iq_');
plot_signal(iq, fs_hz, title_text);

if sound_audio
%     sample_rate_hz = sample_rate_mhz * 1e6;
    % comm.FMDemodulator default: 'FrequencyDeviation', 75e3, 'SampleRate', 240e3
    DEMOD = comm.FMDemodulator('FrequencyDeviation', freq_dev_hz, 'SampleRate', fs_hz);
    
    % fm demodulation
    z = DEMOD(iq);
    size(z)
    
    % play sound
    % to stop sound, use "clear sound" command
%     audio_sample_rate = sample_rate_hz;
    soundsc(z, fs_hz);
end

end

%%
function [] = generate_fm_signal_comm_system_object(freq_dev, sample_rate, signal_plot_length, ...
    sound_audio, save_signal)
% generate fm signal using comm system object
% ### simulate narrow band fm signal (example: simplified license radio station)
%
% [input]
% - freq_dev: frequency deviation
% - sample_rate: sample rate
% - signal_plot_length: signal plot length. less than "min_signal_plot_length" = no plot
% - sound_audio: boolean. 0 = no sound, 1 = sound
% - save_signal: boolean. to speed up modulation classification dataset generation
%
% [usage]
% generate_fm_signal_comm_system_object(1e3, 12e3, 2^12, 1, 0)
%

% to speed up modulation classification dataset generation
% save_signal = 1;

min_signal_plot_length = 2^10;

wav_filename = 'mozart_mono.wav';
A = audioinfo(wav_filename);
total_sample = A.TotalSamples;
if signal_plot_length > total_sample
    fprintf('#### error: max sample length = %d\n', total_sample);
    return;
end
[x, audio_sample_rate] = audioread(wav_filename);
size(x)

% comm.FMModulator default: 'FrequencyDeviation', 75e3, 'SampleRate', 240e3
MOD = comm.FMModulator('FrequencyDeviation', freq_dev, 'SampleRate', sample_rate);

% comm.FMDemodulator default: 'FrequencyDeviation', 75e3, 'SampleRate', 240e3
DEMOD = comm.FMDemodulator('FrequencyDeviation', freq_dev, 'SampleRate', sample_rate);

% fm modulation
y = MOD(x);
size(y)

if save_signal
    signal_filename = sprintf('inf_snr_narrow_band_fm_%d_%d.mat', fix(freq_dev / 1e3), fix(sample_rate / 1e3));
    save(signal_filename, 'y', 'freq_dev', 'sample_rate', 'wav_filename');
end

% % discard initial transient sample
% % transient part (30 msec), see spectrum
% % below "7200" = 30e-3 * 240e3(= sample_rate)
% initial_transient_sample_length = 0;
% y = y(initial_transient_sample_length + 1 : end);

% fm demodulation
z = DEMOD(y);
size(z)

% % discard initial transient sample
% z = z(10 : end);
    
if sound_audio
    
    % play sound
    soundsc(z, audio_sample_rate);
    
end

if signal_plot_length >= min_signal_plot_length
    
    title_text = 'after fm mod';
    
    plot_signal(y(1 : signal_plot_length), sample_rate, title_text);

    title_text = 'audio source, after fm demod';

%     % ##### there is time delay between original signal and demodulated signal (see time domain plot)
%     % ##### but this is NOT my concern
    plot_signal([x(1 : signal_plot_length), z(1 : signal_plot_length)], audio_sample_rate, title_text);
    
end

end


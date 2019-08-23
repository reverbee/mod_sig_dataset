function [] = generate_fm_signal_comm_system_object(freq_dev, sample_rate, sound_audio, save_signal)
% generate fm signal using comm system object
% ### simulate narrow band fm signal (example: simplified license radio station)
%
% [input]
% - freq_dev: frequency deviation. for simple radio, 2.5e3
% - sample_rate: fm modulator input sample rate.
%   fm modulator output sample rate is equal to input sample rate
%   one of 11025(= 44100 / 4), 14700(= 44100 / 3).
%   audio sample rate = 44100
%   fsq bw = sample_rate * .8 (11025 * .8 = 8820, 14700 * .8 = 11760)
% - sound_audio: boolean. 0 = no sound, 1 = sound
% - save_signal: boolean. to speed up modulation classification dataset generation
%
% [usage]
% generate_fm_signal_comm_system_object(2.5e3, 11025, 1, 0)
% generate_fm_signal_comm_system_object(2.5e3, 14700, 1, 0)
%
% #########################################################################################
% "sample_rate" input: comm.FMBroadcastModulator vs comm.FMModulator
%
% when "comm.FMBroadcastModulator", "sample_rate" input = Output signal sample rate (Hz)
% when "comm.FMModulator", "sample_rate" input = Sample rate of the input signal (Hz)
% #########################################################################################

wav_filename = 'mozart_mono.wav';
[x, audio_sample_rate] = audioread(wav_filename);
size(x)

title_text = 'audio signal';
plot_signal_time_domain(x, audio_sample_rate, title_text);

if mod(audio_sample_rate, sample_rate)
    fprintf('when audio sample rate = 44100, ''sample_rate'' must be one of 11025, 14700\n');
    return;
end

% decimate audio signal
decimation_rate = audio_sample_rate / sample_rate;
x = decimate(x, decimation_rate);

title_text = 'decimated audio signal';
plot_signal_time_domain(x, sample_rate, title_text);

% comm.FMModulator default: 'FrequencyDeviation', 75e3, 'SampleRate', 240e3
MOD = comm.FMModulator('FrequencyDeviation', freq_dev, 'SampleRate', sample_rate);

% comm.FMDemodulator default: 'FrequencyDeviation', 75e3, 'SampleRate', 240e3
DEMOD = comm.FMDemodulator('FrequencyDeviation', freq_dev, 'SampleRate', sample_rate);

% fm modulation
y = MOD(x);
size(y)

title_text = 'fm mod signal';
plot_signal_time_domain(y, sample_rate, title_text);

if save_signal
    signal_filename = sprintf('inf_snr_narrow_band_fm_%d_%d.mat', freq_dev, sample_rate);
    save(signal_filename, 'y', 'freq_dev', 'sample_rate', 'wav_filename');
end

% fm demodulation
z = DEMOD(y);
size(z)

title_text = 'fm demod signal';
plot_signal_time_domain(z, sample_rate, title_text);
    
if sound_audio
    % play sound
    soundsc(z, audio_sample_rate);    
end

end




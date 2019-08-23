function [] = generate_fm_broadcast_signal_comm_system_object(stereo, signal_plot_length, ...
    sound_audio, save_signal)
% generate fm broadcast signal using comm system object
%
% [input]
% - stereo: boolean. 0 = mono, 1 = stereo
% - signal_plot_length: less than "min_signal_plot_length" = no plot, '' = plot all signal
% - sound_audio: boolean. 0 = no sound, 1 = sound
% - save_signal: boolean. to speed up modulation classification dataset generation
%
% [usage]
% generate_fm_broadcast_signal_comm_system_object(0, 2^18, 1, 0)
% generate_fm_broadcast_signal_comm_system_object(1, 2^18, 1, 0)
%

% to speed up modulation classification dataset generation
% save_signal = 1;

min_signal_plot_length = 2^10;

% ##### MUST USE 'mozart_stereo.wav'
% ##### when SET to 1(stereo), there is NO problem
wav_filename = 'mozart_stereo.wav';
[x, audio_sample_rate] = audioread(wav_filename);
size(x)
max(x);

% DONT USE wav_filename = 'never_ending_love_stereo.wav';
% #### when SET to 1(stereo), there is problem: 
% #### (1) there is noisy audio after demodulation
% #### (2) fm broadcast modulation spectrum is NOT normal 
% #### dont show stereo pilot at 19e3 hz, mono audio left + right, and stereo audio left - right
% #### https://kr.mathworks.com/help/comm/ref/comm.fmbroadcastmodulator-system-object.html
% #### 
% #### this problem may be fixed in future version (current(180720) version = r2017b)
% wav_filename = 'never_ending_love_stereo.wav';

% ##### what is difference between two audio file('mozart_stereo.wav', 'never_ending_love_stereo.wav')?
% ##### 'never_ending_love_stereo.wav' have large amplitude (max = 1, min = -1)
% ##### 'mozart_stereo.wav' (max = 0.4, min = -0.4)
% ##### retry after scale down amplitude of 'never_ending_love_stereo.wav'

% ##### overwrite original audio sample rate from "audioread"
% ##### default 'AudioSampleRate' in 'comm.FMBroadcastModulator' = 48e3, MUST USE THIS DEFAULT!
audio_sample_rate = 48e3;

% below "48" come from 48e3 (audio sample rate, not original sample rate in audio file)
% ##### input length in 'comm.FMBroadcastModulator' system object MUST be multiple of 48
frame_length = fix(length(x) / 48);
if stereo
    x = x(1 : frame_length * 48, :);
else
    x = x(1 : frame_length * 48, 1);
end
size(x)

% below "441" come from 44.1e3 (audio sample rate)
% ##### there is length limit in input of fmbMod ("comm.FMBroadcastModulator" system object)
% ##### "length(x) / 441 / 2.5" in 'never_ending_love_stereo.wav' is max without no error
% ##### when 'mozart_mono.wav', 'length(x) / 441 / 6' is good, 'length(x) / 441 / 5' is bad
% frame_length = fix(length(x) / 441 / 2.5);
% if stereo
%     x = x(1 : frame_length * 441, :);
% else
%     x = x(1 : frame_length * 441, 1);
% end
% size(x)

% default 'SampleRate' in 'comm.FMBroadcastModulator' = 240e3, MUST USE THIS DEFAULT!
sample_rate = 240e3;
% sample_rate = 200e3;

% ##### 'comm.FMBroadcastModulator' system object properties
% 'SampleRate', default = 240e3
% 'FrequencyDeviation', default = 75e3
% 'FilterTimeConstant', default = 7.5e-05
% 'AudioSampleRate', default = 48e3
% 'Stereo', default = false
% 'RBDS' (Radio Broadcast Data System), default = false
% 'RBDSSamplesPerSymbol', default = 10

% ##### 'comm.FMBroadcastDemodulator' system object properties
% 'SampleRate', default = 240e3
% 'FrequencyDeviation', default = 75e3
% 'FilterTimeConstant', default = 7.5e-05
% 'AudioSampleRate', default = 48e3
% 'PlaySound', default = false
% 'BufferSize', default = 4096
% 'Stereo', default = false
% 'RBDS' (Radio Broadcast Data System), default = false
% 'RBDSSamplesPerSymbol', default = 10
% 'RBDSCostasLoop', default = false

% Create FM broadcast modulator and demodulator objects.
% Set the "AudioSampleRate" property to match the sample rate of the input signal.
% Set the "SampleRate" property of the demodulator
% to match the specified sample rate of the modulator.
if stereo
    fmbMod = comm.FMBroadcastModulator('AudioSampleRate',audio_sample_rate, ...
        'SampleRate',sample_rate,'Stereo',true);
    fmbDemod = comm.FMBroadcastDemodulator('AudioSampleRate',audio_sample_rate, ...
        'SampleRate',sample_rate,'Stereo',true);
else
    fmbMod = comm.FMBroadcastModulator('AudioSampleRate',audio_sample_rate, ...
        'SampleRate',sample_rate);
    fmbDemod = comm.FMBroadcastDemodulator('AudioSampleRate',audio_sample_rate, ...
        'SampleRate',sample_rate);
end

% fm broadcast modulation
y = fmbMod(x);
size(y)

% discard initial transient sample
% ##### length of "y", "fmbDemod" input, MUST BE multiple of 240: 'SampleRate' = 240e3
% transient part (400 msec), see spectrum
% below "96000" = 400e-3 * 240e3
y = y(240 * 400 + 1 : end);
% y = y(950000 : end);

if save_signal
    signal_filename = sprintf('inf_snr_fm_broadcast_%d_%d.mat', ...
        fix(audio_sample_rate / 1e3), fix(sample_rate / 1e3));
    save(signal_filename, 'y', 'audio_sample_rate', 'sample_rate', 'wav_filename', 'stereo');
end

% sound audio
if sound_audio
    % fm broadcast demodulation
    z_audio = fmbDemod(y);
    size(z_audio)
    
    soundsc(z_audio, audio_sample_rate);
end

sample_length = length(y);

if isempty(signal_plot_length) || signal_plot_length >= min_signal_plot_length
    
    if ~isempty(signal_plot_length)
        if signal_plot_length > sample_length
            signal_plot_length = sample_length;
        end
            
        y = y(1 : signal_plot_length);
    end
    
    if stereo
        title_text = '[stereo] before fm demod';
    else
        title_text = '[mono] before fm demod';
    end
    
    plot_signal(y, sample_rate, title_text);
    
    % ##### 'comm.FMDemodulator' system object properties
    % 'FrequencyDeviation', default = 75e3
    % 'SampleRate', default = 240e3
    
    % create fm demodulator
    freq_dev = 75e3;
    fmDemod = comm.FMDemodulator('FrequencyDeviation', freq_dev, 'SampleRate', sample_rate);
    
    % fm demodulate
    z = fmDemod(y);
    size(z)

    if stereo
        title_text = '[stereo] after fm demod';
    else
        title_text = '[mono] after fm demod';
    end
    plot_signal(z, sample_rate, title_text);
    
end

end


function [y, fs] = analog_source(source_sample_length, max_freq_of_source_signal, plot_source_signal, sound_source)
% make source signal for analog modulation
%
% [input]
% - source_sample_length: source sample length
% - max_freq_of_source_signal: max freq of source signal in hz. recommend 5e3
% - plot_source_signal: boolean
% - sound_source: boolean
%
% [output]
% - y: source signal, pass_freq filtered, length = source_sample_length
% - fs: sample rate
% - pass_freq: pass band freq
%
% [usage]
% analog_source(8192, 5e3, 1, 0);
% analog_source(8192, 5e3, 0, 0);
% analog_source(2^18, 5e3, 1, 1);
%

% #####################################################################################
% #### MUST set to 0 (dont set to 1: DO NOT normalize analog source sample)
% #### 
% #### when 256 audio sample read from wav file is all zero,
% #### normalization make "nan" output (nan: Not A Number, zero divided by zero),
% #### which take place very rarely! 
% ####
% #### this rare "nan" in training dataset also make loss of CNN "nan"
% ####
% #### i spent a week to fix this bug!
% ####
% #### audio sample range in "mozart.wav" = [-0.4147, 0.4305]
% #####################################################################################
% normalize_source = 0;

% mozart clarinet concerto in A major, K. 622
wav_filename = 'mozart_mono.wav'; % MUST USE THIS
% wav_filename = 'mozart.wav'; % DO NOT USE, first 2000 zero sample make "nan" problem 

% get audio file info
info = audioinfo(wav_filename);
channel_length = info.NumChannels;
fs = info.SampleRate;
file_sample_length = info.TotalSamples;
max_source_sample_length = round(file_sample_length / 2);
if source_sample_length >= max_source_sample_length
    error('###### source_sample_length must be less than %d\n', max_source_sample_length);
end

% bit number per sample
bit_per_sample = info.BitsPerSample;
switch bit_per_sample
    case 8
        integer_class = 'int8';
    case 16
        integer_class = 'int16';
    otherwise
        error('unknown integer_class');
end

% read sample from audio file
initial_idx = randi(file_sample_length - source_sample_length);
y = audioread(wav_filename, [initial_idx, initial_idx + source_sample_length - 1]);
% ##########################################################################
% #### default data type = 'double'
% #### DONT use 'native' data type, which give integer data type. 
% #### for details, use "help audioread"
% ##########################################################################
% y = audioread(wav_filename, [initial_idx, initial_idx + source_sample_length - 1], 'native');

% if stereo, change to mono
if channel_length == 2
    y = y(:, 1);
end

% % convert integer to single float. 
% % this is needed because audioread function have 'native' data type.
% y = single(y) / single(intmax(integer_class));

if plot_source_signal
    plot_signal(y, fs, 'before filter');
end

% design low pass fir filter
filter_order = 74;
pass_freq = max_freq_of_source_signal;
filter_coeff = fir1(filter_order, pass_freq / fs * 2);

% low pass filtering
a = 1;
y = filter(filter_coeff, a, y);

% remove filter transient (180407)
y = y(round(filter_order / 2) : end);

% if normalize_source
%     y = y / max(abs(y)) * .9;
% end

if plot_source_signal
    plot_signal(y, fs, 'after filter');
end

if sound_source
%     sound(y, fs);
    soundsc(y, fs);
end

end


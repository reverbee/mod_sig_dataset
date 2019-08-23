function [] = check_audioread_nan
% ################### test result: 
% (1) audioread is clean
% (2) 'mozart.wav' wave file is clean
%
% ##### you can also check like below: (this need only a few seconds to run!)
%
% y = audioread(wav_filename);
% sum(sum(isnan(y)) => this give 0
%
% 

run_length = 100000;

iq_sample_length = 128;
source_sample_length = iq_sample_length * 2;

% normalize_source = 1;

% mozart clarinet concerto in A major, K. 622
wav_filename = 'mozart.wav';

% get audio file info
info = audioinfo(wav_filename);
channel_length = info.NumChannels;
fs = info.SampleRate;
file_sample_length = info.TotalSamples;
max_source_sample_length = round(file_sample_length / 2);
if source_sample_length >= max_source_sample_length
    error('###### source_sample_length must be less than %d\n', max_source_sample_length);
end

% % bit number per sample
% bit_per_sample = info.BitsPerSample;
% switch bit_per_sample
%     case 8
%         integer_class = 'int8';
%     case 16
%         integer_class = 'int16';
%     otherwise
%         error('unknown integer_class');
% end
for n = 1 : run_length
   
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
    
    if sum(isnan(y))
        y.'
        fprintf('### [%d] nan\n', n);
        error('####### error: failed to avoid nan output in fading channel');
    end
    
end

end

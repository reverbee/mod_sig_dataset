function [] = remove_consecutive_zero_in_wav_file(wav_filename, consecutive_zero_length)
% ########### incomplete ############
%
% [usage]
% remove_consecutive_zero_in_wav_file('mozart_mono.wav', 128)
%

y = audioread(wav_filename);

% when y is zero, set to 1. otherwise set to 0
y_bool = y == 0;

% find index in y whose value is zero
idx = find(y_bool);

idx2 = diff(idx);

% idx2_bool = idx2 == 1;
% 
% idx3 = find(idx2_bool);
% 
% idx4 = diff(idx3);

end
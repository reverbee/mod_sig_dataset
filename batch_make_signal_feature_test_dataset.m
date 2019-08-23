function [] = ...
    batch_make_signal_feature_test_dataset(signal_dir, save_dir, filename_prepend_string, signal_threshold, ...
    sample_rate_select)
% batch version of "make_signal_feature_test_dataset_190123.m"
%
% [input]
% - signal_dir: directory where signal file live
% - save_dir: directory where feature file will be saved
% - filename_prepend_string: string prepended to feature filename 
% - signal_threshold: signal threshold. 
%   if zero, signal threshold is NOT applied.
%   otherwise iq whose smoothed and normalized magnitude is less than signal threshold is removed.
% - sample_rate_select: sample rate select string 
%   for exmple, signal files with specific sample rate are only selected.
%   if empty, all file in signal directory are selected.
%
% [usage]
% batch_make_signal_feature_test_dataset('E:\real_signal\simple', 'E:\real_signal\feature_simple', 'simple_feature', .1, '0.012000')
%

if isempty(sample_rate_select)
    D = dir(sprintf('%s\\*.mat', signal_dir));
else
    D = dir(sprintf('%s\\*_%s.mat', signal_dir, sample_rate_select));
end

file_length = length(D);
if ~file_length
    fprintf('##### no signal file in ''%s''\n', signal_dir);
    return;
end

for n = 1 : file_length
    filename = sprintf('%s\\%s', signal_dir, D(n).name);
    make_signal_feature_test_dataset_190123(filename, save_dir, filename_prepend_string, signal_threshold);
end

end



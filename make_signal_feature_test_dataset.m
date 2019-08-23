function [] = make_signal_feature_test_dataset(fsq_iq_filename, save_dir, filename_prepend_string)
% make signal feature test dataset to evaluate signal feature trained model
% (random forest, kernel svm, multi layer perceptron)
%
% [input]
% - fsq_iq_filename: iq sample file got from fsq, which is created using "get_iq_from_fsq.m"
% - save_dir: directory where iq sample test dataset file is saved
% - filename_prepend_string: string prepended to iq sample test dataset filename. 
%   used to distinguish signal
%
% [usage]
% make_signal_feature_test_dataset('E:\fsq_iq\data\fsq_iq_180713140113_97.5_0.16_0.2.mat', 'e:\temp\mod_signal\real_signal', 'fmbroadcast')

% ##### must be same as in "generate_feature_of_modulation_signal.m"
feature_name_cell = {'gamma_max', 'sigma_ap', 'sigma_dp', 'P', 'sigma_aa', 'sigma_af', 'sigma_a', ...
    'mu_a42', 'mu_f42', 'C20', 'C21', 'C40', 'C41', 'C42', 'C60', 'C61', 'C62', 'C63'};
feature_length = length(feature_name_cell);

% length of iq sample to compute signal feature
% ##### must be same as in "generate_feature_of_modulation_signal.m"
iq_sample_length = 2^10;

% recommend = .5 ~ 1 (right?). when .5, 85% survive, when 1, 50% survive
% ##### must be same as in "generate_feature_of_modulation_signal.m"
amplitude_threshold = .5;

% ###### reminding what fsq_iq_filename have: see "get_iq_from_fsq.m"
% % save iq into file
% save(filename, 'iq', 'center_freq_mhz', 'signal_bw_mhz', 'sample_rate_mhz', 'sample_length');
%
% ###### after 180817, "get_iq_from_fsq.m" have 'timestamp'

load(fsq_iq_filename);

test_length = fix(sample_length / iq_sample_length);
iq = iq(1 : test_length * iq_sample_length);
iq = reshape(iq, test_length, []);
% iq dimension = test_length * iq_sample_length

% normalize iq sample
for n = 1 : test_length
    pre_iq = iq(n, :);
    pre_iq = pre_iq / max(abs(pre_iq));
    iq(n, :) = pre_iq;
end

% ############################################################################################
% ### signal feature is dependant on sample rate
% ###
% ### if sample rate used in generating train dataset is different from one in test dataset,
% ### model work well?
% ############################################################################################
channel_fs_hz = sample_rate_mhz * 1e6;

% ################# bug fix: complex mean, cumulant(C61 ~ C63) computation
signal_feature = ...
    compute_feature_of_modulation_signal_181023(iq, amplitude_threshold, feature_name_cell, channel_fs_hz);
% signal_feature = ...
%     compute_feature_of_modulation_signal(iq, amplitude_threshold, feature_name_cell, channel_fs_hz);
% signal_feature dimension = test_length x feature_length

if exist('timestamp', 'var')
    fprintf('''timestamp'' variable exist\n');
    creation_date_str = timestamp;
else
    [creation_date_str] = get_file_creation_date(fsq_iq_filename);
end
mat_filename = sprintf('%s\\%s_signal_feature_f%g_b%g_s%g_t%d(%s).mat', ...
    save_dir, filename_prepend_string, center_freq_mhz, signal_bw_mhz, sample_rate_mhz, test_length, ...
    creation_date_str);

% save iq into file
save(mat_filename, ...
    'signal_feature', 'center_freq_mhz', 'signal_bw_mhz', 'sample_rate_mhz', 'test_length');
fprintf('signal feature test dataset saved into ''%s''\n', mat_filename);

end

%%
function [creation_date_str] = get_file_creation_date(fsq_iq_filename)
% ####################################################################################################
% #### caution: bad code, fragile, much dependant on filename string
% #### filename example: fsq_iq_filename = 'E:\fsq_iq\data\fsq_iq_180713140113_97.5_0.16_0.2.mat'
% #### solution: rewrite "get_iq_from_fsq.m" (when create file, save creation date string into file)
% ####################################################################################################

% filename example:
% fsq_iq_filename = 'E:\fsq_iq\data\fsq_iq_180713140113_97.5_0.16_0.2.mat'
[path, name, ext] = fileparts(fsq_iq_filename);

idx = find(name == '_');
creation_date_str = name(idx(2) + 1 : idx(3) - 1);

end



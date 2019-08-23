function [] = ...
    make_signal_feature_test_dataset_190123(fsq_iq_filename, save_dir, filename_prepend_string, signal_threshold)
% make signal feature test dataset to evaluate signal feature trained model
% model = [random forest, kernel svm, multi layer perceptron]
%
% ##################################################################
% new version, modified from "make_signal_feature_test_dataset.m"
% differ from "make_signal_feature_test_dataset.m":
% remove no signal section from simple radio signal file 
% (see "remove_no_signal_simple_radio.m")
% ##################################################################
%
% [input]
% - fsq_iq_filename: iq file got from fsq
% - save_dir: directory where signal feature test dataset is saved
% - filename_prepend_string: string prepended to signal feature test dataset filename. 
%   used to distinguish signal
% - signal_threshold: signal threshold. if zero, signal threshold is NOT applied
%   otherwise declare noise when smoothed and normalized magnitude of iq is less than signal threshold.
%
% [usage]
% make_signal_feature_test_dataset_190123('E:\real_signal\simple\fsq_iq_190102105711_146.512500_0.008500_0.015000.mat', 'E:\real_signal\feature_simple', 'simple_feature', .1)
% make_signal_feature_test_dataset_190123('E:\real_signal\simple\fsq_iq_190109163816_146.587500_0.015000.mat', 'E:\real_signal\feature_simple', 'simple_feature', 0)

% % signal threshold
% % declare noise when smoothed and normalized magnitude of iq is less than signal threshold
% signal_threshold = .1;

% ##### must be same as in "inf_snr_generate_feature_of_modulation_signal.m"
feature_name_cell = {'gamma_max', 'sigma_ap', 'sigma_dp', 'P', 'sigma_aa', 'sigma_af', 'sigma_a', ...
    'mu_a42', 'mu_f42', 'C20', 'C21', 'C40', 'C41', 'C42', 'C60', 'C61', 'C62', 'C63'};
% feature_length = length(feature_name_cell);

% length of iq sample to compute signal feature
% ##### must be same as in "inf_snr_generate_feature_of_modulation_signal.m"
iq_sample_length = 2^10;

% recommend = .5 ~ 1 (right?). when .5, 85% survive, when 1, 50% survive
% ##### must be same as in "inf_snr_generate_feature_of_modulation_signal.m"
amplitude_threshold = .5;

% ###### reminding what signal_filename have: 
% see "get_iq_from_fsq.py" or "simple_radio_get_iq.py" instead of matlab code file
%
% # for backward compatibility: see "get_iq_from_fsq_181122.m" and "plot_fsq_iq.m"
%     savemat(mat_filepath,
%             dict([('iq', iq), ('center_freq_mhz', fsq_freq_mhz),
%                   ('sample_rate_mhz', sample_rate_mhz), ('sample_length', iq_length)]))
load(fsq_iq_filename);

% make sure column vector
iq = iq(:); 

if signal_threshold
    iq = remove_no_signal(iq, signal_threshold);
end

% override 'sample_length' loaded from fsq iq file
sample_length = length(iq);
test_length = fix(sample_length / iq_sample_length);
% test_length = fix(sample_length / iq_sample_length);

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

% % ################# bug fix: complex mean, cumulant(C61 ~ C63) computation
% signal_feature = ...
%     compute_feature_of_modulation_signal_181023(iq, amplitude_threshold, feature_name_cell, channel_fs_hz);
signal_feature = ...
    compute_feature_of_modulation_signal(iq, amplitude_threshold, feature_name_cell, channel_fs_hz);
% signal_feature dimension = test_length x feature_length

if exist('timestamp', 'var')
    fprintf('''timestamp'' variable exist\n');
    creation_date_str = timestamp;
else
    [creation_date_str] = get_file_creation_date(fsq_iq_filename);
end
mat_filename = sprintf('%s\\%s_%s_%.5f_%.5f.mat', ...
    save_dir, filename_prepend_string, creation_date_str, center_freq_mhz, sample_rate_mhz);

% save signal feature into file
save(mat_filename, ...
    'signal_feature', 'center_freq_mhz', 'sample_rate_mhz', 'test_length');
% save(mat_filename, ...
%     'signal_feature', 'center_freq_mhz', 'signal_bw_mhz', 'sample_rate_mhz', 'test_length');
fprintf('signal feature test dataset saved into ''%s''\n', mat_filename);

end

%%
function [iq] = remove_no_signal(iq, signal_threshold)

% ##### see "remove_no_signal_simple_radio.m"

% % signal threshold
% % declare noise when smoothed and normalized magnitude of iq is less than signal threshold
% signal_threshold = .1;

% 1 / fs * smooth_span
% when fs = 15e3, smooth_span: 5000 => 0.3 sec, 10000 => 0.6 sec
smooth_span = 10000;

% get iq magnitude
abs_iq = abs(iq);

% get iq magnitude max
max_abs_iq = max(abs_iq);
% mean_abs_iq = mean(abs_iq);

% normalize iq magnitude
abs_iq = abs_iq / max_abs_iq;

% smooth normalized iq magnitude
smooth_abs_iq = smooth(abs_iq, smooth_span);

% remove no signal(noise) section
iq = iq(smooth_abs_iq > signal_threshold);

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



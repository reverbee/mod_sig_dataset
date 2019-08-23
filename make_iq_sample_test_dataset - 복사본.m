function [] = make_iq_sample_test_dataset(fsq_iq_filename, save_dir, filename_prepend_string, plot_iq)
% make iq sample test dataset to evaluate iq sample trained model(cnn model)
%
% ## you can write simliar code for signal feature trained model
% (random forest, kernel svm, multi layer perceptron)
%
% [input]
% - fsq_iq_filename: iq sample file got from fsq, which is created using "get_iq_from_fsq.m"
% - save_dir: directory where iq sample test dataset file is saved
% - filename_prepend_string: string prepended to iq sample test dataset filename. 
%   used to distinguish signal
% - plot_iq: boolean.
%
% [usage]
% make_iq_sample_test_dataset('E:\fsq_iq\data\fsq_iq_180713140113_97.5_0.16_0.2.mat', 'e:\temp\mod_signal\real_signal', 'fmbroadcast', 0)

% ##### fixed: changing this need rebuild cnn model (hard trabajo)
cnn_model_iq_sample_length = 128;

% ###### reminding what fsq_iq_filename have: see "get_iq_from_fsq.m"
% % save iq into file
% save(filename, 'iq', 'center_freq_mhz', 'signal_bw_mhz', 'sample_rate_mhz', 'sample_length');
%
% ###### after 180817, "get_iq_from_fsq.m" have 'timestamp'

load(fsq_iq_filename);

test_length = fix(sample_length / cnn_model_iq_sample_length);
iq = iq(1 : test_length * cnn_model_iq_sample_length);
iq = reshape(iq, test_length, []);
% iq dimension = [test_length, cnn_iq_sample_length]
% ###########################################################################################################
% ### above reshape seem wrong because matlab is column major order (i was very much disappointed)
%
% ### but see load_iq_sample_from_mat_file" function(line 234 ~ 238) in "real_modulation_classifier.py"
% 
%     X_test = np.zeros([test_len, 2, iq_len], dtype=np.float32)
% 
%     for n in range(test_len):
%         X_test[n, 0, :] = np.real(iq[n])
%         X_test[n, 1, :] = np.imag(iq[n])
%
% #### above code make what i want (now i am happy)
% ###########################################################################################################

% normalize each test dataset
for n = 1 : test_length
    pre_iq = iq(n, :);
    pre_iq = pre_iq / max(abs(pre_iq));
    iq(n, :) = pre_iq;
end

if exist('timestamp', 'var')
    fprintf('''timestamp'' variable exist\n');
    creation_date_str = timestamp;
else
    [creation_date_str] = get_file_creation_date(fsq_iq_filename);
end

mat_filename = sprintf('%s\\%s_iq_sample_f%g_b%g_s%g_t%d(%s).mat', ...
    save_dir, filename_prepend_string, center_freq_mhz, signal_bw_mhz, sample_rate_mhz, test_length, ...
    creation_date_str);

% save iq into file
save(mat_filename, ...
    'iq', 'center_freq_mhz', 'signal_bw_mhz', 'sample_rate_mhz', 'test_length', 'cnn_model_iq_sample_length');
fprintf('iq sample test dataset saved into ''%s''\n', mat_filename);

if plot_iq
    pause(1);
    row_len = 5; col_len = 6;
    tile_display_iq_real_one_mat(mat_filename, row_len, col_len);
end

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



function [] = batch_make_cnn_X_test(fsq_iq_dir, test_set_dir, signal_power_threshold, signal_threshold, filename_prepend_string)
% make cnn model X test set
% ### related code: "make_iq_sample_test_dataset.m"
%
% ########################################
% normalize all iq vector, then reshape
% ########################################
%
% #########################################################################
% "batch_make_cnn_X_test - copy.m": 
% (original code) reshape, then normalize each row vector in array
% #########################################################################
%
% [input] 
% - fsq_iq_dir: directory where fsq iq file live
% - test_set_dir: directory where test set file is saved
% - signal_power_threshold: select signal threshold method. 
%   1 = compute normalized signal power, 0 = use smooth filter
%   valid when "signal_threshold" input is non-zero
% - signal_threshold: signal threshold to remove no signal section
%   used for simple radio signal.
%   if zero, signal threshold is NOT applied.
%   otherwise declare noise when smoothed and normalized magnitude of iq is less than signal threshold. 
%   when "signal_power_threshold" is 1, 
%   "signal_threshold" input is much smaller than when smooth filter method("signal_power_threshold" = 0)
% - filename_prepend_string: string appended to test set filename 
%
% [usage]
% batch_make_cnn_X_test('E:\iq_from_fsq\simple', 'E:\cnn_test_set\nightmare', 1, 0, 'simple')
% batch_make_cnn_X_test('E:\iq_from_fsq\simple', 'E:\cnn_test_set\simple', 1, .01, 'simple')
% batch_make_cnn_X_test('E:\iq_from_fsq\simple', 'E:\cnn_test_set\simple', 0, .5, 'simple')
% batch_make_cnn_X_test('E:\iq_from_fsq\fmbroadcast', 'E:\cnn_test_set\fmbroadcast', 1, 0, 'fmbroadcast')

% ##### fixed: changing this need rebuild cnn model (hard trabajo)
cnn_model_iq_sample_length = 128;

D = dir(sprintf('%s\\*.mat', fsq_iq_dir));

file_length = length(D);
if ~file_length
    fprintf('##### no iq file in ''%s''\n', fsq_iq_dir);
    return;
end

for n = 1 : file_length
    fprintf('%s\n', D(n).name);
    fsq_iq_filename = sprintf('%s\\%s', fsq_iq_dir, D(n).name);
    
    % ###### reminding what fsq_iq_filename have: see "get_iq_from_fsq.py"
    % # for backward compatibility: see "get_iq_from_fsq_181122.m" and "plot_fsq_iq.m"
    %     savemat(mat_filepath,
    %     dict([('iq', iq), ('center_freq_mhz', fsq_freq_mhz), ('signal_bw_mhz', bw_mhz),
    %         ('sample_rate_mhz', sample_rate_mhz), ('sample_length', iq_length),
    %         ('timestamp', timestamp)]))
    %
    % 'timestamp' in python code is not tested(190220), so almost fsq iq file dont have 'timestamp'
    
    % ###### reminding what fsq_iq_filename have: see "get_iq_from_fsq.m"
    % % save iq into file
    % save(filename, 'iq', 'center_freq_mhz', 'signal_bw_mhz', 'sample_rate_mhz', 'sample_length');
    %
    % ###### after 180817, "get_iq_from_fsq.m" have 'timestamp'
    
    load(fsq_iq_filename);
    % make sure column vector: "get_iq_from_fsq.py" save iq with row vector shape
    iq = iq(:);
    
    if signal_threshold
        if signal_power_threshold
            iq = sub_awgn_remove_no_signal_simple_radio(iq, signal_threshold);
        else
            iq = sub_remove_no_signal_simple_radio(iq, signal_threshold);
        end
    end
    sample_length = length(iq);
    
    test_length = fix(sample_length / cnn_model_iq_sample_length);
    if ~test_length
        fprintf('##### [%s] less than %d sample\n', D(n).name, cnn_model_iq_sample_length);
        continue;
    end
    
    iq = iq(1 : test_length * cnn_model_iq_sample_length);
    
    % normalize
    iq = iq / max(abs(iq));
    
    % reshape
    iq = reshape(iq, cnn_model_iq_sample_length, []);
    % iq dimension = [cnn_iq_sample_length, test_length]
    
%     iq = reshape(iq, test_length, []);
%     % iq dimension = [test_length, cnn_iq_sample_length]
    
    
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
    
    % ########################################################################################
    % "batch_make_cnn_X_test - copy.m": 
    % (original code) reshape, then normalize each row vector in array
    % ########################################################################################
    
%     % normalize each test dataset
%     for n = 1 : test_length
%         pre_iq = iq(n, :);
%         pre_iq = pre_iq / max(abs(pre_iq));
%         iq(n, :) = pre_iq;
%     end
    
    if exist('timestamp', 'var')
%         fprintf('''timestamp'' variable exist\n');
        creation_date_str = timestamp;
    else
        creation_date_str = get_file_creation_date(fsq_iq_filename);
    end
    
    if signal_threshold
        mat_filename = sprintf('%s\\%s_iq_sample_f%.6f_b%.6f_s%.6f_h%g_t%d(%s).mat', ...
            test_set_dir, filename_prepend_string, center_freq_mhz, signal_bw_mhz, sample_rate_mhz, ...
            signal_threshold, test_length, creation_date_str);
    else
        mat_filename = sprintf('%s\\%s_iq_sample_f%.6f_b%.6f_s%.6f_t%d(%s).mat', ...
            test_set_dir, filename_prepend_string, center_freq_mhz, signal_bw_mhz, sample_rate_mhz, test_length, ...
            creation_date_str);
    end
    
%     mat_filename = sprintf('%s\\%s_iq_sample_f%g_b%g_s%g_t%d(%s).mat', ...
%         test_set_dir, filename_prepend_string, center_freq_mhz, signal_bw_mhz, sample_rate_mhz, test_length, ...
%         creation_date_str);
    
    % save iq into file
    save(mat_filename, ...
        'iq', 'center_freq_mhz', 'signal_bw_mhz', 'sample_rate_mhz', 'test_length', 'cnn_model_iq_sample_length');
    fprintf('iq sample test dataset saved into ''%s''\n', mat_filename);
    
    % pause 1 sec to wait file saving
    pause(1);
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

%%
function [iq] = sub_awgn_remove_no_signal_simple_radio(iq, signal_threshold)

% normalize iq
norm_iq = iq / max(abs(iq));

% compute normalized iq magnitude
abs_norm_iq = abs(norm_iq);

% compute normalized signal power
norm_sig_power = sum(abs_norm_iq .^ 2) / length(norm_iq);

% get signal index
sig_idx = (abs_norm_iq >= norm_sig_power * signal_threshold);

% remove no signal(noise) section
iq = iq(sig_idx);
size(iq);

end

%%
function [iq] = sub_remove_no_signal_simple_radio(iq, signal_threshold)
% #### modified from "remove_no_signal_simple_radio.m"
%
% remove no signal section from 146 mhz analog simple radio signal
% used to preprocess signal for making test dataset of narrow band fm signal
%
% to analyze signal, use "dcs_dtmf_simple_radio_fm_demod.m"
%
% method for no signal section removal:
% (1) signal threshold for normalized magnitude of iq
% (2) moving average filter, "smooth" function
% 
% [input]
% - simple_radio_iq_filename: simple radio iq mat filename
% - signal_threshold: signal threshold. if zero, signal threshold is NOT applied
%   declare noise when smoothed and normalized magnitude of iq is less than signal threshold.
%

% 1 / fs * smooth_span
% when fs = 15e3, smooth_span: 5000 => 0.3 sec, 10000 => 0.6 sec
smooth_span = 10000;

% % fm freq deviation
% freq_dev_hz = 2.5e3; % see "simple licensed radio technical spec[final] ver1.hwp" 

% ##### reminder: what signal file have? 
% (copied from "get_iq_from_fsq.py")
% # for backward compatibility: see "get_iq_from_fsq_181122.m" and "plot_fsq_iq.m"
% savemat(mat_filepath,
%         dict([('iq', iq), ('center_freq_mhz', fsq_freq_mhz), ('signal_bw_mhz', bw_mhz),
%               ('sample_rate_mhz', sample_rate_mhz), ('sample_length', iq_length)]))
% load(simple_radio_iq_filename);
% center_freq_mhz;
% sample_rate_mhz;
% % sure shot to make column vector, "get_iq_from_fsq.py" save iq array with row vector format
% iq = iq(:);
% size(iq);

% fs_hz = sample_rate_mhz * 1e6;
% [~, filename, ~] = fileparts(simple_radio_iq_filename);

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
size(iq);

end


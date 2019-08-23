function [] = get_test_iq_for_modulation_classifier(test_length, center_freq_mhz, signal_bw_mhz, ...
    mod_dir, mat_filename_prepend_string)
% get test iq for modulation classifier
%
% [input]
% - test_length: test length for modulation classification
% - center_freq_mhz: carrier freq in mhz
% - signal_bw_mhz: signal bw in mhz
% - mod_dir: modulation iq mat file save directory.
% - mat_filename_prepend_string: mat filename prepend string. used for signal name
%   
% [usage]
% (fm broadcasting)
% get_test_iq_for_modulation_classifier(30, 98.5, .2, 'e:\temp\mod_signal\real_signal', 'fmbroadcast')
% get_test_iq_for_modulation_classifier(30, 97.5, .2, 'e:\temp\mod_signal\real_signal', 'fmbroadcast')
%

% plot first 128 normalized iq sample
plot_normalized_iq = 0;

cnn_iq_sample_length = 128;
% 1.5 = margin
sample_length = round(test_length * cnn_iq_sample_length * 1.5);
directory = '';
plot_signal = 0;
% get iq sample from rf receiver(r&s fsq26)
[iq, sample_rate_mhz] = ...
    get_iq_from_fsq(center_freq_mhz, signal_bw_mhz, sample_length, directory, plot_signal);

iq = iq(1 : test_length * 128);
iq = reshape(iq, cnn_iq_sample_length, []);
% iq dimension = cnn_iq_sample_length * test_length
size(iq);

% normalize
for n = 1 : test_length
    pre_iq = iq(:, n);
    pre_iq = pre_iq / max(abs(pre_iq));
    iq(:, n) = pre_iq;
end

iq = iq.';
% iq dimension = test_length * cnn_iq_sample_length
size(iq);

% [timestamp] = get_timestamp;
mat_filename = sprintf('%s\\%s_f%g_b%g_s%g_t%d(%s).mat', ...
    mod_dir, mat_filename_prepend_string, center_freq_mhz, signal_bw_mhz, sample_rate_mhz, test_length, get_timestamp);

% save iq into file
save(mat_filename, 'iq', 'center_freq_mhz', 'signal_bw_mhz', 'sample_rate_mhz', 'test_length');

if plot_normalized_iq
    title_text = '128 normalized iq sample';
    plot_iq(iq(1, :).', sample_rate_mhz * 1e6, title_text);
end

end


function [] = plot_real_iq(mat_filename)
% plot iq sample for real signal which got from rf receiver(r&s fsq26)
% 
% ###### what real signal is different from simulated signal?
%
% [usage]
% (classification success)
% plot_real_iq('E:\temp\mod_signal\fmbroadcast_f98.5_b0.2_s0.25_t30(180405150718).mat')
% (classification fail)
% plot_real_iq('E:\temp\mod_signal\fmbroadcast_f98.5_b0.2_s0.25_t30(180405150809).mat')
% (classification fail)
% plot_real_iq('E:\temp\mod_signal\fmbroadcast_f98.5_b0.2_s0.25_t30(180405150614).mat')

% ########## reminder: what is in mat file 
% ########## see "get_test_iq_for_modulation_classifier.m"
%
% % save iq into file
% save(mat_filename, 'iq', 'center_freq_mhz', 'bw_mhz', 'sample_rate_mhz', 'test_length');
% % iq dimension = test_length * cnn_iq_sample_length
%
% ##### notice iq is normalized for every 128 sample

load(mat_filename);
center_freq_mhz;
bw_mhz;
sample_rate_mhz;
test_length;
size(iq);

iq = iq.';
size(iq);

iq = reshape(iq, numel(iq), 1);

fs = sample_rate_mhz * 1e6;
[~, filename, ~] = fileparts(mat_filename);
title_text = filename;
plot_signal(iq, fs, title_text);

end


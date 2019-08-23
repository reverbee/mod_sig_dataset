function [] = plot_fsq_iq(mat_filename)
% plot iq sample which got from rf receiver(r&s fsq26)
%
% [usage]
% plot_fsq_iq('E:\temp\mod_signal\fmbroadcast_f98.5_b0.2_s0.25_t30(180405150718).mat')

% ########## reminder: what is in mat file 
% ########## see "get_iq_from_fsq.m"
%
% % save iq into file
%     save(filename, 'iq', 'center_freq_mhz', 'signal_bw_mhz', 'sample_rate_mhz', 'sample_length', 'timestamp');

load(mat_filename);
center_freq_mhz;
signal_bw_mhz;
sample_rate_mhz;
% sure shot for column vector, "get_iq_from_fsq.py" save iq array with row vector format
iq = iq(:);
size(iq)

fs = sample_rate_mhz * 1e6;
[~, filename, ~] = fileparts(mat_filename);
title_text = filename;
plot_signal(iq, fs, title_text);

end


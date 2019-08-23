function [] = batch_generate_simple_radio_signal(snr_db_vec, save_signal)
% batch version of "generate_simple_radio_signal.m"
%
% generate simple radio signal for each snr in snr vector
%
% ############## assumed 
% (1) iq length is same for all snr
% (2) parameter (freq_dev, fs, talk_duration, stop_pause_duration) is same for all snr
%
% if not, use cell array
% ###############################
%
% [input]
% - snr_db_vec:
% - save_signal:
%
% [usage]
% batch_generate_simple_radio_signal([-10:2:20], 1)
%

snr_len = length(snr_db_vec);

sub_save_signal = 0;
iq = [];
for n = 1 : snr_len
    fprintf('## snr %d db\n', snr_db_vec(n));
    [sub_iq, freq_dev, fs, talk_duration, stop_pause_duration] = ...
        generate_simple_radio_signal(snr_db_vec(n), sub_save_signal);
    iq(:, n) = sub_iq;
end
size(iq)

if save_signal
    signal_filename = sprintf('simpe_radio_fd%d_fs%d_talk%g_pause%g.mat', ...
        freq_dev, fs, talk_duration, stop_pause_duration);
    save(signal_filename, 'iq', 'snr_db_vec', 'freq_dev', 'fs', 'talk_duration', 'stop_pause_duration');
    
    fprintf('### simple radio signal saved into ''%s'' file\n', signal_filename);
end


end
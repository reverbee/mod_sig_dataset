function [iq] = inf_snr_signal_gen_fm_mod_iq(inf_snr_iq, instance_length, iq_sample_length, snr_db, ...
    channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg)

% modulated_sample_length = iq_sample_length;
% source_sample_length = iq_sample_length * 2;
% max_start_idx = round(iq_sample_length * .5);

imax = length(inf_snr_iq) - iq_sample_length + 1;

iq = zeros(instance_length, iq_sample_length);
for n = 1 : instance_length
    
    idx = randi(imax, 1);
    pre_iq = inf_snr_iq(idx : idx + iq_sample_length - 1);
    
    
    
    
    [pre_iq, ~] = ...
        fm_broadcasting_comm_system_object(modulated_sample_length, snr_db, ...
        plot_modulated_signal, sound_demod, ...
        chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
    % ######## pre_iq length is exactly same as modulated_sample_length(= iq_sample_length)
    
%     [pre_iq, ~] = ...
%         wbfm_modulation(source_sample_length, freq_dev, snr_db, plot_modulated_signal, sound_demod, ...
%         chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
    
%     if iq_from_1st_sample
%         start_idx = 1;
%     else
%         start_idx = randi([2, max_start_idx]);
%     end
    
%     start_idx = 1;
%     pre_iq = pre_iq(start_idx : start_idx + iq_sample_length - 1);
    
    % ##############################################################
    % #### normalize is needed?
    % #### it give "nan" when all pre_iq is zero
    % ##############################################################
    % normalize
    pre_iq = pre_iq / max(abs(pre_iq));
    
    % vertical stack into iq
    iq(n, :) = pre_iq;
end








end

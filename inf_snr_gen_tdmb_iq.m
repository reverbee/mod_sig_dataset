function [iq] = inf_snr_gen_tdmb_iq(inf_snr_iq, instance_length, iq_sample_length, snr_db, ...
    channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg)

fd = 0; % doppler shift freq

imax = length(inf_snr_iq) - iq_sample_length + 1;

iq = zeros(instance_length, iq_sample_length);
for n = 1 : instance_length
    
    idx = randi(imax, 1);
    pre_iq = inf_snr_iq(idx : idx + iq_sample_length - 1);
    
    % apply fading channel
    if ~isempty(channel_type)
        pre_iq = apply_fading_channel(pre_iq, channel_type, channel_fs_hz, fd);
    end
    
    % apply carrier offset
    if max_freq_offset_hz || max_phase_offset_deg
        pre_iq = apply_carrier_offset(pre_iq, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg);
    end
    
    % add awgn noise to signal
    if ~isempty(snr_db)
        pre_iq = awgn(pre_iq, snr_db, 'measured', 'db');
    end
    
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



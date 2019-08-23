function [iq] = gen_ssb_mod_iq(instance_length, iq_sample_length, snr_db, ...
    chan_type, chan_fs, max_freq_offset_hz, max_phase_offset_deg, iq_from_1st_sample)

plot_modulated_signal = 0;
sound_demod = 0;
fd = 0;
save_iq = 0;
% max_phase_offset_deg = 180;

usb = 0;

source_sample_length = iq_sample_length * 2;
% max_start_idx = round(iq_sample_length * .5);

iq = zeros(instance_length, iq_sample_length);
for n = 1 : instance_length
    [pre_iq, ~] = ...
        ssb_modulation(source_sample_length, snr_db, usb, plot_modulated_signal, sound_demod, ...
        chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
    
%     if iq_from_1st_sample
%         start_idx = 1;
%     else
%         start_idx = randi([2, max_start_idx]);
%     end
    
    start_idx = 1;
    pre_iq = pre_iq(start_idx : start_idx + iq_sample_length - 1);
    
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


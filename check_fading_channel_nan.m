function [] = check_fading_channel_nan
% check if fading channel in low channel sample rate may give nan output

instance_length = 100000;
iq_sample_length = 128;
snr_db = 10;
chan_type = 'gsmRAx4c2';
chan_fs = 44.1e3;
max_freq_offset_hz = 100;
max_phase_offset_deg = 180;
iq_from_1st_sample = 0;

plot_modulated_signal = 0;
sound_demod = 0;
fd = 0;
save_iq = 0;
% max_phase_offset_deg = 180;

source_sample_length = iq_sample_length * 2;
max_start_idx = round(iq_sample_length * .5);

tic;

iq = zeros(instance_length, iq_sample_length);
for n = 1 : instance_length
    [pre_iq, ~] = ...
        am_modulation(source_sample_length, snr_db, plot_modulated_signal, sound_demod, ...
        chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
    
    if sum(isnan(pre_iq))
        pre_iq.'
        fprintf('### [%d] nan\n', n);
        error('####### error: failed to avoid nan output in fading channel');
    end
    
    if iq_from_1st_sample
        start_idx = 1;
    else
        start_idx = randi([2, max_start_idx]);
    end
    
    pre_iq = pre_iq(start_idx : start_idx + iq_sample_length - 1);
    
%     if sum(isnan(pre_iq))
%         pre_iq.'
%         fprintf('### [%d] nan\n', n);
%         error('####### error: failed to avoid nan output in fading channel');
%     end
    
    % normalize
    pre_iq = pre_iq / max(abs(pre_iq));
    
    % vertical stack into iq
    iq(n, :) = pre_iq;
end

elapse_time_sec = toc;
fprintf('[%d instance] elapse time = %g min\n', instance_length, elapse_time_sec / 60);

end


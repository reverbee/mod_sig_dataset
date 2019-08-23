function [iq] = gen_simple_radio_iq(simple_iq, instance_length, iq_sample_length, snr_db, simple_snr_vec)
% generate simple radio iq 
% from "simple_iq" array belonged to "snr_db", 128 sample is random selected
%
% [input]
% - simple_iq: dimension = sample_length x snr_length, sample_length may be 130161
%

% get "snr_db" index from "simple_snr_vec"
snr_idx = (simple_snr_vec == snr_db);

% get iq smple belonged to "snr_db"
iq_snr = simple_iq(:, snr_idx);

imax = length(iq_snr) - iq_sample_length + 1;

iq = zeros(instance_length, iq_sample_length);
for n = 1 : instance_length
    
    idx = randi(imax, 1);
    pre_iq = iq_snr(idx : idx + iq_sample_length - 1);
    
    % ##############################################################
    % #### when generate simple radio signal, signal was normalized
    % #### and some 128 iq sample can be noise (must not normalize)
    % ##############################################################
    
%     % normalize
%     pre_iq = pre_iq / max(abs(pre_iq));
    
    % vertical stack into iq
    iq(n, :) = pre_iq;
end

end



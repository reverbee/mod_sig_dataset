function [receiver_if_bw_mhz, sample_rate_mhz, iq_bw_mhz] = ...
    get_receiver_if_bw_and_sample_rate(signal_bw_mhz, sample_per_symbol)
% ##################################################################
% #### sample_per_symbol input added for digital modulation (180731)
%
% [input]
% - signal_bw_mhz: signal bw in mhz
% - sample_per_symbol: sample per symbol. 
%   when 0, dont care (analog modulation)
%   when >= 1, sample_rate = signal_bw_mhz * sample_per_symbol
%   (for digital modulation, set to 8, see "inf_snr_generate_modulation_signal_single_mat.m")

% % ################### not tested (180706) ##################
% % #### for B72 option (I/Q bandwidth extension)
% 
% % ##### may use filter
% if signal_bw_mhz > 30 && signal_bw_mhz <= 55.488
%     receiver_if_bw_mhz = 120;
%     sample_rate_mhz = 81.6;
%     iq_bw_mhz = sample_rate_mhz * .68;
% end
% 
% % 55.4880 = 81.6 * .68, 110.9760 = 163.2 * .68
% if signal_bw_mhz > 55.488 && signal_bw_mhz < 110.976
%     receiver_if_bw_mhz = 120;
%     sample_rate_mhz = signal_bw_mhz / .68;
%     iq_bw_mhz = sample_rate_mhz * .68;
%     
%     return;
% end

% manual read: there is no 200 khz if filter (filter bw begin with 300 khz)
fsq_if_bw_mhz_vec = [.3, .5, 1, 2, 3, 5, 10, 20, 50]; 

% fsq_if_bw_mhz_vec = [.2, .3, .5, 1, 2, 3, 5, 10, 20, 50];
% fsq_sample_rate_mhz_vec = [.2/.8, .3/.8, .5/.8, 1/.8, 2/.8, 3/.8, 5/.8, 10/.8, 20/.68, 40.8];
% iq_bw_mhz_vec = [.2, .3, .5, 1, 2, 3, 5, 10, 20, 30];

I = find(fsq_if_bw_mhz_vec >= signal_bw_mhz, 1, 'first'); 

receiver_if_bw_mhz = fsq_if_bw_mhz_vec(I);

if ~sample_per_symbol 
    % 13.872 = 20.4 * 0.8
    if signal_bw_mhz < 13.872
        sample_rate_mhz = signal_bw_mhz / .8;
    end
    
    % 27.744 = 40.8 * 0.68
    if signal_bw_mhz >= 13.872 && signal_bw_mhz < 27.744
        sample_rate_mhz = signal_bw_mhz / .68;
    end
    
    if signal_bw_mhz >= 27.744
        sample_rate_mhz = 40.8; % min fs
        %     sample_rate_mhz = 81.6; % max fs
    end    
else    
    sample_rate_mhz = signal_bw_mhz * sample_per_symbol;       
end

% double check: compute max bw("iq_bw_mhz") from sample rate
% see page 684 in fsq26 manual
if sample_rate_mhz < 20.4
    iq_bw_mhz = sample_rate_mhz * .8;
end

if sample_rate_mhz >= 20.4 && sample_rate_mhz < 40.8
    iq_bw_mhz = sample_rate_mhz * .68;
end

if sample_rate_mhz >= 40.8
    iq_bw_mhz = 30;
end

end


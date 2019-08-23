function [] = awgn_remove_no_signal_simple_radio(simple_radio_iq_filename, signal_threshold, sound_audio)
% remove no signal section from 146 mhz analog simple radio signal
% used to preprocess signal for making test dataset of narrow band fm signal
%
% ######### differ from "remove_no_signal_simple_radio.m":
% (1) compute signal power of normalized iq
% (2) multiply "signal_threshold" with normalized signal power to get signal threshold
%
% to compute signal power, code in "awgn.m" was used
% #########################################################
%
% to analyze signal, use "dcs_dtmf_simple_radio_fm_demod.m"
%
% method for no signal section removal:
% (1) signal threshold for normalized magnitude of iq
% (2) moving average filter, "smooth" function
% 
% [input]
% - simple_radio_iq_filename: simple radio iq mat filename
% - signal_threshold: signal threshold. if zero, signal threshold is NOT applied
%   declare noise when smoothed and normalized magnitude of iq is less than signal threshold.
% - sound_audio: boolean. 
%   when signal_threhold is non-zero, you hear no signal section removed sound
%
% [usage]
% (good snr)
% awgn_remove_no_signal_simple_radio('E:\iq_from_fsq\simple\fsq_iq_190102133150_146.512500_0.008500_0.015000.mat', .1, 0)
% awgn_remove_no_signal_simple_radio('E:\iq_from_fsq\simple\fsq_iq_190102105711_146.512500_0.008500_0.015000.mat', .1, 0)
% awgn_remove_no_signal_simple_radio('E:\iq_from_fsq\simple\fsq_iq_190109164816_146.587500_0.015000.mat', .1, 0)
%

% % to compute signal power, copy from "awgn.m"
% sigPower = sum(abs(sig(:)).^2)/length(sig(:)); % linear

save_audio = 0;
save_fm_demod = 0;

% % signal threshold
% % declare noise when smoothed and normalized magnitude of iq is less than signal threshold
% signal_threshold = .4;

% 1 / fs * smooth_span
% when fs = 15e3, smooth_span: 5000 => 0.3 sec, 10000 => 0.6 sec
% smooth_span = 50000; % not good
smooth_span = 10000; % original

% % reference signal threshold: used to select optimum threshold
% % signal threshold is dependant on snr: when high snr, set low, when low snr, set high
% % row 1 = magnitude of iq (increasing order) (proportional to snr)
% % row 2 = normalized signal threshold (maybe decreasing order)
% ref_threshold = [1e-6, 1e-5, 1e-4; .2, .1, .02];

% fm freq deviation
freq_dev_hz = 2.5e3; % see "simple licensed radio technical spec[final] ver1.hwp" 

% ##### reminder: what signal file have? 
% (copied from "get_iq_from_fsq.py")
% # for backward compatibility: see "get_iq_from_fsq_181122.m" and "plot_fsq_iq.m"
% savemat(mat_filepath,
%         dict([('iq', iq), ('center_freq_mhz', fsq_freq_mhz), ('signal_bw_mhz', bw_mhz),
%               ('sample_rate_mhz', sample_rate_mhz), ('sample_length', iq_length)]))
load(simple_radio_iq_filename);
center_freq_mhz;
sample_rate_mhz;
% sure shot to make column vector, "get_iq_from_fsq.py" save iq array with row vector format
iq = iq(:);
size(iq)

fs_hz = sample_rate_mhz * 1e6;
[~, filename, ~] = fileparts(simple_radio_iq_filename);
% remove 'fsq_iq_' string from filename to see y-axis of plot (signal level order)
title_text = erase(filename, 'fsq_iq_');
plot_signal(iq, fs_hz, title_text);

% % get iq magnitude
% abs_iq = abs(iq);
% 
% % get iq magnitude max
% max_abs_iq = max(abs_iq)
% % mean_abs_iq = mean(abs_iq);
% 
% % normalize iq magnitude
% abs_iq = abs_iq / max_abs_iq;
% 
% % smooth normalized iq magnitude
% smooth_abs_iq = smooth(abs_iq, smooth_span);
% 
% title_text = sprintf('[%s] norm mag, smoothed', erase(filename, 'fsq_iq_'));
% plot_signal([abs_iq, smooth_abs_iq], fs_hz, title_text);

if signal_threshold 
    % normalize iq
    norm_iq = iq / max(abs(iq));
    
    % compute normalized iq magnitude
    abs_norm_iq = abs(norm_iq);
    
    % compute normalized signal power
    norm_sig_power = sum(abs_norm_iq .^ 2) / length(norm_iq)
    
    % get signal index
    sig_idx = (abs_norm_iq >= norm_sig_power * signal_threshold);   
    
%     title_text = sprintf('[%s] norm iq', erase(filename, 'fsq_iq_'));
%     plot_signal([norm_iq], fs_hz, title_text);
    
    % remove no signal(noise) section
    iq = iq(sig_idx);
    size(iq)
    
    title_text = sprintf('[%s] noise removed', erase(filename, 'fsq_iq_'));
    plot_signal(iq, fs_hz, title_text);
end

% comm.FMDemodulator default: 'FrequencyDeviation', 75e3, 'SampleRate', 240e3
demod_obj = comm.FMDemodulator('FrequencyDeviation', freq_dev_hz, 'SampleRate', fs_hz);

% fm demodulation
z = demod_obj(iq);
size(z);

title_text = 'fm demoded';
plot_signal(z, fs_hz, title_text);

% save fm demodualted signal to analyze dtmf and dcs signal
if save_fm_demod
    save('simple_radio_fm_demoded.mat', 'z', 'fs_hz');
end

% play sound
% to stop sound, use "clear sound" command
if sound_audio
    soundsc(z, fs_hz);
end

if save_audio
    % normalize audio data to write into wav file
    z = z / max(abs(z));
    audiowrite('simple_radio.wav', z, fs_hz);
end

end

% %%
% function [signal_threshold] = select_signal_threshold(max_abs_iq, ref_threshold)
% 
% idx = find(ref_threshold(1, :) < max_abs_iq, 1, 'last');
% signal_threshold = ref_threshold(2, idx);
% 
% end


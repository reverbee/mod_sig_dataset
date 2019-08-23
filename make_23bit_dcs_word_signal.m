function [dcs_word_nrz] = make_23bit_dcs_word_signal(dcs_code_freq, fs, plot_signal)
%
% [input]
% - dcs_code_freq:
% - fs: fm modulator input sample rate
% - plot_signal:
%
% [output]
% - dcs_word_nrz: column vector
% 
% [usage]
% make_23bit_dcs_word_signal(134.3, 14700, 0)
% 

% for dcs, see "dcs_dtmf_simple_radio_fm_demod.m"

% #############################################################
% caution: NOT dcs word because random bit generated
% for exact generation, must study Golay(23,12) code
% this is only for easy coding
% #############################################################
dcs_word = randi([0, 1], 23, 1);

% get nrz (non return to zero)
dcs_word_nrz = dcs_word;
zero_idx = (dcs_word == 0);
dcs_word_nrz(zero_idx) = -1;

up_sample_rate = round(fs / dcs_code_freq);

% gem: "repelem" (Repeat copies of array elements), nicer than "repmat"
dcs_word_nrz = repelem(dcs_word_nrz, up_sample_rate);

% smooth signal, "raised cosine filter" may be better (write code later)
smooth_span = round(up_sample_rate / 2);
dcs_word_nrz = smooth(dcs_word_nrz, smooth_span);

if plot_signal
    plot_signal_time_domain(dcs_word_nrz, fs, '23-bit dcs word');
end


end


function [dcs_turn_off_code_signal] = ...
    make_dcs_turn_off_code_signal(dcs_turn_off_code_duration, dcs_turn_off_code_freq, fs, plot_signal)
%
% [output]
% - dcs_turn_off_code_signal: column vector
% 
% [usage]
% make_dcs_turn_off_code_signal(.18, 268.6, 14700, 0)

% dcs_turn_off_code_duration = .18;
% dcs_turn_off_code_freq = 268.6;

sample_length = round(dcs_turn_off_code_duration * fs);

t = (0 : sample_length - 1)' / fs;

% approximate to sine wave
dcs_turn_off_code_signal = sin(2 * pi * dcs_turn_off_code_freq * t);

if plot_signal
    plot_signal_time_domain(dcs_turn_off_code_signal, fs, 'dcs turn off code signal');
end


end
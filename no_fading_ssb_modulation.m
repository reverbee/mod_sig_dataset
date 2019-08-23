function [y, fs] = no_fading_ssb_modulation(source_sample_length, snr_db, usb, plot_modulated_signal, sound_demod)
% ssb modulation
%
% [input]
% - source_sample_length:
% - snr_db: snr in db. if empty, noise is NOT added to signal
% - usb: 0 = lsb, 1 = usb
% - plot_modulated_signal: boolean
% - sound_demod: boolean
%
% [usage]
% no_fading_ssb_modulation(8192, 10, 0, 1, 0)
% no_fading_ssb_modulation(8192, '', 0, 1, 0)
% no_fading_ssb_modulation(2^18, 10, 0, 1, 1)
% no_fading_ssb_modulation(2^18, '', 0, 1, 1)
% 

plot_source_signal = 0;
sound_source = 0;
max_freq_of_source_signal = 5e3; % recommend = 5e3
[x, fs] = analog_source(source_sample_length, max_freq_of_source_signal, plot_source_signal, sound_source);

% ssb modulation
fc = 10e3;
if usb
    ini_phase = 0;
    sideband = 'upper';
    y = ssbmod(x, fc, fs, ini_phase, sideband);
else
    y = ssbmod(x, fc, fs);
end
size(y);

% add awgn noise to signal
if ~isempty(snr_db)
    y = awgn(y, snr_db, 'measured', 'db');
end

if plot_modulated_signal
    plot_signal(y, fs, 'modulated');
end

% simulate rf receiver: change to baseband(freq down conversion)
t = (0 : length(y) - 1)' / fs;
y_base = y .* exp(-1i * 2 * pi * fc * t);

if plot_modulated_signal
    plot_signal(y_base, fs, 'baseband');
end

% design low pass fir filter
filter_order = 74;
pass_freq = max_freq_of_source_signal * 1.5; % not 1, 1.5 = bandwidth margin
filter_coeff = fir1(filter_order, pass_freq / fs * 2);

% low pass filtering
a = 1;
y_base = filter(filter_coeff, a, y_base);

if plot_modulated_signal
    plot_signal(y_base, fs, 'after filter');
end

% you must hear mozart
if sound_demod  
%     sound(real(y), fs);
    soundsc(real(y_base), fs);
end

end

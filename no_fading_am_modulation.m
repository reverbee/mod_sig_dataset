function [] = am_modulation(source_sample_length, snr_db, plot_modulated_signal, sound_demod)
% am modulation
%
% [input]
% - source_sample_length:
% - snr_db: snr in db. if empty, noise is NOT added to signal
% - plot_modulated_signal: boolean
% - sound_demod: boolean
%
% [usage]
% am_modulation(8192, 10, 1, 0)
% am_modulation(8192, '', 1, 0)
% am_modulation(2^18, 10, 1, 1)
% am_modulation(2^18, '', 1, 1)
%

plot_source_signal = 0;
sound_source = 0;
max_freq_of_source_signal = 5e3; % recommend = 5e3
[x, fs] = analog_source(source_sample_length, max_freq_of_source_signal, plot_source_signal, sound_source);

% am
% must satisfy fs > 2(fc + BW), where BW is the bandwidth of the modulating signal x.
ini_phase = 0;
% suppressed carrier am
carramp = 0;
fc = max_freq_of_source_signal;
y = ammod(x, fc, fs, ini_phase, carramp);
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
y = y .* exp(-1i * 2 * pi * fc * t);

if plot_modulated_signal
    plot_signal(y, fs, 'baseband');
end

% ####### result: not good as fir1, filter coeff = 39 (fir1 filter coeff = 74) ##########
% % design filter with more contraints
% f_pass = pass_freq / fs;
% f_stop = f_pass + .15;
% stop_atten = 80;
% pass_ripple = 0.5;
% lpf = designfilt('lowpassfir', 'PassbandFrequency', f_pass, ...
%     'StopbandFrequency', f_stop, 'PassbandRipple', pass_ripple, ...
%     'StopbandAttenuation', stop_atten);
% length(lpf.Coefficients);
% y = filter(lpf, y);

% design low pass fir filter
filter_order = 74;
pass_freq = max_freq_of_source_signal;
filter_coeff = fir1(filter_order, pass_freq / fs * 2);

% low pass filtering
a = 1;
y = filter(filter_coeff, a, y);

if plot_modulated_signal
    plot_signal(y, fs, 'after baseband filter');
end

% you must hear mozart
if sound_demod
%     sound(real(y), fs);
    soundsc(real(y), fs);
end

end

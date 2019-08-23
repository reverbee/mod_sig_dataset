function [] = learn_am_fc(modulation_index)
% learn am full carrier
%
% [usage]
% learn_am_fc(.5)
% 
% modulation_index recommend = 0.5? search real signal example

plot_modulated_signal = 1;
source_sample_length = 2^10;
plot_source_signal = 0;
sound_source = 0;
max_freq_of_source_signal = 5e3; % recommend = 5e3
[x, fs] = analog_source(source_sample_length, max_freq_of_source_signal, plot_source_signal, sound_source);

% am
% must satisfy fs > 2(fc + BW), where BW is the bandwidth of the modulating signal x.
ini_phase = 0;
% full carrier am
carramp = modulation_index;
fc = max_freq_of_source_signal;
y = ammod(x, fc, fs, ini_phase, carramp);
size(y);

if plot_modulated_signal
    plot_signal(y, fs, sprintf('mod index = %g', modulation_index));
end

return;

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

% apply fading channel
if ~isempty(chan_type)
    y = apply_fading_channel(y, chan_type, chan_fs, fd);
end

% apply carrier offset
if max_freq_offset_hz || max_phase_offset_deg
    y = apply_carrier_offset(y, chan_fs, max_freq_offset_hz, max_phase_offset_deg);
end

% add awgn noise to signal
if ~isempty(snr_db)
    y = awgn(y, snr_db, 'measured', 'db');
end

% save iq into mat file
if save_iq
    mat_filename = sprintf('%s.mat', mfilename);
    save(mat_filename, 'y', 'fs', 'source_sample_length', 'snr_db', 'chan_type', 'chan_fs', 'fd');
end

if plot_modulated_signal
    plot_signal(y, fs, 'after baseband filter');
end

% you must hear mozart
if sound_demod
%     sound(real(y), fs);
    soundsc(real(y), fs);
end

end

function [] = show_oscillator_phase_noise(fc, sample_length, fs)
% show oscillator phase noise
% ###### not complete
%
% [input]
% - fc, sample_length, fs
%
% [usage]
% show_oscillator_phase_noise(1e3, 2^10, 5e3)
%

ini_phase = 0;

t = (0 : sample_length - 1)' / fs;

phase_noise = randn(sample_length, 1);
phase_noise = phase_noise / max(phase_noise) * 2 * pi;

y = cos(2 * pi * fc * t);
% y = cos(2 * pi * fc * t + ini_phase + phase_noise);

plot_signal(y, fs, 'phase_noise');

end

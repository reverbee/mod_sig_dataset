function [] = plot_signal(y, fs, title_text)

% y: column vector
sample_length = size(y, 1);

real_signal = isreal(y);

h = figure;
double_figure_width(h);

subplot(1,2,1);
t = (0 : sample_length - 1) / fs * 1e3;
if real_signal
    plot(t, y, '.-');
else
    plot(t, [real(y), imag(y)], '.-');
end
grid on;
xlim([t(1) t(end)]);
xlabel('time in msec');
if ~real_signal
    legend('real', 'imag');
end
% title(title_text, 'Interpreter', 'none');
title(sprintf('[time] %s', title_text), 'Interpreter', 'none');

subplot(1,2,2);
f = (0 : sample_length - 1) * (fs / sample_length) - (fs / 2);
f = f / 1e3;
% apply hanning window
y = y .* hann(sample_length);
plot(f, 10 * log10(abs(fftshift(fft(y)))), '.-');
grid on;
xlim([f(1) f(end)]);
xlabel('freq in khz');
% % title(title_text);
title(sprintf('[freq] %s', title_text), 'Interpreter', 'none');

end

%%
function [] = double_figure_width(h)

% h = figure;
x = get(h, 'position');
set(h, 'position', x .* [1 1 2 1]);

end


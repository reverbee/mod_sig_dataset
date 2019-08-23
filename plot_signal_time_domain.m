function [] = plot_signal_time_domain(y, fs, title_text)

% y: column vector
sample_length = size(y, 1);

real_signal = isreal(y);

figure;
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
title(title_text, 'Interpreter', 'none');

end


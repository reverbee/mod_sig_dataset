function [] = learn_fir_filter_transient

sig_length = 100;
impulse = zeros(sig_length, 1);
impulse(10) = 1;

fs = 44.1e3;
max_freq_of_source_signal = 5e3;

% design low pass fir filter
filter_order = 74;
pass_freq = max_freq_of_source_signal;
filter_coeff = fir1(filter_order, pass_freq / fs * 2);

% low pass filtering
a = 1;
y = filter(filter_coeff, a, impulse);

figure;
title_text = 'fir filter impulse response';
plot_filter_impulse_response(impulse, y, fs, title_text)

end

%%
function [] = plot_filter_impulse_response(impulse, y, fs, title_text)

sample_length = length(y);

t = 1 : sample_length;
% t = 0 : sample_length - 1;
% t = (0 : sample_length - 1) / fs * 1e3;
plot(t, [impulse, y], '.-');
% plot(t, [real(y), imag(y)], '.-');

grid on;
xlim([t(1) t(end)]);
% xlabel('time in msec');
legend('impulse input', 'filter response');
title(title_text, 'Interpreter', 'none');

end

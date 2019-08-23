function [] = learn_fading_channel_fs
%
% [usage]
% learn_fading_channel_fs
%

sig_length = 50;
impulse = zeros(sig_length, 1);
impulse(10) = 1;

hi_fs = 1e6;
[y_hi, hi_chan] = apply_impulse_fading_channel(impulse, hi_fs);
hi_chan

lo_fs = 44.1e3;
[y_lo, lo_chan] = apply_impulse_fading_channel(impulse, lo_fs);
lo_chan

figure('Position', [553 323 1026 420]);

subplot(1,2,1);
plot_channel_impulse_response(y_hi, hi_fs, sprintf('fs = %g hz', hi_fs));

subplot(1,2,2);
plot_channel_impulse_response(y_lo, lo_fs, sprintf('fs = %g hz', lo_fs));

end

%%
function [y, chan] = apply_impulse_fading_channel(x, fs)

ts = 1 / fs; 
fd = 0;
chan = stdchan(ts, fd, 'gsmRAx4c2');
y = filter(chan, x);

end

%%
function [] = plot_channel_impulse_response(y, fs, title_text)

sample_length = length(y);

t = (0 : sample_length - 1) / fs * 1e3;
plot(t, [real(y), imag(y)], '.-');

grid on;
xlim([t(1) t(end)]);
xlabel('time in msec');
legend('real', 'imag');
title(title_text, 'Interpreter', 'none');

end

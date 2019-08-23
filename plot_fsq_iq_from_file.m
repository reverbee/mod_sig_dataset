function [] = plot_fsq_iq_from_file(mat_filename)
% plot iq sample from mat file which is generated using "get_iq_from_fsq.py"
%
% [usage]
% plot_fsq_iq_from_file('E:\iq_from_fsq\test\fsq_iq_190311142751_473.000000_7.500000.mat')
% plot_fsq_iq_from_file('\\P6X58D-W10\test\fsq_iq_190724101750_146.512500_0.012000.mat')
%

% #### dmb signal show pilot near zero freq when sample length = 2^21, not show when sample length = 2^19
% #### my intention is to remove pilot near zero freq, but failed to remove
remove_dc_component = 0;

% ########## reminder: what is in mat file 
% ########## see "get_iq_from_fsq.m"
%
% % save iq into file
%     save(filename, 'iq', 'center_freq_mhz', 'signal_bw_mhz', 'sample_rate_mhz', 'sample_length', 'timestamp');

% ########## reminder: what is in mat file 
% ########## see "get_iq_from_fsq.py"
% # for backward compatibility: see "get_iq_from_fsq_181122.m" and "plot_fsq_iq.m"
%     savemat(mat_filepath,
%             dict([('iq', iq), ('center_freq_mhz', fsq_freq_mhz),
%                   ('sample_rate_mhz', sample_rate_mhz), ('sample_length', iq_length),
%                   ('timestamp', timestamp)]))

load(mat_filename);
center_freq_mhz;
% signal_bw_mhz;
sample_rate_mhz;
% sure shot for column vector, "get_iq_from_fsq.py" save iq array with row vector format
iq = iq(:);
size(iq)

if remove_dc_component
    iq = iq - abs(mean(iq));
%     iq = iq - mean(abs(iq));
end

fs = sample_rate_mhz * 1e6;
[~, filename, ~] = fileparts(mat_filename);
title_text = erase(filename, 'fsq_iq_');
plot_signal(iq, fs, title_text);

% scatterplot(iq); grid on;

end

% %%
% function [] = plot_signal(y, fs, title_text, plot_sample_length)
% 
% % y: column vector
% sample_length = size(y, 1);
% 
% real_signal = isreal(y);
% 
% h = figure;
% double_figure_width(h);
% 
% subplot(1,2,1);
% t = (0 : sample_length - 1) / fs * 1e3;
% if real_signal
%     plot(t, y, '.-');
% else
%     plot(t, [real(y), imag(y)], '.-');
% end
% grid on;
% xlim([t(1) t(end)]);
% xlabel('time in msec');
% if ~real_signal
%     legend('real', 'imag');
% end
% % title(title_text, 'Interpreter', 'none');
% title(sprintf('[time] %s', title_text), 'Interpreter', 'none');
% 
% subplot(1,2,2);
% f = (0 : sample_length - 1) * (fs / sample_length) - (fs / 2);
% f = f / 1e3;
% % apply hanning window
% y = y .* hann(sample_length);
% plot(f, 10 * log10(abs(fftshift(fft(y)))), '.-');
% grid on;
% xlim([f(1) f(end)]);
% xlabel('freq in khz');
% % % title(title_text);
% title(sprintf('[freq] %s', title_text), 'Interpreter', 'none');
% 
% end
% 
% %%
% function [] = double_figure_width(h)
% 
% % h = figure;
% x = get(h, 'position');
% set(h, 'position', x .* [1 1 2 1]);
% 
% end


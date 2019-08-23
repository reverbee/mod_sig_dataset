function [] = periodogram_plot_fsq_iq_from_file(mat_filename)
% plot power spectrum of fsq iq sample in file which is generated using "get_iq_from_fsq.py"
% ######## using "periodogram" matlab function
% ######## i want to know snr of hd tv signal read from fsq
% ######## this signal can be used to train cnn model 8vsb signal? (snr is enough high?)
%
% [usage]
% periodogram_plot_fsq_iq_from_file('E:\iq_from_fsq\fs43.04_hd_tv_fp5.38\fsq_iq_190320135455_473.000000_43.040000_fp5.380000.mat')
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
plot_periodogram(iq, fs, title_text);

% scatterplot(iq); grid on;

end

%%
function [] = plot_periodogram(iq, fs, title_text)

sample_length = length(iq);

% ######## "periodogram" input: "spectrumtype ? Power spectrum scaling" 
%
% Power spectrum scaling, specified as 'psd' or 'power'. 
% To return the power spectral density, omit spectrumtype or specify 'psd'. 
% To obtain an estimate of the power at each frequency, use 'power' instead. 
% Specifying 'power' scales each estimate of the PSD by the equivalent noise bandwidth of the window.
[pxx, f] = periodogram(iq, hann(sample_length), sample_length, fs, 'centered', 'power');

f = f / 1e3;
figure;
plot(f, 10 * log10(pxx), '.-');
grid on;
xlim([f(1) f(end)]);
xlabel('freq in khz');
% % title(title_text);
title(sprintf('%s', title_text), 'Interpreter', 'none');

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

end

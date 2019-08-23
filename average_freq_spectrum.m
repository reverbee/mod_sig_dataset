function [] = average_freq_spectrum(iq_filename, freq_resolution_hz)
%
% [usage]
% average_freq_spectrum('E:\iq_from_fsq\test\fsq_iq_190430144937_912.000000_120_320.000000.mat', 1e3)
%

% #### reminding what iq file have
%
% savemat(mat_filepath,
% dict([('iq', iq), ('center_freq_mhz', fsq_freq_mhz),
%     ('sample_rate_mhz', sample_rate_mhz), ('sample_length', iq_length),
%     ('timestamp', timestamp),('rbw_mhz', rbw_mhz)]))

load(iq_filename);

iq = iq(:);
sample_rate_mhz;
sample_length = double(sample_length);
sample_rate_mhz * 1e6 / sample_length;

fft_length = round(sample_rate_mhz * 1e6 / freq_resolution_hz)
average_length = floor(sample_length / fft_length)

iq = reshape(iq(1 : fft_length * average_length), fft_length, []);
size(iq)

spect_mag = abs(fft(iq));

avg_spect = fftshift(mean(spect_mag, 2));

figure; plot(10 * log10(avg_spect));











end
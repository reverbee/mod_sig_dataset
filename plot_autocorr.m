function [] = plot_autocorr(iq_filename, corr_sec)
% compute and plot auto correlation
% to make sure the signal read from fsq is tetra signal: every 14 msec peak
%
% [input]
% - iq_filename:
% - corr_sec: plot corr in sec. when tetra signal, recommend = .1
%
% [uage]
% plot_autocorr('E:\iq_from_fsq\trs_company_fp0.023\fsq_iq_190422170122_392.612500_0.054000_fp0.023000.mat', .1);

% ########## reminder: what is in mat file 
% ########## see "get_iq_from_fsq.py"
% # for backward compatibility: see "get_iq_from_fsq_181122.m" and "plot_fsq_iq.m"
%     savemat(mat_filepath,
%             dict([('iq', iq), ('center_freq_mhz', fsq_freq_mhz),
%                   ('sample_rate_mhz', sample_rate_mhz), ('sample_length', iq_length),
%                   ('timestamp', timestamp)]))
load(iq_filename);

sample_rate_mhz;
iq_length = round(sample_rate_mhz * 1e6 * corr_sec);

% sure shot for column vector, "get_iq_from_fsq.py" save iq array with row vector format
iq = iq(:);
size(iq);

C = abs(xcorr(iq));
[~, I] = max(C);
I;

C = C(I : I + iq_length);

t_msec = (0 : length(C) - 1) / (sample_rate_mhz * 1e6) * 1e3;

figure;
plot(t_msec, 10 * log10(C));
xlim([t_msec(1) t_msec(end)]);
xlabel('time in msec');
grid on;
title(sprintf('[auto corr] freq %.6f mhz, fs %.6f mhz', center_freq_mhz, sample_rate_mhz));

end

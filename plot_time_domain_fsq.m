function [] = plot_time_domain_fsq(mat_filename, start_duration_msec, fft_based)
%
% [input]
% - mat_filename:
% - start_duration_msec: [start_msec, duration_msec] or [duration_mec] or [](empty)
%   when [duration_mec], start_msec = 0
%   when [](empty), plot all iq 
% - fft_based: coarse freq offset estimation method
%   1 = fft based, 0 = correlation based, [](empty) = no freq offset estimate
%
% [usage]
% plot_time_domain_fsq('fsq_iq_190430091234_2162.400000_30.720000_rolloff0.22_span10.mat', [0,100], [])
%
% #### to avoid long file path, set matlab path to directory where file live
% #### to remove warning on "directory not found" when matlab start, edit "pathdef.m"
% #### to locate "pathdef.m", use "which -all pathdef.m"

% fft_based = 1;

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

if ~isempty(start_duration_msec)
    [iq, start_idx] = get_iq_from_time_parameter(iq, sample_rate_mhz, start_duration_msec);
else
    start_idx = 1;
end

[~, filename, ~] = fileparts(mat_filename);
title_text = erase(filename, 'fsq_iq_');
plot_signal_time_domain(iq, sample_rate_mhz * 1e6, title_text, start_idx);

if ~isempty(fft_based)
    [iq, freq_offset] = coarse_freq_compensate(iq, sample_rate_mhz * 1e6, fft_based);
    freq_offset
    title_text = sprintf('%s, freq offset %g', title_text, freq_offset);
    if fft_based
        title_text = sprintf('%s, fft_based', title_text);
    else
        title_text = sprintf('%s, corr_based', title_text);
    end
    plot_signal_time_domain(iq, sample_rate_mhz * 1e6, title_text, start_idx);
end

end

%%
function [iq, estFreqOffset] = coarse_freq_compensate(iq, SampleRate, fft_based)

if fft_based
    coarseSync = comm.CoarseFrequencyCompensator( ...
        'Modulation', 'QPSK', ...
        'Algorithm', 'FFT-based', ...
        'FrequencyResolution', 100, ...
        'SampleRate', SampleRate);
else
    coarseSync = comm.CoarseFrequencyCompensator( ...
        'Modulation', 'QPSK', ...
        'Algorithm', 'Correlation-based', ...
        'SampleRate', SampleRate, ...
        'MaximumFrequencyOffset', SampleRate / (4 * 4));
end

[iq, estFreqOffset] = coarseSync(iq);

end

%%
function [] = plot_signal_time_domain(y, fs, title_text, start_idx)

% y: column vector
sample_length = size(y, 1);

real_signal = isreal(y);

figure;
start_idx = start_idx - 1; % when start_idx = 1, set x-axis to 0 msec
t = (start_idx : start_idx + sample_length - 1) / fs * 1e3;
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

%%
function [iq, start_idx] = get_iq_from_time_parameter(iq, sample_rate_mhz, start_duration_msec)

param_length = length(start_duration_msec);

switch(param_length)
    case 1
        start_idx = 1;
        duration_msec = start_duration_msec(1);
    case 2
        start_msec = start_duration_msec(1);
        start_idx = start_msec * (sample_rate_mhz * 1e3) + 1;
        duration_msec = start_duration_msec(2);        
    otherwise
        error('time parameter not correct\n');
end
start_idx;
stop_idx = start_idx + fix(duration_msec * (sample_rate_mhz * 1e3));

iq = iq(start_idx : stop_idx);

end


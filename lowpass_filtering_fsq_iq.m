function [] = lowpass_filtering_fsq_iq(filename, passband_mhz, out_dir)
% atomic version of "lowpass_filter_oversampled_fsq_iq.m": 
% low pass filtering for one fsq iq file
%
% [usage]
% lowpass_filtering_fsq_iq('E:\iq_from_fsq\test\fsq_iq_190625133044_879.000000_10_15.360000.mat', 9.015, 'E:\iq_from_fsq\test')

% ###### reminding what fsq_iq_filename have: see "get_iq_from_fsq.py"
% # for backward compatibility: see "get_iq_from_fsq_181122.m" and "plot_fsq_iq.m"
%     savemat(mat_filepath,
%     dict([('iq', iq), ('center_freq_mhz', fsq_freq_mhz), ('signal_bw_mhz', bw_mhz),
%         ('sample_rate_mhz', sample_rate_mhz), ('sample_length', iq_length),
%         ('timestamp', timestamp)]))

load(filename);

% ###################################################################################
% #### DO NOT CHANGE ROW VECTOR TO COLUMN VECTOR (190326):
% #### python is row major order,
% #### so modulation classifier (python code) DO NOT ACCEPT COLUMN VECTOR
% ###################################################################################
% make sure column vector: "get_iq_from_fsq.py" save iq with row vector shape
%     iq = iq(:);

fs_mhz = sample_rate_mhz;

% design lowpass filter
filter_order = 94; % 74 is not enough for fs = 43.04e6
filter_coeff = fir1(filter_order, passband_mhz / fs_mhz);
%     filter_coeff = fir1(filter_order, passband_mhz / fs_mhz * 2);

% filtering
a = 1;
iq = filter(filter_coeff, a, iq);
size(iq);

% make filtered iq filename
[~, name, ~] = fileparts(filename);
filtered_iq_filename = sprintf('%s\\%s_fp%.6f.mat', out_dir, name, passband_mhz);

% save filtered iq into file
save(filtered_iq_filename, ...
    'iq', 'center_freq_mhz', 'sample_rate_mhz', 'sample_length', 'timestamp', 'passband_mhz');
fprintf('filtered iq sample saved into ''%s''\n', filtered_iq_filename);

end

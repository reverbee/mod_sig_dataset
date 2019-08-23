function [] = lowpass_filter_oversampled_fsq_iq(in_dir, out_dir, passband_mhz)
% low pass filering oversampled fsq iq
%
% to get answer about question, "how sample per symbol affect signal classification accuracy?"
%
% [input]
% - in_dir: folder where fsq iq file live
% - out_dir: folder where lowpass filtered iq file saved
% - passband_mhz: passband in mhz
%
% [usage]
% lowpass_filter_oversampled_fsq_iq('E:\iq_from_fsq\fs21.52_hd_tv', 'E:\iq_from_fsq\fs21.52_hd_tv_fp5.38', 5.38)
% lowpass_filter_oversampled_fsq_iq('E:\iq_from_fsq\trs_company', 'E:\iq_from_fsq\trs_company_fp0.023', 0.023)
%

% if output directory not exist, make directory
if ~exist(out_dir, 'dir')
    [status, ~, ~] = mkdir(out_dir);
    if ~status
        fprintf('###### error: making output folder is failed\n');
        return;
    end
end

D = dir(sprintf('%s\\*.mat', in_dir));

file_length = length(D);
if ~file_length
    fprintf('##### no iq file in ''%s''\n', in_dir);
    return;
end

for n = 1 : file_length
    
    filename = D(n).name;
    fprintf('%s\n', filename);
    fsq_iq_filename = sprintf('%s\\%s', in_dir, filename);
    
    % ###### reminding what fsq_iq_filename have: see "get_iq_from_fsq.py"
    % # for backward compatibility: see "get_iq_from_fsq_181122.m" and "plot_fsq_iq.m"
    %     savemat(mat_filepath,
    %     dict([('iq', iq), ('center_freq_mhz', fsq_freq_mhz), ('signal_bw_mhz', bw_mhz),
    %         ('sample_rate_mhz', sample_rate_mhz), ('sample_length', iq_length),
    %         ('timestamp', timestamp)]))
    
    load(fsq_iq_filename);
    
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
    
    pause(1);
    
end

end



function [] = raised_cosine_filtering_fsq_iq(in_dir, out_dir, symbol_rate_mhz, rolloff, span)
% raised cosine filering fsq iq
%
% to get answer about question, "how sample per symbol affect signal classification accuracy?"
%
% [input]
% - in_dir: folder where fsq iq file live
% - out_dir: folder where filtered iq file saved
% - symbol_rate_mhz: symbol rate in mhz. for wcdma, chip rate (= 3.84 mhz)
% - rolloff: rolloff in raised cosine filter. for wcdma, .22 (see 3gpp spec)
% - span: span in raised cosine filter
%
% [usage]
% raised_cosine_filtering_fsq_iq('E:\iq_from_fsq\wcdma', 'E:\iq_from_fsq\wcdma_rcos', 3.84, 0.22, 10)
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
    iq = double(iq);
    size(iq);
    
    % ###################################################################################
    % #### DO NOT CHANGE ROW VECTOR TO COLUMN VECTOR (190326):
    % #### python is row major order, 
    % #### so modulation classifier (python code) DO NOT ACCEPT COLUMN VECTOR 
    % ###################################################################################
    % make sure column vector: "get_iq_from_fsq.py" save iq with row vector shape
%     iq = iq(:);
    
    % sample per symbol in raised cosine filter
    sps = fix(sample_rate_mhz / symbol_rate_mhz);
    
    % design raised cosine filter
    % ### (span * sps) must be even
    rrcFilter = rcosdesign(rolloff, span, sps);
    
    % ##### if downsample is greater than 1, 
    % ##### rewrite code: 'sample_rate_mhz', 'transient_half' must be changed
    downsample = 1;
    iq = upfirdn(iq, rrcFilter, 1, downsample);
    transient_half = round(span * sps / 2);
    iq = iq(transient_half : end - transient_half - 1);
    size(iq);
    
    % make filtered iq filename
    [~, name, ~] = fileparts(filename);
    filtered_iq_filename = sprintf('%s\\%s_rolloff%g_span%d.mat', out_dir, name, rolloff, span);
    
    % save filtered iq into file
    save(filtered_iq_filename, ...
        'iq', 'center_freq_mhz', 'sample_rate_mhz', 'sample_length', 'timestamp', ...
        'rolloff', 'span', 'sps', 'downsample');
    fprintf('filtered iq sample saved into ''%s''\n', filtered_iq_filename);
    
    pause(1);
    
end

end



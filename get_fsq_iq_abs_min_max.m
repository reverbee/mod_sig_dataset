function [] = get_fsq_iq_abs_min_max(fsq_iq_dir)
% get amplitude min and max of fsq iq sample, and save into file
%
% [input]
% - fsq_iq_dir: directory where fsq iq sample file live
%
% [usage]
% get_fsq_iq_abs_min_max('E:\fsq_iq\data')

log_filename = 'fsq_iq_abs_max_min.txt';

old_dir = cd(fsq_iq_dir);

D = dir('*.mat');
file_length = length(D);
if ~file_length
    fprintf('### mat file not found\n');
    return;
end

fid = fopen(sprintf('%s\\%s', old_dir, log_filename),'w');

for n = 1 : file_length
    filename = sprintf('%s\\%s', fsq_iq_dir, D(n).name);
    load(filename);
    
    % ##### reminding: what filename have? 
%     % save iq into file
%     save(filename, 'iq', 'center_freq_mhz', 'signal_bw_mhz', 'sample_rate_mhz', 'sample_length', 'timestamp');
    abs_iq = abs(iq);
    max_abs_iq = max(abs_iq);
    min_abs_iq = min(abs_iq);
    
%     fprintf('filename = %s, max = %12.5f, min = %12.5f\n', D(n).name, max(abs_iq), min(abs_iq));
    fprintf('filename = %s, max = %g, min = %g\n', D(n).name, max_abs_iq, min_abs_iq);
    fprintf(fid, 'filename = %s, max = %g, min = %g\r\n', D(n).name, max_abs_iq, min_abs_iq);
end

fclose(fid);

cd(old_dir);

end


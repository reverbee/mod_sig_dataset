function [] = write_fsq_iq_to_xls_file(mat_filename, write_sample_length)
% read fsq iq from mat file, and then write to xls file
%
% [input]
% - mat_filename: mat filename, which is saved using "get_iq_from_fsq.m"
% - write_sample_length: if empty, all iq in mat file are written. 
%   if not empty, iq from 1st sample to write_sample_length sample are written.
%   in case of excel 2007, max write_sample_lengt with no error is 60000.
%
% [usage]
% write_fsq_iq_to_xls_file('E:\fsq_iq\data\fsq_iq_180713140446_95.7_0.16_0.2.mat', '')
% write_fsq_iq_to_xls_file('E:\fsq_iq\data\fsq_iq_180713140446_95.7_0.16_0.2.mat', 60000)
%

% % ##### reminding what mat file have
% % save iq into file
% save(filename, 'iq', 'center_freq_mhz', 'signal_bw_mhz', 'sample_rate_mhz', 'sample_length');

% load iq from mat file
load(mat_filename);
% whos;

[pathstr, name, ext] = fileparts(mat_filename);
xls_filename = sprintf('%s\\%s%s', pathstr, name, '.xls');

% cut iq to write_sample_length
if ~isempty(write_sample_length)
    iq = iq(1 : write_sample_length);
    sample_length = length(iq);
end

% column A: real part, column B: imag part
A = [real(iq), imag(iq)];
size(A)

xlrange = sprintf('A1:B%d', sample_length)
xlswrite(xls_filename, A, xlrange);

end



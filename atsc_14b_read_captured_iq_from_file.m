function [] = atsc_14b_read_captured_iq_from_file

fs = 12.5e6;
oversample_rate = 4;

filename = 'E:\ATSC_14B\WCVB_Captured_IQ_int8.dat';
iq_length = 4096;
y = atsc_14b_read(filename, iq_length);

plot_signal(y, fs, 'atsc captured');

filename = 'E:\ATSC_14B\WCVB_Resampled_int8.dat';
iq_length = 4096 * oversample_rate;
y = atsc_14b_read(filename, iq_length);

plot_signal(y, fs * oversample_rate, 'atsc resampled');


% buffer = fread(fid, 2 * iq_length, 'int8');
% % buffer = fread(fid, 2 * Frame_Size, 'int8');
% 
% y = buffer(1 : 2 : end) + 1i * buffer(2 : 2 : end);
% % y = int8(buffer(1 : 2 : end) + 1i * buffer(2 : 2 : end));

% if isempty (fid)
%     name = char(filename);
%     fid=fopen(name);       % no checking for valid file, 
%                            % and just let the file handles accumulate
%     fseek(fid,0,'bof');   
%     buffer=zeros(2*512,1);  % 512 point frames HARD CODED
%     % finfo = dir(name);   % one more thing that does not work in eml :-(
%     % fsize = finfo.bytes;
%     fsize = fsize_in;
%     byte_count=0;
%     closed=0;
% end;
% 
% if byte_count<(fsize-2*Frame_Size)
%    buffer=fread(fid,2*Frame_Size,'int8');
%    byte_count=byte_count+2*Frame_Size;
% else
%    buffer=zeros(2*512,1);
%    if closed==0
%       fclose(fid);
%       closed=1;
%    end;
% end;
% y=int8(buffer(1:2:end)+1i*buffer(2:2:end));

end

%%
function [y] = atsc_14b_read(filename, iq_length)

fid = fopen(filename);

buffer = fread(fid, 2 * iq_length, 'int8');
% buffer = fread(fid, 2 * Frame_Size, 'int8');

y = buffer(1 : 2 : end) + 1i * buffer(2 : 2 : end);
% y = int8(buffer(1 : 2 : end) + 1i * buffer(2 : 2 : end));

end

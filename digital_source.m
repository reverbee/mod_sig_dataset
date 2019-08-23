function [A] = digital_source(byte_length)
% source byte for digital modulation
%
% [input]
% - byte_length:
%
% [usage]
% digital_source(30);

txt_filename = 'gutenberg_shakespeare.txt';

% get total byte length in file
file_info = dir(txt_filename);
file_byte_length = file_info.bytes;

% open file
fid = fopen(txt_filename);

% randomize and locate file position from which byte is read
file_position = randi(file_byte_length - byte_length);
fseek(fid, file_position, 'bof');

% read byte(ascii code) from text file
A = fread(fid, byte_length);
char(A');

% close file
fclose(fid);

end

% digital source symbol mapping
%
% a = [16, 28, 100];
% b = de2bi(a, 8, 2); 2psk, 1 bit
% b = de2bi(a, 4, 4); 4psk, 2 bit
% b = de2bi(a, 3, 8); 8psk, 3 bit, 8 = 2^3, 3 bit * 8 = 24 bit = 8 bit/byte * 3 byte (min 3 byte chunk)
% b = de2bi(a, 2, 16); 16qam, 4 bit
% b = de2bi(a, 2, 32); 32qam, 5 bit, 32 = 2^5, 5 bit * 8 = 40 bit = 8 bit/byte * 5 byte (min 5 byte chunk)
% b = de2bi(a, 2, 64); 64qam, 6 bit, 64 = 2^6, 6 bit * 4 = 24 bit = 8 bit/byte * 3 byte (min 3 byte chunk)


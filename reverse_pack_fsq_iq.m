function [] = reverse_pack_fsq_iq(mat_filename, save_file)
% ###### MUST NOT USE after 180801: all fsq iq was cured
% ###### caution: if run this code for already saved file with replaced iq, you have garbage
%
% [input]
% - mat_filename: fsq iq mat filename
% - save_file: boolean. if iq is replaced with new one, save iq into file (overwrite orginal file).
%   this input cause error in old(not updated) code which use this function as subroutine 
% ######## caution: if run this code for already saved file with replaced iq, you have garbage
%
% [usage]
% [iq] = reverse_pack_fsq_iq('E:\fsq_iq\data\fsq_iq_180713140446_95.7_0.16_0.2.mat', 1);
%

max_sample_per_block = 2^19;

% % #### reminding
% % save iq into file
% save(filename, 'iq', 'center_freq_mhz', 'signal_bw_mhz', 'sample_rate_mhz', 'sample_length');

load(mat_filename);
size(iq);

sample_length = length(iq);
if sample_length <= max_sample_per_block
    return;
end

i_then_q = [real(iq); imag(iq)];
% i_then_q_length = length(i_then_q)

block_length = round(sample_length / max_sample_per_block);
last_block_sample_length = rem(sample_length, max_sample_per_block);
if last_block_sample_length
    sample_length_list = [max_sample_per_block * ones(1, block_length - 1), last_block_sample_length];
else
    sample_length_list = max_sample_per_block * ones(1, block_length);
end
sample_length_list;

reverse_pack_iq = [];
idx = 1;
for n = 1 : block_length
    this_block_sample_length = sample_length_list(n);
%     half_sample_length = this_block_sample_length / 2;
    tmp = i_then_q(idx : idx + this_block_sample_length * 2 - 1);
    
    inphase = tmp(1 : this_block_sample_length);
    quadrature = tmp(this_block_sample_length + 1 : end);
    reverse_pack_iq = [reverse_pack_iq; complex(inphase, quadrature)];
    
    idx = idx + this_block_sample_length * 2;
end
size(reverse_pack_iq);

iq = reverse_pack_iq;

if save_file
    save(mat_filename, ...
        'iq', 'center_freq_mhz', 'signal_bw_mhz', 'sample_rate_mhz', 'sample_length');
    
%     [pathstr, name, ext] = fileparts(mat_filename);
%     save(sprintf('%s\\%s%s', pathstr, name, ext), ...
%         'iq', 'center_freq_mhz', 'signal_bw_mhz', 'sample_rate_mhz', 'sample_length');
    
    fprintf('### iq in %s was replaced\n', mat_filename);
end

%%%%%%%%%%%

% idx_matrix = buffer(1 : length(i_then_q), max_sample_per_block * 2);
% 
% reverse_pack_iq = [];
% for n = 1 : block_length
%     tmp = i_then_q(idx_matrix(:, n));
%     inphase = tmp(1 : max_sample_per_block);
%     quadrature = tmp(max_sample_per_block + 1 : end);
%     reverse_pack_iq = [reverse_pack_iq; complex(inphase, quadrature)];
% end
% size(reverse_pack_iq)

end

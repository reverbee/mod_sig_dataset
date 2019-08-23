function [] = tile_display_iq_RML2018(my_modulation_name_cell, my_snr, row_len, col_len)
% tile display iq sample in modulation signal dataset(mat file)
% ###### (row_len * col_len) subplot of time domain iq sample per modulation: 
% ###### if human learn the displayed iq sample for one month, he can classify modulation? 
% modulation signal dataset is created using "generate_modulation_signal_single_mat.m"
% instance length must be greater than or equal to (row_len * col_len)
%
% [input]
% - my_modulation_name_cell: if empty, all modulation
% - my_snr: snr in db in which iq is displayed
% - row_len: row length in tile
% - col_len: column length in tile
%
% [usage]
% tile_display_iq_RML2018({'bpsk','qpsk','2fsk','4fsk','16qam'}, 16, 3, 4)
% tile_display_iq_RML2018('', 16, 3, 4)

mat_filename = 'E:\temp\mod_signal\RML2018_gsmRAx4c2_1000instance_fm_radio_fs250e3.mat';
% mat_filename = 'E:\temp\mod_signal\RML2018_gsmRAx4c2_1000instance_fm_radio.mat';
% mat_filename = 'E:\temp\mod_signal\RML2018_gsmRAx4c2_1000instance_wbfm.mat';
% mat_filename = 'E:\temp\mod_signal\RML2018_gsmRAx4c2_1000instance.mat';
% mat_filename = 'E:\temp\mod_signal\RML2018_gsmRAx4c2_1000instance_iq_double.mat';

% modulation_name_cell = {'amsc','ssb','nbfm','bpsk','qpsk','2fsk','4fsk','16qam'};
% my_modulation_name_cell = {'bpsk','qpsk','2fsk','4fsk','16qam'};
if isempty(my_modulation_name_cell)
    my_modulation_name_cell = {'amsc','ssb','nbfm','wbfm','bpsk','qpsk','2fsk','4fsk','16qam'};
%     my_modulation_name_cell = {'amsc','ssb','nbfm','bpsk','qpsk','2fsk','4fsk','16qam'};
end
my_mod_length = length(my_modulation_name_cell);

% ########## reminder: what is in param mat file 
% ########## see "generate_modulation_signal_single_mat.m"
%
% % write parameter(modulation name, sample rate, freq offset, snr_db) into mat file
% param_mat_filename = sprintf('%s\\RML2018_param.mat', signal_dir_name);
% save(param_mat_filename, ...
%     'modulation_name_cell', 'channel_fs_hz_vec', 'max_freq_offset_hz_vec', 'snr_db_vec');

% param_mat_filename = 'E:\temp\mod_signal\RML2018_param_all.mat';
param_mat_filename = 'E:\temp\mod_signal\RML2018_param.mat';
% param_mat_filename = 'E:\temp\mod_signal\RML2018_param_digital.mat';
% param_mat_filename = 'E:\temp\mod_signal\RML2018_param_analog.mat';
load(param_mat_filename);

mod_length = length(modulation_name_cell);
snr_length = length(snr_db_vec);

if ~sum(snr_db_vec == my_snr)
    fprintf('#### error: my_snr must be in snr_db_vec\n');
    return;
end

% % in later, below two array will be loaded from mat file: 
% % rewrite "generate_modulation_signal_single_mat.m"
% modulation_name_cell = {'amsc','ssb','nbfm','bpsk','qpsk','2fsk','4fsk','16qam'};
% snr_db_vec = -10:2:20;

% ########## reminder: what is in mat file 
% ########## see "generate_modulation_signal_single_mat.m"
%
% % make array which be saved into mat file.
% % python code read it from mat file
% modulation_name_set = cell(mod_length * snr_length, 1);
% snr_db_set = zeros(mod_length * snr_length, 1);
% % make dimension same as python code. (free in matlab, not in python)
% iq_set = zeros(mod_length * snr_length, instance_length, iq_sample_length);
%
% mat_filename = sprintf('%s\\RML2018_%s_%d.mat', signal_dir_name, channel_type, instance_length);
% save(mat_filename, 'snr_db_set', 'modulation_name_set', 'iq_set');

load(mat_filename);
snr_db_set;
modulation_name_set;
[tuple_length, instance_length, iq_sample_length] = size(iq_set);

% check nan. iq_set dimension = 3, so need 3 nested sum
nan_length = sum(sum(sum(isnan(iq_set))));
if nan_length
    fprintf('###### warning: %d nan in iq_set\n', nan_length);
end

if tuple_length ~= mod_length * snr_length
    fprintf('#### error: dataset dimension is wrong\n#### check paramter file\n');
    return;
end

if instance_length < (row_len * col_len)
    fprintf('#### error: instance length must NOT be less than subplot length(= row_len * col_len)\n');
    return;
end

snr_bool = snr_db_set == my_snr;
% instance_idx = randi([1, instance_length]);

iq_set = iq_set(snr_bool, :, :);
size(iq_set);

% return;

for n = 1 : my_mod_length
    modulation_name = my_modulation_name_cell{n};
    
    idx = find(ismember(modulation_name_cell, modulation_name));
    
    iq = squeeze(iq_set(idx, :, :));
    
    chan_fs = channel_fs_hz_vec(idx);
    
    fig_name = sprintf('[%s] snr = %d dB', modulation_name, my_snr);
    tile_plot_iq_sample(iq, chan_fs, fig_name, row_len, col_len);
end

end

%%
function [] = tile_plot_iq_sample(iqs, fs, fig_name, row_len, col_len)

[instance_length, sample_length] = size(iqs);

figure('Position', [606 199 1009 609], 'Name', fig_name);

% row_len = 3; col_len = 4;
axes_position = get_tight_subplot_axes_position(row_len, col_len);

P = randperm(instance_length, row_len * col_len);
P_length = length(P);

for n = 1 : P_length
    % ######## for large subplot length, must use "subplot('Position',positionVector)"
    subplot('Position', axes_position(n, :));
%     subplot(row_len, col_len, n);
    
    iq = iqs(P(n), :).';
    
    plot([real(iq), imag(iq)], '.-');
    grid on;
    xlim([1 sample_length]);
    
    set(gca, 'XtickLabel', {});
    set(gca, 'YtickLabel', {});
    
%     set(gca, 'Position', axes_position(n, :));
end

% for n = 1 : P_length
%     subplot(row_len, col_len, n);
%     
%     iq = iqs(P(n), :).';
%     
%     plot([real(iq), imag(iq)], '.-');
%     grid on;
%     xlim([1 sample_length]);
%     
%     set(gca, 'XtickLabel', {});
%     set(gca, 'YtickLabel', {});
%     
%     set(gca, 'Position', axes_position(n, :));
% end

end





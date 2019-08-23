function [] = tile_display_iq_real(mat_file_dir, signal_name, row_len, col_len)
% #### differ from "tile_display_iq_real_one_mat.m":
% iq sample in all mat file of same signal name is displayed
%
% tile display of time domain iq sample in all mat file:
% (row_len * col_len) subplot
%
% mat file is created using "get_test_iq_for_modulation_classifier.m",
% have iq sample read from rf receiver(r&s fsq26), 
% and is used for testing modulation classifier.
%
% iq sample dimension in mat file = test_length * cnn_iq_sample_length(= fixed to 128)
% test length must be greater than or equal to (row_len * col_len)
% you can see test length in mat filename: 
% 't30' in 'fmbroadcast_f98.5_b0.2_s0.25_t30(180405150718).mat' mean 30 test length
%
% [input]
% - mat_file_dir: directory where signal mat file live
% - signal_name: signal name
% - row_len: row length of tile
% - col_len: column length of tile
%
% [usage]
% tile_display_iq_real('E:\cnn_test_set\fmbroadcast', 'fmbroadcast', 5, 6)

D = dir(sprintf('%s\\%s*.mat', mat_file_dir, signal_name));
mat_length = length(D)

all_iq = [];
for n = 1 : mat_length
    mat_filename = sprintf('%s\\%s', mat_file_dir, D(n).name);
    
    % ########## reminder: what is in mat file
    % ########## see "get_test_iq_for_modulation_classifier.m"
    %
    % % save iq into file
    % save(mat_filename, 'iq', 'center_freq_mhz', 'bw_mhz', 'sample_rate_mhz', 'test_length');
    % % iq dimension = test_length * cnn_iq_sample_length
    
    load(mat_filename);
    
    % vertical stack iq
    all_iq = [all_iq; iq];
end
size(all_iq)

% return;

% load(mat_filename);
% center_freq_mhz;
% bw_mhz;
% sample_rate_mhz;
% 
% test_length;
% if size(iq, 1) ~= test_length
%     fprintf('#### error: test length not same as row length of iq array\n');
%     return;
% end
% 
% iq_sample_length = size(iq, 2);
% if iq_sample_length ~= 128
%     fprintf('#### error: iq sample length must be 128\n');
%     return;
% end
% 
% if test_length < (row_len * col_len)
%     fprintf('#### error: test length must NOT be less than subplot length(= row_len * col_len)\n');
%     return;
% end

% [~, name, ~] = fileparts(mat_filename);

fig_name = signal_name;
tile_plot_iq_sample(all_iq, sample_rate_mhz, fig_name, row_len, col_len);

end

%%
function [] = tile_plot_iq_sample(iqs, fs, fig_name, row_len, col_len)

[instance_length, sample_length] = size(iqs);

figure('Position', [606 199 1009 609], 'Name', fig_name);

axes_position = get_tight_subplot_axes_position(row_len, col_len);

P = randperm(instance_length, row_len * col_len);
P_length = length(P);

for n = 1 : P_length
    % ######## for large subplot length, must use "subplot('Position',positionVector)"
    subplot('Position', axes_position(n, :));
    
    iq = iqs(P(n), :).';
    
    plot([real(iq), imag(iq)], '.-');
    grid on;
    xlim([1 sample_length]);
    
    set(gca, 'XtickLabel', {});
    set(gca, 'YtickLabel', {});
    
%     set(gca, 'Position', axes_position(n, :));
end

end





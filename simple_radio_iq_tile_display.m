function [] = simple_radio_iq_tile_display(fsq_iq_dir, downsample_rate, row_len, col_len)
%
% [usage]
% simple_radio_iq_tile_display('E:\iq_from_fsq\simple', 15, 8, 9)
%

% min_iq_length = 2^17; % 131072
min_iq_length = 2^14; % 16384

D = dir(sprintf('%s\\*.mat', fsq_iq_dir));
file_length = length(D);

% empty vertical stack
iq_vs = [];

for n = 1 : file_length
    filename = sprintf('%s\\%s', fsq_iq_dir, D(n).name);
    
    % ###### reminding what fsq_iq_filename have: see "get_iq_from_fsq.py"
    % # for backward compatibility: see "get_iq_from_fsq_181122.m" and "plot_fsq_iq.m"
    %     savemat(mat_filepath,
    %     dict([('iq', iq), ('center_freq_mhz', fsq_freq_mhz), ('signal_bw_mhz', bw_mhz),
    %         ('sample_rate_mhz', sample_rate_mhz), ('sample_length', iq_length),
    %         ('timestamp', timestamp)]))
    %
    % 'timestamp' in python code is not tested(190220), so almost fsq iq file dont have 'timestamp'
    
    % ###### reminding what fsq_iq_filename have: see "get_iq_from_fsq.m"
    % % save iq into file
    % save(filename, 'iq', 'center_freq_mhz', 'signal_bw_mhz', 'sample_rate_mhz', 'sample_length');
    %
    % ###### after 180817, "get_iq_from_fsq.m" have 'timestamp'
    
    load(filename);
    % make column vector
    iq = iq(:);
    length(iq);
    
    % normalize
    iq = iq / max(abs(iq));
    
    iq = downsample(iq, downsample_rate);
    iq_length = length(iq);
    if iq_length < min_iq_length
        continue;
    else
        iq = iq(1 : min_iq_length);
    end 
    
    iq_vs = [iq_vs; iq.'];
end
size(iq_vs)

signal_len = size(iq_vs, 1);
subplot_len = row_len * col_len;
if signal_len < subplot_len
    fprintf('#### signal length = %d, subplot length = %d\n', signal_len, subplot_len);
    return;
end

% ##### below modified to compare noise section removed signal with original:
% ##### use same "P" output from "randperm"
P = randperm(signal_len, subplot_len);
axes_position = get_tight_subplot_axes_position(row_len, col_len);
fig_name = 'simple radio';
tile_plot_iq_sample(iq_vs, sample_rate_mhz, fig_name, P, axes_position);

end

%%
function [] = tile_plot_iq_sample(iqs, fs, fig_name, P, axes_position)

[instance_length, sample_length] = size(iqs);

figure('Position', [606 199 1009 609], 'Name', fig_name);

% axes_position = get_tight_subplot_axes_position(row_len, col_len);

% P = randperm(instance_length, row_len * col_len);
subplot_length = length(P);

for n = 1 : subplot_length
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

%%
function [] = old_tile_plot_iq_sample(iqs, fs, fig_name, row_len, col_len)

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


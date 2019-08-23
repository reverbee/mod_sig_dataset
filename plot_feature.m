function [] = plot_feature(feature_filename, my_snr, x_axis_is_modulation)
% plot modulation feature 
% to see how feature is good to modulation classification
%
% [input]
% - feature_filename: feature filename
%   feature file is generated using learn_feature_of_modulation_signal.m"
% - my_snr: snr for plot. can be vector
%   if empty, feature for all snr in feature filename is plotted
% - x_axis_is_modulation: x axis is modulation.
%   1 = x axis is modulation(one plot per feature)
%   0 = x axis is feature(one plot per modulation)
%
% [usage]
% plot_feature('E:\temp\mod_signal\feature.mat', [12,16], 1)
% plot_feature('E:\temp\mod_signal\feature.mat', '', 1)

% only for digital modulation
% my_modulation_name_cell = {'bpsk', 'qpsk', '2fsk', '4fsk', '16qam'};
my_modulation_name_cell = '';

% #### reminder: "learn_feature_of_modulation_signal.m"
% 
% % #####################################################
% % array to check feature is good
% % used for only this program, not used in classifier
% % #####################################################
% ff = zeros(snr_length, mod_length, instance_length, feature_length);
%
% save('E:\temp\mod_signal\feature.mat', ...
%     'ff', 'feature_name_cell', 'modulation_name_cell', 'snr_db_vec', 'sample_per_symbol');
load(feature_filename);

[snr_len, mod_len, inst_len, feat_len] = size(ff);

% compute mean for instance
ff = squeeze(mean(ff, 3));
[snr_len, mod_len, feat_len] = size(ff);

% get index of valid feature whose value is non-zero
idx = squeeze(sum(sum(ff))) ~= 0;
% idx = squeeze(ff(1, 1, :)) ~= 0;

% remove not-used feature
ff = ff(:, :, idx);
[snr_len, mod_len, feat_len] = size(ff);

% remove not-used feature name
feature_name_cell = feature_name_cell(idx);

if ~isempty(my_modulation_name_cell)
    idx = ismember(modulation_name_cell, my_modulation_name_cell);
    ff = ff(:, idx, :);
    modulation_name_cell = my_modulation_name_cell;
    mod_len = length(modulation_name_cell);
end

if isempty(my_snr)
    my_snr = snr_db_vec;
end

my_snr_len = length(my_snr);

idx = ismember(snr_db_vec, my_snr);
% idx = find(ismember(snr_db_vec, my_snr));
if sum(idx) ~= my_snr_len
    fprintf('### error: my snr is not in snr list\n');
    fprintf('### snr list = %s\n', num2str(snr_db_vec));
    return;
end
ff = ff(idx, :, :);

legend_text = cell(1, my_snr_len);
for n = 1 : my_snr_len
    legend_text{n} = sprintf('%d', my_snr(n));
end

if x_axis_is_modulation
    % #### x axis is modulation. one plot per feature
    for n = 1 : feat_len
        figure;
        plot(ff(:, :, n)', '.-');
        set(gca, 'XTick', 1:mod_len);
        set(gca, 'XTickLabel', modulation_name_cell);
        grid on;
        title(feature_name_cell{n}, 'interpreter', 'none');
        legend(legend_text, 'location', 'Best');
    end
else
    % #### x axis is feature. one plot per modulation
    for n = 1 : mod_len
        figure('Position', [473 558 929 420]);
        plot(squeeze(ff(:, n, :))', '.-');
        set(gca, 'XTickLabel', feature_name_cell);
        grid on;
        title(modulation_name_cell{n}, 'interpreter', 'none');
        legend(legend_text, 'location', 'Best');
    end
end

end



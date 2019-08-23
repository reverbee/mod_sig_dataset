function [] = learn_axes_position(row_len, col_len)

% figure;
% plot(1:100);
% 
% set(gca, 'XtickLabel', {});
% set(gca, 'YtickLabel', {});
% set(gca, 'Position', [0 0 1 1]);

subplot_length = row_len * col_len;

axes_position = get_tight_subplot_axes_position(row_len, col_len)

figure;

for n = 1 : subplot_length
    subplot('Position', axes_position(n, :));
    plot(0:10, '.-');
    xlim([1 11]);
    set(gca, 'XtickLabel', {});
    set(gca, 'YtickLabel', {});
%     get(gca, 'Position');
%     set(gca, 'Position', axes_position(n, :));
end

% for n = 1 : subplot_length
%     subplot(row_len, col_len, n);
%     plot(0:10, '.-');
%     xlim([1 11]);
%     set(gca, 'XtickLabel', {});
%     set(gca, 'YtickLabel', {});
% %     get(gca, 'Position');
%     set(gca, 'Position', axes_position(n, :));
% end

% subplot(2, 2, 1);
% plot(0:10);
% xlim([1 11]);
% set(gca, 'XtickLabel', {});
% set(gca, 'YtickLabel', {});
% get(gca, 'Position')
% set(gca, 'Position', [0.01 0.5 .48 .479]);
% 
% subplot(2, 2, 2);
% plot(0:10);
% xlim([1 11]);
% set(gca, 'XtickLabel', {});
% set(gca, 'YtickLabel', {});
% get(gca, 'Position')
% set(gca, 'Position', [0.5 0.5 .48 .479]);
% 
% subplot(2, 2, 3);
% plot(0:10);
% xlim([1 11]);
% set(gca, 'XtickLabel', {});
% set(gca, 'YtickLabel', {});
% get(gca, 'Position')
% set(gca, 'Position', [0.01 0.01 .48 .479]);
% 
% subplot(2, 2, 4);
% plot(0:10);
% xlim([1 11]);
% set(gca, 'XtickLabel', {});
% set(gca, 'YtickLabel', {});
% get(gca, 'Position')
% set(gca, 'Position', [0.5 0.01 .48 .479]);

end

%%
% function [z] = get_tight_subplot_axes_position(row_len, col_len)
% % get axes position for tight subplot
% %
% % [input]
% % - row_len: subplot row length
% % - col_len: subplot column length
% %
% % [output]
% % - z: subplot axes position. [left, bottom, width, height], dimension = (row_len * col_len) x 4
% %   unit = normalized
% %   
% % [usage]
% % z = get_tight_subplot_axes_position(3, 4);
% 
% % subplot width
% w = 1 / col_len;
% % subplot height
% h = 1 / row_len;
% 
% % subplot left: x coordinate
% x = (w * (0 : (col_len - 1)))';
% x = repmat(x, row_len, 1);
% 
% % subplot bottom: y coordinate
% y = h * ((row_len - 1) : -1 : 0);
% y = repmat(y, col_len, 1);
% y = y(:);
% 
% % [left, bottom, width, height], dimension = (row_len * col_len) x 4
% z = [x, y, w * ones(row_len * col_len, 1),  h * ones(row_len * col_len, 1)];
% 
% % give margin for making blank road between subplot
% z(:, 1) = z(:, 1) + .01;
% z(:, 2) = z(:, 2) + .01;
% z(:, 3) = z(:, 3) - .02;
% z(:, 4) = z(:, 4) - .02;
% 
% end

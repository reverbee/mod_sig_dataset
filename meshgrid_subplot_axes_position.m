function [] = meshgrid_subplot_axes_position(row_len, col_len)
% ##### incomplete, dont use ######
% using meshgrid, get tight subplot axes position
%
% [usage]
% meshgrid_subplot_axes_position(2, 3)
%

w = 1 / col_len;
h = 1 / row_len;

x = w * (0 : col_len);
y = h * (0 : row_len);

[X, Y] = meshgrid(x, y);
X = X';
Y = Y';
X = X(:);
Y = Y(:);

z = [X, Y]
idx = z(:, 1) == 1 || z(:, 2) == 1
% idx = z ~= 1;
% z = z(idx)

% c = num2cell(z, 2);
% c = reshape(c, row_len + 1, []);
% c = c(1 : end - 1, 1 : end - 1);

end

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
% z = [x, y, w * ones(row_len * col_len, 1),  h * ones(row_len * col_len, 1)]
% 
% % give margin for making blank road between subplot
% z(:, 1) = z(:, 1) + .01;
% z(:, 2) = z(:, 2) + .01;
% z(:, 3) = z(:, 3) - .02;
% z(:, 4) = z(:, 4) - .02;

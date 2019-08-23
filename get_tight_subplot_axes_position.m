function [z] = get_tight_subplot_axes_position(row_len, col_len)
% get axes position for tight subplot
%
% [input]
% - row_len: subplot row length
% - col_len: subplot column length
%
% [output]
% - z: subplot axes position. [left, bottom, width, height], dimension = (row_len * col_len) x 4
%   unit = normalized
%   
% [usage]
% z = get_tight_subplot_axes_position(3, 4);

% subplot width
w = 1 / col_len;
% subplot height
h = 1 / row_len;

% subplot left: x coordinate
x = (w * (0 : (col_len - 1)))';
x = repmat(x, row_len, 1);

% subplot bottom: y coordinate
y = h * ((row_len - 1) : -1 : 0);
y = repmat(y, col_len, 1);
y = y(:);

% [left, bottom, width, height], dimension = (row_len * col_len) x 4
z = [x, y, w * ones(row_len * col_len, 1),  h * ones(row_len * col_len, 1)];

% give subplot position margin for constructing blank road between subplot
% ### modify position margin(i.e. .01, .015) as you like
z(:, 1) = z(:, 1) + .01;
z(:, 2) = z(:, 2) + .01;
z(:, 3) = z(:, 3) - .015;
z(:, 4) = z(:, 4) - .015;
% z(:, 3) = z(:, 3) - .02;
% z(:, 4) = z(:, 4) - .02;

end

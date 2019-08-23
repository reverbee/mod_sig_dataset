function [] = plot_gaussian_filter(bt, span, sps)
%
% [usage]
% plot_gaussian_filter(.3, 4, 8)

% bt = 0.3;
% span = 4;
% sps = 8;
h = gaussdesign(bt, span, sps);
fvtool(h,'impulse')

end
function [] = plot_raised_cosine_filter(roll_off, span, sps)
%
% [usage]
% plot_raised_cosine_filter(.25, 6, 8)

h = rcosdesign(roll_off, span, sps, 'sqrt');
fvtool(h,'Analysis','impulse');


end
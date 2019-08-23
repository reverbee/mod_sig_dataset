function [] = plot_constellation(x, title_text)

h = scatterplot(x);
grid on;
title(title_text, 'Interpreter', 'none');

end
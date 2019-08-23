function [] = learn_complex_mean(vec_len)
% learn complex mean
%
% [input]
% - vec_len: vector length
%
% [usage]
% learn_complex_mean(10000)
%

% make complex vector with dc bias
a = complex(randn(vec_len,1), randn(vec_len,1)) + complex(-2, 7);

figure('Name', 'original');
plot([real(a), imag(a)]);

% complex mean
mean(a)
% minus complex mean
b = a - mean(a);

figure('Name', 'original minus complex mean');
plot([real(b), imag(b)]);

% absolute mean
mean(abs(a))
% minus absolute mean
c = a - mean(abs(a));

figure('Name', 'original minus absolute mean');
plot([real(c), imag(c)]);


end

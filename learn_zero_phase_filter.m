function [] = learn_zero_phase_filter
% ### cant understand what is zero phase filter(190305)
% ### study minimum phase filter
%
% what is "zerophase" function?
%
% [ref]
% https://ccrma.stanford.edu/~jos/fp/Example_Zero_Phase_Filter_Design.html

% filter length - must be odd
N = 11; 

% band edges
b = [0 0.1 0.2 0.5] * 2; 

% desired band values
M = [1  1   0   0 ]; 

% Remez multiple exchange design
h = remez(N-1,b,M); 

h

fvtool(h,'Analysis','impulse');

[hf, w] = freqz(h);


end

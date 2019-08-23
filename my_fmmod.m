function [] = my_fmmod(x, Fc, Fs, freqdev)
% to understand fm modulation
% write fsk modulation with pulse shaping

% check that Fs must be greater than 2*Fc
if (Fs < 2 * Fc)
    error('Fs must be at least 2*Fc.');
end

ini_phase = 0;

% Assure that X, if one dimensional, has the correct orientation
len = size(x, 1);
if (len == 1)
    x = x(:);
end
   
t = (0 : 1 / Fs : ((size(x, 1) - 1) / Fs))'
% t = t(:, ones(1, size(x, 2)))
size(t)

int_x = cumsum(x) / Fs;
y = cos(2 * pi * Fc * t + 2 * pi * freqdev * int_x + ini_phase); 

max(freqdev * int_x);

% restore the output signal to the original orientation
if (len == 1)
    y = y';
end
    
end

function [] = learn_nyquist_filter()
% to apply nyquist filter to 8-vsb exciter
% but Raised cosine filters are a special case of Nyquist filters
% so better to focus on raised cosine filter
%
% [ref]
% http://zone.ni.com/reference/en-XX/help/371325F-01/lvdfdtconcepts/nyquist_filters/
%
% matlab support for nyquist filter design:
% (1) firnyquist
% (2) fdesign.nyquist
% 

% "b = firnyquist(n,l,r)" designs an Nth order, Lth band, Nyquist FIR filter 
% with a rolloff factor r and an equiripple characteristic.
% "Lth band" seem to be same as "filter span" in raised cosine filter

bmin = firnyquist(47, 10, .45, 'minphase');

b = firnyquist(2 * 47, 6, .45, 'nonnegative');

[hmin, w] = freqz(bmin);

[h, w] = freqz(b); 

fvtool(b,'Analysis','impulse');

% fvtool(b, 1, bmin, 1);



end

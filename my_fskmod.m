function [y] = my_fskmod(x, M, freq_sep, nSamp, Fs)
% modified from matlab fskmod function to understand fsk modulation
% only consider continuous phase case and 1 channel
%
% ######## comment on fs and freq_sep
% (1) fs = 1, freq_sep = .2
% (2) fs = 1e3, freq_sep = 200 (= 1e3 * .2)
% above two case give same y (iq sample)
%
% [usage]
% my_fskmod([0,1,0], 2, .2, 8, 1)

samptime = 1 / Fs;

nRows = length(x);

% Initialize the phase increments and the oscillator phase for modulator with discontinous phase.  
% phaseIncr is the incremental phase over one symbol, across all M tones.  
% phIncrSamp is the incremental phase over one sample, across all M tones.
phaseIncr = (0 : nSamp - 1)' * (-(M - 1) : 2 : (M - 1)) * pi * freq_sep * samptime
phIncrSamp = phaseIncr(2, :)    % recall that phaseIncr(1:0) = 0
prevPhase = 0;

Phase = zeros(nSamp * nRows, 1);

for iSym = 1 : nRows
    % Get the initial phase for the current symbol
    ph1 = prevPhase;
    
    % Compute the phase of the current symbol 
    % by summing the initial phase with the per-symbol phase trajectory associated with the given M-ary data element.
    Phase(nSamp * (iSym - 1) + 1 : nSamp * iSym) = ...
        ph1 * ones(nSamp, 1) + phaseIncr(:, x(iSym) + 1);
    Phase
    
    % the starting phase for the next symbol is 
    % the ending phase of the current symbol plus the phase increment over one sample.
    prevPhase = Phase(nSamp * iSym) + phIncrSamp(x(iSym) + 1)
end

y = exp(1i * Phase);

end

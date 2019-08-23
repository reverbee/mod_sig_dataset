function [y] = no_fading_fsk_modulation(M, freq_sep, symbol_length, sample_per_symbol, snr_db, fs, plot_modulated, plot_stella)
% fsk modulation
%
% [input]
% - M: mary, mother of jesus. must be power of 2.
% - freq_sep: fsk freq separation. (M-1) * freq_sep <= fs.
%   the desired separation between successive frequencies
%   see "learn_fsk_modulation_index.m"
%   important factor in fsk modulation: freq spectrum depend on freq_sep
% - symbol_length:
% - sample_per_symbol: sample per symbol
% - snr_db:
% - fs: sample rate. dont care in here
% - plot_modulated: boolean
% - plot_stella: boolean
%
% [usage]
% no_fading_fsk_modulation(2, .2, 2^8, 8, 10, 1, 1, 1)
% no_fading_fsk_modulation(4, .2, 2^8, 8, 10, 1, 1, 1)
% 
% ####### fsk example in real life ########
%
% [2fsk = bluetooth basic rate] (see "intro_to_bluetooth_test(basic rate, gfsk).pdf")
% binary gfsk(gaussian fsk), 1 Msymbol/sec (= 1Mbps)
% fsk modulation index = 0.32 nominal
% freq deviation between two peaks = 166e3 * 2 (two peaks from carrier = +-166e3)
% pulse shaping = gaussian filter
% bandwidth bit period product, BT = 0.5 (gaussian filter cut-off freq = 500e3)
%
% [4fsk = digital mobile radio] (see "digital mobile radio air interface protocol(2016).pdf")
% rf carrier bandwidth = 12.5e3
% symbol rate = 4800 symbols/sec
% symbol mapping to 4fsk freq deviation from carrier center: 
% (bit1,bit0) = [(0,1),(0,0),(1,0),(1,1)], symbol = [+3,+1,-1,-3], freq = [+1.944e3,+0.648e3,-0.648e3,-1.944e3]
% pulse shaping = root raised cosine filter
% 

% symbol
x = randi([0, M-1], symbol_length, 1);

if (M - 1) * freq_sep > fs
    error('must satisfy (M - 1) * freq_sep <= fs');
end

% fsk modulation
% must satisfy (M-1) * freq_sep <= fs
y = fskmod(x, M, freq_sep, sample_per_symbol, fs);
length(y);

% add noise
if ~isempty(snr_db)
    y = awgn(y, snr_db, 'measured', 'db');
end

if plot_modulated
    plot_signal(y, fs, sprintf('[%dfsk] freq sep = %g, snr = %d dB, sps = %d', ...
        M, freq_sep, snr_db, sample_per_symbol));
end

if plot_stella   
    y_rx = fskdemod(y, M, freq_sep, sample_per_symbol, fs);
    [number, ratio] = symerr(x, y_rx);
    
    plot_constellation(y, sprintf('[%dfsk] freq sep = %g, snr = %d dB, symbol error rate = %g', ...
        M, freq_sep, snr_db, ratio));
end

end

% % matlab digital modulation function
% %
% % pskmod(x, M, ini_phase)
% % fskmod(x, M, freq_sep, nsamp, fs) % phase_cont = 'cont' (default)
% % fskmod(x, M, freq_sep, nsamp, fs, phase_cont)
% % qammod(x, M, ini_phase)
% % mskmod(x, nsamp)
% % dpskmod(x, M)
% % oqpskmod(x)
% %



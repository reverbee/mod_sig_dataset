function [] = fsk_modulation(M, freq_sep, symbol_length, sample_per_symbol, snr_db, fs, plot_modulated, plot_stella)
% fsk modulation
%
% [input]
% - M: mary, mother of jesus
% - freq_sep: fsk freq separation. (M-1) * freq_sep <= 1
% - symbol_length:
% - sample_per_symbol:
% - snr_db:
% - fs:
% - plot_modulated: boolean
% - plot_stella: boolean
%
% [usage]
% fsk_modulation(2, .2, 30, 8, 10, 220e3, 1, 1)
% 
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
x;

if (M - 1) * freq_sep > 1
    error('must satisfy (M - 1) * freq_sep <= 1');
end

% fsk modulation
% must satisfy (M-1) * freq_sep <= fsk_fs
% freq_sep = .2;
fsk_sps = 2; % ############# must be greater than 1
fsk_fs = 1;
y = fskmod(x, M, freq_sep, fsk_sps, fsk_fs);
length(y)

if plot_modulated
    plot_signal(y, fs, 'modulated');
end

% design raised cosine filter
rolloff = .25; % roll-off factor
span = 6; % number of symbols
shape = 'sqrt'; % root raised cosine filter
rrc_filter = rcosdesign(rolloff, span, sample_per_symbol, shape);

% upsample and filter psk modulated signal
y = upfirdn(y, rrc_filter, sample_per_symbol);
length(y)

% if plot_modulated_signal
%     plot_signal(y, fs, 'modulated');
% end

transient_length = (span / 2) * sample_per_symbol;
% transient_length = ((span/2) - 1) * sample_per_symbol + sample_per_symbol / 2;
y = y(transient_length + 1 : end - transient_length);
length(y);

if plot_modulated
    plot_signal(y, fs, 'modulated');
end

if plot_stella
    % rrc fi;ter and down sample
    y = upfirdn(y, rrc_filter, 1, sample_per_symbol);
    % remove filter transient
    y = y(span + 1 : end - span);
    length(y);
    
    plot_constellation(y, 'fsk');
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



function [] = tdmb_ofdm_signal
% generate terrestrial dmb ofdm signal
%
% [ref] etsi 300 401 v010401(2006-01), transmission mode I, page 144 ~ 145 
%

sample_length = 2^10;

dqpsk_symbol_length = 2^5;

% elementary period
ep = 1 / 2.048e6;

% the number of OFDM symbols per transmission frame (the Null symbol being excluded)
L = 76;

% number of transmitted carriers
K = 1536;

% transmission frame duration, 196608 * ep = 96 msec
Tf = 196608 * ep;
Nf = 196608;

% null symbol duration, 2656 * ep = 1.297 msec
Tnull = 2656 * ep;
Nnull = 2656;

% duration of ofdm symbol except null symbol, 2552 * ep = 1.246 msec
Ts = 2552 * ep;
Ns = 2552;

% the inverse of carrier spacing, 2048 * ep = 1 msec
Tu = 2048 * ep;
Nu = 2048;
carrier_spacing = 1e3; % 1/(1 msec) = 1 khz

% the duration of the time interval called guard interval, 504 * ep = 0.246 msec
Tg = 504 * ep;
Ng = 504;

M = 4;

x = randi([0, M - 1], dqpsk_symbol_length, 1);

y = dpskmod(x, M);

% t = (0 : sample_length - 1)' * ep;

iq = zeros(sample_length, 1);

t = (0 : Ns - 1)' * ep;

% code formula in page 144
% when el = 0, null symbol should be genrated, 
% but i take another approach: null symbol will be prepended after all ofdm symbol is generated
ofdm_signal = zeros(Ns, L);
for el = 1 : L
    
    x = randi([0, M - 1], K + 1, 1);
    y = dpskmod(x, M);
    
    signal_per_carrier = zeros(K + 1, Ns);
    for k = (-K/2) : (K/2)
        signal_per_carrier(k + K/2 + 1, :) = exp(1i * 2 * pi * k * carrier_spacing * t) * y(k + K/2 + 1);
    end
    one_ofdm_symbol = sum(signal_per_carrier);
    
    ofdm_signal(:, el) = one_ofdm_symbol;
    
end
size(ofdm_signal)

y = ofdm_signal(:);
fs = 1 / ep;
title_text = 'tdmb';
plot_signal(y, fs, title_text)

end


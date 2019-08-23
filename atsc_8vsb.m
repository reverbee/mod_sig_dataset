function [] = atsc_8vsb(symbol_length, sample_per_symbol, snr_db, plot_modulated, plot_stella)
% atsc 8vsb modulation
% 
% [input]
% - symbol_length: symbol length
% - sample_per_symbol: sample per symbol
% - snr_db: snr in db. if empty, noise is NOT added to signal
% - plot_modulated: boolean
% - plot_stella: boolean
%
% [usage]
% atsc_8vsb(2^13, 8, 10, 1, 1)
% atsc_8vsb(2^13, 8, '', 1, 1)
%

% atsc symbol rate
atsc_symbol_rate = 10.762e6;
% sample rate
fs = atsc_symbol_rate * sample_per_symbol;

% symbol
M = 8;
x = randi([0, M-1], symbol_length, 1);

% pam modulation
ini_phase = 0;
y = pammod(x, M, ini_phase);

% pilot insertion
y = y + 1.25;

% design raised cosine filter for pulse shaping
% ##### this filter is for demo only, not having exact atsc spec.
rolloff = .25; % roll-off factor
span = 6; % number of symbols
shape = 'sqrt'; % root raised cosine filter
rrc_filter = rcosdesign(rolloff, span, sample_per_symbol, shape);

% upsample and filter modulated signal
y = upfirdn(y, rrc_filter, sample_per_symbol);
length(y);

% remove filter transient
transient_length = (span / 2) * sample_per_symbol;
% transient_length = ((span/2) - 1) * sample_per_symbol + sample_per_symbol / 2;
y = y(transient_length + 1 : end - transient_length);
length(y);

if plot_modulated
    plot_signal(y, fs, 'baseband');
end

if plot_stella
    % rrc filter and down sample
    y_rx = upfirdn(y, rrc_filter, 1, sample_per_symbol);
    % remove filter transient
    y_rx = y_rx(span + 1 : end - span);
    length(y_rx);
    
    plot_constellation(y_rx, sprintf('%dvsb after pilot insertion', M));
end

% freq down conversion
f_dn = 2.69e6;
t = (0 : length(y) - 1)' / fs;
y = y .* exp(-1i * 2 * pi * f_dn * t);

if plot_modulated
    plot_signal(y, fs, sprintf('freq down to %g mhz', -f_dn / 1e6));
end

% design low pass fir filter
% ##### this filter is for demo only, not having exact atsc spec.
filter_order = 74;
pass_freq = f_dn;
filter_coeff = fir1(filter_order, pass_freq / fs * 2);

% low pass filtering
a = 1;
y = filter(filter_coeff, a, y);

if plot_modulated
    plot_signal(y, fs, 'after filtering');
end

% fictitious carrier freq
fc = 25e6;
t = (0 : length(y) - 1)' / fs;
y = y .* exp(1i * 2 * pi * fc * t);

if plot_modulated
    plot_signal(y, fs, sprintf('freq up to carrier freq (= %g mhz)', fc / 1e6));
end

y = real(y);

% add awgn noise to signal
if ~isempty(snr_db)
    y = awgn(y, snr_db, 'measured', 'db');
end

if plot_modulated
    plot_signal(y, fs, sprintf('tx in air: carrier freq (= %g mhz)', fc / 1e6));
end

end


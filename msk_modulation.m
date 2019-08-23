function [] = msk_modulation(symbol_length, sample_per_symbol, snr_db, fs, plot_modulated, plot_stella)
% msk modulation
%
% [input]
% - M: mary, mother of jesus
% - symbol_length:
% - sample_per_symbol:
% - snr_db:
% - fs:
% - plot_modulated: boolean
% - plot_stella: boolean
%
% [usage]
% msk_modulation(2, 30, 8, 10, 220e3, 1, 1)
% 

% symbol
x = randi([0, 1], symbol_length, 1);
x;

% msk modulation
msk_sps = 8;
% msk_sps = 1;
y = mskmod(x, msk_sps);
% y = mskmod(x, sample_per_symbol);
length(y)

% if plot_modulated
%     plot_signal(y, fs, 'modulated');
% end

% design raised cosine filter
rolloff = .25; % roll-off factor
span = 6; % number of symbols
shape = 'sqrt'; % root raised cosine filter
rrc_sps = 8; 
rrc_filter = rcosdesign(rolloff, span, rrc_sps, shape);

% upsample and filter psk modulated signal
y = upfirdn(y, rrc_filter, 1);
% y = upfirdn(y, rrc_filter, sample_per_symbol);
length(y);

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
    % rrc filter and down sample
    y = upfirdn(y, rrc_filter);
%     y = upfirdn(y, rrc_filter, 1, sample_per_symbol);
    % remove filter transient
    y = y(span + 1 : end - span);
    length(y);
    
    plot_constellation(y, 'msk');
end

end

% % matlab digital modulation function
% %
% % pskmod(x, M, ini_phase)
% % fskmod(x, M, freq_sep, nsamp, fs, phase_cont)
% % qammod(x, M, ini_phase)
% % mskmod(x, nsamp)
% % dpskmod(x, M)
% % oqpskmod(x)
% %


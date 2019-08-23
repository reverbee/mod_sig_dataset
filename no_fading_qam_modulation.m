function [] = no_fading_qam_modulation(M, symbol_length, sample_per_symbol, snr_db, fs, plot_modulated, plot_stella)
% qam modulation
%
% [input]
% - M: mary, mother of jesus
% - symbol_length:
% - sample_per_symbol:
% - snr_db: snr in db. if empty, noise is NOT added to signal
% - fs: sample rate. dont care in here
% - plot_modulated: boolean
% - plot_constella: boolean
%
% [usage]
% no_fading_qam_modulation(16, 2^10, 8, 10, 220e3, 1, 1)
% no_fading_qam_modulation(64, 2^10, 8, 10, 220e3, 1, 1)
% 

% symbol
x = randi([0, M-1], symbol_length, 1);

% qam modulation
ini_phase = 0;
y = qammod(x, M, ini_phase);

% design raised cosine filter for pulse shaping
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

% add noise
if ~isempty(snr_db)
    y = awgn(y, snr_db, 'measured', 'db');
end

if plot_modulated
    plot_signal(y, fs, 'modulated');
end

if plot_stella
    % rrc filter and down sample
    y_rx = upfirdn(y, rrc_filter, 1, sample_per_symbol);
    % remove filter transient
    y_rx = y_rx(span + 1 : end - span);
    length(y);
    
    plot_constellation(y_rx, sprintf('%dqam', M));
end

end

% % matlab digital modulation function
% %
% % pskmod(x, M, ini_phase)
% % fskmod(x, M, freq_sep, nsamp, fs, phase_cont)
% % qammod(x, M, ini_phase)
% % mskmod(x, nsamp, data_enc, ini_phase)
% % dpskmod(x, M, phase_rot)
% % oqpskmod(x, ini_phase)
% %


function [] = dpsk_modulation(M, phase_rot, symbol_length, sample_per_symbol, snr_db, fs, ...
    plot_modulated, plot_stella)
% dpsk modulation
%
% [input]
% - M: mary, mother of jesus
% - phase_rot: phase rotation in radian
% - symbol_length:
% - sample_per_symbol:
% - snr_db:
% - fs:
% - plot_modulated: boolean
% - plot_stella: boolean
%
% [usage]
% dpsk_modulation(4, pi/8, 30, 8, 10, 220e3, 1, 1)
% 

% symbol
x = randi([0, M-1], symbol_length, 1);
x;

% dpsk modulation
y = dpskmod(x, M, phase_rot);
y;

% if plot_modulated
%     plot_signal(y, fs, 'modulated');
% end

% design raised cosine filter
rolloff = .25; % roll-off factor
span = 6; % number of symbols
shape = 'sqrt'; % root raised cosine filter
rrc_filter = rcosdesign(rolloff, span, sample_per_symbol, shape);

% upsample and filter psk modulated signal
y = upfirdn(y, rrc_filter, sample_per_symbol);
length(y);

% remove filter transient
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
    
    plot_constellation(y, 'dpsk');
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

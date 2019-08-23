function [] = stdchan_digital_mod(modulation_filename, chan_type, chan_fs, fd, snr_db)
% pass digital modulation signal through standard rician channel,
% and compare fading signal with non-fading signal.
% ######### key point:
% (1) same signal must be used in both case(non-fading, fading)
% (2) modulation file must have only signal, no noise
%
% [input]
% - modulation_filename: modulation signal mat filename. 
%   to compare fading signal with non-fading signal, must have non-fading, non-awgn signal.
%   to generate modulation file, use "psk_modulation.m", "qam_modulation.m", 'fsk_modulation.m"
%   (ex) psk_modulation(2, 2^13, 8, '', 1, 1, 1, '', 1e6, 0, 1);
%   (ex) psk_modulation(4, 2^13, 8, '', 1, 1, 1, '', 1e6, 0, 1);
%   (ex) qam_modulation(16, 2^13, 8, '', 1, 1, 1, '', 1e6, 0, 1);
%   (ex) fsk_modulation(2, .2, 2^13, 8, '', 1, 1, 1, '', 1e6, 0, 1);
%   (ex) fsk_modulation(4, .2, 2^13, 8, '', 1, 1, 1, '', 1e6, 0, 1);
% - chan_type: one of 'gsmRAx6c1', 'gsmRAx4c2', 'cost207RAx6', 'cost207RAx4'
% - chan_fs: channel fs. used for sample period in constructing fading channel object.
% - fd: max doppler freq in hz. must be 0.
% - snr_db: snr in db after fading channel
%
% [usage]
% stdchan_digital_mod('2psk_modulation.mat', 'gsmRAx4c2', 1e6, 0, 10);
% stdchan_digital_mod('4psk_modulation.mat', 'gsmRAx4c2', 1e6, 0, 10);
% stdchan_digital_mod('16qam_modulation.mat', 'gsmRAx6c1', 1e6, 0, 10);
% stdchan_digital_mod('2fsk_modulation.mat', 'gsmRAx6c1', 1e6, 0, 10);
% stdchan_digital_mod('4fsk_modulation.mat', 'gsmRAx6c1', 1e6, 0, 10);
%
% [rician channel in GSM/EDGE channel models]
% 'gsmRAx6c1': Typical case for rural area (RAx), 6 taps, case 1
% 'gsmRAx4c2': Typical case for rural area (RAx), 4 taps, case 2
%
% [rician channel in COST 207 channel models]
% 'cost207RAx4': Rural Area (RAx), 4 taps
% 'cost207RAx6': Rural Area (RAx), 6 taps
% 
% [reference]
% [1] COST 207, "Digital land mobile radio communications," 
%     Office for Official Publications of the European Communities, 
%     Final report, Luxembourg, 1989.
% [2] 3GPP TS 05.05 V8.20.0 (2005-11): 3rd Generation Partnership Project; 
%     Technical Specification Group GSM/EDGE Radio Access(TM) Network; 
%     Radio transmission and reception (Release 1999).
% [3] 3GPP TS 45.005 V7.9.0 (2007-2): 3rd Generation Partnership Project; 
%     Technical Specification Group GSM/EDGE Radio Access Network; 
%     Radio transmission and reception (Release 7).

% S: struct to protect variables in loaded file
S = load(modulation_filename);

% design raised cosine filter for pulse shaping
rolloff = .25; % roll-off factor
span = 6; % number of symbols
sample_per_symbol = S.sample_per_symbol;
shape = 'sqrt'; % root raised cosine filter
rrc_filter = rcosdesign(rolloff, span, sample_per_symbol, shape);

% add noise
y_awgn = awgn(S.y, snr_db, 'measured', 'db');

plot_signal(y_awgn, S.fs, sprintf('[no fading] %s', modulation_filename));

% rrc filter and down sample
y_awgn_rx = upfirdn(y_awgn, rrc_filter, 1, sample_per_symbol);
% remove filter transient
y_awgn_rx = y_awgn_rx(span + 1 : end - span);

plot_constellation(y_awgn_rx, sprintf('[no fading] %s', modulation_filename));

% create standard channel
ts = 1 / chan_fs;
chan = stdchan(ts, fd, chan_type);
% pass signal through channel
y_chan = filter(chan, S.y);

% add noise
y_chan = awgn(y_chan, snr_db, 'measured', 'db');

plot_signal(y_chan, S.fs, sprintf('[%s] %s', chan_type, modulation_filename));

% rrc filter and down sample
y_chan_rx = upfirdn(y_chan, rrc_filter, 1, sample_per_symbol);
% remove filter transient
y_chan_rx = y_chan_rx(span + 1 : end - span);

plot_constellation(y_chan_rx, sprintf('[%s] %s', chan_type, modulation_filename));

end


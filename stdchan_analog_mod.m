function [] = stdchan_analog_mod(modulation_filename, chan_type, chan_fs, fd, snr_db)
% pass analog modulation signal through standard rician channel,
% and compare fading signal with non-fading signal.
% ######### key point: 
% (1) same signal must be used in both case(non-fading, fading)
% (2) modulation file must have only signal, no noise
%
% [input]
% - modulation_filename: modulation signal mat filename. 
%   to compare fading signal with non-fading signal, must be non-fading, non-awgn signal
%   to generate modulation file, use "am_modulation.m", "ssb_modulation.m", 'nbfm_modulation.m"
%   (ex) am_modulation(2^13, '', 1, 0, '', 44.1e3, 0, 1);
%   (ex) ssb_modulation(2^13, '', 0, 1, 0, '', 44.1e3, 0, 1);
%   (ex) nbfm_modulation(2^13, 1e3, '', 1, 0, '', 44.1e3, 0, 1);
% - chan_type: one of 'gsmRAx6c1', 'gsmRAx4c2', 'cost207RAx6', 'cost207RAx4'
% - chan_fs: channel fs. used for sample period in constructing fading channel object.
% - fd: max doppler freq in hz. must be 0.
% - snr_db: snr in db after fading channel
%
% [usage]
% stdchan_analog_mod('am_modulation.mat', 'gsmRAx4c2', 44.1e3, 0, 10);
% stdchan_analog_mod('ssb_modulation.mat', 'gsmRAx4c2', 44.1e3, 0, 10);
% stdchan_analog_mod('nbfm_modulation.mat', 'gsmRAx4c2', 44.1e3, 0, 10);
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

% add noise
y_awgn = awgn(S.y, snr_db, 'measured', 'db');

plot_signal(y_awgn, S.fs, sprintf('[no fading] %s', modulation_filename));

% create standard channel
ts = 1 / chan_fs;
chan = stdchan(ts, fd, chan_type);
% pass signal through channel
y_chan = filter(chan, S.y);

% add noise
y_chan = awgn(y_chan, snr_db, 'measured', 'db');

plot_signal(y_chan, S.fs, sprintf('[%s] %s', chan_type, modulation_filename));

end


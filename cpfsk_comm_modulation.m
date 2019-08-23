function [y] = ...
    cpfsk_comm_modulation(M, modulation_index, symbol_length, sample_per_symbol, snr_db, fs, plot_modulated, plot_stella, ...
    chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg)
% fsk modulation using comm.CPFSKModulator System object
%
% [input]
% - M: mary, mother of jesus. must be power of 2.
% - modulation_index: fsk modulation index
%   important factor in fsk modulation: freq spectrum depend on freq_sep
% - symbol_length:
% - sample_per_symbol: sample per symbol
% - snr_db:
% - fs: sample rate.
%   ####### set to 1, not important because only plot_signal function use this.
% - plot_modulated: boolean
% - plot_stella: boolean
% - chan_type: standard fading channel(rician). one of 'gsmRAx6c1', 'gsmRAx4c2', 'cost207RAx6', 'cost207RAx4'
%   for details, use "help stdchan" in matlab command window
%   if empty, no fading channel
% - chan_fs: channel fs. used for sample period in constructing fading channel object.
%   even if chan_type is empty, "apply_carrier_offset" function use it.
% - fd: max doppler freq in hz. used in constructing fading channel object. 
%   recommend = 0. dont use fd > 0 (##### you may restart matlab program)
%   if chan_type is empty, dont care
% - save_iq: 0 = no save, 1 = save iq into 'nbfm_modulation.mat' file.
% - max_freq_offset_hz: freq offset = randi([-max_freq_offset_hz, max_freq_offset_hz]). 
%   if 0, no freq offset
% - max_phase_offset_deg: phase offset = randi([-max_phase_offset_deg, max_phase_offset_deg]). 
%   if 0, no phase offset
%
% [usage]
% cpfsk_comm_modulation(2, .5, 2^8, 8, 10, 1, 1, 1, 'gsmRAx6c1', 1e6, 0, 0, 100, 180);
% cpfsk_comm_modulation(4, .5, 2^8, 8, 10, 1, 1, 1, '', 1e6, 0, 0, 100, 180);
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

code_book = (-(M-1) : 2 : (M-1))';
x = code_book(x + 1);

% fsk modulation using comm.CPFSKModulator System object
h_mod = comm.CPFSKModulator(M, 'ModulationIndex', modulation_index, 'SamplesPerSymbol', sample_per_symbol);
y = step(h_mod, x);

% apply fading channel
if ~isempty(chan_type)
    y = apply_fading_channel(y, chan_type, chan_fs, fd);
end

% apply carrier offset
if max_freq_offset_hz || max_phase_offset_deg
    % ##########################################################
    % #### must have chan_fs input, NOT fs
    % #### in later, must write (fs, chan_fs) unified version
    % ##########################################################
    y = apply_carrier_offset(y, chan_fs, max_freq_offset_hz, max_phase_offset_deg);
end

% add noise
if ~isempty(snr_db)
    y = awgn(y, snr_db, 'measured', 'db');
end

% save iq into mat file
if save_iq
    mat_filename = sprintf('%d%s.mat', M, mfilename);
    save(mat_filename, 'y', 'M', 'modulation_index', 'symbol_length', 'sample_per_symbol', 'snr_db', 'fs', ...
        'chan_type', 'chan_fs', 'fd');
end

if plot_modulated
    plot_signal(y, fs, sprintf('[%dfsk] mod index = %g, snr = %d dB, sps = %d', ...
        M, modulation_index, snr_db, sample_per_symbol));
end

if plot_stella
    h_demod = comm.CPFSKDemodulator(M, 'ModulationIndex', modulation_index, 'SamplesPerSymbol', sample_per_symbol);
    y_rx = step(h_demod, y);
    
    delay = log2(h_demod.ModulationOrder) * h_demod.TracebackDepth;
    h_error = comm.ErrorRate('ReceiveDelay', delay);
    error_status = step(h_error, x, y_rx); % for output error_status, see "comm.CPFSKModulator" example
    
    plot_constellation(y, sprintf('[%dfsk] mod index = %g, snr = %d dB, symbol error rate = %g', ...
        M, modulation_index, snr_db, error_status(1)));
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



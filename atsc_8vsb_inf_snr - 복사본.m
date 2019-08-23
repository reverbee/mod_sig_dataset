function [] = atsc_8vsb_inf_snr(symbol_length, sample_per_symbol, downsample_rate, signal_plot, signal_save)
% atsc 8vsb modulation when inf snr
% used to generate atsc digital tv signal and save signal
% "generate_modulation_signal_cnn_train_set.m" will load the saved 8vsb signal from file
%
% ####### how to generate training signal
% (1) load iq from saved inf snr signal file
% (1) select random 128 samples from loaded iq
% (2) apply fading, snr, carrier offset
% (3) symbol synch error is NOT needed because 128 samples are random selected
% 
% [input]
% - symbol_length: symbol length
%   when 2^20, final sample length = 748734, 
%   fix(748734 / 128) = 5849 instance (greater than 1000 instance)
% - sample_per_symbol: sample per symbol, must be integer greater than 1
%   ###################################################################################
%   atsc symbol rate = 10.76e6, atsc bw = 5.38e6 (atsc channel spacing = 6e6)
%   fsq sample rate = 6.725e6, fsq bw = 6.725e6 * .8 = 5.38e6
%   select "sample_per_symbol" and "downsample_rate" for final sample rate to be slightly greater than fsq sample rate
%   how to compute final sample rate: 
%   final_sample_rate = 10.76e6 * sample_per_symbol / downsample_rate
%   (example)
%   sample_per_symbol = 7, downsample_rate = 11, 10.76e6 * 5 / 11 = 6.8473e6
%   ###################################################################################
% - downsample_rate: final downsample rate, see "sample_per_symbol" input comment
% - signal_plot: boolean
% - signal_save: boolean
%
% [usage]
% atsc_8vsb_inf_snr(2^20, 7, 11, 0, 1)
% atsc_8vsb_inf_snr(2^12, 7, 11, 1, 0)
%

% [atsc standard] https://www.atsc.org/wp-content/uploads/2015/03/a_53-Part-2-2011.pdf
% 
% [block diagram of 8-vsb exciter]
% [reference] http://www.arrl.org/files/file/Technology/TV_Channels/8_Bit_VSB.pdf
%
% (mpeg-2 packet) -> (frame synchronizer) -> (data randomizer) -> (reed solomon encoder) -> (data interleaver) -> 
% (trellis encoder) -> (sync insertion: segment sync, field sync) -> (pilot insertion) -> (8-vsb modulator) -> 
% (analog upconversion) -> (8-vsb rf out)
%
% (mpeg-2 packet) 
% output from mpeg-2 encoder, rate = 19.39 mbit/sec, 
%
% (frame synchronizer)
% mpeg-2 data packets are 188 bytes in length with the first byte in each packet always being the sync byte. 
% the mpeg-2 sync byte is then discarded; 
% it will ultimately be replaced by the ATSC segment sync in a later stage of processing.
%
% (data randomizer)
% with the exception of the segment and field syncs, 
% the 8-VSB bit stream must have a completely random, noise-like nature.
%
% each byte value is changed according to known pattern of pseudo-random number generation. 
% this process is reversed in the receiver in order to recover the proper data values.
%
% (reed solomon encoder)
% takes all 187 bytes of an incoming mpeg-2 data packet (the packet sync byte has been removed)
% and mathematically manipulates them as a block to create a sort of "digital thumbnail sketch" of the block contents. 
% this "sketch" occupies 20 additional bytes which are then tacked onto the tail end of the original 187 byte packet. 
% these 20 bytes are known as Reed-Solomon parity bytes.
%
% The receiver will compare the received 187 byte block to the 20 parity bytes 
% in order to determine the validity of the recovered data. 
% If errors are detected, the receiver can use the parity bytes to locate the exact location of the errors, 
% modify the corrupted bytes, and reconstruct the original information. 
% Up to 10 byte errors per packet can be corrected this way.
%
% (data interleaver)
% scrambles the sequential order of the data stream and disperses the mpeg-2 data packet data 
% throughout time (over a range of about 4.5 msec through the use of memory buffers) 
% in order to minimize the transmitted signal's sensitivity to burst type interference. 
% the data interleaver then assembles new data packets incorporating tiny fragments 
% from many different mpeg-2 (pre-interleaved) packets. 
% These reconstituted data packets are the same length as the original mpeg-2 packets: 
% 207 bytes (after Reed-Solomon coding).
%
% Data interleaving is done according to a known pattern; 
% the process is reversed in the receiver in order to recover the proper data order.
%
% (trellis encoder)
% For trellis coding, each 8-bit byte is split up into a stream of four, 2-bit words. 
% In the trellis coder, each 2-bit word that arrives is compared to the past history of previous 2-bit words. 
% A 3-bit binary code is mathematically generated 
% to describe the transition from the previous 2-bit word to the current one. 
% These 3-bit codes are substituted for the original 2-bit words 
% and transmitted over-the-air as the eight level symbols of 8-VSB (3 bits = 2^3 = 8 combinations or levels). 
% For every two bits that go into the trellis coder, three bits come out. 
% For this reason, the trellis coder in the 8-VSB system is said to be a 2/3 rate coder.
%
% The trellis decoder in the receiver uses the received 3-bit transition codes 
% to reconstruct the evolution of the data stream from one 2-bit word to the next. 
% In this way, the trellis coder follows a "trail" as the signal moves from one word to the next through time. 
% The power of trellis coding lies in its ability to track a signal's history through time 
% and discard potentially faulty information (errors) based on a signal's past and future behavior.
%
% (segment sync insertion)
% An ATSC data segment is comprised of the 207 bytes of an interleaved data packet. 
% After trellis coding, our 207 byte segment has been stretched out 
% into a baseband stream of 828 eight level symbols. 
% The ATSC segment sync is a four symbol pulse that is added to the front of each data segment 
% and replaces the missing first byte (packet sync byte) of the original MPEG-II data packet. 
% The segment sync appears once every 832 symbols 
% and always takes the form of a positive-negative-positive pulse swinging between the +5 and -5 signal levels
%
% Each ATSC segment sync lasts 0.37 usec; An ATSC data segment lasts 77.3 usec.
%
% (field sync insertion)
% 313 data segments are combined to make a data field. 
% The ATSC field sync is an entire data segment that is repeated once per field (24.2 msec).
% The ATSC field sync has a known data symbol pattern of positive-negative pulses 
% and is used by the receiver to eliminate signal ghosts caused by poor reception.
%
% At the end of each field sync segment, the last twelve symbols from the last data segment are repeated 
% in order to restart the trellis coder in the receiver.
%
% (pilot insertion)
% Just before modulation, a small DC shift is applied to the 8-VSB baseband signal
% (which was previously centered about zero volts with no DC component). 
% This causes a small residual carrier to appear at the zero frequency point of the resulting modulated spectrum. 
% This is the ATSC pilot. 
%
% This gives the RF PLL circuits in the 8-VSB receiver something to lock onto 
% that is independent of the data being transmitted.
%
% the ATSC pilot is much smaller than the NTSC visual carrier, 
% consuming only 0.3 dB or 7 percent of the transmitted power.
% 
% (am modulation)
% Our eight level baseband DTV signal, with syncs and DC pilot shift added, is then amplitude modulated 
% onto an intermediate frequency (IF) carrier. 
% This creates a large, double sideband IF spectrum about our carrier frequency.
% The occupied bandwidth of this IF signal is far too wide to be transmitted in our assigned 6 MHz channel.
%
% (nyquist filter)
% As a result of the data overhead added to the signal stream 
% in the form of forward error correction coding and sync insertion,
% our data rate has gone from 19.39 Mbit/sec at the exciter input to 32.28 Mbit/sec at the output of the trellis coder.
% Since 3 bits are transmitted in each symbol of the 8-level 8-VSB constellation, 
% the resulting symbol rate is 32.28 Mbit/3 = 10.76 Msymbols/sec. 
% By virtue of the Nyquist Theorem, we know that 10.76 Msymbols/sec can be transmitted 
% in a vestigial sideband signal (VSB) with a minimum frequency bandwidth of 1/2 * 10.76 MHz = 5.38 MHz. 
% Since we are allotted a channel bandwidth of 6 MHz, 
% we can relax the steepness of our VSB filter skirts slightly and still fall within the 6 MHz channel. 
% This permissible excess bandwidth is 11.5% for the ATSC 8-VSB system. 
% That is, 5.38 MHz (minimum bandwidth per Nyquist) + 620 kHz (11.5% excess bandwidth) = 6.00 MHz.
%

% % 1 = raised cosine filter, 0 = nyquist filter 
% use_raised_cosine_filter = 1;

% atsc symbol rate
atsc_symbol_rate = 10.76e6;
% sample rate
fs = atsc_symbol_rate * sample_per_symbol;

% symbol
M = 8;
x = randi([0, M-1], symbol_length, 1);

% pam modulation
ini_phase = 0;
y = pammod(x, M, ini_phase);
size(y);

% if signal_plot
%     plot_signal_time_domain(y, atsc_symbol_rate, 'after pam mod');
% end

% pilot insertion
% why 1.25? see page 24 in "https://www.atsc.org/wp-content/uploads/2015/03/a_53-Part-2-2011.pdf"
y = y + 1.25;

% sample_len_before_rcos_filter = symbol_length * sample_per_symbol;

% design raised cosine filter for pulse shaping
% The order of the filter, (sample_per_symbol * span), must be even
% ##### this filter is for demo only, not having exact atsc spec.
rolloff = .1152; % roll-off factor, see "atsc spec"
% rolloff = .25; % roll-off factor
span = 10; % number of symbols to span, this is right?
shape = 'sqrt'; % root raised cosine filter
rrc_filter = rcosdesign(rolloff, span, sample_per_symbol, shape);

% upsample and root raised cosine filtering
y = upfirdn(y, rrc_filter, sample_per_symbol);
size(y);

% % remove filter transient, make signal length to (symbol_length * sample_per_symbol)
% transient_length = length(y) - symbol_length * sample_per_symbol;
% if mod(transient_length, 2) % odd number
%     half_length = fix(transient_length / 2);
%     y = y(half_length + 1 : end - half_length - 1);
% else % even number
%     half_length = transient_length / 2;
%     y = y(half_length + 1 : end - half_length);
% end
% size(y);

if signal_plot
    plot_signal(y, fs, 'after upsample and rcos filter');
end

% freq down conversion
f_down = 2.69e6;
t = (0 : length(y) - 1)' / fs;
y = y .* exp(-1i * 2 * pi * f_down * t);
size(y);

% if signal_plot
%     plot_signal(y, fs, sprintf('freq down to -%g mhz', f_down / 1e6));
% end

% design low pass fir filter
% ##### this filter is for demo only, not exact atsc spec.
filter_order = 74;
pass_freq = f_down;
filter_coeff = fir1(filter_order, pass_freq / fs * 2);

% low pass filtering
a = 1;
y = filter(filter_coeff, a, y);
size(y);

if signal_plot
    plot_signal(y, fs, 'after freq down and low pass filtering');
end

% only downsample, not rcos filter, we are not digital tv receiver
% ##### try "decimate"
% downsample_rate must set to fsq sample rate, see "command input"
y = downsample(y, downsample_rate);
% y = downsample(y, sample_per_symbol);
size(y);

% remove transient
transient_length = 128;
y = y(transient_length + 1 : end - transient_length);
size(y)

if signal_plot
    plot_signal(y, fs / downsample_rate, 'after only downsample (not rcos filter)');
%     plot_signal(y, fs / sample_per_symbol, 'after only downsample (not rcos filter)');
end

if signal_save
    fs = fs / downsample_rate; % final sample rate
    signal_filename = sprintf('inf_snr_8vsb_atsc_dtv_sps%d_down%d.mat', ...
        sample_per_symbol, downsample_rate);
    save(signal_filename, 'y', 'sample_per_symbol', 'downsample_rate', 'fs');
    
    fprintf('### atsc digital tv signal saved into ''%s'' file\n', signal_filename);
end

end


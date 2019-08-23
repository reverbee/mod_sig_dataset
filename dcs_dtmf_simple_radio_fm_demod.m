function [] = dcs_dtmf_simple_radio_fm_demod(mat_filename)
% extract dcs, dtmf signal from simple radio fm demodulated signal
%
% [input]
% - mat_filename: simple radio fm demodulated signal filename
%
% [usage]
% dcs_dtmf_simple_radio_fm_demod('simple_radio_fm_demoded_190102133150.mat')
%

% ##############################################################
% simple radio fm demoded(freq devation = 2.5 khz) signal have:
% (1) audio signal (human conversation)
% (2) dtmf(dual tone multi frequency) signal
% (3) dcs(digital coded squelch) signal
%
% dtmf and dcs signal is for selective calling
% [reference] 
% https://en.wikipedia.org/wiki/Selective_calling
%
% dtmf signal is used for individual calling to identify radio station.
% [reference] 
% https://en.wikipedia.org/wiki/Dual-tone_multi-frequency_signaling
%
% dcs signal is used for group calling to identify radio station group,
% and also known as digital private line(motorola trade mark).
% [reference] 
% https://wiki.radioreference.com/index.php/DCS
% http://mmi-comm.tripod.com/dcs.html
%
% largest market share of analog simple radio in korea is motorola
% ####################################################################

load(mat_filename);

title_text = 'simple radio fm demoded';
plot_signal(z, fs_hz, title_text);

% ####################################################
% dcs is a digital subaudible selective signalling system. 
% it uses a code composed of 23 bits sent repeatedly at rate of 134 bps. 
% the code is based on the Golay (23,12) code, 
% and has the ability to detect and correct any three bit or less error that occurs in the 23 bit word. 
% the word is composed of a 12 bit data field and an 11 bit parity vector. 
% the 12 bits are divided into 4 octal digits:
% the first always being set to 100 (octal), the 2nd, 3rd and 4th digits form the three octal digit DCS code number.
%
% the dcs word is sent continuously, starting when transmission begins. 
% when the user releases the PTT, 
% the encoder will change the code to a pattern of alternating 1's and 0's at 268 bps for 180 ~ 200 msec, 
% then stop transmitting. 
% this "turn off" code causes receiving decoders to mute, thereby eliminating the squelch tail noise burst.
% ##############################################

% design low pass filter to extract dcs code signal
% passband = 300 hz ("turn off" dcs code is at 268 bps)
filter_order = 78;
b = fir1(filter_order, 300 / fs_hz);

% low pass filtering
dcs_code = filter(b, 1, z);
% ##############################################
% good news: there is no filter delay
% matlab version dependant? there was delay in old version
% ########################################
size(z);
size(dcs_code);

plot_signal(dcs_code, fs_hz, 'dcs code using low pass filter');

% design high pass filter to remove dcs code signal
filter_order = 128;
filter_type = 'high';
b = fir1(filter_order, 300 / fs_hz, filter_type);

% high pass filtering
z_no_dcs = filter(b, 1, z);

plot_signal(z_no_dcs, fs_hz, 'removed dcs code using high pass filter');

% % plot to get sample index for dtmf signal
% figure; plot(z_no_dcs, '.-'); grid on;

% manual method: tedious, not nice
% #########################################################################################################
% only valid in fm demoded file, 'simple_radio_fm_demoded_190102133150.mat', 
% which is obtained by demodulation of signal in 'fsq_iq_190102133150_146.512500_0.008500_0.015000.mat' 
% use "remove_no_signal_simple_radio.m" to get fm demoded file
% #########################################################################################################
dtmf_sample_idx = ...
    [
    100, 700
    1600, 2200
    3100, 3800
    
    93000, 94200
    95600, 96800

    202900, 203500
    204200, 204900
    205600, 206200

    263400, 264000
    264900, 265600
    266500, 267100
    268000, 268700
    ];

dtmf_signal_length = size(dtmf_sample_idx, 1);

% decode dtmf digit
dtmf_digit = zeros(1, dtmf_signal_length);
for n = 1 : dtmf_signal_length
    y = z_no_dcs(dtmf_sample_idx(n, 1) : dtmf_sample_idx(n, 2));
    dtmf_digit(n) = dtmf_decode(y, fs_hz);
end
dtmf_digit

end

%% 
function [dtmf_digit] = dtmf_decode(y, fs)

% ##########################################
% DTMF keypad frequencies
%         1209 Hz 1336 Hz 1477 Hz 1633 Hz
% ----------------------------------------
% 697 Hz   1	   2	   3	   A
% 770 Hz   4	   5	   6	   B
% 852 Hz   7	   8	   9	   C
% 941 Hz   *	   0	   #	   D
% ######################################

% [reference] 
% https://en.wikipedia.org/wiki/Dual-tone_multi-frequency_signaling

dtmf_freq = [697 770 852 941 1209 1336 1477 1633];

N = length(y);
freq_idx = round(dtmf_freq / fs * N) + 1;

% using goertzel algorithm
dft_data = abs(goertzel(y, freq_idx));

% get index of two largest max
[Y, I_1st] = max(dft_data);
dft_data(I_1st) = 0;
[Y, I_2nd] = max(dft_data);

% sort index in increasing order
[two_max_idx] = sort([I_1st, I_2nd]);

% see dtmf keypad freq table
% row index = [697 770 852 941], column index = [1209 1336 1477 1633]
digit_table = ...
    [
    1, 2, 3, 65    % double('A') = 65
    4, 5, 6, 66    % double('B') = 66
    7, 8, 9, 67    % double('C') = 67
    42, 0, 35, 68  % double('*') = 42, double('#') = 35, double('D') = 68
    ];

two_max_idx(2) = two_max_idx(2) - 4;

dtmf_digit = digit_table(two_max_idx(1), two_max_idx(2));

end

%% 
function [dtmf_digit] = old_dtmf_decode(y, fs)

% ##########################################
% DTMF keypad frequencies
%         1209 Hz 1336 Hz 1477 Hz 1633 Hz
% ----------------------------------------
% 697 Hz   1	   2	   3	   A
% 770 Hz   4	   5	   6	   B
% 852 Hz   7	   8	   9	   C
% 941 Hz   *	   0	   #	   D
% ######################################

dtmf_freq = [697 770 852 941 1209 1336 1477 1633];

N = length(y);
freq_idx = round(dtmf_freq / fs * N) + 1;

% using goertzel algorithm
dft_data = abs(goertzel(y, freq_idx));

% get index of two largest max
[Y, I_1st] = max(dft_data);
dft_data(I_1st) = 0;
[Y, I_2nd] = max(dft_data);

% sort index in increasing order
[two_max_idx] = sort([I_1st, I_2nd]);

% see dtmf keypad freq table
digit_table = [
    1, 5  % digit = 1
    1, 6  % digit = 2
    1, 7  % digit = 3
    2, 5  % digit = 4
    2, 6  % digit = 5
    2, 7  % digit = 6
    3, 5  % digit = 7
    3, 6  % digit = 8
    3, 7  % digit = 9
    4, 6  % digit = 0
    ];

d_minus_idx = digit_table - two_max_idx;

d_row_len = size(digit_table, 1);
dtmf_digit = [];
for n = 1 : d_row_len
    if d_minus_idx(n, 1) == 0 && d_minus_idx(n, 2) == 0
        dtmf_digit = n;
        break;
    end
end

if dtmf_digit == 10
    dtmf_digit = 0;
end

end



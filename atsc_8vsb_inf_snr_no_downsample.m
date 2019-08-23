function [] = atsc_8vsb_inf_snr_no_downsample(symbol_length, sample_per_symbol, signal_plot, signal_save)
% atsc 8vsb modulation when inf snr
%
% differ from "atsc_8vsb_inf_snr.m":
% "downsample_rate" input is not used
%
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
%   ###################################################################################
% - signal_plot: boolean
% - signal_save: boolean
%
% [usage]
% atsc_8vsb_inf_snr_no_downsample(2^20, 4, 0, 1)
% atsc_8vsb_inf_snr_no_downsample(2^12, 4, 1, 0)
%

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

% % only downsample, not rcos filter, we are not digital tv receiver
% % ##### try "decimate"
% % downsample_rate must set to fsq sample rate, see "command input"
% y = downsample(y, downsample_rate);
% % y = downsample(y, sample_per_symbol);
% size(y);
% 
% % remove transient
% transient_length = 128;
% y = y(transient_length + 1 : end - transient_length);
% size(y)
% 
% if signal_plot
%     plot_signal(y, fs / downsample_rate, 'after only downsample (not rcos filter)');
% %     plot_signal(y, fs / sample_per_symbol, 'after only downsample (not rcos filter)');
% end

if signal_save
%     fs = fs / downsample_rate; % final sample rate
    signal_filename = sprintf('inf_snr_8vsb_atsc_dtv_sps%d.mat', ...
        sample_per_symbol);
    save(signal_filename, 'y', 'sample_per_symbol', 'fs');
    
    fprintf('### atsc digital tv signal saved into ''%s'' file\n', signal_filename);
end

end


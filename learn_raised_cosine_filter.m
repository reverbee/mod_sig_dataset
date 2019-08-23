function [] = learn_raised_cosine_filter(rolloff, span, sps, symbol_rate)
% learn raised cosine filter
%
% Raised cosine FIR pulse-shaping filter design
% b = rcosdesign(beta,span,sps,shape) returns a square-root raised cosine filter 
% when you set shape to 'sqrt' and a normal raised cosine FIR filter when you set shape to 'normal'
%
% This example shows how to interpolate and decimate signals 
% using square-root, raised cosine filters designed with the rcosdesign function. 
% This example requires the Communications System Toolbox software.
%
% [usage]
% learn_raised_cosine_filter(.25, 6, 4, 500)

% Define the square-root, raised cosine filter parameters. Define the signal constellation parameters.
% rolloff = 0.25; % Filter rolloff
% span = 6;       % Filter span
% sps = 4;        % Samples per symbol
M = 4;          % Size of the signal constellation
k = log2(M);    % Number of bits per symbol

% Generate the coefficients of the square-root, raised cosine filter using the rcosdesign function.
rrcFilter = rcosdesign(rolloff, span, sps);

% Generate 10,000 data symbols using the randi function.
data = randi([0 M-1], 10000, 1);

% Apply PSK modulation to the data symbols. Because the constellation size is 4, the modulation type is QPSK.
modData = pskmod(data, M, pi/4);

fs = 1e3;
plot_signal(modData, fs, 'before tx filter');

fs = symbol_rate * k;
% for bw, see "https://en.wikipedia.org/wiki/Raised-cosine_filter"
bw = symbol_rate * (1 + rolloff);
fprintf('symbol rate = %g hz, bandwidth = %g hz\n', symbol_rate, bw);

% Using the upfirdn function, upsample and filter the input data.
txSig = upfirdn(modData, rrcFilter, sps);

title_text = sprintf('rolloff %g, span %d, sps %d, fsym %g, bw %g', ...
    rolloff, span, sps, symbol_rate, bw);
plot_signal(txSig, fs * sps, title_text);

% Convert the Eb/N0 to SNR and then pass the signal through an AWGN channel.
EbNo = 7;
snr = EbNo + 10*log10(k) - 10*log10(sps);
rxSig = txSig + awgn(txSig, snr, 'measured');

% Filter and downsample the received signal. Remove a portion of the signal to compensate for the filter delay.
rxFilt = upfirdn(rxSig, rrcFilter, 1, sps);
rxFilt = rxFilt(span+1:end-span);

plot_signal(rxFilt, fs, 'after rx filter');

% Create a scatter plot of the modulated data using the first 5,000 symbols.
h = scatterplot(sqrt(sps)*rxSig(1:sps*5000),sps,0,'g.');
hold on;
scatterplot(rxFilt(1:5000),1,0,'kx',h);
title('Received Signal, Before and After Filtering');
legend('Before Filtering','After Filtering');
axis([-3 3 -3 3]); % Set axis ranges
hold off;

end


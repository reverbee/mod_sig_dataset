function [] = learn_pll_wiki()
% ############ cant understand and give meaningless plot (190303)
%
% https://en.wikipedia.org/wiki/Phase-locked_loop
% This example is written in MATLAB

% In this example, an array "tracksig" is assumed to contain a reference signal to be tracked. 
% The oscillator is implemented by a counter,
% with the most significant bit of the counter indicating the on/off status of the oscillator. 
% This code simulates the two D-type flip-flops that comprise a phase-frequency comparator. 
% When either the reference or signal has a positive edge, the corresponding flip-flop switches high. 
% Once both reference and signal is high, both flip-flops are reset. 
% Which flip-flop is high determines at that instant whether the reference or signal leads the other. 
% The error signal is the difference between these two flip-flop values. 
% The pole-zero filter is implemented by adding the error signal and its derivative to the filtered error signal. 
% This in turn is integrated to find the oscillator frequency.

NF = 2^18;
numiterations = NF;

f0 = 1e6; % Frequency of reference signal [Hz]
phase_ref = 0; % Phase of reference signal [radians]
fs = 100e6; % Sampling frequency [Hz]

Ts = 1 / fs; % sampling period
t_vec = 0 : Ts : (NF - 1) * Ts; % time vector
tracksig = sin(2 * pi * f0 * t_vec + phase_ref); % reference signal array

% Initialize variables
vcofreq = zeros(1, numiterations);
ervec = zeros(1, numiterations);

% Keep track of last states of reference, signal, and error signal
qsig = 0; qref = 0; lref = 0; lsig = 0; lersig = 0;

phs = 0; freq = 0;

% Loop filter constants (proportional and derivative)
% Currently powers of two to facilitate multiplication by shifts
prop = 1/128;
deriv = 64;

for it = 1 : numiterations
    
    % Simulate a local oscillator using a 16-bit counter
    phs = mod(phs + floor(freq / 2^16), 2^16);
    ref = phs < 32768;
    % Get the next digital value (0 or 1) of the signal to track
    sig = tracksig(it);
    % Implement the phase-frequency detector
    rst = ~(qsig & qref);  % Reset the "flip-flop" of the phase-frequency
                    % detector when both signal and reference are high
    qsig = (qsig | (sig & ~lsig)) & rst;   % Trigger signal flip-flop and leading edge of signal
    qref = (qref | (ref & ~lref)) & rst;   % Trigger reference flip-flop on leading edge of reference
    lref = ref; lsig = sig; % Store these values for next iteration (for edge detection)
    ersig = qref - qsig;    % Compute the error signal (whether frequency should increase or decrease)
                            % Error signal is given by one or the other flip flop signal
    % Implement a pole-zero filter by proportional and derivative input to frequency
    filtered_ersig = ersig + (ersig - lersig) * deriv; 
    % Keep error signal for proportional output
    lersig = ersig;
    % Integrate VCO frequency using the error signal
    freq = freq - 2^16 * filtered_ersig * prop;
    % Frequency is tracked as a fixed-point binary fraction
    % Store the current VCO frequency
    vcofreq(1, it) = freq / 2^16;
    % Store the error signal to show whether signal or reference is higher frequency
    ervec(1, it) = ersig;
    
end
size(vcofreq)
vcofreq;

figure;
plot(t_vec, tracksig);
% plot(t_vec, tracksig, t_vec, vcofreq);
title('Plot of input and output signals', 'FontSize', 12);
xlabel('time [s]','FontSize', 12);
% legend('Input', 'Output');



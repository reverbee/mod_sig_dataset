function [] = learn_pll_scher_type_2()
% This program performs a sampled time domain simulation of an analog phase locked loop (Type 2)
%
% Written by Aaron Scher
% http://www.aaronscher.com/phase_locked_loop/matlab_pll.html
%
% The reference signal is a simple sinusoid. 
% The output should be a sinusoid that tracks the frequency of the reference signal 
% after a certain amount of start up time.

% User inputs:
f0 = 1e6; % Frequency of reference signal [Hz]
phase_ref = 0; % Phase of reference signal [radians]
fVCO = 1.1e6; % free running oscilating frequency of VCO [Hz]
KVCO = .5e6; % Gain of VCO (i.e. voltage to frequency transfer coefficient) [Hz/V]
G1 = 0.4467; % Proportional gain term of PI controller
G2 = 1.7783e+05; % Integral gain term of PI controller
fs = 100e6; % Sampling frequency [Hz]
NF = 2000; % Number of samples in simulation
fc = .2e6; % Cut-off frequency of low-pass filter (after the mixer) [Hz]
filter_coefficient_num = 100; % Number of filter coefficeints of low-pass filter

b = fir1(filter_coefficient_num, fc / (fs / 2)); % design FIR filter coefficients
Ts = 1 / fs; % sampling period
t_vec = 0 : Ts : (NF - 1) * Ts; % time vector
phi = zeros(1, NF); % initialize VCO angle (phi) array
error = zeros(1, NF); % initialize error array
Int_error = zeros(1,NF); % initialize error array
reference = sin(2 * pi * f0 * t_vec + phase_ref); % reference signal array
VCO = zeros(1, NF); % initialize VCO signal array

for n = 2 : NF
    t = (n - 2) * Ts; % Current time (start at t = 0 seconds)
   
    error_mult(n) = reference(n) * VCO(n - 1); % multiply VCO x Signal input to get raw error signal 

    % #### Low pass filter the raw error signal:
    for m = 1 : length(b)
        if n - m + 1 >= 1
            error_array(m) = error_mult(n - m + 1);
        else 
            error_array(m) = 0;
        end
    end
    error(n) = sum(error_array .* b);
    % #### end of filter
    
    % Process filtered error signal through PI controller:
    Int_error(n) = Int_error(n - 1) + G2 * error(n) * Ts;
    PI_error(n) = G1 * error(n) + Int_error(n);
    
    % update the phase of the VCO
    phi(n) = phi(n - 1) + 2 * pi * PI_error(n) * KVCO * Ts;
    % compute VCO signal
    VCO(n) = sin(2 * pi * fVCO * t + phi(n));
  
end

% Plot VCO and reference signals:
figure;
plot(t_vec,reference,t_vec,VCO);
title('Plot of input and output signals','FontSize',12);
xlabel('time [s]','FontSize',12);
legend('Input','Output');

% Plot error signal:
figure;
plot(t_vec,error);
title('Error signal','FontSize',12);
xlabel('time [s]','FontSize',12);

end

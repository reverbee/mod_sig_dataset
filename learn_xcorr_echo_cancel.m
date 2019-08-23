function [] = learn_xcorr_echo_cancel
% matlab xcorr example to echo cancellation
% using IIR filter

% load speech data and sample rate
load mtlb

% Model the echo by adding to the recording a copy of the signal 
% delayed by delta samples and attenuated by a known factor alpha: y(n) = x(n) + alpha * x(n - delta)
% Specify a time lag of 0.23 sec and an attenuation factor of 0.5.
timelag = 0.23;
delta = round(Fs*timelag);
alpha = 0.5;

orig = [mtlb; zeros(delta,1)];
echo = [zeros(delta,1); mtlb] * alpha;

mtEcho = orig + echo;

% Plot the original, the echo, and the resulting signal.
t = (0:length(mtEcho)-1)/Fs;

subplot(2,1,1);
plot(t,[orig echo]);
legend('Original','Echo');

subplot(2,1,2);
plot(t,mtEcho);
legend('Total');
xlabel('Time (s)');

% Compute an unbiased estimate of the signal autocorrelation. 
% Select and plot the section that corresponds to lags greater than zero.
[Rmm,lags] = xcorr(mtEcho,'unbiased');

Rmm = Rmm(lags>0);
lags = lags(lags>0);

figure;
plot(lags/Fs,Rmm);
xlabel('Lag (s)');

% The autocorrelation has a sharp peak at the lag at which the echo arrives. 
[~, dl] = findpeaks(Rmm,lags,'MinPeakHeight',0.22);

% ########################################
% y = filter(b,a,x)
% 
% (difference equation)
% a(1)*y(n) = b(1)*x(n) + b(2)*x(n-1) + ... + b(nb+1)*x(n-nb) - a(2)*y(n-1) - ... - a(na+1)*y(n-na)
% #######################################################################################

% Cancel the echo by filtering the signal 
% through an IIR system whose output, w, obeys w(n) + alpha * w(n - delta) = y(n)
% 
% a(1)*w(n) + a(2)*w(n-1) - ... - a(na+1)*w(n-na) = b(1)*y(n)
% a(1) = 1, a(2) = 0, ... a(na) = 0, a(na+1) = alpha, b(1) = 1
mtNew = filter(1, [1, zeros(1, dl - 1), alpha], mtEcho);

% Plot the filtered signal and compare to the original.
figure;
subplot(2,1,1);
plot(t,orig);
legend('Original');

subplot(2,1,2);
plot(t,mtNew);
legend('Filtered');
xlabel('Time (s)');


end

function [] = learn_simple_pll_channa
% https://www.researchgate.net/publication/316667182_Simple_PLL_including_the_MATLAB_code_for_PLL_and_its_theory
% Operating Principle Of Phase Locked Loop:
% 
% Phase Locked Loop is a circuit which generates a frequency 
% which finally detects the difference between the input frequency and the output frequency.
% According to which it corrects the output frequency 
% so as to synchronize or lock the input frequency of Phase Locked Loop. 
% So, in other words, we can also say that a Phase Locked Loop generates a signal 
% which has phase and its relation is the same as reference signal i.e. input frequency.
%
% Block Diagram Of Phase Locked Loop:
%
% Here, there are three blocks of Phase Locked Loop:
%
% (1) Phase Detector
% (2) Low Pass Filter
% (3) VCO (Voltage Controlled Oscilator)
% 
% They are described as below:
%
% (1) Phase Detector: 
% Phase Detector is a comparator 
% which compares the difference between the input frequency and the output frequency 
% and finally it gives a voltage (which is a DC voltage), 
% which is directly proportional to the difference between the input frequency and the output frequency. 
% And the Phase Detector is followed by a low pass filter. 
% Phase voltage or Error voltage is the input of low pass filter.
%
% (2) Low Pass Filter:
% To alternate the high frequency components of the error signals. 
% Means it alternates the high frequency component of this error voltage. 
% And finally the output of the low pass filter is applied to VCO, after amplifying.
%
% (3)VCO: 
% Voltage Controlled Oscilator generates the frequency. 
% It controls the output frequency in such a manner 
% that the output frequency becomes equal to the input frequency. 
% Or we can say that the difference between the input frequency and the output frequency 
% is reduced to a minimum level.
% And finally the output of VCO is sent back to the phase detector. 
% Then two frequencies of the phase detector become equal. 
% And in this way the output frequency becomes equal to the input frequency. 
% Or we can say that output frequency becomes locked with the input frequency.
% 
% So this is all about the working of PLL.
% 
% Here, in last we can say that, when the AC signal is not applied, or when there is no input signal 
% then the phase detector output is zero. 
% At this time, VCO works at its free runing frequency or we can say that VCO works at its centre frequency. 
% Here a free runing frequency is also called as centre frequency. 
% And when an input signal is applied then the phase error is applied. 
% And in such a way when the phase error is applied 
% then the VCO works in such a way so that its output frequency becomes equal to input frequency.
% 
% This is the basic principle of PLL. 
%
% A Source Code For Simple Phase Locked Loop System in MATLAB:

reg1=0;reg2=0;reg3=0;
eta=sqrt(2)/2;
theta=2*pi*1/100;
kp=[(4*eta*theta)/(1+2*eta*theta+theta^2)];
ki=[(4*theta^2)/(1+2*eta*theta+theta^2)];
d_phi_1=1/20;
n_data=100;
for nn=1:n_data    
    phi1=reg1+d_phi_1;    
    phi1_reg(nn)=phi1;   
    s1=exp(j*2*pi*reg1);    
    s2=exp(j*2*pi*reg2);    
    s1_reg(nn)=s1;    
    s2_reg(nn)=s2;    
    t=s1*conj(s2);    
    phi_error=atan(imag(t)/real(t))/(2*pi);    
    phi_error_reg(nn)=phi_error;    
    sum1=kp*phi_error+phi_error*ki+reg3;    
    reg1_reg(nn)=reg1;    
    reg2_reg(nn)=reg2;    
    reg1=phi1;    
    reg2=reg2+sum1;    
    reg3=reg3+phi_error*ki;    
    phi2_reg(nn)=reg2;
end

figure(1);
plot(phi1_reg);
hold on;
plot(phi2_reg,'r');
hold off;
grid on;
title('Phase Plot');
xlabel('Samples');
ylabel('Phase');

figure(2);
plot(phi_error_reg);
title('Phase Error Of Phase Detector');
grid on;
xlabel('Samples(n)');
ylabel('Phase Error(Degrees)');

figure(3);
plot(real(s1_reg));
hold on;
plot(real(s2_reg),'r');
hold off;
grid on;
title('Input Signal And Output Signal Of VCO');
xlabel('Samples');
ylabel('Amplitude');
axis([0 n_data -1.1 1.1]);

end

% This code of MATLAB generates the output of Phase Locked Loop 
% which remains in transient state some time 
% and then it slowly goes and finally remains in a steady state.
% Thus the output frequency becomes locked with the input frequency.
% The three plots of this Phase locked loop system are also generated which are attached with it.


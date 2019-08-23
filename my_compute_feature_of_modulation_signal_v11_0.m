
function [feature]=my_compute_feature_of_modulation_signal_v11_0(iqn,amplitude_threshold,feature_name_cell,fs)

[instance_length,~]=size(iqn);
feature_length=length(feature_name_cell);
feature=zeros(instance_length,feature_length);

for n=1:instance_length
    iq=iqn(n,:);
    feature(n,1)=feature_gamma_max(iq);
    feature(n,2)=feature_sigma_ap(iq,amplitude_threshold);
    feature(n,3)=feature_sigma_dp(iq,amplitude_threshold);
    feature(n,4)=feature_P(iq,fs);
    feature(n,5)=feature_sigma_aa(iq);
    feature(n,6)=feature_sigma_af(iq,amplitude_threshold,fs);
    feature(n,7)=feature_sigma_a(iq,amplitude_threshold);
    feature(n,8)=feature_mu_a42(iq);
    feature(n,9)=feature_mu_f42(iq,fs);    
    feature(n,10)=feature_beta(iq);
    feature(n,11)=feature_v20(iq);
    feature(n,12)=feature_K(iq);
    feature(n,13)=feature_S(iq);
    feature(n,14)=feature_PA(iq);
    feature(n,15)=feature_PR(iq);
    feature(n,16)=feature_sigma_v(iq);    
    feature(n,17)=feature_m_a(iq);
    feature(n,18)=feature_sigma_f(iq,fs);
    feature(n,19)=feature_sigma_inst_a(iq);
    feature(n,20)=feature_gamma_maxf(iq,fs);
    feature(n,21)=feature_gamma_maxa(iq);
    feature(n,22)=feature_mu_aa(iq);
    feature(n,23)=feature_v_phs(iq);       
    feature(n,24)=feature_C20(iq);
    feature(n,25)=feature_C21(iq);
    feature(n,26)=feature_C40(iq);
    feature(n,27)=feature_C41(iq);
    feature(n,28)=feature_C42(iq);
    feature(n,29)=feature_C60(iq);
    feature(n,30)=feature_C61(iq);
    feature(n,31)=feature_C62(iq);
    feature(n,32)=feature_C63(iq);    
    feature(n,33)=feature_C80(iq);
    feature(n,34)=feature_C81(iq);
    feature(n,35)=feature_C82(iq);
    feature(n,36)=feature_C83(iq);
    feature(n,37)=feature_C84(iq);    
    feature(n,38)=feature_C100(iq);
    feature(n,39)=feature_C101(iq);
    feature(n,40)=feature_C102(iq); 

end

end%end of main function

%% 
function [gamma_max]=feature_gamma_max(iq)

sample_length=length(iq);
amp_iq=abs(iq);
mu_iq=mean(amp_iq);
n_amp_iq=(amp_iq/mu_iq);
cn_amp_iq=n_amp_iq-1;

gamma_max=max(abs(fft(cn_amp_iq)).^2)/sample_length;

end

%% 
function [sigma_ap] = feature_sigma_ap(iq,amplitude_threshold)

amp_iq=abs(iq);
mu_iq=mean(amp_iq);
n_amp_iq=(amp_iq/mu_iq);
valid_idx=n_amp_iq>amplitude_threshold;
iq=iq(valid_idx);

phase_iq=angle(iq)-mean(angle(iq));

sigma_ap=std(abs(phase_iq));

end

%% 
function [sigma_dp] = feature_sigma_dp(iq,amplitude_threshold)

amp_iq=abs(iq);
mu_iq=mean(amp_iq);
n_amp_iq=(amp_iq/mu_iq);
valid_idx=n_amp_iq>amplitude_threshold;
iq=iq(valid_idx);

phase_iq=angle(iq)-mean(angle(iq));

sigma_dp=std(phase_iq);

end

%% 
function [P]=feature_P(iq,fs)

sample_length=length(iq);
half_length=fix(sample_length/2);

x_c=iq;
p=abs( fftshift(fft(x_c)).*fs ).^2;
p_lower=sum(p(1:half_length));
p_upper=sum(p(half_length+1:end));

P=(p_lower-p_upper)/(p_lower+p_upper);

end

%% 
function [sigma_aa] = feature_sigma_aa(iq)

amp_iq=abs(iq);
mu_iq=mean(amp_iq);
n_amp_iq=(amp_iq/mu_iq);
cn_amp_iq=n_amp_iq-1;

sigma_aa=std(abs(cn_amp_iq));

end

%% 
function [sigma_af] = feature_sigma_af(iq,amplitude_threshold,fs)

amp_iq=abs(iq);
mu_iq=mean(amp_iq);
n_amp_iq=(amp_iq/mu_iq);
valid_idx=n_amp_iq>amplitude_threshold;
iq=iq(valid_idx);

phase_iq=angle(iq)-mean(angle(iq));
freq_iq=1/(2*pi)*diff(phase_iq)*fs;
freq_iq=freq_iq-mean(freq_iq);
freq_iq=freq_iq/fs;

sigma_af=std(abs(freq_iq));

end

%% 
function [sigma_a] = feature_sigma_a(iq, amplitude_threshold)

amp_iq=abs(iq);
mu_iq=mean(amp_iq);
n_amp_iq=(amp_iq/mu_iq);
valid_idx=n_amp_iq>amplitude_threshold;
iq=iq(valid_idx);

amp_iq=abs(iq);
mu_iq=mean(amp_iq);
n_amp_iq=(amp_iq/mu_iq);
cn_amp_iq=n_amp_iq-1;

sigma_a=std(cn_amp_iq);

end

%% 
function [mu_a42] = feature_mu_a42(iq)

amp_iq=abs(iq);
mu_iq=mean(amp_iq);
n_amp_iq=(amp_iq/mu_iq);
cn_amp_iq=n_amp_iq-1;

mu_a42=mean(cn_amp_iq.^4)/(mean(cn_amp_iq.^2)^2);

end

%% 
function [mu_f42] = feature_mu_f42(iq,fs)

phase_iq=angle(iq)-mean(angle(iq));
freq_iq=1/(2*pi)*diff(phase_iq)*fs;
freq_iq=freq_iq-mean(freq_iq);
freq_iq=freq_iq/fs;

mu_f42=mean(freq_iq.^4)/(mean(freq_iq.^2)^2);

end

%% 
function [beta]=feature_beta(iq)

sum_of_imag=sum(imag(iq).^2);
sum_of_real=sum(real(iq).^2);

beta=sum_of_imag/sum_of_real;

end

%% 
function [v20] = feature_v20(iq)

sample_length = length(iq);

M22=sum(iq.^0.*(iq(:)').^2)/sample_length;
M11=sum(iq.^0.*(iq(:)').^1)/sample_length;

v20=M22/M11;
v20=abs(v20);

end

%% 
function [K] = feature_K(iq)

amp_iq=abs(iq);
mu_iq=mean(amp_iq);

K=mean((amp_iq-mu_iq).^4)/(mean((amp_iq-mu_iq).^2)^2);
K=abs(K);

end

%% 
function [S] = feature_S(iq)

amp_iq=abs(iq);
mu_iq=mean(amp_iq);

S=mean((amp_iq-mu_iq).^3)/(mean((amp_iq-mu_iq).^2)^(3/2));
S=abs(S);

end

%% 
function [PA] = feature_PA(iq)

amp_iq=abs(iq);
mu_iq=mean(amp_iq);
max_iq=max(amp_iq);

PA=max_iq/mu_iq;

end

%% 
function [PR] = feature_PR(iq)

amp_iq=abs(iq);
mu_iq=mean(amp_iq.^2);
max_iq=max(amp_iq.^2);

PR=max_iq/mu_iq;

end

%% 
function [sigma_v] = feature_sigma_v(iq)

amp_iq=abs(iq);
mu_iq=mean(amp_iq);
sum_r=mean((iq-mu_iq).^2);
r_v=((iq/sum_r).^(1/2))-1;

sigma_v=std(abs(r_v));

end

%% 
function [m_a] = feature_m_a(iq)

amp_iq=abs(iq);
mu_iq=mean(amp_iq);

m_a=mu_iq;

end

%% 
function [sigma_f] = feature_sigma_f(iq,fs)

phase_iq=angle(iq)-mean(angle(iq));
freq_iq=1/(2*pi)*diff(phase_iq)*fs;

sigma_f=std(freq_iq);

end

%% 
function [sigma_inst_a] = feature_sigma_inst_a(iq)

amp_iq=abs(iq);

sigma_inst_a=std(amp_iq);

end

%% 
function [gamma_maxf] = feature_gamma_maxf(iq,fs)

phase_iq=angle(iq)-mean(angle(iq));
freq_iq=1/(2*pi)*diff(phase_iq)*fs;
freq_iq=freq_iq-mean(freq_iq);

gamma_maxf=max(abs(fft(freq_iq)));

end

%% 
function [gamma_maxa]=feature_gamma_maxa(iq)

amp_iq=abs(iq);
c_amp_iq=amp_iq-1;

gamma_maxa=max(abs(fft(c_amp_iq)));

end

%% 
function [mu_aa]=feature_mu_aa(iq)

amp_iq=abs(iq);
mu_iq=mean(amp_iq);
c_amp_iq=(amp_iq-mu_iq)/mu_iq;

mu_aa=mean((c_amp_iq).^2);

end

%% 
function [v_phs] = feature_v_phs(iq)

phase_iq=angle(iq)-mean(angle(iq));
valid_idx=phase_iq<(3*pi/2);
iq=iq(valid_idx);

phase_iq=angle(iq)-mean(angle(iq));

v_phs=std((phase_iq).^2)^2;

end

%% 
function [C20] = feature_C20(iq)

sample_length=length(iq);
iq=iq-mean(iq);

M20=sum(iq.^2.*(iq(:)').^0)/sample_length;

C20=abs(M20);

end

%% 
function [C21]=feature_C21(iq)

sample_length=length(iq);
iq=iq-mean(iq);

M21=sum(iq.^1.*(iq(:)').^1)/sample_length;

C21=abs(M21);

end

%% 
function [C40] = feature_C40(iq)

sample_length=length(iq);
iq=iq-mean(iq);

M40=sum(iq.^4.*(iq(:)').^0)/sample_length;
M20=sum(iq.^2.*(iq(:)').^0)/sample_length;

C40 =M40-3*M20^2;
C40 = abs(C40);

end

%% 
function [C41] = feature_C41(iq)

sample_length=length(iq);
iq=iq-mean(iq);

M41=sum(iq.^3.*(iq(:)').^1)/sample_length;
M20=sum(iq.^2.*(iq(:)').^0)/sample_length;
M21=sum(iq.^1.*(iq(:)').^1)/sample_length;

C41=M41-3*M20*M21;
C41=abs(C41);

end

%% 
function [C42] = feature_C42(iq)

sample_length=length(iq);
iq=iq-mean(iq);

M42=sum(iq.^2.*(iq(:)').^2)/sample_length;
M20=sum(iq.^2.*(iq(:)').^0)/sample_length;
M21=sum(iq.^1.*(iq(:)').^1)/sample_length;

C42=M42-abs(M20)^2-2*(M21^2);
C42=abs(C42);

end

%% 
function [C60] = feature_C60(iq)

sample_length=length(iq);
iq=iq-mean(iq);

M20=sum(iq.^2.*(iq(:)').^0)/sample_length;
M40=sum(iq.^4.*(iq(:)').^0)/sample_length;
M60=sum(iq.^6.*(iq(:)').^0)/sample_length;

C60=M60-15*M20*M40+30*M20^3;
C60=abs(C60);

end

%% 
function [C61] = feature_C61(iq)

sample_length=length(iq);
iq=iq-mean(iq);

M61=sum(iq.^5.*(iq(:)').^1)/sample_length;
M21=sum(iq.^1.*(iq(:)').^1)/sample_length;
M40=sum(iq.^4.*(iq(:)').^0)/sample_length;
M20=sum(iq.^2.*(iq(:)').^0)/sample_length;
M41=sum(iq.^3.*(iq(:)').^1)/sample_length;

C61=M61-5*M21*M40-10*M20*M41+30*M20^2*M21;
C61=abs(C61);

end

%% 
function [C62] = feature_C62(iq)

sample_length=length(iq);
iq=iq-mean(iq);

M62 = sum(iq.^4.*(iq(:)').^2)/sample_length;
M40 = sum(iq.^4.*(iq(:)').^0)/sample_length;
M20 = sum(iq.^2.*(iq(:)').^0)/sample_length;
M42 = sum(iq.^2.*(iq(:)').^2)/sample_length;
M21 = sum(iq.^1.*(iq(:)').^1)/sample_length;
M41 = sum(iq.^3.*(iq(:)').^1)/sample_length;
M22 = sum(iq.^2.*(iq(:)').^2)/sample_length;

C62=M62-6*M20*M42-8*M21*M41-M22*M40+6*M20^2*M22+24*M21^2*M20;
C62=abs(C62);

end

%% 
function [C63] = feature_C63(iq)

sample_length=length(iq);
iq=iq-mean(iq);
M63=sum(iq.^3.*(iq(:)').^3)/sample_length;
M20=sum(iq.^2.*(iq(:)').^0)/sample_length;
M42=sum(iq.^2.*(iq(:)').^2)/sample_length;
M21=sum(iq.^1.*(iq(:)').^1)/sample_length;
M41=sum(iq.^3.*(iq(:)').^1)/sample_length;
M22=sum(iq.^2.*(iq(:)').^2)/sample_length;
M43=sum(iq.^1.*(iq(:)').^3)/sample_length;

C63=M63-9*M21*M42+12*M21^3-3*M20*M43-3*M22*M41+18*M20*M21*M22;
C63=abs(C63);

end

%% 
function [C80] = feature_C80(iq)

sample_length=length(iq);
iq=iq-mean(iq);

M80=sum(iq.^8.*(iq(:)').^0)/sample_length;
M40=sum(iq.^4.*(iq(:)').^0)/sample_length;
M60=sum(iq.^4.*(iq(:)').^0)/sample_length;
M20=sum(iq.^2.*(iq(:)').^0)/sample_length;

C80=M80-35*M40^2-28*M60*M20+420*M40*M20^2-630*M20^4;
C80=abs(C80);

end

%% 
function [C81] = feature_C81(iq)

sample_length=length(iq);
iq=iq-mean(iq);

M81=sum(iq.^7.*(iq(:)').^1)/sample_length;
M20=sum(iq.^2.*(iq(:)').^0)/sample_length;
M61=sum(iq.^5.*(iq(:)').^1)/sample_length;
M21=sum(iq.^1.*(iq(:)').^1)/sample_length;
M60=sum(iq.^6.*(iq(:)').^0)/sample_length;
M40=sum(iq.^4.*(iq(:)').^0)/sample_length;
M41=sum(iq.^3.*(iq(:)').^1)/sample_length;

C81=M81-21*M20*M61-7*M21*M60-35*M40*M41+210*M21*M20*M40+210*M20^2*M41-630*M21*M20^3;
C81=abs(C81);

end

%% 
function [C82] = feature_C82(iq)

sample_length=length(iq);
iq=iq-mean(iq);

M82=sum(iq.^6.*(iq(:)').^2)/sample_length;
M20=sum(iq.^2.*(iq(:)').^0)/sample_length;
M62=sum(iq.^4.*(iq(:)').^2)/sample_length;
M21=sum(iq.^1.*(iq(:)').^1)/sample_length;
M61=sum(iq.^5.*(iq(:)').^1)/sample_length;
M22=sum(iq.^0.*(iq(:)').^2)/sample_length;
M60=sum(iq.^6.*(iq(:)').^0)/sample_length;
M40=sum(iq.^4.*(iq(:)').^0)/sample_length;
M42=sum(iq.^2.*(iq(:)').^2)/sample_length;
M41=sum(iq.^3.*(iq(:)').^1)/sample_length;

C82=M82-15*M20*M62-12*M21*M61-M22*M60-15*M40*M42-20*M41^2+90*M20^2*M42+240*M20*M21*M41+30*M20*M22*M40+60*M21^2-540*M21^2*M20^2-90*M22*M20^3;
C82=abs(C82);

end

%% 
function [C83] = feature_C83(iq)

sample_length=length(iq);
iq=iq-mean(iq);

M83=sum(iq.^5.*(iq(:)').^3)/sample_length;
M20=sum(iq.^2.*(iq(:)').^0)/sample_length;
M63=sum(iq.^3.*(iq(:)').^3)/sample_length;
M21=sum(iq.^1.*(iq(:)').^1)/sample_length;
M62=sum(iq.^4.*(iq(:)').^2)/sample_length;
M22=sum(iq.^2.*(iq(:)').^2)/sample_length;
M61=sum(iq.^5.*(iq(:)').^1)/sample_length;
M40=sum(iq.^4.*(iq(:)').^0)/sample_length;
M43=sum(iq.^1.*(iq(:)').^3)/sample_length;
M41=sum(iq.^3.*(iq(:)').^1)/sample_length;
M42=sum(iq.^2.*(iq(:)').^2)/sample_length;

C83=M83-10*M20*M63-15*M21*M62-3*M22*M61-5*M40*M43-30*M41*M42+30*M40*M22*M21+60*M41*M22*M20+120*M41*M21^2++180*M41*M21*M20+30*M43*M20^2-360*M21^3-270*M22*M21*M20^2;
C83=abs(C83);

end

%% 
function [C84] = feature_C84(iq)

sample_length=length(iq);
iq=iq-mean(iq);

M84=sum(iq.^4.*(iq(:)').^4)/sample_length;
M20=sum(iq.^2.*(iq(:)').^0)/sample_length;
M64=sum(iq.^2.*(iq(:)').^4)/sample_length;
M21=sum(iq.^1.*(iq(:)').^1)/sample_length;
M63=sum(iq.^3.*(iq(:)').^3)/sample_length;
M22=sum(iq.^2.*(iq(:)').^2)/sample_length;
M62=sum(iq.^4.*(iq(:)').^2)/sample_length;
M40=sum(iq.^4.*(iq(:)').^0)/sample_length;
M44=sum(iq.^0.*(iq(:)').^4)/sample_length;
M41=sum(iq.^3.*(iq(:)').^1)/sample_length;
M43=sum(iq.^1.*(iq(:)').^3)/sample_length;
M42=sum(iq.^2.*(iq(:)').^2)/sample_length;

C84=M84-6*M20*M64-16*M21*M63-6*M22*M62-M40*M44-16*M41*M43-18*M42^2+6*M44*M20^2+96*M43*M21*M20+144*M42*M21^2+72*M42*M22*M20+96*M41*M22*M21+6*M40*M22^2-432*M22*M21^2*M20-54*M22^2*M20^2-144*M21^4;
C84=abs(C84);

end

%% 
function [C100] = feature_C100(iq)

sample_length=length(iq);
iq=iq-mean(iq);

M100=sum(iq.^10.*(iq(:)').^0)/sample_length;
M20  =sum(iq.^2.*(iq(:)').^0)/sample_length;
M80  =sum(iq.^8.*(iq(:)').^0)/sample_length;
M40  =sum(iq.^4.*(iq(:)').^0)/sample_length;
M60  =sum(iq.^6.*(iq(:)').^0)/sample_length;

C100=M100-45*M20*M80-210*M40*M60+1260*M20^2*M60+3150*M20*M40^2+22680*M20^5;
C100=abs(C100);

end

%% 
function [C101] = feature_C101(iq)

sample_length=length(iq);
iq=iq-mean(iq);

M101=sum(iq.^9.*(iq(:)').^1)/sample_length;
M20 =sum(iq.^2.*(iq(:)').^0)/sample_length;
M81 =sum(iq.^7.*(iq(:)').^1)/sample_length;
M21 =sum(iq.^1.*(iq(:)').^1)/sample_length;
M80 =sum(iq.^8.*(iq(:)').^0)/sample_length;
M40 =sum(iq.^4.*(iq(:)').^0)/sample_length;
M61 =sum(iq.^5.*(iq(:)').^1)/sample_length;
M41 =sum(iq.^3.*(iq(:)').^1)/sample_length;
M60 =sum(iq.^6.*(iq(:)').^0)/sample_length;

C101=M101-9*M20*M81-36*M21*M80-126*M40*M61-84*M41*M60+504*M60*M20*M21+756*M61*M20^2+2520*M41*M40*M20+630*M40^2*M21+22680*M20^4*M21;
C101=abs(C101);

end

%% 
function [C102] = feature_C102(iq)

sample_length=length(iq);
iq=iq-mean(iq);

M102=sum(iq.^8.*(iq(:)').^2)/sample_length;
M20 =sum(iq.^2.*(iq(:)').^0)/sample_length;
M82 =sum(iq.^6.*(iq(:)').^2)/sample_length;
M21 =sum(iq.^1.*(iq(:)').^1)/sample_length;
M41 =sum(iq.^3.*(iq(:)').^1)/sample_length;
M62 =sum(iq.^4.*(iq(:)').^2)/sample_length;
M40 =sum(iq.^4.*(iq(:)').^0)/sample_length;
M81 =sum(iq.^7.*(iq(:)').^1)/sample_length;
M22 =sum(iq.^0.*(iq(:)').^2)/sample_length;
M80 =sum(iq.^8.*(iq(:)').^0)/sample_length;
M60 =sum(iq.^6.*(iq(:)').^0)/sample_length;
M61 =sum(iq.^5.*(iq(:)').^1)/sample_length;
M42 =sum(iq.^2.*(iq(:)').^2)/sample_length;

C102=M102-28*M20*M82-16*M21*M81-M22*M80-28*M60*M42-112*M61*M41-70*M62*M40+56*M60*M20*M22+112*M60*M21^2+672*M61*M21*M20+420*M62*M20^2+70*M40^2*M22+1120*M40*M41*M21+1120*M41^2*M20+840*M42*M40*M20+2520*M22*M20^4+20160*M21^2*M20^3;
C102=abs(C102);

end
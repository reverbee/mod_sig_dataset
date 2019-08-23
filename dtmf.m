function [] = dtmf

[y, fs] = audioread('DTMF_trucking_push_to_talk_ID_example.ogg');
whos;

y = y(:, 1);

title_text = 'dtmf';
plot_signal(y, fs, title_text);

soundsc(y, fs);

figure;
plot(y);

% figure;
% plot(y(28030:30580));

f = [697 770 852 941 1209 1336 1477 1633];

z = y(28030:30580);
N = length(z);
freq_idx = round(f/fs*N) + 1;   
dft_data = abs(goertzel(z, freq_idx))

z = y(339500:342020);
N = length(z);
freq_idx = round(f/fs*N) + 1;   
dft_data = abs(goertzel(z, freq_idx))

z = y(1346790:1349350);
N = length(z);
freq_idx = round(f/fs*N) + 1;   
dft_data = abs(goertzel(z, freq_idx))

% figure;
% stem(f,abs(dft_data))
% 
% ax = gca;
% ax.XTick = f;
% xlabel('Frequency (Hz)')
% title('DFT Magnitude')


end
% This script demonstrates IQ data acquisition with FSx using LAN (LXI)

% Instrument connection via LAN (LXI),IP string as TCPIP::xxx.xxx.xxx.xxx
strInstr='TCPIP::172.25.77.14';
% Create NI-VISA object 
SA=visa('ni',strInstr);

% Measurement points
points = 65536;
% IO buffer size of analyzer
SA.InputBufferSize=points*8;

% Center frequency
CenterFreq = 1e9;
% Sample rate
Fs = 200e6;

% Open object(analyzer)
fopen(SA);

%% Configure instrument
fprintf(SA,strcat('FREQ:CENT',sprintf('% f',CenterFreq))); %set center freq.
fprintf(SA,'INST:CRE IQ,"IQANALYZER"'); % IQ analyzer mode
fprintf(SA,strcat('TRAC:IQ:SRAT',sprintf('% f',Fs))); % Set sample rate 
fprintf(SA,strcat('TRAC:IQ:RLEN',sprintf('% d',points))); % Set measurement points
fprintf(SA,'FORM:DATA ASCII');% Format ascii
fprintf(SA,'TRAC:IQ:BWID?'); % Read bandwidth
BW=str2double(fscanf(SA)); % BW - bandwidth
fprintf(SA,'TRAC:IQ:DATA:FORM IQBLock'); % Set IQ format
fprintf(SA,'FORM:DATA REAL,32'); % Format Real


%% Read I/Q data
fprintf(SA,'TRACE1:IQ:DATA?;*WAI');

header=fread(SA,2,'char');
digits=str2double(char(header(2)));    
LenOfData=str2double(char(fread(SA,digits,'int8'))); %#ok<FREAD>
% Now read I data
Idat=fread(SA, LenOfData/8,'float32');
% ... and Q data
Qdat=fread(SA, LenOfData/8,'float32');
fclose(SA);

IQdata=Idat+1i.*Qdat;

%% Data processing - spectrum
t = (0:1/Fs:(points-1)/Fs)';
xTable = timetable(seconds(t),IQdata);
L = 4096;
noverlap = floor(L*0.75);
[pxx,f] = pwelch(IQdata,flattopwin(L),noverlap,points,Fs,'centered','power');
NumOfSpec = length(pxx);
Freq = f+CenterFreq;
Spec = pxx;
dbm = pow2db(Spec/50)+30;
plot(Freq,dbm);
xlabel('Frequency (Hz)')
ylabel('Power Spectrum (dBm)')
title('Your Spectrum')


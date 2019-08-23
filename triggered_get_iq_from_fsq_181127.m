function [iq, sample_rate_mhz] = ...
    triggered_get_iq_from_fsq_181127(center_freq_mhz, signal_bw_mhz, sample_length, sample_per_symbol, directory, ...
    plot_signal, input_atten_db)
% triggered get iq from R&S FSQ26 signal analyzer
% #############################################################################################
% difference from "triggered_get_iq_from_fsq_181126.m":
% 
% rbw parameter in 'TRAC:IQ:SET' command force to set 10 MHz
% 
% #############################################################################################
%
% control interface: LAN
% must use FW 4.75 version operating manual (not FW 4.55)
% for STATus:OPERation Register, FW 4.75 is different from FW 4.55
% 
% [input]
% - center_freq_mhz: carrier frequency in mhz
% - signal_bw_mhz: signal bw in mhz, max bw = 30 mhz, min bw = 8 khz
% - sample_length: iq sample length, max sample length = 2^21 = 2097152
% - sample_per_symbol: sample per symbol. 
%   when 0, dont care (analog modulation)
%   when >= 1, sample_rate = signal_bw_mhz * sample_per_symbol
%   for digital modulation, set to 8 (see "inf_snr_generate_modulation_signal_single_mat.m")
% - directory: iq mat file save directory. if empty, dont save iq into mat file
% - plot_signal: boolean
% - input_atten_db: rf input attenuation in db. if empty, set to "auto".
%   attenuation step width is 5 db, so if this input is 7, input attenuation set in fsq will be 10 db
%
% [output]
% - iq:
% - sample_rate_mhz:
%
% [usage]
% (fm broadcasting)
% triggered_get_iq_from_fsq_181127(95.7, .192, 2^17, 0, 'e:\fsq_iq\data', 0, 0);
% triggered_get_iq_from_fsq_181127(95.7, .192, 2^21, 0, 'e:\fsq_iq\data', 0, '');
% 

% - if_bw_mhz: bandwidth of analog filters in front of the A/D converter
%   Value range: 300 kHz ~ 10 MHz in steps of 1, 2, 3, 5 and 20 MHz and 50 MHz for <filter type> = NORMal
%   ###### acceptable bandwith is restricted, so after getting iq sample, you need filtering
%   ###### [example] DMB BW 1.536 mhz, but next acceptable BW is 2 mhz
% - sample_rate_mhz: sample rate in mhz. if empty, set to (if_bw_mhz / 0.8)
%   in later version, drop from input: automatically set to (if_bw_mhz / 0.8)
%   see page 684 in "fsq operating manual"

% ESE is connected with ESR
% bit set: use "bi2de" command

% using_trigger = 0;
plot_filter_response = 1;

% 26 come from fsq26
fsq_ip_address = '172.16.110.26'; 
% lucky boy, serendipitious discovery
fsq_tcp_port = 5025;

max_signal_bw_mhz = 30;
min_signal_bw_mhz = .008; % min sample rate = 10 khz, min bw = 8 khz(= 10 khz * 0.8)
if signal_bw_mhz > max_signal_bw_mhz
    fprintf('##### error: max signal bw = %d mhz\n', max_signal_bw_mhz);
    return;
end

[if_bw_mhz, sample_rate_mhz, iq_bw_mhz] = get_receiver_if_bw_and_sample_rate(signal_bw_mhz, sample_per_symbol);
if_bw_mhz, sample_rate_mhz, iq_bw_mhz

% if ~isempty(signal_bw_mhz) && (if_bw_mhz < signal_bw_mhz)
%     fprintf('##### error: FSQ26 IF BW less than signal BW\n');
%     return;
% end

% if isempty(sample_rate_mhz)
%     sample_rate_mhz = if_bw_mhz / .8;
% end

% if any, delete opened instrument control
delete(instrfind);

% ### if system_max_sample_length = 16776704, matlab error message is displayed :
% ### ??? There is not enough memory to create the inputbuffer. Try specifying a smaller value.
% ### to cure this error, more computer memory is needed
system_max_sample_length = 16776704;
% system_max_sample_length = 16776704 / 4;

% ### if sample_length > user_max_sample_length, visa time-out error is displayed :
% ### VISA: Timeout expired before operation completed.
% ### to cure this error, set time-out
user_max_sample_length = 2^21; % 2^21 = 2097152
% user_max_sample_length = 16776704 / 4;
% user_max_sample_length = 16776704 / 32;
if sample_length > user_max_sample_length
    fprintf('###### error: max sample length = %d\n', user_max_sample_length);
    return;
end

% create tcp object
fsq_obj = tcpip(fsq_ip_address, fsq_tcp_port);

% close
% set 'input buffer size' properties
% set(fsq_obj, 'InputBufferSize', system_max_sample_length * 16);
set(fsq_obj, 'InputBufferSize', system_max_sample_length * 8);
% ### 8 above line : I sample = 4 byte, Q sample = 4 byte

% set 'timeout' to 60 sec for getting large iq sample with low sample rate
set(fsq_obj, 'Timeout', 60);

fopen(fsq_obj);

% when tcp, default is 'bigEndian', so must set to 'littleEndian'
% when gpib-enet/100, default was 'littleEndian', so need not touch
set(fsq_obj, 'ByteOrder', 'littleEndian');
% ByteOrder = littleEndian
% get(vsa_obj);

% Rohde&Schwarz,FSQ-26,200460/026,4.75 [firmware version = 4.75]
response = query(fsq_obj, '*IDN?');

% [installed option] B4 B16 B25 B72-120 B72 K70 K100
% #######################################################
% B4 = Improved aging OCXO, low aging/improved phase noise at 10 Hz carrier offset
% B16 = LAN interface 
% B25 = Electronic Attenuator, 0 to 30 dB, preamp 20 dB
% B72-120 = ??
% B72 = I/Q bandwidth extension
% K70 = Firmware General Purpose Vector Signal Analyzer
% K100 = Analysis of EUTRA/LTE FDD Downlink Signals
% #######################################################
response = query(fsq_obj, '*OPT?');

% reset and clear buffer
fprintf(fsq_obj, '*RST');
fprintf(fsq_obj, '*CLS');

% This command resets the edge detectors and ENABle parts of all registers to a defined value:
% All PTRansition parts are set to FFFFh, i.e. all transitions from 0 to 1 are detected. 
% All NTRansition parts are set to 0, i.e. a transition from 1 to 0 in a CONDition bit is not detected. 
% The ENABle part of the STATus:OPERation and STATus:QUEStionable registers are set to 0, 
% i.e. all events in these registers are not passed on.

% fprintf(fsq_obj, 'STAT:PRES');

% #############################################################################
% ### set up status reporting system in fsq26
% ### for status register overview, see page 425 in "operating manual"
% #############################################################################

% set ESE(event status enable) register to all bit enable
% bit meaning: (see page 427 in "operating manual")
% 0 = operation complete, 2 = query error, 3 = device dependent error, 4 = execution error, 
% 5 = command error, 6 = user request, 7 = power on 

% fprintf(fsq_obj, '*ESE 255');

% set STATus:OPERation Register to all bit enable
% bit meaning: (see page 428 in "operating manual")
% 0 = CALibrating, 3 = SWEeping, 4 = MEASuring, 
% 5 = Waiting for TRIGger, only supported for I/Q measurements (TRACe:IQ state is on),
% 8 = HardCOPy in progress, 10 = Sweep Break
% % set valid meaning bit to 1
% stat_oper_enable = [1 0 0 0 0 0 0 0 1 0 1];
% % D = bi2de(B);
% command = sprintf('STAT:OPER:ENAB %d', bi2de(stat_oper_enable));
% fprintf(fsq_obj, command);

% fprintf(fsq_obj, 'STAT:OPER:ENAB 65535');

% set STATus:QUEStionable Register to all bit enable
% bit meaning: (see page 429 in "operating manual")
% 3 = POWer, 5 = FREQuency, 8 = CALibration, 9 = LIMit (device-specific)
% 10 = LMARgin, 12 = ACPLimit

% fprintf(fsq_obj, 'STAT:QUES:ENAB 65535');

% set STATus:QUEStionable:FREQuency Register to all bit enable
% bit meaning: (see page 432 in "operating manual")
% 0 = OVEN COLD, 1 = LO UNLocked (Screen A), 9 = LO UNLocked (Screen B)

% fprintf(fsq_obj, 'STAT:QUES:FREQ:ENAB 65535');

% set STATus:QUEStionable:POWer Register to all bit enable
% bit meaning: (see page 434 in "operating manual")
% 0 = RF input OVERload (Screen A), 1 = RF input UNDerload (Screen A),
% 2 = IF_OVerload (Screen A), 3 = Overload Trace (Screen A),
% 8 = RF input OVERload (Screen A), 9 = RF input UNDerload (Screen A),
% 10 = IF_OVerload (Screen A), 11 = Overload Trace (Screen A),

% fprintf(fsq_obj, 'STAT:QUES:POW:ENAB 65535');

% % display on to see what is going on FSQ
% fprintf(vsa_obj, 'SYSTem:DISPlay:UPDate ON');

% % set preamp on
% fprintf(fsq_obj, 'INP:GAIN ON'); ######## this is needed? ##########

% set input attenuation
if isempty(input_atten_db)
    fprintf(fsq_obj, 'INP:ATT:AUTO ON');
else
    fprintf(fsq_obj, 'INP:ATT:AUTO OFF');
    
    command = sprintf('INP:ATT %ddB', input_atten_db);
    fprintf(fsq_obj, command);
end

% query input attenuation auto
response = query(fsq_obj, 'INP:ATT:AUTO?');
fprintf('input attenuation auto = %s\n', response(1:end-1));

% query input attenuation
response = query(fsq_obj, 'INP:ATT?');
fprintf('input attenuation = %s db\n', response(1:end-1));

% set tuning freq
command = sprintf('FREQ:CENT %gMHz', center_freq_mhz);
fprintf(fsq_obj, command);

% set span to 0 for time domain measurement
fprintf(fsq_obj, 'FREQ:SPAN 0MHZ');
% response = query(fsq_obj, 'FREQ:SPAN?')

% set trigger source to if power
fprintf(fsq_obj, 'TRIG:SOUR IFP');

fprintf(fsq_obj, 'TRIG:SYNC:ADJ');

% % set trigger to if power -70dbm (this is minimum)
% fprintf(fsq_obj, 'TRIG:LEV:IFP -70DBM');

% ######## advice from r&s online support engineer(zhang, laura) #########
% switch to single-sweep mode
fprintf(fsq_obj, 'INIT:CONT OFF');

response = query(fsq_obj, 'INIT:CONT?');
fprintf('continuous mode = %s\n', response(1:end-1));

% ######################################################################### 
% #### assumed that rbw, vbw is dont care parameter for IQ acquisition ####
% #########################################################################

% turn on IQ acquisition
fprintf(fsq_obj, 'TRAC:IQ:STAT ON');

% set IQ acquisition parameter :
% - analog resolution filter type : NORM (fixed)
% - bandwidth of analog filters in front of the A/D converter : 2 MHz for CDMA basestation
%   (this is same as rbw in spectrum analyzer)
%   Value range: 300 kHz ~ 10 MHz in steps of 1, 2, 3, 5 and 20 MHz and 50 MHz for <filter type> = NORMal
% - sample rate : A/D sample rate
%   Value range: 10 kHz to 81,6 MHz for <filter type> = NORMal
% - trigger mode : IMM (not fixed?) #### Values: IMMediate | EXTernal | IFPower
%   After selecting IFPower, the trigger threshold can be set with command TRIG:LEV:IFP
%   TRIGger<1|2>[:SEQuence]:LEVel:IFPower -70 to +30 dBm
%   This command sets the level of the IF power trigger source. *RST value: -20 dBm
% - trigger slope : POS (fixed)
% - pretrigger samples : 0 (fixed)
% - sample number : iq sample length

% pretrigger_sample_length = 0;
% pretrigger_sample_length = 2^10;
pretrigger_sample_length = -2^10;

% #######################################
% ##### rbw forced to 10 MHz 
% #######################################
if_bw_mhz = 10;

command = sprintf('TRAC:IQ:SET NORM,%gMHz,%gMHz,IFP,POS,%d,%d', ...
    if_bw_mhz, sample_rate_mhz, pretrigger_sample_length, sample_length);
% command = sprintf('TRAC:IQ:SET NORM,%gMHz,%gMHz,IFP,POS,%d,%d', ...
%     if_bw_mhz, sample_rate_mhz, pretrigger_sample_length, sample_length);
fprintf('set command = %s\n', command);
% command = sprintf('TRAC:IQ:SET NORM,%gMHz,%gMHz,IMM,POS,0,%d', ...
%     if_bw_mhz, sample_rate_mhz, sample_length);
fprintf(fsq_obj, command);

% set trigger to if power -70dbm (this is minimum)
fprintf(fsq_obj, 'TRIG:LEV:IFP -70DBM');

% % wait for FSQ to acquire IQ
% fprintf(fsq_obj, 'INIT;*WAI');

% set IQ format to 32-bit floating point binary
fprintf(fsq_obj, 'FORMAT REAL,32');

% set IQ data ouput format : IQB (= first all I and then all Q data is transferred)
fprintf(fsq_obj, 'TRAC:IQ:DATA:FORM IQB');

% % ######## advice from r&s online support engineer(zhang, laura) #########
% % switch to single-sweep mode
% fprintf(fsq_obj, 'INIT:CONT OFF');
% 
% % response = query(fsq_obj, 'INIT:CONT?');
% % fprintf('continuous mode = %s\n', response(1:end-1));

fprintf('###### entering get iq command\n');

% get IQ from FSQ
fprintf(fsq_obj, 'TRAC:IQ:DATA?');
% fprintf(fsq_obj, 'TRAC:IQ:DATA?;*WAI');

% ### for IQ data output format, see page 6.1-219 in FSQ operating manual

% read start indicator, and byte length in length block
[A, count, msg] = fread(fsq_obj, 2, 'char');
count
msg
if count ~= 2
    fprintf(fsq_obj, 'ABOR');
    error('##### fread to read start indicator was time-out. sent abort command, and exit');
end
% check start indicator(= #)
if char(A(1)) ~= '#'
    fclose(fsq_obj);
    error('start indicator = # not found');
end

% get digit length
% #### digits expressing number of subsequent data bytes
% ascii code of '0' = 48
digit_length = A(2) - 48;

% read number of subsequent data bytes whose size was given in digit_length
% number of subsequent data bytes
[A, count, msg] = fread(fsq_obj, digit_length, 'char');

% convert ascii code to digit
A = A - 48;
% convert digit to number
ten_base = 10 .^ [length(A) - 1 : -1 : 0];
% get byte length
byte_length = sum(A' .* ten_base);
% ########################################################################################################
% ### you can replace above statements with "byte_length = sscanf(char(A), '%d')", which is nicer
% ########################################################################################################

if byte_length ~= sample_length * 8
    fprintf('##### error: byte length must be %d(= %d * 8), but it was %d\n', sample_length * 8, sample_length, byte_length);
    fclose(fsq_obj);
    return;
%     error('byte length = %d, sample length * 8 = %d', ...
%         byte_length, sample_length * 8);
end

% read i_then_q whose size was given in byte_length
[i_then_q, count, msg] = fread(fsq_obj, byte_length, 'float');
% i_then_q is column vector, which is default output of fread function
i_plus_q_length = length(i_then_q);
if i_plus_q_length ~= sample_length * 2
    fclose(fsq_obj);
    error('i plus q length = %d, sample length * 2 = %d', ...
        i_plus_q_length, sample_length * 2);
end

% pause(1);

% ### read STB(status byte) register
% bit meaning: (see page 426 in "operating manual")
% 2 = Error Queue not empty. 
% The bit is set when an entry is made in the error queue.
% 3 = QUEStionable status sum bit. 
% The bit is set if an EVENt bit is set in the QUEStionable: status register and the associated ENABle bit is set to 1.
% 4 = MAV bit (message available)
% The bit is set if a message is available in the output buffer which can be read.
% 5 = ESB bit. Sum bit of the event status register. 
% It is set if one of the bits in the event status register is set and enabled in the event status enable register.
% 6 = MSS bit (master status summary bit)
% The bit is set if the instrument triggers a service request. (NOT USED)
% 7 = OPERation status register sum bit. 
% The bit is set if an EVENt bit is set in the OPERation-Status register and the associated ENABle bit is set to 1.
% ########## stb = 128 = [0 0 0 0 0 0 0 1] = STATus:OPERation Register set bit 7, normal condition #########

% response = query(fsq_obj, '*STB?');
% stb = sscanf(response(1 : end - 1), '%d');
% fprintf('*STB? => %d\n', stb);

% ### read ESR(event status register)
% bit meaning: (see page 427 in "operating manual")
% 0 = operation complete, 2 = query error, 3 = device dependent error, 4 = execution error, 
% 5 = command error, 6 = user request, 7 = power on 

% response = query(fsq_obj, '*ESR?');
% esr = sscanf(response(1 : end - 1), '%d');
% fprintf('*ESR? => %d\n', esr);

% ### read STATus:OPERation Register
% bit meaning: (see page 428 in "operating manual")
% 0 = CALibrating, 3 = SWEeping, 4 = MEASuring, 
% 5 = Waiting for TRIGger, only supported for I/Q measurements (TRACe:IQ state is on),
% 8 = HardCOPy in progress, 10 = Sweep Break
% ###### stat_oper = 24 = [0 0 0 1 1], normal condition when no trigger
% ###### stat_oper = 56 = [0 0 0 1 1 1], normal condition when waiting for trigger

% response = query(fsq_obj, 'STAT:OPER?');
% stat_oper = sscanf(response(1 : end - 1), '%d');
% % % remove not used bit in STATus:OPERation Register
% % stat_oper = bi2de(bitand(stat_oper, stat_oper_enable));
% fprintf('STAT:OPER? => %d\n', stat_oper);

% ### read STATus:QUEStionable Register
% bit meaning: (see page 429 in "operating manual")
% 3 = POWer, 5 = FREQuency, 8 = CALibration, 9 = LIMit (device-specific)
% 10 = LMARgin, 12 = ACPLimit

% response = query(fsq_obj, 'STAT:QUES?');
% stat_ques = sscanf(response(1 : end - 1), '%d');
% fprintf('STAT:QUES? => %d\n', stat_ques);

% ### read STATus:QUEStionable:FREQuency Register
% bit meaning: (see page 432 in "operating manual")
% 0 = OVEN COLD, 1 = LO UNLocked (Screen A), 9 = LO UNLocked (Screen B)

% response = query(fsq_obj, 'STAT:QUES:FREQ?');
% stat_ques_freq = sscanf(response(1 : end - 1), '%d');
% fprintf('STAT:QUES:FREQ? => %d\n', stat_ques_freq);

% ### read STATus:QUEStionable:POWer Register
% bit meaning: (see page 434 in "operating manual")
% 0 = RF input OVERload (Screen A), 1 = RF input UNDerload (Screen A),
% 2 = IF_OVerload (Screen A), 3 = Overload Trace (Screen A),
% 8 = RF input OVERload (Screen A), 9 = RF input UNDerload (Screen A),
% 10 = IF_OVerload (Screen A), 11 = Overload Trace (Screen A),

% response = query(fsq_obj, 'STAT:QUES:POW?');
% stat_ques_pow = sscanf(response(1 : end - 1), '%d');
% fprintf('STAT:QUES:POW? => %d\n', stat_ques_pow);
% 
% response = query(fsq_obj, 'STAT:QUE?');
% fprintf('STAT:QUE? => %s\n', response(1 : end - 1));

% if esr || (stat_oper ~= 32) || stat_ques || stat_ques_freq || stat_ques_pow  
%     fclose(fsq_obj);
%     fprintf('############## something wrong, so discard iq sample and quit\n');
%     return;
% end

% ########## before 181107 #########
% if (stb ~= 128) || esr || (stat_oper ~= 24) || stat_ques || stat_ques_freq || stat_ques_pow  
%     fclose(fsq_obj);
%     fprintf('############## something wrong, so discard iq sample and quit\n');
%     return;
% end

% ### read STATus:OPERation Register
% In the CONDition part, 
% this register contains information on which actions the instrument is being executing or, 
% in the EVENt part, 
% information on which actions the instrument has executed since the last reading. 
% It can be read using commands "STATus:OPERation:CONDition?" or "STATus:OPERation[:EVENt]?".
% response = query(fsq_obj, 'STAT:OPER:COND?'); % condition part
% response = query(fsq_obj, 'STAT:OPER?'); % event part

% ### read STATus:QUEStionable Register
% This register comprises information about indefinite states 
% which may occur if the unit is operated without meeting the specifications. 
% It can be queried by commands STATus:QUEStionable:CONDition? and STATus:QUEStionable[:EVENt]?.
% bit meaning:
% 3 = POWer, This bit is set if a questionable power occurs
% 5 = FREQuency
% 8 = CALibration
% 9 = LIMit (device-specific), This bit is set if a limit value is violated
% 10 = LMARgin, This bit is set if a margin is violated
% 12 = ACPLimit, This bit is set if a limit for the adjacent channel power measurement is violated
% response = query(fsq_obj, 'STAT:QUES:COND?'); % condition part
% response = query(fsq_obj, 'STAT:QUES?'); % event part

% ### read STATus:QUEStionable:FREQuency Register
% This register comprises information about the reference and local oscillator.
% It can be queried with commands STATus:QUEStionable:FREQuency:CONDition? and STATus:QUEStionable:FREQuency[:EVENt]?
% bit meaning:
% 0 = OVEN COLD, 1 = LO UNLocked (Screen A), 9 = LO UNLocked (Screen B)
% response = query(fsq_obj, 'STAT:QUES:FREQ:COND?'); % condition part
% response = query(fsq_obj, 'STAT:QUES:FREQ?'); % event part

% ### read STATus:QUEStionable:POWer Register
% This register comprises all information about possible overloads of the unit.
% It can be queried with commands STATus:QUEStionable:POWer:CONDition? and STATus:QUEStionable:POWer[:EVENt]?.
% bit meaning:
% 0 = OVERload (Screen A), This bit is set if the RF input is overloaded.
% 1 = UNDerload (Screen A), This bit is set if the RF input is underloaded.
% 2 = IF_OVerload (Screen A), This bit is set if the IF path is overloaded.
% 3 = Overload Trace (Screen A)
% 8 = OVERload (Screen B), This bit is set if the RF input is overloaded.
% 9 = UNDerload (Screen B), This bit is set if the RF input is underloaded.
% 10 = IF_OVerload (Screen B), This bit is set if the IF path is overloaded.
% 11 = Overload Trace (Screen B)
% response = query(fsq_obj, 'STAT:QUES:POW:COND?'); % condition part
% response = query(fsq_obj, 'STAT:QUES:POW?'); % event part

% all is successful, so close
fclose(fsq_obj);

% make complex iq from i_then_q
inphase = i_then_q(1 : sample_length);
quadrature = i_then_q(sample_length + 1 : end);
iq = complex(inphase, quadrature);

% ########################################################################
% when sample length > 2^19, original iq will be replaced (180731)
% see fig 6.3 in fsq manual
% "Blockwise transmission with data volumes exceeding 512k words"
% i suspect "TRAC:IQ:DATA:FORMat COMPatible | IQBLock | IQPair" is right
% ########################################################################
max_sample_per_block = 2^19;
if length(iq) > max_sample_per_block
    fprintf('#### re-arranging iq\n');
    [iq] = re_arrange_iq(iq, max_sample_per_block);
end

% if needed, filter iq
if iq_bw_mhz > signal_bw_mhz
    fprintf('#### filtering: iq bw = %g mhz, signal bw = %g mhz\n', iq_bw_mhz, signal_bw_mhz);
    iq = filter_iq(iq, signal_bw_mhz, sample_rate_mhz, plot_filter_response);
end

% % if needed, filter iq
% if ~isempty(signal_bw_mhz) && (if_bw_mhz > signal_bw_mhz)
%     fprintf('#### filtering: if bw = %g mhz, signal bw = %g mhz\n', if_bw_mhz, signal_bw_mhz);
%     iq = filter_iq(iq, signal_bw_mhz, sample_rate_mhz, plot_filter_response);
%     bw_mhz = signal_bw_mhz;
% else
%     bw_mhz = if_bw_mhz;
% end

if ~isempty(directory)   
    % make iq filename
    % directory = 'D:\direction_finding\data\wideband_if';
    filename_initial = 'fsq_iq';
    [timestamp] = get_timestamp;
    filename = sprintf('%s\\%s_%s_%g_%g_%g.mat', ...
        directory, filename_initial, timestamp, center_freq_mhz, signal_bw_mhz, sample_rate_mhz);
    % filename = sprintf('%s\\%s_%s_%d.mat', directory, filename_initial, timestamp, fix(center_freq_mhz));
    
    % save iq into file
    save(filename, 'iq', 'center_freq_mhz', 'signal_bw_mhz', 'sample_rate_mhz', 'sample_length', 'timestamp');
end

if plot_signal
    title_text = ...
        sprintf('  %g MHz, bw %g MHz, fs %g MHz, sample %d', ...
        center_freq_mhz, signal_bw_mhz, sample_rate_mhz, sample_length);
    plot_iq(iq, sample_rate_mhz * 1e6, title_text);
end

end

%%
function [iq] = re_arrange_iq(iq, max_sample_per_block)

sample_length = length(iq);

i_then_q = [real(iq); imag(iq)];

block_length = round(sample_length / max_sample_per_block);
last_block_sample_length = rem(sample_length, max_sample_per_block);
if last_block_sample_length
    sample_length_list = [max_sample_per_block * ones(1, block_length - 1), last_block_sample_length];
else
    sample_length_list = max_sample_per_block * ones(1, block_length);
end
sample_length_list;

reverse_pack_iq = [];
idx = 1;
for n = 1 : block_length
    this_block_sample_length = sample_length_list(n);
    tmp = i_then_q(idx : idx + this_block_sample_length * 2 - 1);
    
    inphase = tmp(1 : this_block_sample_length);
    quadrature = tmp(this_block_sample_length + 1 : end);
    reverse_pack_iq = [reverse_pack_iq; complex(inphase, quadrature)];
    
    idx = idx + this_block_sample_length * 2;
end
size(reverse_pack_iq);

iq = reverse_pack_iq;

end

%%
% function [receiver_if_bw_mhz, sample_rate_mhz, iq_bw_mhz] = get_receiver_if_bw_and_sample_rate(signal_bw_mhz)
% 
% fsq_if_bw_mhz_vec = [.2, .3, .5, 1, 2, 3, 5, 10, 20, 50];
% fsq_sample_rate_mhz_vec = [.2/.8, .3/.8, .5/.8, 1/.8, 2/.8, 3/.8, 5/.8, 10/.8, 20/.68, 40.8];
% iq_bw_mhz_vec = [.2, .3, .5, 1, 2, 3, 5, 10, 20, 30];
% 
% I = find(iq_bw_mhz_vec >= signal_bw_mhz, 1, 'first'); 
% 
% receiver_if_bw_mhz = fsq_if_bw_mhz_vec(I);
% 
% % 8.16 = 10.2 * 0.8
% if signal_bw_mhz < 8.16
%     sample_rate_mhz = signal_bw_mhz / .8;
% end
% 
% % 13.872 = 20.4 * 0.68
% if signal_bw_mhz < 13.872
%     sample_rate_mhz = signal_bw_mhz / .8;
% end
% 
% sample_rate_mhz = signal_bw_mhz / .8;
% 
% if sample_rate_mhz >= 20.4 && sample_rate_mhz < 40.8
%     ;
% end
% 
% sample_rate_mhz = fsq_sample_rate_mhz_vec(I);
% iq_bw_mhz = iq_bw_mhz_vec(I);
% 
% end





function [] = tx_rx_modulation_signal(fc_mhz, modulation_type, sample_length, symbol_rate_mhz, save_dir, plot_signal)
% tx and rx modulation signal
%
% [input]
% - fc_mhz: carrier frequency in mhz
% - modulation_type: one of 'bpsk', 'qpsk', '2fsk', '4fsk', '16qam', 'nbfm', 'wbfm', 'ssb', 'amsc'
% - sample_length: iq sample length, max sample length = 2^21 = 2097152
% - symbol_rate_mhz: symbol rate in mhz, valid in digital modulation
% - fsk_freq_dev: fsk frequency deviation, valid in '2fsk', '4fsk'
% - am_modulation_index: am modulation index, valid in 'amsc'
% - fm_freq_dev: narrow band fm, wide band fm
% - save_dir:
% - plot_signal:
% 
% [usage]
% tx_rx_modulation_signal(1000, 'bpsk', 2^13, 200e3)
%
% [tx equipment]
% signal generator: r&s smu200a (etri equipment number: 29-07-06046) for digital modulation
% signal generator: can't find good one for analog modulation
% power amp:
% antenna:
%
% [smu200a fw version] SMU200A,1141.2005k02/102441,2.1.96.0-02.10.111.189
% [smu200a option] SMU-B11, SMU-B13, SMU-B20, SMU-B106
% #######################################################
% B-11: Baseband Generator with ARB (16 Msample) and Digital Modulation (realtime)
% B-13: Baseband Main Module
% B-20: FM/PM Modulator
% B-106: 100 kHz to 6 GHz
% ######################################################
%
% [rx equipment]
% signal analyzer: r&s fsq26 (etri equipment number: 29-07-06049)
% must use FW 4.75 version operating manual (not FW 4.55)
% STATus:OPERation Register in FW 4.75 is different from FW 4.55
% antenna:
%
% [fsq26 fw version] FSQ-26,200460/026,4.75
% [fsq26 option] B4 B16 B25 B72-120 B72 K70 K100
% #######################################################
% B4 = Improved aging OCXO, low aging/improved phase noise at 10 Hz carrier offset
% B16 = LAN interface 
% B25 = Electronic Attenuator, 0 to 30 dB, preamp 20 dB
% B72-120 = ??
% B72 = I/Q bandwidth extension
% K70 = Firmware General Purpose Vector Signal Analyzer
% K100 = Analysis of EUTRA/LTE FDD Downlink Signals
% #######################################################

pause_sec = 3;

max_sample_length = 2^21; % 2^21 = 2097152
if sample_length > max_sample_length
    fprintf('###### error: max sample length = %d\n', max_sample_length);
    return;
end

% initialize smu200a
smu_ip_address = '172.16.100.200'; 
smu_tcp_port = 5025;
smu_obj = initialize_signal_generator(smu_ip_address, smu_tcp_port);

% initialize fsq26
fsq_ip_address = '172.16.110.26'; 
fsq_tcp_port = 5025;
fsq_obj = initialize_signal_analyzer(fsq_ip_address, fsq_tcp_port);

% fsq_ip_address = '172.16.110.26'; 
% fsq_tcp_port = 5025;
% initialize_power_amp();

% set up signal generator to generate modulation signal
generate_modulation_signal(smu_obj, fc_mhz, modulation_type, symbol_rate_mhz);

% on signal generator rf output
on_signal_generator(smu_obj);

% % on power amp output
% on_power_amp();

% wait for modulation signal to arrive at rx antenna (signal go slowly? human running speed?)
pause(pause_sec);

[signal_bw_mhz] = compute_tx_signal_bw(symbol_rate_mhz);

% get fsq26 if bw and sample rate
% see "6.20.3 TRACe:IQ Subsystem" in fsq26 manual
[receiver_if_bw_mhz, sample_rate_mhz, iq_bw_mhz] = get_receiver_if_bw_and_sample_rate(signal_bw_mhz);

[iq, receiver_status_error, sample_reading_error] = ...
    receive_modulation_signal(fsq_obj, fc_mhz, receiver_if_bw_mhz, sample_rate_mhz, sample_length);

fclose(fsq_obj);

if receiver_status_error || sample_reading_error
    % off power amp output
    off_power_amp();
    
    % off signal generator rf output
    off_signal_gnerator(smu_obj);
    
    return;
end

% % off power amp output
% off_power_amp();

% off signal generator rf output
off_signal_gnerator(smu_obj);

fclose(smu_obj);
delete(instrfind);

% % disconnect_delete_instrument(smu_obj, fsq_obj, power_amp_obj);
% disconnect_delete_instrument(smu_obj, fsq_obj);

% post process: filtering, saving, plotting of iq sample
post_process_iq_sample(iq, modulation_type, fc_mhz, signal_bw_mhz, sample_rate_mhz, ...
    iq_bw_mhz, save_dir, plot_signal);

end

%%
function [] = generate_modulation_signal(smu_obj, fc_mhz, modulation_type, symbol_rate)





end

%%
function [iq, receiver_status_error, sample_reading_error] = ...
    receive_modulation_signal(fsq_obj, fc_mhz, if_bw_mhz, sample_rate_mhz, sample_length)

receiver_status_error = 0;
sample_reading_error = 0;

% set tuning freq
command = sprintf('FREQ:CENT %gMHz', fc_mhz);
fprintf(fsq_obj, command);

% set span to 0 for time domain measurement
fprintf(fsq_obj, 'FREQ:SPAN 0MHZ');
% response = query(fsq_obj, 'FREQ:SPAN?')

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

command = sprintf('TRAC:IQ:SET NORM,%gMHz,%gMHz,IMM,POS,0,%d', ...
    if_bw_mhz, sample_rate_mhz, sample_length);
fprintf(fsq_obj, command);

% wait for FSQ to acquire IQ
fprintf(fsq_obj, 'INIT;*WAI');

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
response = query(fsq_obj, '*STB?');
stb = sscanf(response(1 : end - 1), '%d');
fprintf('*STB? => %d\n', stb);

% ### read ESR(event status register)
% bit meaning: (see page 427 in "operating manual")
% 0 = operation complete, 2 = query error, 3 = device dependent error, 4 = execution error, 
% 5 = command error, 6 = user request, 7 = power on 
response = query(fsq_obj, '*ESR?');
esr = sscanf(response(1 : end - 1), '%d');
fprintf('*ESR? => %d\n', esr);

% ### read STATus:OPERation Register
% bit meaning: (see page 428 in "operating manual")
% 0 = CALibrating, 3 = SWEeping, 4 = MEASuring, 
% 5 = Waiting for TRIGger, only supported for I/Q measurements (TRACe:IQ state is on),
% 8 = HardCOPy in progress, 10 = Sweep Break
% ###### stat_oper = 24 = [0 0 0 1 1], normal condition when no trigger
% ###### stat_oper = 56 = [0 0 0 1 1 1], normal condition when waiting for trigger
response = query(fsq_obj, 'STAT:OPER?');
stat_oper = sscanf(response(1 : end - 1), '%d');
% % remove not used bit in STATus:OPERation Register
% stat_oper = bi2de(bitand(stat_oper, stat_oper_enable));
fprintf('STAT:OPER? => %d\n', stat_oper);

% ### read STATus:QUEStionable Register
% bit meaning: (see page 429 in "operating manual")
% 3 = POWer, 5 = FREQuency, 8 = CALibration, 9 = LIMit (device-specific)
% 10 = LMARgin, 12 = ACPLimit
response = query(fsq_obj, 'STAT:QUES?');
stat_ques = sscanf(response(1 : end - 1), '%d');
fprintf('STAT:QUES? => %d\n', stat_ques);

% ### read STATus:QUEStionable:FREQuency Register
% bit meaning: (see page 432 in "operating manual")
% 0 = OVEN COLD, 1 = LO UNLocked (Screen A), 9 = LO UNLocked (Screen B)
response = query(fsq_obj, 'STAT:QUES:FREQ?');
stat_ques_freq = sscanf(response(1 : end - 1), '%d');
fprintf('STAT:QUES:FREQ? => %d\n', stat_ques_freq);

% ### read STATus:QUEStionable:POWer Register
% bit meaning: (see page 434 in "operating manual")
% 0 = RF input OVERload (Screen A), 1 = RF input UNDerload (Screen A),
% 2 = IF_OVerload (Screen A), 3 = Overload Trace (Screen A),
% 8 = RF input OVERload (Screen A), 9 = RF input UNDerload (Screen A),
% 10 = IF_OVerload (Screen A), 11 = Overload Trace (Screen A),
response = query(fsq_obj, 'STAT:QUES:POW?');
stat_ques_pow = sscanf(response(1 : end - 1), '%d');
fprintf('STAT:QUES:POW? => %d\n', stat_ques_pow);

response = query(fsq_obj, 'STAT:QUE?');
fprintf('STAT:QUE? => %s\n', response(1 : end - 1));

if (stb ~= 128) || esr || (stat_oper ~= 24) || stat_ques || stat_ques_freq || stat_ques_pow
%     fprintf('*STB? => %s\n', mat2str(de2bi(stb))); % ### nice code, use it
%     
%     fprintf('*ESR? => %s\n', mat2str(de2bi(esr)));
%     
%     fprintf('STAT:OPER? => %s\n', mat2str(de2bi(stat_oper)));
%     
%     fprintf('STAT:QUES? => %s\n', mat2str(de2bi(stat_ques)));
%     
%     fprintf('STAT:QUES:FREQ? => %s\n', mat2str(de2bi(stat_ques_freq)));
%     
%     fprintf('STAT:QUES:POW? => %s\n', mat2str(de2bi(stat_ques_pow)));
    
%     fclose(fsq_obj);
    receiver_status_error = 1;
    fprintf('##### receiver status error\n');
    
    return;
end

% set IQ format to 32-bit floating point binary
fprintf(fsq_obj, 'FORMAT REAL,32');

% set IQ data ouput format : IQB (= first all I and then all Q data is transferred)
fprintf(fsq_obj, 'TRAC:IQ:DATA:FORM IQB');

% get IQ from FSQ
fprintf(fsq_obj, 'TRAC:IQ:DATA?');
% ### for IQ data output format, see page 6.1-219 in FSQ operating manual

% read start indicator, and byte length in length block
[A, count, msg] = fread(fsq_obj, 2, 'char');
% check start indicator(= #)
if char(A(1)) ~= '#'
%     fclose(fsq_obj);
    sample_reading_error = 1;   
    fprintf('##### sample reading error: start indicator = # not found\n');
    
    return;
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
%     fclose(fsq_obj);
    sample_reading_error = 1;
    fprintf('##### sample reading error: byte length must be %d(= %d * 8), but it was %d\n', ...
        sample_length * 8, sample_length, byte_length);
    
    return;
end

% read i_then_q whose size was given in byte_length
[i_then_q, count, msg] = fread(fsq_obj, byte_length, 'float');
% i_then_q is column vector, which is default output of fread function
i_plus_q_length = length(i_then_q);
if i_plus_q_length ~= sample_length * 2
%     fclose(fsq_obj);
    sample_reading_error = 1;
    fprintf('#### sample reading error: i plus q length = %d, sample length * 2 = %d\n', ...
        i_plus_q_length, sample_length * 2);
    
    return;
end

% make complex iq from i_then_q
inphase = i_then_q(1 : sample_length);
quadrature = i_then_q(sample_length + 1 : end);
iq = complex(inphase, quadrature);

end

%%
function [] = post_process_iq_sample(iq, modulation_type, fc_mhz, signal_bw_mhz, sample_rate_mhz, ...
    iq_bw_mhz, save_dir, plot_signal)

% if needed, filter iq
if iq_bw_mhz > signal_bw_mhz
    fprintf('#### filtering: iq bw = %g mhz, signal bw = %g mhz\n', iq_bw_mhz, signal_bw_mhz);
    plot_filter_response = 0;
    iq = filter_iq(iq, signal_bw_mhz, sample_rate_mhz, plot_filter_response);
end

if ~isempty(save_dir)   
    % make iq filename
    % directory = 'D:\direction_finding\data\wideband_if';
    filename_initial = 'fsq_iq';
    [timestamp] = get_timestamp;
    filename = sprintf('%s\\%s_%s_%s_%g_%g_%g.mat', ...
        save_dir, filename_initial, timestamp, modulation_type, fc_mhz, signal_bw_mhz, sample_rate_mhz);
    % filename = sprintf('%s\\%s_%s_%d.mat', directory, filename_initial, timestamp, fix(center_freq_mhz));
    
    % save iq into file
    save(filename, ...
        'iq', 'fc_mhz', 'signal_bw_mhz', 'receiver_if_bw_mhz', 'sample_rate_mhz', 'sample_length');
end

if plot_signal
    title_text = ...
        sprintf('  %g MHz, bw %g MHz, fs %g MHz, sample %d', ...
        fc_mhz, signal_bw_mhz, sample_rate_mhz, sample_length);
    plot_iq(iq, sample_rate_mhz * 1e6, title_text);
end

end

%%
function [] = on_signal_generator(smu_obj)




end

%%
function [] = off_signal_generator(smu_obj)




end

%%
function [] = on_power_amp()


end

%%
function [] = off_power_amp()



end

%%
function [signal_bw_mhz] = compute_tx_signal_bw(symbol_rate_mhz)




end

%%
function [smu_obj] = initialize_signal_generator(smu_ip_address, smu_tcp_port)

% create tcp object
smu_obj = tcpip(smu_ip_address, smu_tcp_port);

% % ### if system_max_sample_length = 16776704, matlab error message is displayed :
% % ### ??? There is not enough memory to create the inputbuffer. Try specifying a smaller value.
% % ### to cure this error, more computer memory is needed
% system_max_sample_length = 16776704 / 4;
% 
% % set 'input buffer size' properties
% set(smu_obj, 'InputBufferSize', system_max_sample_length * 8);
% % ### 8 above line : I sample = 4 byte, Q sample = 4 byte
% 
% % set 'timeout' to 60 sec
% set(smu_obj, 'Timeout', 60);

% connect with equipment
fopen(smu_obj);

% when tcp, default is 'bigEndian', so must set to 'littleEndian'
% when gpib-enet/100, default was 'littleEndian', so need not touch
set(smu_obj, 'ByteOrder', 'littleEndian');
% ByteOrder = littleEndian

% query "who are you?"
response = query(smu_obj, '*IDN?');
fprintf('i''m %s\n', response(1:end-1));

% query "which option do you have?"
response = query(smu_obj, '*OPT?');
fprintf('my option: %s\n', response(1:end-1));

% reset and clear buffer
fprintf(fsq_obj, '*RST');
fprintf(fsq_obj, '*CLS');

end

%%
function [fsq_obj] = initialize_signal_analyzer(fsq_ip_address, fsq_tcp_port)

% create tcp object
fsq_obj = tcpip(fsq_ip_address, fsq_tcp_port);

% ### if system_max_sample_length = 16776704, matlab error message is displayed :
% ### ??? There is not enough memory to create the inputbuffer. Try specifying a smaller value.
% ### to cure this error, more computer memory is needed
system_max_sample_length = 16776704;

% % ### if sample_length > user_max_sample_length, visa time-out error is displayed :
% % ### VISA: Timeout expired before operation completed.
% % ### to cure this error, set time-out
% user_max_sample_length = 2^21; % 2^21 = 2097152
% % user_max_sample_length = 16776704 / 4;
% % user_max_sample_length = 16776704 / 32;
% if sample_length > user_max_sample_length
%     fprintf('###### error: max sample length = %d\n', user_max_sample_length);
%     return;
% end

% set 'input buffer size' properties
set(fsq_obj, 'InputBufferSize', system_max_sample_length * 8);
% ### 8 above line : I sample = 4 byte, Q sample = 4 byte

% set 'timeout' to 60 sec
set(fsq_obj, 'Timeout', 60);

% connect with equipment
fopen(fsq_obj);

% when tcp, default is 'bigEndian', so must set to 'littleEndian'
% when gpib-enet/100, default was 'littleEndian', so need not touch
set(fsq_obj, 'ByteOrder', 'littleEndian');
% ByteOrder = littleEndian

% query "who are you?"
response = query(fsq_obj, '*IDN?');
fprintf('i''m %s\n', response(1:end-1));

% query "which option do you have?"
response = query(fsq_obj, '*OPT?');
fprintf('my option: %s\n', response(1:end-1));

% reset and clear buffer
fprintf(fsq_obj, '*RST');
fprintf(fsq_obj, '*CLS');

% This command resets the edge detectors and ENABle parts of all registers to a defined value:
% All PTRansition parts are set to FFFFh, i.e. all transitions from 0 to 1 are detected. 
% All NTRansition parts are set to 0, i.e. a transition from 1 to 0 in a CONDition bit is not detected. 
% The ENABle part of the STATus:OPERation and STATus:QUEStionable registers are set to 0, 
% i.e. all events in these registers are not passed on.
fprintf(fsq_obj, 'STAT:PRES');

% #############################################################################
% ### set up status reporting system in fsq26
% ### for status register overview, see page 425 in "operating manual"
% #############################################################################

% set ESE(event status enable) register to all bit enable
% bit meaning: (see page 427 in "operating manual")
% 0 = operation complete, 2 = query error, 3 = device dependent error, 4 = execution error, 
% 5 = command error, 6 = user request, 7 = power on 
fprintf(fsq_obj, '*ESE 255');

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
fprintf(fsq_obj, 'STAT:OPER:ENAB 65535');

% set STATus:QUEStionable Register to all bit enable
% bit meaning: (see page 429 in "operating manual")
% 3 = POWer, 5 = FREQuency, 8 = CALibration, 9 = LIMit (device-specific)
% 10 = LMARgin, 12 = ACPLimit
fprintf(fsq_obj, 'STAT:QUES:ENAB 65535');

% set STATus:QUEStionable:FREQuency Register to all bit enable
% bit meaning: (see page 432 in "operating manual")
% 0 = OVEN COLD, 1 = LO UNLocked (Screen A), 9 = LO UNLocked (Screen B)
fprintf(fsq_obj, 'STAT:QUES:FREQ:ENAB 65535');

% set STATus:QUEStionable:POWer Register to all bit enable
% bit meaning: (see page 434 in "operating manual")
% 0 = RF input OVERload (Screen A), 1 = RF input UNDerload (Screen A),
% 2 = IF_OVerload (Screen A), 3 = Overload Trace (Screen A),
% 8 = RF input OVERload (Screen A), 9 = RF input UNDerload (Screen A),
% 10 = IF_OVerload (Screen A), 11 = Overload Trace (Screen A),
fprintf(fsq_obj, 'STAT:QUES:POW:ENAB 65535');

end

%%
% function [] = disconnect_delete_instrument(smu_obj, fsq_obj)
% 
% fclose(smu_obj);
% fclose(fsq_obj);
% 
% delete(instrfind);
% 
% end



function [] = fixed_freq_esmb(freq_mhz, squelch_threshold_dbuv)
% freq scan using esmb is not easy, 
% instead of freq scan, try fixed freq to get 146 mhz signal
%
% [usage]
% fixed_freq_esmb(146.5875, 0)
%

% #######################################################################################
% [reference]
% R&S C example code for freq scan: "CExample.c"
%
% good how to control device (see command flow), read string and trace data from esmb
% #######################################################################################

% ############### response from esmb ################################################
% terminator are 2 char, '13 10' (carriage return, line feed)
% you can see this using "uint8(response)" or "double(response)"
% different from fsq where terminator is 1 char, '10' (line feed)
%
% to print response without linefeed, 
%
% (1) use "response(1 : end - 2)"
% or
% (2) get object property ("out = propinfo(obj)") and change 'Terminator' property
% (not tested method) 
% ###################################################################################

off_speaker = 1;

% sweep_count = 11;
% dwell_time_sec = 5;
% hold_time_sec = 10;
% squelch_threshold_dbuv = 0;

signal_acquisition_number = 1;

% 146 mhz, 8.5 khz signal
freq_hz_vec = 146.5125e6 : 12.5e3 : 146.5875e6;
freq_length = length(freq_hz_vec);

bw_hz = 9000;

esmb_bw = [0.15,0.3,0.6,1,1.5,2.4,3,4,6,8,9,15,30,100,120,150,250,300] * 1e3;

ip_address = '172.16.110.11';
port_number = 5555;

% create tcp object
esmb = tcpip(ip_address, port_number);

% % ###### dependant on: 
% % (1) freq number in freq scan
% % (2) sweep count
% set(esmb, 'InputBufferSize', 2^14);

fopen(esmb);
% out = propinfo(esmb);
% out.Terminator

fprintf(esmb, '*RST');
fprintf(esmb, '*CLS');

% dont disturb other (speaker off), default = speaker on
if off_speaker
    fprintf(esmb, 'SYST:SPE:STAT OFF');
end

% fprintf(esmb, 'SYST:KLOCK ON');

response = query(esmb, '*IDN?');
response(1 : end - 2);

% query installed option (see '*OPT?' page in manual)
response = query(esmb, '*OPT?');
response(1 : end - 2);
% [esmb response] 'SU,0,0,ER,0,0,FS,F1,0'
% SU = internal IF-panorama module 
% ER = Expansion RAM 
% FS = Field Strength measurement (software option) 
% F1 = Front panel with controls 

% fixed freq
dev_command = sprintf('FREQ %d Hz', freq_mhz * 1e6);
fprintf(esmb, dev_command);

response = query(esmb, 'FREQ?');
response(1 : end - 2);

% bw = 9 khz, demodulation = fm, detector = average of voltage, gain control = agc
% dev_command = sprintf('BAND %d Hz;DEM FM;DET PAV;GCON:MODE MGC;GCON -30', bw_hz);
dev_command = sprintf('BAND %d Hz;DEM FM;DET PAV;GCON:MODE AGC', bw_hz);
fprintf(esmb, dev_command);

response = query(esmb, 'BAND?');
response(1 : end - 2);

response = query(esmb, 'GCON?');
response(1 : end - 2);

% #################################################################################
% ### dont use 'low noise' mode: it give error code 10 (= Component failure)
% #################################################################################
% % try 'low noise' mode
% fprintf(esmb, 'INP:ATT:MODE LOWN');
% 
% response = query(esmb, 'INP:ATT:MODE?');
% response(1 : end - 2)

% ###### ':OUTP:SQU:STAT OFF', 
% ###### i think ':OUTP:SQU:STAT ON' may be right
dev_command = sprintf('INP:ATT:AUTO OFF;:OUTP:SQU:STAT ON;THR %d dbuV', squelch_threshold_dbuv);
fprintf(esmb, dev_command);
% fprintf(esmb, 'INP:ATT:AUTO OFF;:OUTP:SQU:STAT OFF;THR 40 dbuV');

% turn off "freq offset", turn on "level measurement"
fprintf(esmb, "FUNC:OFF 'FREQ:OFFS';ON 'VOLT:AC'");

% ################# config trace ####################

% % store result only if level is over threshold
% fprintf(esmb, 'TRAC:FEED:CONT MTRACE,SQU;CONT ITRACE,SQU');
% 
% % set notification limit to 80 percent
% fprintf(esmb, 'TRAC:LIM MTRACE,80 PCT;LIM ITRACE,80 PCT');

% ############### config status reporting system ##############

% ############ disable srq
fprintf(esmb, '*SRE 0');
% % enable srq on 'STAT:OPER', 'STAT:TRAC', 'STAT:EXT' events
% fprintf(esmb, '*SRE #H87');

response = query(esmb, '*SRE?');
response(1 : end - 2);

% enable signal over threshold event (NOT rx data changed)
fprintf(esmb, 'STAT:EXT:ENAB #B10000');
% enable rx data changed event
% fprintf(esmb, 'STAT:EXT:ENAB 1');

% % enable mtrace, itrace not empty event
% fprintf(esmb, 'STAT:TRAC:ENAB #B1001');

% % enable mtrace limit exceeded event
% fprintf(esmb, 'STAT:TRAC:ENAB #B10');

% % enable scan stop event
% fprintf(esmb, 'STAT:OPER:SWE:ENAB #B10');
% fprintf(esmb, 'STAT:OPER:SWE:NTR #B10;PTR 0');

% % enable measuring events in 'STAT:OPER' register
% fprintf(esmb, 'STAT:OPER:ENAB #B10000');
% ######### too mnay 'operation status'

% % enable sweeping events in 'STAT:OPER' register
% fprintf(esmb, 'STAT:OPER:ENAB #B1000');

% % switch to freq scanning mode
% fprintf(esmb, 'FREQ:MODE SWE');

% ############# start freq scanning ##########

fprintf(esmb, 'INIT');

% ############################################################################
% Status Byte (STB) and Service Request Enable (SRE) register (see manual)
%
% [bit 0] EXTended status register summary bit
% The bit is set if an EVENt bit is set in the EXTended status register 
% and if the corresponding ENABle bit is set to 1.
% The states of the hardware functions and change bits are combined in the EXTended status register.
%
% [bit 1] TRACe status register summary bit
% The bit is set if an EVENt bit is set in the TRACe status register 
% and if the corresponding ENABle bit is set to 1.
% The states of the TRACes MTRACE, ITRACE, SSTART and SSTOP are represented in the TRACe status register.
%
% [bit 2] Error Queue not empty
% The bit is set when the error queue contains an entry.
% If this bit is enabled by the SRE, an entry into the empty error queue generates a service request.
% Thus, an error can be recognized and specified in greater detail by polling the error queue. 
% The poll provides an informative error message. 
% This procedure is recommended since it considerably reduces the problems involved with the control.
%
% [bit 3] QUEStionable status register summary bit
% The bit is set if an EVENt bit is set in the QUEStionable status register 
% and the corresponding ENABle bit is set to 1. 
% A set bit indicates a questionable device status which can be specified in greater detail 
% by polling the QUEStionable status register.
%
% [bit 4] MAV bit (message available)
% No meaning
%
% [bit 5] ESB bit
% Summary bit of the EVENt status register. 
% It is set if one of the bits in the EVENt status register is set 
% and enabled in the EVENt status enable register.
% Setting of this bit implies a serious error which can be specified in greater detail 
% by polling the EVENt status register.
% 
% [bit 6] MSS bit (master status summary bit)
% The bit is set if the device triggers a service request. 
% This is the case if one of the other bits of this registers is set together 
% with its mask bit in the service request enable register SRE.
%
% [bit 7] OPERation status register summary bit
% The bit is set if an EVENt bit is set in the OPERation status register 
% and the corresponding ENABle bit is set to 1.
% A set bit indicates that the device is just performing an action. 
% The type of action can be determined by polling the QUEStionable status register.
% ###############################################################################################

over_threshold_number = 0;
while over_threshold_number < signal_acquisition_number
    % query status byte register
    response = query(esmb, '*STB?');
    stb = sscanf(response(1 : end - 2), '%d');
    
    % [bit 0] EXTended status register summary bit
    if bitand(stb, 1)
        response = query(esmb, 'STAT:EXT?');
        ext = sscanf(response(1 : end - 2), '%d');
        fprintf("ext = b'%s'\n", dec2bin(ext));
        
        if bitand(ext, 16)
            response = query(esmb, 'SENS:DATA?');
%             level = sscanf(response(1 : end - 2), '%d');
            fprintf('over threshold, level = %s dbuv\n', response(1 : end - 2));
            
            % ####### write code here to get iq from fsq #######
            
            over_threshold_number = over_threshold_number + 1;
        end
        
%         % #### this is needed?
%         response = query(esmb, 'FREQ?');
%         fprintf('freq = %s hz\n', response(1 : end - 2));
    end
    % ext = 1, extension register, bit 0, rx data changed
    % ext = 1031, "dec2bin(1031)", '10000000111', extension register, bit 0, bit 1, bit 2, bit 10
    
    % [bit 1] TRACe status register summary bit
    % mtrace not empty. Read trace information.
    if bitand(stb, 2)
%         read_trace(esmb);
        fprintf('trace read\n');
    end
    
    % [bit 2] Error Queue not empty
    if bitand(stb, 4)
        response = query(esmb, 'SYST:ERR?');
        err = sscanf(response(1 : end - 2), '%d')
        if err >= 0
            fprintf("err = b'%s'\n", dec2bin(err));
        end
    end
    
    % [bit 3] QUEStionable status register summary bit
    if bitand(stb, 8)
        fprintf('quest\n');
    end
    
    % [bit 5] EVENt status register summary bit
    if bitand(stb, 32)
        fprintf('event\n');
    end
    
    % [bit 7] OPERation status register summary bit
    % scan stopped
    if bitand(stb, 128)
        fprintf('operation status\n');
%         response = query(esmb, 'STAT:OPER?');
%         opr = sscanf(response(1 : end - 2), '%d');
%         fprintf("opr = '%s'\n", dec2bin(opr));
%         
%         response = query(esmb, 'STAT:OPER:SWE?');
%         swe = sscanf(response(1 : end - 2), '%d');
%         fprintf("swe = '%s'\n", dec2bin(swe));
%         
%         response = query(esmb, 'STAT:TRAC?');
%         tra = sscanf(response(1 : end - 2), '%d');
%         fprintf("tra = '%s'\n", dec2bin(tra));
%         
%         read_trace(esmb);
%         
%         fprintf('freq scan stopped\n');
%         
%         break;
    end
    % opr = 8, operation register, bit 3, sweeping
    % swe = 2, sweeping register, bit 1, running up
    % tra = 9, trace register, bit 0, mtrace not empty, bit 3, itrace not empty
end

% fprintf('while loop exited\n');

% conversion in 50 ohm system: 
% Value in dBm = Value in dBuV - 107dB

% process trace data

% mtrace_level_dbuv
% itrace_freq_hz

fclose(esmb);

end

%%
function [] = read_trace(esmb)

% function [mtrace_level_dbuv, itrace_freq_hz] = read_trace(esmb, freq_length, sweep_count)

% response = query(esmb, 'TRAC? MTRACE')
% response = query(esmb, 'TRAC? ITRACE')

% recommend to read together m trace and i trace
response = query(esmb, 'TRAC? MTRACE;TRAC? ITRACE');
mi_trace = response(1 : end - 2);

% find trace delimter
idx = strfind(mi_trace, ';');
if isempty(idx)
    error("delimter(';') between mtrace and itrace not found");
end

% divide m trace and i trace
m_trace = mi_trace(1 : idx - 1);
i_trace = mi_trace(idx + 1: end);

% convert string to number
mtrace = str2num(m_trace);
itrace = str2num(i_trace);

% 9.9E37 means infinity value to identify range limit (see trace page in manual)
% remove 9.9E37
idx = mtrace >= 9.9E37;
mtrace = mtrace(~idx)

idx = itrace >= 9.9E37;
itrace = itrace(~idx);

if length(itrace) ~= length(mtrace) * 2
    error('itrace length must be double of mtrace length');
end

% mtrace_level_dbuv = reshape(mtrace, freq_length, sweep_count);

% i trace example: 
% itrace =
%   Columns 1 through 8
%            0   146512500           1   146525000           2   146537500           3   146550000

% remove index to get only freq
itrace = itrace(2 : 2 : end)

% freq_hz = reshape(itrace, freq_length, sweep_count);
% 
% % get only 1st column
% itrace_freq_hz = freq_hz(:, 1);

end




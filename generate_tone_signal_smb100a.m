function [] = generate_tone_signal_smb100a(freq_mhz, level_dbm, duration_sec)
% generate tone signal using smb100a(r&s signal generator).
%
% used for fsq(r&s signal analyzer) rf input to test triggered iq acquisition.
% 
% [input]
% - freq_mhz: signal freq in mhz
% - level_dbm: signal level in dbm. -145dbm ~ +30 dbm (see "smb100a data sheet")
%   max level is +20 dbm, decimal point is discarded
% - duration_sec: signal duration in sec. resolution may be 0.01 sec (matlab help "pause")
%
% [usage]
% generate_tone_signal_smb100a(95.7, -50, 1)
%

% smb100a(291700757) installed option: 
% (1) SMB-B1(OCXO Reference Oscillator) 
% (2) SMB-B112(100 kHz to 12.75 GHz, with electronic step attenuator)
%
% smb100a firmware version:
% 1406.6000k03/180218,3.1.19.15-3.20.390.24 

% it is worth to see configuration rf sweep(freq, level) signal: 'SOUR:SWE' subsystem
% for pulse modulation(strength of smb100a), SMB-K23 option is NEEDED!

% fsq rf input max = +30 dbm
max_level_dbm = 20;
if level_dbm > max_level_dbm
    fprintf('### error: max level = +%d dbm\n', max_level_dbm);
    return;
end

% smb100a signal generator ip address
ip_adr = '172.16.100.200';

% use default
tcp_port = '';
input_buffer_size = '';
time_out = '';

% get firware version and installed option. used when test first contact.
who_are_you = 0;

% connect and init r&s device
smb100a = connect_init_rs_device(ip_adr, tcp_port, input_buffer_size, time_out, who_are_you);

% % test query for system os
% response = query(smb100a, ':SYST:OSYS?');
% fprintf('os system = %s\n', response(1:end-1));

% select reference freq source to internal because default is '---' (manual page 422, right?)
fprintf(smb100a, ':ROSC:SOUR INT');

% query referenec freq source
response = query(smb100a, ':ROSC:SOUR?');
fprintf('ref freq source = %s\n', response(1:end-1));

% deactivates the output when the instrument is switched on.
% default state('*RST') is 'UNCH' (unchanged):
% restores the initial state of the RF output before the last turn off.
% sets the output status as it was when the instrument was switched off.
fprintf(smb100a, ':OUTP:PON OFF');

% query rf output state when power on
response = query(smb100a, ':OUTP:PON?');
fprintf('output when power on = %s\n', response(1:end-1));

% turn on rf signal
on_rf_output(smb100a, freq_mhz, level_dbm);

% duration resolution may be 0.01 sec (matlab help "pause")
pause(duration_sec);

% turn off rf signal
off_rf_output(smb100a);

% query event status register
response = query(smb100a, '*ESR?');
fprintf('event status register = %s\n', response(1:end-1));
% #### "no error" must be 0

% query eror/event queue and remove them from queue
response = query(smb100a, ':SYST:ERR:ALL?');
fprintf('system error = %s\n', response(1:end-1));
% #### "no error" must be 0

end

%%
function [] = on_rf_output(gen_obj, freq_mhz, level_dbm)

% signal generator default freq mode is fixed(cw), so ':FREQ:MODE CW' is not used
% default modulation state is 'ON', ':MOD OFF' is needed?
% may be not needed beacuse default state of every specific modulation(am, fm, pm) is 'OFF'

% set freq of rf signal
cmd = sprintf(':FREQ %gMHZ', freq_mhz);
fprintf(gen_obj, cmd);
% ############################
% below NOT work, dont use
% ############################
% fprintf(gen_obj, ':FREQ %gMHZ', freq_mhz);

% ############################################################################
% "help icinterface/fprintf":
%
% fprintf(OBJ,'FORMAT','CMD') writes the string CMD, to the instrument
% connected to interface object, OBJ, with the format, FORMAT. 
% By default, the %s\n FORMAT string is used. 
% The SPRINTF function is used to format the data written to the instrument.
% ############################################################################

% query freq
response = query(gen_obj, ':FREQ?');
fprintf('freq = %s hz\n', response(1:end-1));

% default state of automatic level correction is 'AUTO',
% so level correction is NOT needed

% set level of rf signal
cmd = sprintf(':POW %d', fix(level_dbm));
fprintf(gen_obj, cmd);
% ############################
% below NOT work, dont use
% ############################
% fprintf(gen_obj, ':POW %d', fix(level_dbm));

% query level
response = query(gen_obj, ':POW?');
fprintf('level = %s dbm\n', response(1:end-1));

% activates the RF output signal
fprintf(gen_obj, ':OUTP ON');

end

%% 
function [] = off_rf_output(gen_obj)

% deactivates the RF output signal
fprintf(gen_obj, ':OUTP OFF');

end

%%
function [dev_obj] = connect_init_rs_device(ip_address, tcp_port, input_buffer_size, time_out, who_are_you)
% connect and init rohde & schwarz device
%
% [input]
% - ip_address: ip address
% - tcp_port: if empty, set default(5025)
% - input_buffer_size: if empty, set default(?)
% - time_out: if empty, set default(?)

if isempty(tcp_port)
    % r&s default tcp port
    tcp_port = 5025;
end

% create tcp object
dev_obj = tcpip(ip_address, tcp_port);

if ~isempty(input_buffer_size)
    % set 'input buffer size' properties
    set(dev_obj, 'InputBufferSize', input_buffer_size);
end

if ~isempty(time_out)
    % set 'timeout'
    set(dev_obj, 'Timeout', time_out);
end

% connect with equipment
fopen(dev_obj);

% when tcp, default is 'bigEndian', so must set to 'littleEndian'
% when gpib-enet/100, default was 'littleEndian', so need not touch
set(dev_obj, 'ByteOrder', 'littleEndian');
% ByteOrder = littleEndian

if who_are_you
    % query "who are you?"
    response = query(dev_obj, '*IDN?');
    fprintf('I am %s\n', response(1:end-1));
    
    % query "which option do you have?"
    response = query(dev_obj, '*OPT?');
    fprintf('my option: %s\n', response(1:end-1));
end

% reset and clear buffer
fprintf(dev_obj, '*RST');
fprintf(dev_obj, '*CLS');

end

function [] = n5181a_generate_tone_signal(freq_mhz, level_dbm, duration_sec)
% generate tone signal using n5181a(agilent signal generator).
%
% used for fsq(r&s signal analyzer) rf input to test triggered iq acquisition.
% 
% [input]
% - freq_mhz: signal freq in mhz, max freq = 1 ghz
% - level_dbm: signal level in dbm. -110dbm ~ +10 dbm (see "n5181a data sheet")
%   max level is +10 dbm, decimal point is discarded
% - duration_sec: signal duration in sec. resolution may be 0.01 sec (matlab help "pause")
%
% [usage]
% n5181a_generate_tone_signal(95.7, -50, 1)
%

% installed option: 
% (1) 501 = Frequency range from 100 kHz to 1 GHz 
% (2) 1ER = Flexible reference input (1 to 50 MHz)
%
% firmware version: MY46241020, A.01.10
%

% fsq rf input max = +30 dbm

% n5181a max output level = +10dbm
max_level_dbm = 10;
if level_dbm > max_level_dbm
    fprintf('### error: max level = +%d dbm\n', max_level_dbm);
    return;
end

% signal generator ip address
ip_adr = '172.16.110.81';

% use default
tcp_port = '';
input_buffer_size = '';
time_out = '';

% get firware version and installed option. used when test first contact.
who_are_you = 0;

% connect and init device
n5181a = connect_init_device(ip_adr, tcp_port, input_buffer_size, time_out, who_are_you);

% query referenec freq source
response = query(n5181a, ':ROSC:SOUR?');
fprintf('ref freq source = %s\n', response(1:end-1));

% deactivates the RF output signal
fprintf(n5181a, ':OUTP OFF');

% query rf output state
response = query(n5181a, ':OUTP?');
fprintf('output state = %s\n', response(1:end-1));

% turn on rf signal
on_rf_output(n5181a, freq_mhz, level_dbm);

% duration resolution may be 0.01 sec (matlab help "pause")
pause(duration_sec);

% turn off rf signal
off_rf_output(n5181a);

% query event status register
response = query(n5181a, '*ESR?');
fprintf('##### event status register = %s\n', response(1:end-1));
% #### "no error" must be 0

fclose(n5181a);

% delete(n5181a);
% clear n5181a

% delete(instrfind)

end

%%
function [] = on_rf_output(gen_obj, freq_mhz, level_dbm)

% when query freq or level, agilent device respond with long string of numeric value
% for example, '+9.5700000000000E+07', '-5.00000000E+001'
% for agilent device, 'str2double' is used to show simple numeric value.
agilent_device = 1;

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
if agilent_device
    fprintf('freq = %d hz\n', str2double(response(1:end-1)));
else
    fprintf('freq = %s hz\n', response(1:end-1));
end

% set level of rf signal
cmd = sprintf(':POW %d', fix(level_dbm));
fprintf(gen_obj, cmd);

% query level
response = query(gen_obj, ':POW?');
if agilent_device
    fprintf('level = %d dbm\n', str2double(response(1:end-1)));
else
    fprintf('level = %s dbm\n', response(1:end-1));
end

% activates the RF output signal
fprintf(gen_obj, ':OUTP ON');

end

%% 
function [] = off_rf_output(gen_obj)

% deactivates the RF output signal
fprintf(gen_obj, ':OUTP OFF');

end

%%
function [dev_obj] = connect_init_device(ip_address, tcp_port, input_buffer_size, time_out, who_are_you)
% connect and init device
%
% [input]
% - ip_address: ip address
% - tcp_port: if empty, set default(5025)
% - input_buffer_size: if empty, set default(?)
% - time_out: if empty, set default(?)

if isempty(tcp_port)
    % r&s, agilent default tcp port
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

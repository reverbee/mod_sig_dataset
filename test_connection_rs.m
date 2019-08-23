function [] = test_connection_rs
% test connection with r&s equipment (fsq26, smu200a)
%
% [usage]
% test_connection_rs
%

% ######### connection with fsq26 (etri equipment number: 29-07-06049) ##########
% [fw verion] FSQ-26,200460/026,4.75
% [option] B4,B16,B25,B72-120,B72,K70,K100

% 26 come from fsq26
fsq_ip_address = '172.16.110.26'; 
% lucky boy, serendipitious discovery
fsq_tcp_port = 5025;

fprintf('#### connect with fsq26\n');
connect_and_query(fsq_ip_address, fsq_tcp_port);

% ######### connection with smu200a (etri equipment number: 29-07-06046) ##########
% [fw version] SMU200A,1141.2005k02/102441,2.1.96.0-02.10.111.189
% [option] SMU-B11, SMU-B13, SMU-B20, SMU-B106

% 200 come from smu200a
smu_ip_address = '172.16.100.200'; 
% lucky boy, serendipitious discovery
smu_tcp_port = 5025;

fprintf('#### connect with smu200a\n');
connect_and_query(smu_ip_address, smu_tcp_port);

% delete any remaining object
delete(instrfind);

end

%%
function [] = connect_and_query(ip_address, tcp_port)
    
% create tcp object
obj = tcpip(ip_address, tcp_port);

% ### if system_max_sample_length = 16776704, matlab error message is displayed :
% ### ??? There is not enough memory to create the inputbuffer. Try specifying a smaller value.
% ### to cure this error, more computer memory is needed
system_max_sample_length = 16776704 / 4;

% set 'input buffer size' properties
set(obj, 'InputBufferSize', system_max_sample_length * 8);
% ### 8 above line : I sample = 4 byte, Q sample = 4 byte

% set 'timeout' to 5 sec
set(obj, 'Timeout', 5);

% connect with equipment
fopen(obj);

% when tcp, default is 'bigEndian', so must set to 'littleEndian'
% when gpib-enet/100, default was 'littleEndian', so need not touch
set(obj, 'ByteOrder', 'littleEndian');
% ByteOrder = littleEndian

% query "who are you?"
response = query(obj, '*IDN?');
fprintf('i''m %s\n', response(1:end-1));

% query "which option do you have?"
response = query(obj, '*OPT?');
fprintf('my option: %s\n', response(1:end-1));

response = query(obj, '*STB?');
stb = sscanf(response(1 : end - 1), '%d');
fprintf('*STB? => %d\n', stb);

% disconnect
fclose(obj);

end





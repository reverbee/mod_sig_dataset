function [] = check_fsq_alive()

% 26 come from fsq26
fsq_ip_address = '172.16.110.26'; 
% lucky boy, serendipitious discovery
fsq_tcp_port = 5025;

% create tcp object
fsq_obj = tcpip(fsq_ip_address, fsq_tcp_port);

fopen(fsq_obj);

% Rohde&Schwarz,FSQ-26,200460/026,4.75 [firmware version = 4.75]
response = query(fsq_obj, '*IDN?');
response
if ~length(response)
    fprintf('####### fsq is dead or failed in communication\n');
end

fclose(fsq_obj);
delete(instrfind);

end

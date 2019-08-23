function [] = check_esmb_alive()

% ip adr
esmb_ip_address = '172.16.110.11'; 
% lucky boy, serendipitious discovery
% ####### esmb tcp port is NOT same as fsq
esmb_tcp_port = 5555;
% fsq_tcp_port = 5025;

% create tcp object
esmb_obj = tcpip(esmb_ip_address, esmb_tcp_port);

fopen(esmb_obj);

% Rohde&Schwarz, ESMB,100.697/002,V01.72-4055.3671.00
response = query(esmb_obj, '*IDN?');
response
if ~length(response)
    fprintf('####### esmb is dead or failed in communication\n');
end

fclose(esmb_obj);
delete(instrfind);

end

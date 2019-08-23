function [] = udp_client

delete(instrfind);

for n = 1 : 3
    remote_port = 12000;
    udp_server = udp('127.0.0.1', 'RemotePort', remote_port);
    udp_server.EnablePortSharing = 'on';
    
    fopen(udp_server);   
    
    %     fprintf('sending analyzer ready %d\n', n);
    fprintf(udp_server, 'test');
    %     fprintf(udp_server, 'analyzer ready %d', n);
    pause(3);
    
    A = fscanf(udp_server);
    A    
    
    fclose(udp_server);
    delete(udp_server);
end

% remote_port = 12000;
% udp_server = udp('127.0.0.1', 'RemotePort', remote_port);
% % udp_server.EnablePortSharing = 'on';
% 
% fopen(udp_server);
% 
% for n = 1 : 3
% %     fprintf('sending analyzer ready %d\n', n);
%     fprintf(udp_server, 'test');
% %     fprintf(udp_server, 'analyzer ready %d', n);
%     pause(3);
%     
%     A = fscanf(udp_server); 
%     A
% end
% 
% fclose(udp_server);

% fprintf('i am analyzer, talking to generator\n');

% generator = udp('127.0.0.1', 'RemotePort', 8844, 'LocalPort', 8866);
% generator.EnablePortSharing = 'on';

% fopen(generator);
% 
% for n = 1 : 3
%     fprintf('sending analyzer ready %d\n', n);
%     fprintf(generator, 'analyzer ready %d', n);
%     pause(5);

% fclose(generator);
% delete(generator);
% clear generator;

% ######### use r2017b: udp socket "enable_port_sharing" property



end

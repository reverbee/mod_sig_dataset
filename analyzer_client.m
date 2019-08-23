function [] = analyzer_client
% analyzer(fsq) is client
% generator(smb100a) is server whose code is "udp_server.py"
% also see udp client example, "udp_client.py"

generator = udp('127.0.0.1', 'RemotePort', 12000);

fopen(generator);

for n = 1 : 10
    fprintf(generator, 'ready %d', n);
    
    A = fscanf(generator);
    A
    
    pause(5);
end

end
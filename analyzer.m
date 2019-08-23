function [] = analyzer

fprintf('i am analyzer, talking to generator\n');

generator = udp('127.0.0.1', 'RemotePort', 8844, 'LocalPort', 8866);
generator.EnablePortSharing = 'on';

fopen(generator);

for n = 1 : 3
    fprintf('sending analyzer ready %d\n', n);
    fprintf(generator, 'analyzer ready %d', n);
    pause(5);

% fclose(generator);
% delete(generator);
% clear generator;

% ######### use r2017b: udp socket "enable_port_sharing" property

end
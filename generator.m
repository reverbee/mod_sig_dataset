function [] = generator

fprintf('i am generator, talking to analyzer\n');

analyzer = udp('127.0.0.1', 'RemotePort', 8866, 'LocalPort', 8844);
analyzer.EnablePortSharing = 'on';

fopen(analyzer);

for n = 1 : 3
    A = fscanf(analyzer);
    A

% fclose(analyzer);
% delete(analyzer);
% clear analyzer;

% ######### use r2017b: udp socket "enable_port_sharing" property

end
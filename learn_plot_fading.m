function [] = learn_plot_fading()

M = 8;                      % Modulation order

hMod = comm.PSKModulator(M, 'PhaseOffset', 0); % PSK Modulator System object

Rsym = 9600;                % Input symbol rate
Rbit = Rsym * log2(M);      % Input bit rate
Nos = 4;                    % Oversampling factor
ts = (1/Rbit) / Nos;        % Input sample period

v = 120 * 1e3/3600;         % Mobile speed (m/s)
fc = 1800e6;                % Carrier frequency
c = 3e8;                    % Speed of light in free space
fd = v*fc/c;                % Maximum Doppler shift of diffuse component

kFactor = 0.87/0.13;    % Note: we use the value from 3GPP TS 45.005 V7.9.0
fdLOS = 0.7 * fd;
RAx4PathDelays = [0.0 0.2 0.4 0.6] * 1e-6;
RAx4AvgPathGaindB = [0 -2 -10 -20];

chan = ricianchan(ts, fd, kFactor, RAx4PathDelays, RAx4AvgPathGaindB, fdLOS);
chan

% This setting is needed to store quantities used by the channel visualization tool.
chan.StoreHistory = 1;
% After each frame is processed, the channel is not reset: 
% this is necessary to preserve continuity across frames.
chan.ResetBeforeFiltering = 0;
% This setting makes the total average power of all path gains be equal to 1.
chan.NormalizePathGains = 1;

Nframes = 12;
Nsamples = 1e4;
for iFrames = 1:Nframes
    y = filter(chan, step(hMod, randi([0 M-1], Nsamples, 1)));
    plot(chan);
    % Select the Doppler spectrum as the current visualization.
    if iFrames == 1
        channel_vis(chan, 'visualization', 'doppler'); 
    end
%     pause(1);
end

% channel_vis(chan, 'visualization', 'scattering');
% 
% Nframes = 6;
% for iFrames = 1:Nframes
%     y = filter(chan, step(hMod, randi([0 M-1],Nsamples,1)));
%     plot(chan);
% end

end


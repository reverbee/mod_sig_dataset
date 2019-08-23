%% FM Modulate and Demodulate an Audio File
% Playback an audio file after applying FM modulation and demodulation. The 
% example takes advantage of the characteristics of System objects¢â to process 
% the data in streaming mode.
% 
% Load the audio file, |guitartune.wav|, using an audio file reader object.

AUDIO = dsp.AudioFileReader...
    ('guitartune.wav','SamplesPerFrame',4410);
%% 
% Create an audio device writer object for audio playback.
%%
AUDIOPLAYER = audioDeviceWriter;
%% 
% Create modulator and demodulator objects having default properties.
%%
MOD = comm.FMModulator;
DEMOD = comm.FMDemodulator;
%% 
% Read audio data, FM modulate, FM demodulate, and playback the demodulated 
% signal, |z|.
%%
while ~isDone(AUDIO)
    x = step(AUDIO);                      % Read audio data
    y = step(MOD,x);                      % FM modulate
    z = step(DEMOD,y);                    % FM demodulate
    step(AUDIOPLAYER,z);                  % Playback the demodulated signal
end
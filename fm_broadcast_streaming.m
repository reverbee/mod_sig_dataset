function [] = fm_broadcast_streaming
%% FM Broadcast a Streaming Audio Signal
% Modulate and demodulate a streaming audio signal with the FM broadcast modulator and demodulator objects. 
% Play the audio signal using a default audio device.
% 
% *Note*: This example runs only in R2016b or later. 
% If you are using an earlier release, replace each call to the function with the equivalent "step" syntax. 
% For example, myObject(x) becomes step(myObject,x).
% 
% Create an audio file reader System object¢â and read the file "guitartune.wav".

audio = dsp.AudioFileReader('guitartune.wav','SamplesPerFrame',4410);
%% 
% Create FM broadcast modulator and demodulator objects. 
% Set the "AudioSampleRate" property to match the sample rate of the input signal. 
% Set the "SampleRate" property of the demodulator to match the specified sample rate of the modulator. 
% Set the "PlaySound" property of the demodulator to "true" to enable audio playback.
%%
fmbMod = comm.FMBroadcastModulator('AudioSampleRate',audio.SampleRate, ...
    'SampleRate',240e3);
fmbDemod = comm.FMBroadcastDemodulator( ...
    'AudioSampleRate',audio.SampleRate, ...
    'SampleRate',240e3,'PlaySound',true);
%% 
% Read the audio data in frames of length 4410, apply FM broadcast modulation, 
% demodulate the FM signal and playback the audio input.
%%
while ~isDone(audio)
    audioData = audio();
    modData = fmbMod(audioData);
    demodData = fmbDemod(modData);
end

end

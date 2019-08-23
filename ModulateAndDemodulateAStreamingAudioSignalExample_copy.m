%% Modulate and Demodulate a Streaming Audio Signal
% Modulate and demodulate an audio signal with the FM broadcast modulator
% and demodulator objects. Plot the frequency responses of the input and
% demodulated signals.
%%
% Create an audio file reader System object(TM) and read the file
% |guitartune.wav|. Set the |SamplesPerFrame| property to include 
% the entire file.
audio = dsp.AudioFileReader('guitartune.wav','SamplesPerFrame',44100);
x = audio();
%%
% Create spectrum analyzer objects to plot the spectra of the modulated and
% demodulated signals.
SAaudio = dsp.SpectrumAnalyzer('SampleRate',44100,'ShowLegend',true, ...
    'Title','Audio Signal', ...
    'ChannelNames',{'Input Signal' 'Demodulated Signal'});
SAfm = dsp.SpectrumAnalyzer('SampleRate',152e3, ...
    'Title','FM Broadcast Signal');
%%
% Create FM broadcast modulator and demodulator objects. Set the
% |AudioSampleRate| property to match the sample rate of the input signal.
% Set the |SampleRate| property of the demodulator to match the specified
% sample rate of the modulator.
fmbMod = comm.FMBroadcastModulator('AudioSampleRate',audio.SampleRate, ...
    'SampleRate',200e3);
fmbDemod = comm.FMBroadcastDemodulator( ...
    'AudioSampleRate',audio.SampleRate,'SampleRate',200e3);
%%
% Use the |info| method to determine the audio decimation factor of the
% filter in the modulator object. The length of the
% sequence input to the object must be an integer multiple of the
% object's decimation factor.
info(fmbMod)
%%
% Use the |info| method to determine the audio decimation factor of the
% filter in the demodulator object.
info(fmbDemod)
%%
% The audio decimation factor of the modulator is a multiple of the audio
% frame length of 44100. The audio decimation factor of the demodulator is
% an integer multiple of the 200000 samples data sequence length of the
% modulator output.
%%
% Modulate the audio signal and plot its spectrum.
y = fmbMod(x);
SAfm(y)
%%
% Demodulate |y| and plot the resultant spectrum. Compare the input signal
% spectrum with the demodulated signal spectrum. The spectra are similar
% except that demodulated signal has smaller high frequency components.
z = fmbDemod(y);
SAaudio([x z])
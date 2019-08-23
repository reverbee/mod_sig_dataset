function [] = fm_comm_system_object_handel_mat
%% Create an FM Demodulator from an FM Modulator
% Create an FM demodulator System object(TM) from an FM modulator object.
% Modulate and demodulate audio data loaded from a file and compare its
% spectrum with that of the input data.
%%
% Set the example parameters.

% Copyright 2015 The MathWorks, Inc.

fd = 50e3;                               % Frequency deviation (Hz)
fs = 300e3;                              % Sample rate (Hz)
%%
% Create an FM modulator System object.
MOD = comm.FMModulator('FrequencyDeviation',fd,'SampleRate',fs);
%%
% Create a companion demodulator object based on the modulator.
DEMOD = comm.FMDemodulator(MOD);
%%
% Verify that the properties are identical in the two System objects.
MOD
DEMOD
%%
% Load audio data into structure variable, |S|.
S = load('handel.mat');
data = S.y;
fsamp = S.Fs;
%%
% Create a spectrum analyzer System object.
% SA = dsp.SpectrumAnalyzer('SampleRate',fsamp,'ShowLegend',true);
%%
% FM modulate and demodulate the audio data.

modData = MOD(data);
% modData = step(MOD,data);
demodData = DEMOD(modData);
% demodData = step(DEMOD,modData);
%%
% Verify that the spectrum plot of the input data (Channel 1) is aligned
% with that of the demodulated data (Channel 2).
% step(SA,[data demodData])


end



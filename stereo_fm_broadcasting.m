function [] = stereo_fm_broadcasting(stereo, signal_plot)
% ###### stereo channel NOT WORKING! in matlab r2017b: noisy
% ###### see spectrum of signal after modulation: bad spectrum shape
% ###### >> stereo_fm_broadcasting(1, 1)
% try next matlab version
%
% [input]
% - stereo: 1 = stereo channel, 0 = mono channel
% - signal_plot: 
%
% [usage]
% stereo_fm_broadcasting(0, 0)
% stereo_fm_broadcasting(1, 0)

% ##### 'comm.FMBroadcastModulator' system object porperties
% 'SampleRate', default = 240e3
% 'FrequencyDeviation', default = 75e3
% 'FilterTimeConstant', default = 7.5e-05
% 'AudioSampleRate', default = 48e3
% 'Stereo', default = false
% 'RBDS' (Radio Broadcast Data System), default = false
% 'RBDSSamplesPerSymbol', default = 10

% ##### 'comm.FMBroadcastDemodulator' system object porperties
% 'SampleRate', default = 240e3
% 'FrequencyDeviation', default = 75e3
% 'FilterTimeConstant', default = 7.5e-05
% 'AudioSampleRate', default = 48e3
% 'PlaySound', default = false
% 'BufferSize', default = 4096
% 'Stereo', default = false
% 'RBDS' (Radio Broadcast Data System), default = false
% 'RBDSSamplesPerSymbol', default = 10
% 'RBDSCostasLoop', default = false

%% Modulate and Demodulate a Streaming Audio Signal
% Modulate and demodulate an audio signal 
% with the FM broadcast modulator and demodulator objects. 
% Plot the frequency responses of the input and demodulated signals.
%%
wav_filename = 'never_ending_love_stereo.wav';
[x, audio_sample_rate] = audioread(wav_filename);
size(x)
max(x);

frame_length = fix(length(x) / 441 / 3);
% frame_length = fix(length(x) / 441 / 10);
if stereo
    x = x(1 : frame_length * 441, :);
else   
    x = x(1 : frame_length * 441, 1);
end
size(x)

% if use_mozart
%     wav_filename = 'mozart_mono.wav';
%     [x, audio_sample_rate] = audioread(wav_filename);
%     
%     frame_length = fix(length(x) / 441 / 10);
%     x = x(1 : frame_length * 441);
%     size(x)
% else
%     % Create an audio file reader System object(TM) and read the file "guitartune.wav".
%     % Set the "SamplesPerFrame" property to include the entire file.
%     audio = dsp.AudioFileReader('guitartune.wav','SamplesPerFrame', 44100 * 20);
%     audio_sample_rate = audio.SampleRate
%     x = audio();
% end
length(x)
size(x, 1)

% return;

% if signal_plot
%     fs = 200e3; title_text = 'audio file';
%     plot_signal(x, audio_sample_rate, title_text);
% end
%%
% % Create spectrum analyzer objects 
% % to plot the spectra of the modulated and demodulated signals.
% SAaudio = dsp.SpectrumAnalyzer('SampleRate',44100,'ShowLegend',true, ...
%     'Title','Audio Signal', ...
%     'ChannelNames',{'Input Signal' 'Demodulated Signal'});
% SAfm = dsp.SpectrumAnalyzer('SampleRate',152e3, ...
%     'Title','FM Broadcast Signal');
%%
% Create FM broadcast modulator and demodulator objects. 
% Set the "AudioSampleRate" property to match the sample rate of the input signal.
% Set the "SampleRate" property of the demodulator 
% to match the specified sample rate of the modulator.
if stereo
    fmbMod = comm.FMBroadcastModulator('AudioSampleRate',audio_sample_rate, ...
        'SampleRate',200e3,'Stereo',true);
    fmbDemod = comm.FMBroadcastDemodulator('AudioSampleRate',audio_sample_rate, ...
        'SampleRate',200e3,'Stereo',true);
else
    fmbMod = comm.FMBroadcastModulator('AudioSampleRate',audio_sample_rate, ...
        'SampleRate',200e3);
    fmbDemod = comm.FMBroadcastDemodulator('AudioSampleRate',audio_sample_rate, ...
        'SampleRate',200e3);
end
%%
% Use the "info" method to determine the audio decimation factor of the filter in the modulator object. 
% The length of the sequence input to the object must be an integer multiple of the object's decimation factor.
info(fmbMod)
%%
% Use the "info" method to determine the audio decimation factor of the filter in the demodulator object.
info(fmbDemod)
%%
% The audio decimation factor of the modulator is a multiple of the audio frame length of 44100. 
% The audio decimation factor of the demodulator is
% an integer multiple of the 200000 samples data sequence length of the modulator output.
%%
% Modulate the audio signal and plot its spectrum.
y = fmbMod(x);
size(y)
% SAfm(y)
min(abs(y))
max(abs(y))

if signal_plot
    fs = 200e3; title_text = 'after modulation';
    plot_signal(y(4096:4096 * 10), fs, title_text);
end
%%
% Demodulate "y" and plot the resultant spectrum. 
% Compare the input signal spectrum with the demodulated signal spectrum. 
% The spectra are similar except that demodulated signal has smaller high frequency components.
z = fmbDemod(y);
size(z)
% SAaudio([x z])

if signal_plot
    fs = 200e3; title_text = 'after demodulation';
    plot_signal(z, fs, title_text);
end

soundsc(z, audio_sample_rate);

end

% %%
% function [iq] = clip_by_decimation(iq, audio_decimation_factor)
% 
%     audio_decimation_factor = lcm(441, 2000);
%     
% %     audio_decimation_factor = lcm(audio_decimation_factor, 760)
% %     audio_decimation_factor = 19000; % 19000 = lcm(125, 760)
%     
%     size(iq)
%     frame_length = fix(length(iq) / audio_decimation_factor);
%     iq = iq(1 : frame_length * audio_decimation_factor);
%     size(iq)
% 
% end


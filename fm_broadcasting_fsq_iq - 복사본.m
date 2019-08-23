function [] = fm_broadcasting_fsq_iq(mat_filename, stereo_iq, use_mozart, signal_plot)

% [usage]
% fm_broadcasting_fsq_iq('', 1, 1, 0)
% fm_broadcasting_fsq_iq('E:\fsq_iq\data\fsq_iq_180713140446_95.7_0.16_0.2.mat', 1, 0, 0)
% fm_broadcasting_fsq_iq('E:\fsq_iq\data\fsq_iq_180713140113_97.5_0.16_0.2.mat', 1, 0, 0)

% ### good to use below: very weak signal with poor rx antenna, but give good sound
% sound_fm_broadcasting('E:\fsq_iq\data\fsq_iq_180706164550_98.5_0.2_0.25.mat')

% ##### 'comm.FMBroadcastModulator' system object properties
% 'SampleRate', default = 240e3
% 'FrequencyDeviation', default = 75e3
% 'FilterTimeConstant', default = 7.5e-05
% 'AudioSampleRate', default = 48e3
% 'Stereo', default = false
% 'RBDS' (Radio Broadcast Data System), default = false
% 'RBDSSamplesPerSymbol', default = 10

% ##### 'comm.FMBroadcastDemodulator' system object properties
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

if ~isempty(mat_filename)
    % % #### reminding
    % % save iq into file
    % save(filename, 'iq', 'center_freq_mhz', 'signal_bw_mhz', 'sample_rate_mhz', 'sample_length');
    
    load(mat_filename);
    size(iq)
    
    % when sample length > 2^19, original iq will be replaced
    % see fig 6.3 in fsq manual 
    % "Blockwise transmission with data volumes exceeding 512k words"
    % i suspect "TRAC:IQ:DATA:FORMat COMPatible | IQBLock | IQPair" is right
    [iq] = reverse_pack_fsq_iq(mat_filename);
    
    audio_sample_rate = 44100;
    sample_rate = sample_rate_mhz * 1e6;
    
    if signal_plot
        title_text = 'from fsq26';
        plot_signal(iq, sample_rate, title_text);
    end
    
    if stereo_iq
        fmbDemod = comm.FMBroadcastDemodulator('AudioSampleRate',audio_sample_rate,...
            'SampleRate',sample_rate,'Stereo',true);
    else
        fmbDemod = comm.FMBroadcastDemodulator('AudioSampleRate',audio_sample_rate,...
            'SampleRate',sample_rate);
    end
    D = info(fmbDemod);
    D
    
    % lcm (least common multiple)
    % 441 from 44100 (audio sample rate), 2000 from 200000 (iq sample rate)
    audio_decimation_factor = lcm(441, 2000);
    
    iq = clip_by_decimation(iq, audio_decimation_factor);
    size(iq)
    max(abs(iq))
    min(abs(iq))
    
%     % normalize
%     iq = iq / max(abs(iq));
%     max(abs(iq))
%     min(abs(iq))
    
    z = fmbDemod(iq);
    size(z)
    
    soundsc(z, audio_sample_rate);
    
    if signal_plot
        title_text = 'after demod';
        plot_signal(z, sample_rate, title_text);
    end
    
%     plot_filter_response = 0;
%     signal_bw_mhz = 0.015 * 2; % filter input is real, so '*2' is needed
%     z_mono = filter_iq(z, signal_bw_mhz, sample_rate_mhz, plot_filter_response);
%     size(z_mono)
%     if size(z_mono, 2) >= 2
%         sum(z_mono(:, 1) - z(:, 2))
%     end
%         
%     if signal_plot
%         title_text = 'after filter';
%         plot_signal(z_mono, sample_rate, title_text);
%     end
%     
%     soundsc(z_mono, audio_sample_rate);
    
    return;
end

%% Modulate and Demodulate a Streaming Audio Signal
% Modulate and demodulate an audio signal 
% with the FM broadcast modulator and demodulator objects. 
% Plot the frequency responses of the input and demodulated signals.
%%
if use_mozart
    wav_filename = 'mozart_mono.wav';
    [x, audio_sample_rate] = audioread(wav_filename);
    
    % ##### there is length limit in input of fmbMod ("comm.FMBroadcastModulator" system object)
    % ##### when 'mozart_mono.wav', 'length(x) / 441 / 6' is good, 'length(x) / 441 / 5' is bad
    frame_length = fix(length(x) / 441 / 6);
    x = x(1 : frame_length * 441);
    size(x)
else
    % Create an audio file reader System object(TM) and read the file "guitartune.wav".
    % Set the "SamplesPerFrame" property to include the entire file.
    audio = dsp.AudioFileReader('guitartune.wav','SamplesPerFrame', 44100 * 20);
    audio_sample_rate = audio.SampleRate
    x = audio();
end
x_length = length(x)

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
fmbMod = comm.FMBroadcastModulator('AudioSampleRate',audio_sample_rate, ...
    'SampleRate',200e3);
% fmbMod = comm.FMBroadcastModulator('AudioSampleRate',audio_sample_rate, ...
%     'SampleRate',200e3,'Stereo',true);
fmbDemod = comm.FMBroadcastDemodulator('AudioSampleRate',audio_sample_rate, ...
    'SampleRate',200e3);
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
% %     audio_decimation_factor = lcm(441, 2000);
%     
% %     audio_decimation_factor = lcm(audio_decimation_factor, 760)
% %     audio_decimation_factor = 19000; % 19000 = lcm(125, 760)
%     
%     size(iq);
%     frame_length = fix(length(iq) / audio_decimation_factor);
%     iq = iq(1 : frame_length * audio_decimation_factor);
%     size(iq);
% 
% end


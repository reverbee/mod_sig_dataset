function [] = study_fm_broadcasting_fsq_iq(mat_filename, signal_plot_length, sound_audio)
% study fm broadcasting iq read from mat file which is saved using "get_iq_from_fsq.m"
% (1) extract and sound audio
% (2) plot multiplex baseaband signal spectrum
% 
% ###### matlab version MUST be r2017a or above
%
% [input]
% - mat_filename:
% - signal_plot_length: less than 2^8 = no plot, '' = plot all signal
% - sound_audio: 0 = no sound, 1 = mono sound, 2 = stereo sound
%
% [usage]
% study_fm_broadcasting_fsq_iq('E:\fsq_iq\data\fsq_iq_180713140446_95.7_0.16_0.2.mat', 2^10, 2)
% study_fm_broadcasting_fsq_iq('E:\fsq_iq\data\fsq_iq_180713140113_97.5_0.16_0.2.mat', '', 1)
% study_fm_broadcasting_fsq_iq('E:\fsq_iq\data\fsq_iq_180711170430_97.5_0.16_0.2.mat', 2^16, 2)

% [reference]
% https://kr.mathworks.com/help/comm/ref/comm.fmbroadcastmodulator-system-object.html

min_signal_plot_length = 2^8;

% % #### reminding, see "get_iq_from_fsq.m"
% % save iq into file
% save(filename, 'iq', 'center_freq_mhz', 'signal_bw_mhz', 'sample_rate_mhz', 'sample_length');
load(mat_filename);
% sure shot for column vector, "get_iq_from_fsq.py" save iq array with row vector format
iq = iq(:);
size(iq);
fprintf('sample length = %d\n', sample_length);

% if sound_audio && round(sample_rate_mhz * 1e6) ~= 200e3
%     fprintf('##### error: iq sample rate must be 200 khz for sound audio\n');
%     return;
% end

% ########### MUST NOT USE after 180801 ############
% when sample length > 2^19, original iq will be replaced
% see fig 6.3 in fsq manual
% "Blockwise transmission with data volumes exceeding 512k words"
% i suspect "TRAC:IQ:DATA:FORMat COMPatible | IQBLock | IQPair" is right
% [iq] = reverse_pack_fsq_iq(mat_filename);

max(abs(iq))
min(abs(iq))

% ####### 'AudioSampleRate' in 'comm.FMBroadcastDemodulator' system object, default = 48e3
audio_sample_rate = 48e3;
% audio_sample_rate = 44100;
sample_rate = round(sample_rate_mhz * 1e6)

if sound_audio
    
    % lcm (least common multiple)
    % 48 from 48e3 (audio sample rate)
    audio_decimation_factor = lcm(48, sample_rate / 1e3);
    % 48 from 48e3 (audio sample rate), 200 from 200e3 (iq sample rate)
%     audio_decimation_factor = lcm(48, 200);
%     audio_decimation_factor = lcm(441, 2000);
    
    % #### there is special condition for sample length (why?)
    iq = clip_by_decimation(iq, audio_decimation_factor);
    fprintf('after clipping, sample length = %d\n', length(iq));
    
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
    
    % create fm broadcast demodulator
    if sound_audio == 2
        fmbDemod = comm.FMBroadcastDemodulator('AudioSampleRate',audio_sample_rate,...
            'SampleRate',sample_rate,'Stereo',true);
    else
        fmbDemod = comm.FMBroadcastDemodulator('AudioSampleRate',audio_sample_rate,...
            'SampleRate',sample_rate);
    end
    
    D = info(fmbDemod);
    
    % get audio signal from fsq iq
    z = fmbDemod(iq);
    size(z)
    
    soundsc(z, audio_sample_rate);
    
end

if isempty(signal_plot_length) || signal_plot_length >= min_signal_plot_length
    
    if ~isempty(signal_plot_length)
        if signal_plot_length > sample_length
            signal_plot_length = sample_length;
        end
            
        iq = iq(1 : signal_plot_length);
    end
    
    title_text = 'before fm demod';
    plot_signal(iq, sample_rate, title_text);
    
    % ##### 'comm.FMDemodulator' system object properties
    % 'FrequencyDeviation', default = 75e3
    % 'SampleRate', default = 240e3
    
    % create fm demodulator
    freq_dev = 75e3;
    fmDemod = comm.FMDemodulator('FrequencyDeviation', freq_dev, 'SampleRate', sample_rate);
    
    % fm demodulate
    z = fmDemod(iq);

    title_text = 'after fm demod';
    plot_signal(z, sample_rate, title_text);
    
end

end




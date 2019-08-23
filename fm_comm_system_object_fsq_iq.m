function [] = fm_comm_system_object_fsq_iq(mat_filename, signal_plot)
% demodulation of fm broadcasting signal using comm system object
% ##### only good from r2016b communication system toolbox
%
% [input]
% - mat_filename: iq sample filename, which is created by "get_iq_from_fsq.m"
%
% [usage]
% fm_comm_system_object_fsq_iq('E:\fsq_iq\data\fsq_iq_180713140113_97.5_0.16_0.2.mat', 0)
%
 
% see carson's rule, https://en.wikipedia.org/wiki/Frequency_modulation
% fm_bandwidth = 2 * (freq_dev + max_freq_of_source_signal)
% fm modulation index = freq_dev / max_freq_of_source_signal

% ##### wide band fm (large freq deviation) example: fm radio broadcasting
% max_freq_of_source_signal = 15e3, freq_dev = 75e3 (modulation index = 5)
% occupied(98%) fm_bandwidth = 180e3

% ##### narrow band fm (small freq devation) example: 
% max_freq_of_source_signal = 5e3, freq_dev = 1e3 (modulation index = 0.2)
% occupied(98%) fm_bandwidth = 12e3

% % #### reminding what mat file have
% % save iq into file
% save(filename, 'iq', 'center_freq_mhz', 'signal_bw_mhz', 'sample_rate_mhz', 'sample_length');

load(mat_filename);
size(iq)

% when sample length > 2^19, original iq will be replaced
% see fig 6.3 in fsq manual
% "Blockwise transmission with data volumes exceeding 512k words"
% i suspect "TRAC:IQ:DATA:FORMat COMPatible | IQBLock | IQPair" is right
[iq] = reverse_pack_fsq_iq(mat_filename);

max(iq)
min(iq)

audio_sample_rate = 44100;
sample_rate = sample_rate_mhz * 1e6;

if signal_plot
    title_text = 'iq';
    plot_signal(iq, sample_rate, title_text);
end

freq_dev = 75e3;

DEMOD = comm.FMDemodulator('FrequencyDeviation', freq_dev, 'SampleRate', sample_rate);

% fm demodulation
z = DEMOD(iq);
% whos;

if signal_plot
    title_text = 'after freq demod';
    plot_signal(z, sample_rate, title_text);
end

plot_filter_response = 0;
signal_bw_mhz = 0.015 * 2; % filter input is real, so '*2' is needed
z_mono = filter_iq(z, signal_bw_mhz, sample_rate_mhz, plot_filter_response);

if signal_plot
    title_text = 'after filter';
    plot_signal(z_mono, sample_rate, title_text);
end

% play sound
soundsc(z_mono, audio_sample_rate);
% to stop sound, use "clear sound" command

end


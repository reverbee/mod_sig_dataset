function [carrier_freq_offset] = estimate_fm_broadcasting_carrier_freq_offset(mat_filename, signal_plot)
% ######### dont show what i want to see
% ######### i expected freq spectrum of stereo pilot is outstanding peak
%
% [usage]
% estimate_fm_broadcasting_carrier_freq_offset('E:\fsq_iq\data\fsq_iq_180713140113_97.5_0.16_0.2.mat', 1);
%
% [reference]
% https://kr.mathworks.com/help/comm/ref/comm.fmbroadcastmodulator-system-object.html
%

% mono audio left + right: 0 ~ 15e3
% stereo pilot: 19e3 (15e3 ~ 23e3)
% stereo audio left - right: amsc(am suppressed carrier), 23e3 ~ 38e3(lower), 38e3 ~ 53e3(upper)
% rdbs: amsc, center = 57e3

carrier_freq_offset = [];

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

freq_dev = 75e3;
sample_rate = sample_rate_mhz * 1e6;
DEMOD = comm.FMDemodulator('FrequencyDeviation', freq_dev, 'SampleRate', sample_rate);

z = DEMOD(iq);

if signal_plot
    title_text = 'after demod';
    plot_signal(z, sample_rate, title_text);
end

return;

audio_sample_rate = 44100;
sample_rate = sample_rate_mhz * 1e6;

fmbDemod = comm.FMBroadcastDemodulator('AudioSampleRate',audio_sample_rate,...
    'SampleRate',sample_rate);
D = info(fmbDemod);

% lcm (least common multiple)
% 441 from 44100 (audio sample rate), 2000 from 200000 (iq sample rate)
audio_decimation_factor = lcm(441, 2000);

iq = clip_by_decimation(iq, audio_decimation_factor);
size(iq)
max(abs(iq));
min(abs(iq));

z = fmbDemod(iq);

if signal_plot
    title_text = 'after demod';
    plot_signal(z, sample_rate, title_text);
end

% stereo pilot is freq down converted to baseband
fc = 19e3; % stereo pilot freq
t = (0 : length(z) - 1)' / sample_rate;
z = z .* exp(-1i * 2 * pi * fc * t);

plot_filter_response = 0;
signal_bw_mhz = 0.002; 
% signal_bw_mhz = 0.004;
% signal_bw_mhz = 0.008; 
% signal_bw_mhz = 0.015 * 2; % filter input is real, so '*2' is needed
stereo_pilot = filter_iq(z, signal_bw_mhz, sample_rate_mhz, plot_filter_response);

if signal_plot
    title_text = 'stereo pilot';
    plot_signal(stereo_pilot, sample_rate, title_text);
end

end

%%
function [iq] = clip_by_decimation(iq, audio_decimation_factor)

%     audio_decimation_factor = lcm(441, 2000);
    
%     audio_decimation_factor = lcm(audio_decimation_factor, 760)
%     audio_decimation_factor = 19000; % 19000 = lcm(125, 760)
    
    size(iq);
    frame_length = fix(length(iq) / audio_decimation_factor);
    iq = iq(1 : frame_length * audio_decimation_factor);
    size(iq);

end

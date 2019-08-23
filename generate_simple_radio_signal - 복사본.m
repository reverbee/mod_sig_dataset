function [] = generate_simple_radio_signal(snr_db)
% generate simple radio signal given snr
% 
% [usage]
% generate_simple_radio_signal(10)
%

freq_dev = 2.5e3;
fs = 15e3;

% ###########################################################
% below value is got from fm demoded signal plot:
% "remove_no_signal_simple_radio('E:\iq_from_fsq\simple\fsq_iq_190102133150_146.512500_0.008500_0.015000.mat',.1, 0)"
% #########################################################

mean_talk_duration = 7;
std_talk_duration = 2;

% no signal section, pause between talk
mean_pause_duration = 4;
std_pause_duration = 1;

max_dtmf_code_num = 4;

dtmf_code_duration = .05;
dtmf_magnitude_ratio_to_talk = .7;

mute_after_dtmf_code = .05;
mute_before_talk = .15;
min_mute_after_talk = .2; % #### mute_after_talk is variable, always greater than this

% must be equal to or greater than max_dtmf_code_num, see "randperm"
% when 4, dtmf code = 0 ~ 3
max_dtmf_code = 4;

% [ref] http://mmi-comm.tripod.com/dcs.html
dcs_code_freq = 134.3;
dcs_turn_off_code_duration = .18;
dcs_turn_off_code_freq = 268.6;
dcs_magnitude_ratio_to_talk = .15;
dcs_turn_off_magnitude_ratio_to_talk = .1;

% downloaded from "http://www.podbbang.com/ch/13909"
% processed using "mp3_to_wav.m"
% duration = 476.5662 sec
audio_filename = 'marquez_part.wav';

% read talk signal into x
[x, audio_fs] = audioread(audio_filename);

A = audioinfo(audio_filename);
% max_talk_num = fix(A.Duration / mean_talk_duration) - 10; % 10 is margin

% get dcs turn off code signal, this is all same for each talk
plot_signal = 0;
[dcs_turn_off_code_signal] = ...
    make_dcs_turn_off_code_signal(dcs_turn_off_code_duration, dcs_turn_off_code_freq, audio_fs, plot_signal);
% dcs_turn_off_code_signal: column vector

% comm.FMModulator default: 'FrequencyDeviation', 75e3, 'SampleRate', 240e3
fm_mod = comm.FMModulator('FrequencyDeviation', freq_dev, 'SampleRate', fs);

% comm.FMDemodulator default: 'FrequencyDeviation', 75e3, 'SampleRate', 240e3
fm_demod = comm.FMDemodulator('FrequencyDeviation', freq_dev, 'SampleRate', fs);

talk_signal_idx = 1;

simple_radio_signal = [];

max_talk_num = fix(A.Duration / mean_talk_duration) - 10; % 10 is margin
max_talk_num = 2; % this is good?

for n = 1 : max_talk_num
    
    % dtmf_code_num = 2 ~ max_dtmf_code_num
    dtmf_code_num = randi([2, max_dtmf_code_num]);
    
    % dtmf code
    dtmf_code = randperm(max_dtmf_code, dtmf_code_num) - 1;
    
    % talk duration 
    talk_duration = mean_talk_duration + std_talk_duration * randn(1);
    if talk_duration <= 0
        talk_duration = mean_talk_duration;
    end
    
    % ##### below "dcs_signal_duration" NOT include dcs turn off code signal
    dcs_signal_duration = dtmf_code_num * (dtmf_code_duration + mute_after_dtmf_code) + ...
        mute_before_talk + talk_duration + min_mute_after_talk;
    
    % make 23-bit dcs word signal
    plot_signal = 0;
    dcs_word_signal = make_23bit_dcs_word_signal(dcs_code_freq, audio_fs, plot_signal);
    % dcs_word_signal: column vector
    
    % get dcs word number
    dcs_word_num = round(dcs_signal_duration * audio_fs / length(dcs_word_signal));
    
    % repeat dcs word signal for "dcs_word_num" times,
    % append dcs turn off code signal,
    % and apply dcs magnitude ratio to talk
    dcs_signal = [dcs_magnitude_ratio_to_talk * repmat(dcs_word_signal, dcs_word_num, 1); ...
        dcs_turn_off_magnitude_ratio_to_talk * dcs_turn_off_code_signal];
    dcs_signal_len = length(dcs_signal);
    
    dtmf_signal_array = make_dtmf_code_signal(dtmf_code, dtmf_code_duration, audio_fs);
    % dtmf_signal_array: dimension = sample_length_per_dtmf_code x dtmf_code_num
    
    % apply ratio
    dtmf_signal_array = dtmf_magnitude_ratio_to_talk * dtmf_signal_array;
    
    % position dtmf array into signal stream
    dtmf_signal = ...
        position_dfmf_signal(dtmf_signal_array, mute_after_dtmf_code, audio_fs, dcs_signal_len);
    
    talk_signal_len = round(talk_duration / audio_fs);
    
    talk_signal_x = x(talk_signal_idx : talk_signal_idx + talk_signal_len - 1);
    
    duration_before_talk = dtmf_code_num * (dtmf_code_duration + mute_after_dtmf_code) + ...
        mute_before_talk;
    
    % position talk signal from x into signal stream
    talk_signal = ...
        position_talk_signal(talk_signal_x, duration_before_talk, audio_fs, dcs_signal_len);
    
    talk_signal_idx = talk_signal_idx + talk_signal_len;
    
    simple_signal = dcs_signal + dtmf_signal + talk_signal;
    
    % fm modulation
    y = fm_mod(simple_signal);
    
    % #### set random attenuation ####
    
    % apply fading channel
    if ~isempty(channel_type)
        pre_iq = apply_fading_channel(pre_iq, channel_type, channel_fs_hz, fd);
    end
    
    % apply carrier offset
    if max_freq_offset_hz || max_phase_offset_deg
        pre_iq = apply_carrier_offset(pre_iq, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg);
    end
    
    % add awgn noise to signal
    if ~isempty(snr_db)
        pre_iq = awgn(pre_iq, snr_db, 'measured', 'db');
    end
    
    pause_duration = mean_pause_duration + std_pause_duration * randn(1);
    if pause_duration <= 0
        pause_duration = mean_pause_duration;
    end
    
    pause_signal_len = round(pause_duration / fs);
    pause_signal = zeros(pause_signal_len, 1);
    
    % #### awgn: which is right: inside or outside for loop
%     y = awgn(y, snr_db, 'measured', 'db');
    
end

y = awgn(y, snr_db, 'measured', 'db');



end

%%
function [talk_signal] = ...
    position_talk_signal(talk_signal_x, duration_before_talk, audio_fs, dcs_signal_len)
    
talk_signal = zeros(dcs_signal_len, 1);

talk_signal_x_length = length(talk_signal_x);

idx = round(duration_before_talk * audio_fs);

talk_signal(idx : idx + talk_signal_x_length - 1) = talk_signal_x;  
    
end

%%
function [dtmf_signal] = ...
    position_dfmf_signal(dtmf_signal_array, mute_after_dtmf_code, audio_fs, dcs_signal_len)

dtmf_signal = zeros(dcs_signal_len, 1);

[sample_length_per_dtmf_code, dtmf_code_length] = size(dtmf_signal_array);

mute_sample_length = round(mute_after_dtmf_code * audio_fs);

idx = 1;
for n = 1 : dtmf_code_length
    dtmf_signal(idx : sample_length_per_dtmf_code) = dtmf_signal_array(:, n);
    
    idx = idx + mute_sample_length;
end

end

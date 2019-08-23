function [iq, freq_dev, fs, talk_duration, stop_pause_duration] = ...
    generate_simple_radio_signal(snr_db, save_signal)
% generate simple radio signal given snr
% #### simplified code (190226) 
% original, incomplete code: see "- copy.m"
% 
% [usage]
% generate_simple_radio_signal(10, 1)
%

% save_signal = 1;

fm_mod_input_signal_plot = 0;
fm_mod_output_signal_plot = 0;
fm_demod_output_signal_plot = 0;
sound_audio = 0;

freq_dev = 2.5e3;

% fm modulator input sample rate.
% must be one of 11025(= 44100 / 4), 14700(= 44100 / 3).
% audio sample rate = 44100
% fsq bw = sample_rate * .8 (11025 * .8 = 8820, 14700 * .8 = 11760)
fs = 14700;

% most audio sample rate: 44100
audio_fs = 44100;
if mod(audio_fs, fs)
    fprintf('##### assumed audio fs = 44100, ''fs'' must be one of 11025, 14700\n');
    return;
end

% downloaded from "http://www.podbbang.com/ch/13909"
% processed using "mp3_to_wav.m"
% duration = 476.5662 sec
audio_filename = 'marquez_part.wav';
A = audioinfo(audio_filename);
total_sample = A.TotalSamples;
if A.SampleRate ~= audio_fs
    fprintf('##### audio fs from "audioinfo" is NOT %d', audio_fs);
    return;
end

channel_type = 'gsmRAx4c2';
channel_fs_hz = fs;
% channel doppler freq
fd = 0;

max_freq_offset_hz = 100;
max_phase_offset_deg = 180;

% comm.FMModulator default: 'FrequencyDeviation', 75e3, 'SampleRate', 240e3
fm_mod = comm.FMModulator('FrequencyDeviation', freq_dev, 'SampleRate', fs);

% comm.FMDemodulator default: 'FrequencyDeviation', 75e3, 'SampleRate', 240e3
fm_demod = comm.FMDemodulator('FrequencyDeviation', freq_dev, 'SampleRate', fs);

% ###########################################################
% below value is got from fm demoded signal plot:
% "remove_no_signal_simple_radio('E:\iq_from_fsq\simple\fsq_iq_190102133150_146.512500_0.008500_0.015000.mat',.1, 0)"
% #########################################################

% not average talk duration, set enough to train signal
talk_duration = 7;

% no signal section, not average pause duration, set enough to train signal
% pause before talk
start_pause_duration = .5;
% pause after talk
stop_pause_duration = .5;

% dtmf code number, fixed for easy coding, can be variable
dtmf_code_num = 3;
dtmf_code_duration = .05;
dtmf_magnitude_ratio_to_talk = .5; % .7 = too large sound
mute_after_dtmf_code = .05;

mute_before_talk = .15;
min_mute_after_talk = .2; % #### mute_after_talk is variable, always greater than this

% [ref] http://mmi-comm.tripod.com/dcs.html
dcs_code_freq = 134.3;
dcs_turn_off_code_duration = .18;
dcs_turn_off_code_freq = 268.6;
dcs_magnitude_ratio_to_talk = .15;
dcs_turn_off_magnitude_ratio_to_talk = .1;

% ######### simple radio signal timing ##########################################################
% (1) dtmf_code_duration: 50 msec 
% (2) mute_after_dtmf_code: 50 msec
% (3) mute_before_talk: ~150 msec
% (4) talk_duration: variable by talker
% (5) mute_after_talk: greater than min_mute_after_talk to make multiple 23-bit dcs word
%     min_mute_after_talk: ~200 msec
% (6) dcs_turn_off_code_duration: 180 msec
%
% dcs_signal_duration = dtmf_code_number * ((1) + (2)) + (3) + (4) + (5) + (6)
%
% simple radio signal duration is SAME as dcs signal duration
% ########################################################################################

% ######### dcs signal ########

% make 23-bit dcs word signal
plot_sig = 0;
dcs_word_signal = make_23bit_dcs_word_signal(dcs_code_freq, fs, plot_sig);
% dcs_word_signal: column vector

% make dcs turn off code signal
plot_sig = 0;
dcs_turn_off_code_signal = ...
    make_dcs_turn_off_code_signal(dcs_turn_off_code_duration, dcs_turn_off_code_freq, fs, plot_sig);
% dcs_turn_off_code_signal: column vector

% below NOT include dcs turn off code signal
dcs_signal_duration_except_turn_off_code = ...
    dtmf_code_num * (dtmf_code_duration + mute_after_dtmf_code) + ...
    mute_before_talk + talk_duration + min_mute_after_talk;

% get dcs word number
dcs_word_num = ...
    round(dcs_signal_duration_except_turn_off_code * fs / length(dcs_word_signal));

% repeat dcs word signal for "dcs_word_num" times,
% append dcs turn off code signal,
% and apply dcs magnitude ratio to talk
dcs_signal = [dcs_magnitude_ratio_to_talk * repmat(dcs_word_signal, dcs_word_num, 1); ...
    dcs_turn_off_magnitude_ratio_to_talk * dcs_turn_off_code_signal];
dcs_signal_len = length(dcs_signal);

% plot_signal_time_domain(dcs_signal, fs, 'dcs signal');

% ######### talk signal #########

% compute talk signal length
talk_signal_len = round(talk_duration * audio_fs);

% read audio signal into "talk_signal_x"
start_idx = randi(total_sample - talk_signal_len - 1);
stop_idx = start_idx + talk_signal_len - 1;
[talk_signal_x, ~] = audioread(audio_filename, [start_idx, stop_idx]);

% decimate audio signal
decimation_rate = audio_fs / fs;
talk_signal_x = decimate(talk_signal_x, decimation_rate);

% plot_signal_time_domain(talk_signal_x, fs, 'talk signal');

% position "talk_signal_x" into dcs signal stream
duration_before_talk = dtmf_code_num * (dtmf_code_duration + mute_after_dtmf_code) + ...
    mute_before_talk;
talk_signal = ...
    position_talk_signal(talk_signal_x, duration_before_talk, fs, dcs_signal_len);

% plot_signal_time_domain(talk_signal, fs, 'positioned talk signal');

% ###### dtmf signal #######
    
% generate dtmf code
dtmf_code = randperm(dtmf_code_num) - 1;

% generate dtmf code signal
plot_sig = 0;
dtmf_signal_x = make_dtmf_code_signal(dtmf_code, dtmf_code_duration, fs, plot_sig);
% dtmf_signal_x: dimension = sample_length_per_dtmf_code x dtmf_code_num

% apply ratio
dtmf_signal_x = dtmf_magnitude_ratio_to_talk * dtmf_signal_x;

% position "dtmf_signal_x" into dcs signal stream
dtmf_signal = ...
    position_dfmf_signal(dtmf_signal_x, mute_after_dtmf_code, fs, dcs_signal_len);

% plot_signal_time_domain(dtmf_signal, fs, 'positioned dtmf signal');

% ####### add all signal (dcs signal, dtmf signal, talk signal)

y = dcs_signal + dtmf_signal + talk_signal;

if fm_mod_input_signal_plot
    plot_signal_time_domain(y, fs, '[simple radio] fm mod input');
end

% fm modulation
iq = fm_mod(y);

% apply fading channel
if ~isempty(channel_type)
    iq = apply_fading_channel(iq, channel_type, channel_fs_hz, fd);
end

% apply carrier offset
if max_freq_offset_hz || max_phase_offset_deg
    iq = apply_carrier_offset(iq, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg);
end

start_pause_signal = zeros(round(start_pause_duration * fs), 1);
stop_pause_signal = zeros(round(stop_pause_duration * fs), 1);

iq = [start_pause_signal; iq; stop_pause_signal];

% add awgn noise to signal
iq = awgn(iq, snr_db, 'measured', 'db');

% normalize
iq = iq / max(abs(iq));
size(iq)

if fm_mod_output_signal_plot
    plot_signal_time_domain(iq, fs, '[simple radio] fm mod output');
end

% fm demod
z = fm_demod(iq);

if fm_demod_output_signal_plot
    plot_signal_time_domain(z, fs, '[simple radio] fm demod output');
end

if sound_audio
    soundsc(z, fs);
end

if save_signal
    signal_filename = sprintf('simpe_radio_snr%d_fd%d_fs%d_talk%g_pause%g.mat', ...
        snr_db, freq_dev, fs, talk_duration, stop_pause_duration);
    save(signal_filename, 'iq', 'snr_db', 'freq_dev', 'fs', 'talk_duration', 'stop_pause_duration');
    
    fprintf('### [snr %d db] signal saved into ''%s'' file\n', snr_db, signal_filename);
end

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
    position_dfmf_signal(dtmf_signal_x, mute_after_dtmf_code, fs, dcs_signal_len)

dtmf_signal = zeros(dcs_signal_len, 1);

[sample_length_per_dtmf_code, dtmf_code_length] = size(dtmf_signal_x);

mute_sample_length = round(mute_after_dtmf_code * fs);

mute_signal = repmat(zeros(mute_sample_length, 1), 1, dtmf_code_length);

% vertical stack
dtmf_signal_x = [dtmf_signal_x; mute_signal];

% change array into column vector
dtmf_signal_x = dtmf_signal_x(:);

x_length = length(dtmf_signal_x);

dtmf_signal(1 : x_length) = dtmf_signal_x;

end

function [] = ...
    generate_modulation_signal_cnn_train_set(signal_dir_name, instance_length, ...
    mat_filename_append_string, sample_per_symbol)
% generate modulation signal for cnn model train and save into mat file
%
% modified from "inf_snr_generate_modulation_signal_single_mat.m"
% #######################################################################
% differ from "inf_snr_generate_modulation_signal_single_mat.m":
% (1) set fsk modulation index to small value to simulate digital simple radio signal 
%     (see "dpmr", "dmr" document)
%     large_fsk_modulation_index = 0;
% (2) for narrow band fm signal, freq dev 2.5e3 is used instead of 1e3
%     ('inf_snr_narrow_band_fm_2.5_12.mat' is used instead of 'inf_snr_narrow_band_fm_1_12.mat')
%     because freq dev of simple radio is 2.5e3
%
% [input]
% - signal_dir_name: signal foler name where signal is generated. if not exist, folder will be created
% - instance_length: instance length per modulation class, recommend = 1000
%   when 1000 and 8 modulation, expected program run time = 90 min 
%   (pc spec: cpu = Intel Core i7-4930K, ram = 64 GB, main board = P9X79, os = windows 7 64-bit)
% - mat_filename_append_string: mat filename appended string
%   when '_new_test', RML2018_gsmRAx4c2_1000instance.mat => RML2018_gsmRAx4c2_1000instance_new_test.mat
% - sample_per_symbol: sample per symbol. original = 8
%   model trained with 8 sps(sample per symbol) dataset can classify modulation signal with different sps? 
%
% [usage]
% generate_modulation_signal_train_set('e:\temp\mod_signal', 1000, '_small_fsk', 8)

% mat_filename_append_string = '';
% below string is appended in filename: 
% RML2018_gsmRAx4c2_1000instance.mat => RML2018_gsmRAx4c2_1000instance_1e6chanfs.mat
% mat_filename_append_string = '_new_test';

% sample_per_symbol = 8;

call_python_for_making_dat_file = 1;
python_command = 'E:\\modulation classification\\matlab_dataset\\make_dict_from_mat_file.py';

% load inf snr signal from file

% #### to have 'inf_snr_fm_broadcast_48_240.mat', 
% #### use 'generate_fm_broadcast_signal_comm_system_object.m' 

% #### reminding
% save(signal_filename, 'y', 'audio_sample_rate', 'sample_rate', 'wav_filename', 'stereo');
wbfm = load('inf_snr_fm_broadcast_48_240.mat'); % fm broadcast signal

% #### to have 'inf_snr_narrow_band_fm_1_12.mat.mat', 
% #### use 'generate_fm_signal_comm_system_object.m'

% #### reminding
% save(signal_filename, 'y', 'freq_dev', 'sample_rate', 'wav_filename');
nbfm = load('inf_snr_narrow_band_fm_2.5_12.mat'); % narrow band fm signal
% nbfm = load('inf_snr_narrow_band_fm_1_12.mat'); % narrow band fm signal

fprintf('#### inf snr fm signal loaded\n');

% large_fsk_modulation_index = 1;
large_fsk_modulation_index = 0;

% #############################################################
% ### recommend: single_float_iq = 0; (set to double float)
% ###
% ### disk is not expensive
% ### single float is NOT fully tested
% #############################################################
% single_float_iq = 1; % single float iq, half size of double float iq
single_float_iq = 0; % double float iq

% ############################################################################
% 'wbfm' simulate fm radio broadcasting signal (88 ~ 108 mhz)
% "wbfm_modulation.m" is replaced with "fm_radio_modulation.m",
% in "fm_radio_modulation.m",
% freq_dev = 75e3, and max_freq_of_source_signal = 15e3,
% fc = 100e3, fs = 400e3
%
% [question]
% sample rate(fs) difference:
% real fm radio signal is read from rf receiver(r&s fsq26) with fs = 250e3.
% simulated fm radio signal is generated with fs = 400e3.
% fs difference give any problem?
% simulated fm radio signal is needed to decimate by 2 (fs = 200e3)?
% ############################################################################
                
% 'amsc': am suppressed carrier, 'nbfm': narrow band fm
% modulation_name_cell = {'amsc','ssb','nbfm'}; % analog only
% modulation_name_cell = {'bpsk','qpsk','2fsk','4fsk','16qam'}; % digital only
modulation_name_cell = {'amsc','ssb','nbfm','wbfm','bpsk','qpsk','2fsk','4fsk','16qam'};
mod_length = length(modulation_name_cell);

% length must be same as modulation_name length
% channel_fs_hz_vec = [44.1e3, 44.1e3, 44.1e3];
% channel_fs_hz_vec = [1e6, 1e6, 1e6, 1e6, 1e6];
% channel_fs_hz_vec = [44.1e3, 44.1e3, 44.1e3, 220.5e3, 1e6, 1e6, 1e6, 1e6, 1e6];
% channel_fs_hz_vec = [44.1e3, 44.1e3, 44.1e3, 400e3, 1e6, 1e6, 1e6, 1e6, 1e6];
nbfm_channel_fs_hz = nbfm.sample_rate; % 12e3
wbfm_channel_fs_hz = wbfm.sample_rate; % 240e3
channel_fs_hz_vec = [44.1e3, 44.1e3, nbfm_channel_fs_hz, wbfm_channel_fs_hz, 1e6, 1e6, 1e6, 1e6, 1e6];
if length(channel_fs_hz_vec) ~= mod_length
    fprintf('###### error: channel_fs length must be same as modulation_name length\n');
    return;
end

% length must be same as modulation_name length
% max_freq_offset_hz_vec = [0, 0, 0, 0, 0, 0, 0, 0]; % no freq offset. not realistic
% max_freq_offset_hz_vec = [100, 100, 100];
% max_freq_offset_hz_vec = [100, 100, 100, 100, 100];
max_freq_offset_hz_vec = [100, 100, 100, 100, 100, 100, 100, 100, 100];
if length(max_freq_offset_hz_vec) ~= mod_length
    fprintf('###### error: max_freq_offset length must be same as modulation_name length\n');
    return;
end

% % instance length per modulation class
% instance_length = 12; % original = 1000

iq_sample_length = 128;

snr_db_vec = -10:2:20;

channel_type = 'gsmRAx4c2';
% channel_type = ''; % no fading channel. not realistic

% ###### assume fskmod matlab function input fs = 1, see "fsk_modulation.m"
if large_fsk_modulation_index
    % modulation index = 2
    freq_sep_2fsk = .25;
    % modulation index = 1.5
    freq_sep_4fsk = .1875;
else
    % modulation index = 0.32
    freq_sep_2fsk = .04;
    % modulation index = 0.27
    freq_sep_4fsk = .0338;
end

% only scalar is supported. 0 or 180 may be meaningful
% max_phase_offset_deg = 0; % no freq offset. not realistic
max_phase_offset_deg = 180;

% iq acquisition is from 1st sample. 0 = after 1st sample (random), 1 = from 1st sample (not realistic)
% when digital modulation, this simulate symbol timing error
% ###### when analog modulation, not used
iq_from_1st_sample = 0; % symbol timing error
% iq_from_1st_sample = 1; % no symbol timing error. not realistic

if ~exist(signal_dir_name, 'dir')
    [status, ~, ~] = mkdir(signal_dir_name);
    if ~status
        fprintf('###### error: making signal folder is failed\n');
        return;
    end
end

snr_length = length(snr_db_vec);

% make array which be saved into mat file.
% python code read it from mat file
modulation_name_set = cell(mod_length * snr_length, 1);
snr_db_set = zeros(mod_length * snr_length, 1);
% make dimension same as python code. (free in matlab, not in python)
iq_set = zeros(mod_length * snr_length, instance_length, iq_sample_length);

% start stopwatch timer to see who is time killer
tic;

% nested loop: snr_length(outer), mod_length(inner)
for n = 1 : snr_length
    
    snr_db = snr_db_vec(n);
    fprintf('### snr = %d db\n', snr_db);
    
    for m = 1 : mod_length
        
        modulation_name = modulation_name_cell{m};
        channel_fs_hz = channel_fs_hz_vec(m);
        max_freq_offset_hz = max_freq_offset_hz_vec(m);
        
        switch modulation_name
            case 'amsc'
                am_modulation_index = 0;
                iq = gen_am_mod_iq(am_modulation_index, instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg, iq_from_1st_sample);
            case 'ssb'
                iq = gen_ssb_mod_iq(instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg, iq_from_1st_sample);
            case 'nbfm'
                % ###############################################
                % 'nbfm' simulate "simplified-license raio station" signal
                % in "gen_nbfm_mod_iq,m",
                % "nbfm_modulation.m" is replaced with "nbfm_comm_system_object.m"
                % in which 'comm.FMModulator', 'comm.FMDemodulator' system object is used
                % (180720)
                % ##################################################
                inf_snr_iq = nbfm.y;
                iq = inf_snr_gen_fm_mod_iq(inf_snr_iq, instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg);
            case 'wbfm'
                % ############################################################################
                % 'wbfm' simulate fm radio broadcasting signal (88 ~ 108 mhz)
                % in "gen_wbfm_mod_iq.m", 
                % "fm_radio_modulation.m" is replaced with "fm_broadcasting_comm_system_object.m",
                % in which 'comm.FMBroadcastModulator', 'comm.FMBroadcastDemodulator' system object is used
                % (180720)
                % ############################################################################
                inf_snr_iq = wbfm.y;
                iq = inf_snr_gen_fm_mod_iq(inf_snr_iq, instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg);
            case 'bpsk'
                M = 2;
                iq = gen_psk_mod_iq(M, instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg, iq_from_1st_sample, ...
                    sample_per_symbol);
            case 'qpsk'
                M = 4;
                iq = gen_psk_mod_iq(M, instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg, iq_from_1st_sample, ...
                    sample_per_symbol);
            case '2fsk'
                M = 2;
                iq = gen_fsk_mod_iq(M, freq_sep_2fsk, instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg, iq_from_1st_sample, ...
                    sample_per_symbol);
            case '4fsk'
                M = 4;
                iq = gen_fsk_mod_iq(M, freq_sep_4fsk, instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg, iq_from_1st_sample, ...
                    sample_per_symbol);
            case '16qam'
                M = 16;
                iq = gen_qam_mod_iq(M, instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg, iq_from_1st_sample, ...
                    sample_per_symbol);
            otherwise
                fprintf('###### error: %s = unknown modulation name\n', modulation_name);
                return;
        end % end of switch
        
%         if single_float_iq
%             % convert single float for small file size
%             % iq dimension = instance_length x iq_sample_length
%             iq = single(iq);
%         end
        
        row_idx = (n - 1) * mod_length + m;
        
        snr_db_set(row_idx) = snr_db;
        modulation_name_set{row_idx} = modulation_name;
        iq_set(row_idx, :, :) = iq;
        
        % check nan. iq_set dimension = 2, so need 2 nested sum
        nan_length = sum(sum(isnan(iq)));
        if nan_length
            fprintf('###### error: [%s] nan in iq_set, nan length = %d\n', modulation_name, nan_length);
            return;
        end
        
%         iq_dataset(row_idx, :) = {modulation_name, snr_db, iq};
        
    end % end of mod_length
    
end % end of snr_length

% stop stopwatch timer
elapse_time_sec = toc;
fprintf('[%d iq, %d instance, %d snr, %d modulation] elapse time = %g min\n', ...
    iq_sample_length, instance_length, snr_length, mod_length, elapse_time_sec / 60);

% save iq_dataset into mat file
if isempty(channel_type)
    channel_type = 'nofading';
end

if isempty(mat_filename_append_string)
    mat_filename = sprintf('%s\\RML2018_%s_%dinstance.mat', signal_dir_name, channel_type, instance_length);
else
    mat_filename = sprintf('%s\\RML2018_%s_%dinstance%s.mat', ...
        signal_dir_name, channel_type, instance_length, mat_filename_append_string);
end
% mat_filename = sprintf('%s\\RML2018_%s_%dinstance.mat', signal_dir_name, channel_type, instance_length);
save(mat_filename, 'snr_db_set', 'modulation_name_set', 'iq_set');
fprintf('#### iq dataset is saving into "%s" file\n', mat_filename);

% write parameter(modulation name, sample rate, freq offset, snr_db) into mat file
param_mat_filename = sprintf('%s\\RML2018_param.mat', signal_dir_name);
save(param_mat_filename, ...
    'modulation_name_cell', 'channel_fs_hz_vec', 'max_freq_offset_hz_vec', 'snr_db_vec');
fprintf('#### parameter is saving into "%s" file\n', param_mat_filename);

if call_python_for_making_dat_file
    pause(2);
    status = call_python(mat_filename, python_command);
    if status
        fprintf('### error: python command = %s failed\n', python_command);
    end
end

% % check nan. iq_set dimension = 3, so need 3 nested sum
% nan_length = sum(sum(sum(isnan(iq_set))));
% if nan_length
%     fprintf('###### error: there is nan in iq_set, nan length = %d\n', nan_length);
% end

end

%%
% function [status] = call_python(mat_filename, python_command)
% 
% % ############ python must be 3.x, not 2.x
% 
% python_command_input = mat_filename;
% % python_command = 'E:\\modulation classification\\matlab_dataset\\make_dict_from_mat_file.py';
% command = sprintf('python "%s" "%s"', python_command, python_command_input);
% 
% status = dos(command);
% 
% end




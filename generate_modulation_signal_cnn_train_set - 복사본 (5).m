function [] = ...
    generate_modulation_signal_cnn_train_set(signal_dir_name, instance_length, ...
    mat_filename_append_string, sample_per_symbol)
% generate modulation signal for cnn model train and save into mat file
%
% modified from "generate_modulation_signal_cnn_train_set - copy(4).m" (190411)
% ######################################################
% differ from "- copy(4).m":
% (1) nbfm: train signal is generated from inf snr signal file
%     inf snr signal dont have start, stop pause section
% #########################################################
%
% modified from "generate_modulation_signal_cnn_train_set - copy(3).m" (190410)
% ######################################################
% differ from "- copy(3).m":
% (1) wbfm: real signal read from fsq is used for train signal instead of computer generated signal
% #########################################################
%
% modified from "generate_modulation_signal_cnn_train_set - copy(2).m" (190307)
% ##############################################################################
% differ from "generate_modulation_signal_cnn_train_set - copy(2).m"
% (1) "8vsb" (atsc digital tv) modulation signal is added
%     "modulation_name_cell", "channel_fs_hz_vec", "max_freq_offset_hz_vec" is changed
% (2) "8vsb" signal is loaded from inf snr 8vsb file
%     example file: 'inf_snr_8vsb_atsc_dtv_sps5_down7.mat'
%     which is generated using "atsc_8vsb_inf_snr.m"
%     "inf_snr_gen_8vsb_mod_iq.m" is used to make cnn train set for 8vsb every snr
% (3) due to 8vsb addition, parameter file, "RML2019_param.mat", is changed
% (4) check to rewrite "make_dict_from_mat_file.py" due to "8vsb" addition
%     maybe no need to rewrite (190307)
% (5) must rewrite "batch_real_modulation_classifier.py", "real_modulation_classifier.py" 
%     to add "8vsb" modulation (190307)
% ##############################################################################
% 
% modified from "generate_modulation_signal_cnn_train_set - copy.m" (190227)
% ######################################################################
% differ from "generate_modulation_signal_cnn_train_set - copy.m"
% (1) for narrow band fm signal, iq sample is loaded from simple radio signal file
%     example file: "simpe_radio_fd2500_fs14700_talk7_pause0.5.mat"
%     which is generated using "batch_generate_simple_radio_signal.m"
%     iq array have iq sample for every snr
%     (dimension = sample_length x snr_length)
% (2) simple radio signal file have iq sample already affected by snr, fading, carrier offset
%     (not infinite snr file like wide band fm signal file)
%     so when narrow band signal is generated, snr, fading, carrier offset is NOT applied
% ######################################################################
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
% #####################################################################
%
% [input]
% - signal_dir_name: signal foler name where signal is generated. if not exist, folder will be created
% - instance_length: instance length per modulation class, recommend = 1000
%   when 1000 and 8 modulation, program run time = 90 min 
%   when 1000 and 10 modulation, program run time = 143 min
%   (pc spec: cpu = Intel Core i7-4930K, ram = 64 GB, main board = P9X79, os = windows 7 64-bit)
% - mat_filename_append_string: mat filename appended string
%   when '_new_test', RML2018_gsmRAx4c2_1000instance.mat => RML2018_gsmRAx4c2_1000instance_new_test.mat
% - sample_per_symbol: sample per symbol. original = 8
%   model trained with 8 sps(sample per symbol) dataset can classify modulation signal with different sps?
%   #### importance of this input become fading out (190325): 
%   #### atsc 8vsb signal with sample per symbol 4 is generated and saved into file,
%   #### and then 128 8vsb sample is randomly selected from file.
%
% [usage]
% generate_modulation_signal_cnn_train_set('e:\temp\mod_signal', 1000, '_multi_talk_simpe_radio', 8)
% generate_modulation_signal_cnn_train_set('e:\temp\mod_signal', 1000, '_wbfm_fmbroadcasting_fsq_iq', 8)

% ### fixed for cnn model input
iq_sample_length = 128;

snr_db_vec = -10:2:20;
snr_length = length(snr_db_vec);

% fading channel
channel_type = 'gsmRAx4c2';

call_python_for_making_dat_file = 1;
python_command = 'E:\\modulation classification\\matlab_dataset\\make_dict_from_mat_file.py';

use_wbfm_from_fsq_iq_file = 1;

if use_wbfm_from_fsq_iq_file
    fsq_iq_filename = 'E:\iq_from_fsq\fmbroadcast\fsq_iq_181205093757_95.7_0.192_0.24.mat';
    wbfm = load(fsq_iq_filename);
    inf_snr_wbfm_iq = wbfm.iq;
    wbfm_channel_fs_hz = wbfm.sample_rate_mhz * 1e6; % 240e3
else
    % #### load wide band fm signal from file
    % #### to have 'inf_snr_fm_broadcast_48_240.mat',
    % #### use 'generate_fm_broadcast_signal_comm_system_object.m'
    
    % #### reminding what file have
    % save(signal_filename, 'y', 'audio_sample_rate', 'sample_rate', 'wav_filename', 'stereo');
    wbfm = load('inf_snr_fm_broadcast_48_240.mat'); % fm broadcast signal
    inf_snr_wbfm_iq = wbfm.y;
    wbfm_channel_fs_hz = wbfm.sample_rate; % 240e3
end

% #### load narrow band fm signal from file
% #### to have 'inf_snr_simpe_radio_fd2500_fs14700.mat', 
% #### use 'inf_snr_generate_simple_radio_signal.m'

% #### reminding what file have
% save(signal_filename, 'iq', 'freq_dev', 'fs', 'talk_duration_vec', 'audio_filename');
nbfm = load('inf_snr_simpe_radio_fd2500_fs14700.mat'); % simple radio signal

% simple_iq dimension = sample_length x snr_length
inf_snr_simple_iq = nbfm.iq; 
% sample_length may be 371592

nbfm_channel_fs_hz = nbfm.fs; % 14700
% simple_snr_vec = nbfm.snr_db_vec;

% % #### load narrow band fm signal from file
% % #### to have 'simpe_radio_fd2500_fs14700_talk7_pause0.5.mat', 
% % #### use 'batch_generate_simple_radio_signal.m'
% 
% % #### reminding what file have
% % save(signal_filename, 'iq', 'snr_db_vec', 'freq_dev', 'fs', 'talk_duration', 'stop_pause_duration');
% nbfm = load('simpe_radio_fd2500_fs14700_talk7_pause0.5.mat'); % simple radio signal
% 
% % simple_iq dimension = sample_length x snr_length
% simple_iq = nbfm.iq; 
% % sample_length may be 130161
% 
% simple_snr_vec = nbfm.snr_db_vec;

% when 8vsb iq read from fsq is used as 8vsb signal, set to 1
use_8vsb_from_fsq_iq_file = 1;

if use_8vsb_from_fsq_iq_file
    % ##### load 8vsb atsc signal from fsq iq file
    % ##### to have fsq iq file, use "get_iq_from_fsq.py"
    
    % #### reminding what file have (see "get_iq_from_fsq.py")
    %
    %     # for backward compatibility: see "get_iq_from_fsq_181122.m" and "plot_fsq_iq.m"
    %     savemat(mat_filepath,
    %             dict([('iq', iq), ('center_freq_mhz', fsq_freq_mhz),
    %                   ('sample_rate_mhz', sample_rate_mhz), ('sample_length', iq_length),
    %                   ('timestamp', timestamp)]))
    fsq_iq_filename = 'E:\iq_from_fsq\fs64.56_hd_tv_fp5.38\fsq_iq_190320163253_473.000000_64.560000_fp5.380000.mat'; % sps = 6
%     fsq_iq_filename = 'E:\iq_from_fsq\fs53.8_hd_tv_fp5.38\fsq_iq_190320162705_473.000000_53.800000_fp5.380000.mat'; % sps = 5
%     fsq_iq_filename = 'E:\iq_from_fsq\fs32.28_hd_tv_fp5.38\fsq_iq_190320134612_473.000000_32.280000_fp5.380000.mat'; % sps = 3
%     fsq_iq_filename = 'fsq_iq_190320133832_473.000000_21.520000_fp5.380000.mat'; % sps = 2
%     fsq_iq_filename = 'fsq_iq_190320135455_473.000000_43.040000_fp5.380000.mat'; % sps = 4
    atsc_8vsb = load(fsq_iq_filename);
    % row vector (python numpy default: row major order)
    inf_snr_atsc_8vsb_iq = atsc_8vsb.iq;
    atsc_8vsb_channel_fs_hz = atsc_8vsb.sample_rate_mhz * 1e6;
else
    % ##### load 8vsb atsc signal from file
    % #### to have 'inf_snr_8vsb_atsc_dtv_sps7_down11.mat', use 'atsc_8vsb_inf_snr.m'
    % #### example: "atsc_8vsb_inf_snr(2^20, 7, 11, 0, 1)"
    
    % #### reminding what file have
    % save(signal_filename, 'y', 'sample_per_symbol', 'downsample_rate', 'fs');
    atsc_8vsb = load('inf_snr_8vsb_atsc_dtv_sps4_down1.mat'); % atsc 8vsb signal (sample per symbol = 4)
    % atsc_8vsb = load('inf_snr_8vsb_atsc_dtv_sps7_down11.mat'); % atsc 8vsb signal
    % column vector
    inf_snr_atsc_8vsb_iq = atsc_8vsb.y;
    atsc_8vsb_channel_fs_hz = atsc_8vsb.fs;
end

fprintf('## signal loaded from file\n');

% large_fsk_modulation_index = 1;
large_fsk_modulation_index = 0;
                
% 'amsc': am suppressed carrier, 'nbfm': narrow band fm
modulation_name_cell = {'amsc','ssb','nbfm','wbfm','bpsk','qpsk','2fsk','4fsk','16qam','8vsb'};
mod_length = length(modulation_name_cell);

% length must be same as modulation_name length
% nbfm_channel_fs_hz = nbfm.fs; % 14700
% wbfm_channel_fs_hz = wbfm.sample_rate; % 240e3
% atsc_8vsb_channel_fs_hz = atsc_8vsb.fs; % 7.5e6 (fsq sample rate)
channel_fs_hz_vec = ...
    [44.1e3, 44.1e3, nbfm_channel_fs_hz, wbfm_channel_fs_hz, 1e6, 1e6, 1e6, 1e6, 1e6, atsc_8vsb_channel_fs_hz];
if length(channel_fs_hz_vec) ~= mod_length
    fprintf('###### error: channel_fs length must be same as modulation_name length\n');
    return;
end

% length must be same as modulation_name length
max_freq_offset_hz_vec = [100, 100, 100, 100, 100, 100, 100, 100, 100, 100];
if length(max_freq_offset_hz_vec) ~= mod_length
    fprintf('###### error: max_freq_offset length must be same as modulation_name length\n');
    return;
end

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

% only scalar is supported.
% max_phase_offset_deg = 0; % no freq offset. not realistic
max_phase_offset_deg = 180;

% iq acquisition is from 1st sample. 0 = after 1st sample (random), 1 = from 1st sample (not realistic)
% when digital modulation, this simulate symbol timing error
% ###### when analog modulation, not used
iq_from_1st_sample = 0; % symbol timing error
% iq_from_1st_sample = 1; % no symbol timing error. not realistic

% check signal folder exist
if ~exist(signal_dir_name, 'dir')
    [status, ~, ~] = mkdir(signal_dir_name);
    if ~status
        fprintf('###### can''t make signal folder\n');
        return;
    end
end

% make array which be saved into mat file.
% python code read it from mat file
modulation_name_set = cell(mod_length * snr_length, 1);
snr_db_set = zeros(mod_length * snr_length, 1);

% make dimension same as python code. (free in matlab, not in python)
iq_set = zeros(mod_length * snr_length, instance_length, iq_sample_length);

% start stopwatch timer
tic;

% nested loop
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
                % ##########################################################
                % 'nbfm' simulate "simple raio" signal (146 mhz)
                % ##########################################################
                % #### "inf_snr_simple_iq" loaded from file
                iq = inf_snr_gen_simple_radio_iq(inf_snr_simple_iq, instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg);
                
%                 iq = gen_simple_radio_iq(simple_iq, instance_length, iq_sample_length, snr_db, simple_snr_vec);
%                 % #### fading, carrier offset, snr is not needed because iq sample was already affected
%                 % #### snr_db is only for reference
%                 % #### "simple_iq" loaded from file
                
%                 iq = inf_snr_gen_fm_mod_iq(inf_snr_iq, instance_length, iq_sample_length, snr_db, ...
%                     channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg);
            case 'wbfm'
                if use_wbfm_from_fsq_iq_file
                    % ########### real signal from fsq is used:
                    % ########### so channel fading, carrier offset is NOT applied
                    % ########### only noise from snr is added
                    
                    % ####### DONT UNCOMMENT below: other modulation is AFFECTED!
                    %                     channel_type = [];
                    %                     max_freq_offset_hz = 0;
                    %                     max_phase_offset_deg = 0;
                    iq = inf_snr_gen_fm_mod_iq(inf_snr_wbfm_iq, instance_length, iq_sample_length, ...
                        snr_db, [], 0, 0, 0);
                else
                    % ################################################################
                    % 'wbfm' simulate fm radio broadcasting signal (88 ~ 108 mhz)
                    % ################################################################
                    iq = inf_snr_gen_fm_mod_iq(inf_snr_wbfm_iq, instance_length, iq_sample_length, snr_db, ...
                        channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg);
                end
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
            case '8vsb'
                if use_8vsb_from_fsq_iq_file
                    % ########### real signal from fsq is used:
                    % ########### so channel fading, carrier offset is NOT applied
                    % ########### only noise from snr is added
                    
                    % ####### DONT UNCOMMENT below: other modulation is AFFECTED!
%                     channel_type = [];
%                     max_freq_offset_hz = 0;
%                     max_phase_offset_deg = 0;
                    iq = inf_snr_gen_8vsb_mod_iq(inf_snr_atsc_8vsb_iq, instance_length, iq_sample_length, ...
                        snr_db, [], 0, 0, 0);   
                else
                    % ####### how to generate training signal
                    % (1) select random 128 samples among iq loaded from inf snr signal file
                    % (2) apply fading, snr, carrier offset
                    % (3) symbol synch error is NOT needed because 128 samples are random selected
                    % ################# "sample_per_symbol" input is not needed in 8vsb
                    % ################# which may be true to all digital modulation
                    % ################# because (fsq sample rate) * 0.8 is max signal bandwidth
                    iq = inf_snr_gen_8vsb_mod_iq(inf_snr_atsc_8vsb_iq, instance_length, iq_sample_length, ...
                        snr_db, channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg);
                end
            otherwise
                fprintf('###### error: %s = unknown modulation name\n', modulation_name);
                return;
        end % end of switch
        
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
        
    end % end of mod_length
    
end % end of snr_length

% stop stopwatch timer
elapse_time_sec = toc;
fprintf('[%d iq, %d instance, %d snr, %d modulation] elapse time = %g min\n', ...
    iq_sample_length, instance_length, snr_length, mod_length, elapse_time_sec / 60);

% make filename
if isempty(mat_filename_append_string)
    mat_filename = sprintf('%s\\RML2019_%s_%dinstance.mat', signal_dir_name, channel_type, instance_length);
else
    mat_filename = sprintf('%s\\RML2019_%s_%dinstance%s.mat', ...
        signal_dir_name, channel_type, instance_length, mat_filename_append_string);
end

% save iq array, modulation name cell vector, snr db vector into mat file
save(mat_filename, 'snr_db_set', 'modulation_name_set', 'iq_set');
fprintf('#### iq dataset is saving into "%s" file\n', mat_filename);

% write parameter(modulation name, sample rate, freq offset, snr_db) into mat file
% #################################################
% this parameter file is needed? which program use this file? (190307)
% old code('display_iq_real.py', 'display_iq_RML2018.py', 'modulation_classifier.py") only use this file
% some matlab code use this file? must check (190307)
% ##############################################
param_mat_filename = sprintf('%s\\RML2019_param.mat', signal_dir_name);
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

end


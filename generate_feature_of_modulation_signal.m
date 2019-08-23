function [] = generate_feature_of_modulation_signal(signal_dir_name, instance_length, mat_filename_append_string, ...
    sample_per_symbol)
% generate feature of modulation signal
%
% ################# paradigm change (180410)
% [old] 
% model = convolutional neural network, input = complex iq sample (dimension = 2 * 128)
%
% [new] 
% model = fully connected neural network, input = feature (dimension = 1 * feature_length)
% ###########################################################################################
%
% [input]
% - signal_dir_name: signal foler name where signal is generated. if not exist, folder will be created
% - instance_length: instance length per modulation class, recommend = 1000
% - mat_filename_append_string: mat filename appended string
%   when '_new_test', RML2018_gsmRAx4c2_1000instance.mat => RML2018_gsmRAx4c2_1000instance_new_test.mat
% - sample_per_symbol: sample per symbol. original = 8
%   model trained with 8 sps(sample per symbol) dataset can classify modulation signal with different sps? 
%
% [usage]
% generate_feature_of_modulation_signal('e:\temp\mod_signal', 1000, '', 8)
%
% [run time]
% when 1000 instance, 9 modulation, 16 snr, 1024 iq sample, 18 feature, program run time = xx min 
% (pc spec: cpu = Intel Core i7-4930K, ram = 64 GB, main board = P9X79, os = windows 7 64-bit)

% sample_per_symbol = 8;

% #### fill cell array
feature_name_cell = {'gamma_max', 'sigma_ap', 'sigma_dp', 'P', 'sigma_aa', 'sigma_af', 'sigma_a', ...
    'mu_a42', 'mu_f42', 'C20', 'C21', 'C40', 'C41', 'C42', 'C60', 'C61', 'C62', 'C63'};
feature_length = length(feature_name_cell);

% recommend = .5 ~ 1 (right?). when .5, 85% survive, when 1, 50% survive
amplitude_threshold = .5;

iq_sample_length = 2^10;
% iq_sample_length = 2^12;

snr_db_vec = -10:2:20;

call_python_for_making_dat_file = 1;
% #############################################################################
% #### (180519) "make_feature_dict_from_mat_file.py" was tested
% #############################################################################
python_command = 'E:\\modulation classification\\matlab_dataset\\feature_make_dict_from_mat_file.py';

large_fsk_modulation_index = 1;
% large_fsk_modulation_index = 0;

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
channel_fs_hz_vec = [44.1e3, 44.1e3, 44.1e3, 250e3, 1e6, 1e6, 1e6, 1e6, 1e6];
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
feature_set = zeros(mod_length * snr_length, instance_length, feature_length);

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
                iq = gen_nbfm_mod_iq(instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg, iq_from_1st_sample);
            case 'wbfm'
                % ############################################################################
                % 'wbfm' simulate fm radio broadcasting signal (88 ~ 108 mhz)
                % "wbfm_modulation.m" is replaced with "fm_radio_modulation.m",
                % in which freq_dev = 75e3, and max_freq_of_source_signal = 15e3 is used
                % ############################################################################
                iq = gen_wbfm_mod_iq(instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg, iq_from_1st_sample);
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
        
        % iq dimension = instance_length x iq_sample_length
        % check nan. iq_set dimension = 2, so need 2 nested sum
        nan_length = sum(sum(isnan(iq)));
        if nan_length
            fprintf('###### error: [%s] nan in iq_set, nan length = %d\n', modulation_name, nan_length);
            return;
        end
        
        row_idx = (n - 1) * mod_length + m;
        
        snr_db_set(row_idx) = snr_db;
        modulation_name_set{row_idx} = modulation_name;
        % iq dimension = instance_length x iq_sample_length
        % compute_feature output dimension = instance_length x feature_length
        feature_set(row_idx, :, :) = ...
            compute_feature_of_modulation_signal(iq, amplitude_threshold, feature_name_cell, channel_fs_hz);
        
    end % end of mod_length
    
end % end of snr_length

% stop stopwatch timer
elapse_time_sec = toc;
fprintf('[%d iq sample, %d instance, %d snr, %d modulation, %d feature] elapse time = %g min\n', ...
    iq_sample_length, instance_length, snr_length, mod_length, feature_length, elapse_time_sec / 60);

% save iq_dataset into mat file
if isempty(channel_type)
    channel_type = 'nofading';
end

if isempty(mat_filename_append_string)
    mat_filename = sprintf('%s\\feature_%s_%dinst_%dsps.mat', ...
        signal_dir_name, channel_type, instance_length, sample_per_symbol);
else
    mat_filename = sprintf('%s\\feature_%s_%dinst_%dsps%s.mat', ...
        signal_dir_name, channel_type, instance_length, sample_per_symbol, mat_filename_append_string);
end
save(mat_filename, 'snr_db_set', 'modulation_name_set', 'feature_set');
fprintf('#### feature set is saving into "%s" file\n', mat_filename);

% write parameter(modulation name, sample rate, freq offset, snr_db, feature name) into mat file
param_mat_filename = sprintf('%s\\feature_param.mat', signal_dir_name);
save(param_mat_filename, ...
    'modulation_name_cell', 'channel_fs_hz_vec', 'max_freq_offset_hz_vec', 'snr_db_vec', 'feature_name_cell');
fprintf('#### parameter is saving into "%s" file\n', param_mat_filename);

if call_python_for_making_dat_file
    pause(2);
    status = call_python(mat_filename, python_command);
    if status
        fprintf('### error: python command = %s failed\n', python_command);
        return;
    end
end

end

%%
function [status] = call_python(mat_filename, python_command)

% ############ python must be 3.x, not 2.x

python_command_input = mat_filename;
% python_command = 'E:\\modulation classification\\matlab_dataset\\feature_make_dict_from_mat_file.py';
command = sprintf('python "%s" "%s"', python_command, python_command_input);

status = dos(command);

end

%%
% function [iq] = gen_am_mod_iq(am_modulation_index, instance_length, iq_sample_length, snr_db, ...
%     chan_type, chan_fs, max_freq_offset_hz, max_phase_offset_deg, iq_from_1st_sample)
% 
% plot_modulated_signal = 0;
% sound_demod = 0;
% fd = 0;
% save_iq = 0;
% 
% source_sample_length = iq_sample_length * 2;
% 
% iq = zeros(instance_length, iq_sample_length);
% for n = 1 : instance_length
%     [pre_iq, ~] = ...
%         am_modulation(am_modulation_index, source_sample_length, snr_db, plot_modulated_signal, sound_demod, ...
%         chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
%     
%     start_idx = 1;
%     pre_iq = pre_iq(start_idx : start_idx + iq_sample_length - 1);
%     
%     % ##############################################################
%     % #### normalize is needed?
%     % #### it give "nan" when all pre_iq is zero
%     % ##############################################################
%     % normalize
%     pre_iq = pre_iq / max(abs(pre_iq));
%     
%     % vertical stack into iq
%     iq(n, :) = pre_iq;
% end
% 
% end

%%
% function [iq] = gen_ssb_mod_iq(instance_length, iq_sample_length, snr_db, ...
%     chan_type, chan_fs, max_freq_offset_hz, max_phase_offset_deg, iq_from_1st_sample)
% 
% plot_modulated_signal = 0;
% sound_demod = 0;
% fd = 0;
% save_iq = 0;
% 
% usb = 0;
% 
% source_sample_length = iq_sample_length * 2;
% 
% iq = zeros(instance_length, iq_sample_length);
% for n = 1 : instance_length
%     [pre_iq, ~] = ...
%         ssb_modulation(source_sample_length, snr_db, usb, plot_modulated_signal, sound_demod, ...
%         chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
%     
%     start_idx = 1;
%     pre_iq = pre_iq(start_idx : start_idx + iq_sample_length - 1);
%     
%     % ##############################################################
%     % #### normalize is needed?
%     % #### it give "nan" when all pre_iq is zero
%     % ##############################################################
%     % normalize
%     pre_iq = pre_iq / max(abs(pre_iq));
%     
%     % vertical stack into iq
%     iq(n, :) = pre_iq;  
% end
% 
% end

%%
% function [iq] = gen_nbfm_mod_iq(instance_length, iq_sample_length, snr_db, ...
%     chan_type, chan_fs, max_freq_offset_hz, max_phase_offset_deg, iq_from_1st_sample)
% 
% plot_modulated_signal = 0;
% sound_demod = 0;
% fd = 0;
% save_iq = 0;
% 
% freq_dev = 1e3;
% 
% source_sample_length = iq_sample_length * 2;
% 
% iq = zeros(instance_length, iq_sample_length);
% for n = 1 : instance_length
%     [pre_iq, ~] = ...
%         nbfm_modulation(source_sample_length, freq_dev, snr_db, plot_modulated_signal, sound_demod, ...
%         chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
%     
%     start_idx = 1;
%     pre_iq = pre_iq(start_idx : start_idx + iq_sample_length - 1);
%     
%     % ##############################################################
%     % #### normalize is needed?
%     % #### it give "nan" when all pre_iq is zero
%     % ##############################################################
%     % normalize
%     pre_iq = pre_iq / max(abs(pre_iq));
%     
%     % vertical stack into iq
%     iq(n, :) = pre_iq;
% end
% 
% end

%%
% function [iq] = gen_wbfm_mod_iq(instance_length, iq_sample_length, snr_db, ...
%     chan_type, chan_fs, max_freq_offset_hz, max_phase_offset_deg, iq_from_1st_sample)
% % ############################################################################
% % simulate fm radio broadcasting signal (88 ~ 108 mhz)
% % "wbfm_modulation.m" is replaced with "fm_radio_modulation.m",
% % in which freq_dev = 75e3, and max_freq_of_source_signal = 15e3 is used
% % ############################################################################
% 
% plot_modulated_signal = 0;
% sound_demod = 0;
% fd = 0;
% save_iq = 0;
% 
% % fm radio
% freq_dev = 75e3;
% 
% source_sample_length = iq_sample_length * 2;
% 
% iq = zeros(instance_length, iq_sample_length);
% for n = 1 : instance_length
%     [pre_iq, ~] = ...
%         fm_radio_modulation(source_sample_length, freq_dev, snr_db, plot_modulated_signal, sound_demod, ...
%         chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
% %     [pre_iq, ~] = ...
% %         wbfm_modulation(source_sample_length, freq_dev, snr_db, plot_modulated_signal, sound_demod, ...
% %         chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
%     
%     start_idx = 1;
%     pre_iq = pre_iq(start_idx : start_idx + iq_sample_length - 1);
%     
%     % ##############################################################
%     % #### normalize is needed?
%     % #### it give "nan" when all pre_iq is zero
%     % ##############################################################
%     % normalize
%     pre_iq = pre_iq / max(abs(pre_iq));
%     
%     % vertical stack into iq
%     iq(n, :) = pre_iq;
% end
% 
% end

%%
% function [iq] = gen_psk_mod_iq(M, instance_length, iq_sample_length, snr_db, ...
%     chan_type, chan_fs, max_freq_offset_hz, max_phase_offset_deg, iq_from_1st_sample)
% 
% plot_modulated = 0;
% plot_stella = 0;
% fd = 0;
% save_iq = 0;
% sample_per_symbol = 8;
% fs = 1;
% 
% symbol_length = round(iq_sample_length * 2 / sample_per_symbol);
% 
% iq = zeros(instance_length, iq_sample_length);
% for n = 1 : instance_length
%     [pre_iq] = ...
%         psk_modulation(M, symbol_length, sample_per_symbol, snr_db, fs, plot_modulated, plot_stella, ...
%         chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
%     
%     if iq_from_1st_sample
%         start_idx = 1;
%     else
%         start_idx = randi([2, sample_per_symbol]);
%     end
%     
%     pre_iq = pre_iq(start_idx : start_idx + iq_sample_length - 1);
%     
%     % ##############################################################
%     % #### normalize is needed?
%     % #### it give "nan" when all pre_iq is zero
%     % ##############################################################
%     % normalize
%     pre_iq = pre_iq / max(abs(pre_iq));
%     
%     % vertical stack into iq
%     iq(n, :) = pre_iq;
% end
% 
% end

%%
% function [iq] = gen_fsk_mod_iq(M, freq_sep, instance_length, iq_sample_length, snr_db, ...
%     chan_type, chan_fs, max_freq_offset_hz, max_phase_offset_deg, iq_from_1st_sample)
% 
% plot_modulated = 0;
% plot_stella = 0;
% fd = 0;
% save_iq = 0;
% sample_per_symbol = 8;
% fs = 1;
% 
% symbol_length = round(iq_sample_length * 2 / sample_per_symbol);
% 
% iq = zeros(instance_length, iq_sample_length);
% for n = 1 : instance_length
%     [pre_iq] = ...
%         fsk_modulation(M, freq_sep, symbol_length, sample_per_symbol, snr_db, fs, plot_modulated, plot_stella, ...
%         chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
%     
%     if iq_from_1st_sample
%         start_idx = 1;
%     else
%         start_idx = randi([2, sample_per_symbol]);
%     end
%     
%     pre_iq = pre_iq(start_idx : start_idx + iq_sample_length - 1);
%     
%     % ##############################################################
%     % #### normalize is needed?
%     % #### it give "nan" when all pre_iq is zero
%     % ##############################################################
%     % normalize
%     pre_iq = pre_iq / max(abs(pre_iq));
%     
%     % vertical stack into iq
%     iq(n, :) = pre_iq;
% end
% 
% end

%%
% function [iq] = gen_qam_mod_iq(M, instance_length, iq_sample_length, snr_db, ...
%     chan_type, chan_fs, max_freq_offset_hz, max_phase_offset_deg, iq_from_1st_sample)
% 
% plot_modulated = 0;
% plot_stella = 0;
% fd = 0;
% save_iq = 0;
% sample_per_symbol = 8;
% fs = 1;
% 
% symbol_length = round(iq_sample_length * 2 / sample_per_symbol);
% 
% iq = zeros(instance_length, iq_sample_length);
% for n = 1 : instance_length
%     [pre_iq] = ...
%         qam_modulation(M, symbol_length, sample_per_symbol, snr_db, fs, plot_modulated, plot_stella, ...
%         chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
%     
%     if iq_from_1st_sample
%         start_idx = 1;
%     else
%         start_idx = randi([2, sample_per_symbol]);
%     end
%     
%     pre_iq = pre_iq(start_idx : start_idx + iq_sample_length - 1);
%     
%     % ##############################################################
%     % #### normalize is needed?
%     % #### it give "nan" when all pre_iq is zero
%     % ##############################################################
%     % normalize
%     pre_iq = pre_iq / max(abs(pre_iq));
%     
%     % vertical stack into iq
%     iq(n, :) = pre_iq;
% end
% 
% end


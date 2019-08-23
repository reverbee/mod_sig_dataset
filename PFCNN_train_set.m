function [] = PFCNN_train_set(PF_input_CNN, train_set_dir_name, instance_length, filename_append_string)
% generate train set for signal classification
%
% good for model: PF(Phase Frequency) input LSTM, IQ(In-phase Quadrature) input CNN, PF input CNN
%
% when 1000 instance, 7 modulation and 16 snr, program run time = 14 min 
% (pc spec: cpu = Intel Core i7-4930K, ram = 64 GB, main board = P9X79, os = windows 7 64-bit)
%
% [input]
% - PF_input_CNN: 1 = PF input CNN or PF input LSTM, 0 = IQ input CNN
% - train_set_dir_name: foler name where train set is generated.
% - instance_length: instance length per modulation class, recommend = 1000
% - filename_append_string: mat filename appended string
%   when '_new_test', RML2018_gsmRAx4c2_1000instance.mat => RML2018_gsmRAx4c2_1000instance_new_test.mat
%
% [usage]
% PFCNN_train_set(1, 'e:\temp\mod_signal', 1000, '')
% PFCNN_train_set(0, 'e:\temp\mod_signal', 1000, '')

% modulation(exactly technology) name cell
% 'fmsimple' = simple licensed(narrow band fm), 'fmbroad' = fm broadcasting(wide band fm)
modulation_name_cell = {'fmbroad', 'fmsimple', 'hdtv', 'lte', 'tdmb', 'tetra', 'wcdma'};
mod_length = length(modulation_name_cell);

% signal filename
fmbroad_filename = 'E:\iq_from_fsq\fmbroadcast\fsq_iq_181205093757_95.7_0.192_0.24.mat';
% #### to have 'inf_snr_simpe_radio_fd2500_fs14700.mat', 
% #### use 'inf_snr_generate_simple_radio_signal.m'
fmsimple_filename = 'inf_snr_simpe_radio_fd2500_fs14700.mat';
hdtv_filename = 'E:\iq_from_fsq\fs64.56_hd_tv_fp5.38\fsq_iq_190320163253_473.000000_64.560000_fp5.380000.mat';
lte_filename = 'E:\iq_from_fsq\lte_ext_ref_fp9.015\fsq_iq_190625133044_879.000000_10_15.360000_fp9.015000.mat';
tdmb_filename = 'E:\iq_from_fsq\fs6.144_tdmb_fp1.536\fsq_iq_190409152651_199.280000_6.144000_fp1.536000.mat';
tetra_filename = 'E:\iq_from_fsq\tetra_govern_fp0.023\fsq_iq_190424143409_855.312500_0.126000_fp0.023000.mat';
wcdma_filename = 'E:\iq_from_fsq\wcdma_ext_ref_rcos\fsq_iq_190430091434_2162.400000_38.400000_rolloff0.22_span10.mat';

% load signal from iq file
fmbroad = load(fmbroad_filename);
fmsimple = load(fmsimple_filename);
hdtv = load(hdtv_filename);
lte = load(lte_filename);
tdmb = load(tdmb_filename);
tetra = load(tetra_filename);
wcdma = load(wcdma_filename);

fprintf('########## signal loaded from file\n');

% use in "pfcnn_compute_phase_freq" function
% ##################### DONT SET TO 1
% use_fs = 1;
use_fs = 0;
normalize_freq = 0;

% ### fixed for cnn model input
iq_sample_length = 128;

% ################################################################
% assumed that snr of signal received from rx antenna is near infinite
% ################################################################
snr_db_vec = -10:2:20;
snr_length = length(snr_db_vec);

% % fading channel
% channel_type = 'gsmRAx4c2';

call_python_for_making_dat_file = 1;
if PF_input_CNN
    python_command = 'E:\\modulation classification\\matlab_dataset\\pfcnn_make_dict_from_mat_file.py';
else
    python_command = 'E:\\modulation classification\\matlab_dataset\\make_dict_from_mat_file.py';
end

% fsk modulation index: small or large?
% fsk may conflict with 'fmsimple', 'fmbroad'
% ########################################
% add fsk modulation(dmr, dpmr, two-way paging)
% #########################################

% make array which be saved into mat file.
% python code read it from mat file
modulation_name_set = cell(mod_length * snr_length, 1);
snr_db_set = zeros(mod_length * snr_length, 1);

% make dimension same as python code. (free in matlab, not in python)
pf_set = zeros(mod_length * snr_length, instance_length, iq_sample_length);
iq_set = zeros(mod_length * snr_length, instance_length, iq_sample_length);

% start stopwatch timer
tic;

% nested loop
for n = 1 : snr_length
    
    snr_db = snr_db_vec(n);
    fprintf('### snr = %d db\n', snr_db);
    
    for m = 1 : mod_length
        
        modulation_name = modulation_name_cell{m};
        
        switch modulation_name
            case 'fmsimple'
                channel_type = 'gsmRAx4c2';
                max_freq_offset_hz = 100;
                max_phase_offset_deg = 180;
                
                target_iq = fmsimple.iq;
                target_fs = fmsimple.fs;
            case 'fmbroad'
                channel_type = [];
                max_freq_offset_hz = 0;
                max_phase_offset_deg = 0;
                
                target_iq = fmbroad.iq;
                target_fs = fmbroad.sample_rate_mhz * 1e6;
            case 'hdtv'
                channel_type = [];
                max_freq_offset_hz = 0;
                max_phase_offset_deg = 0;
                
                target_iq = hdtv.iq;
                target_fs = hdtv.sample_rate_mhz * 1e6;
            case 'lte'
                channel_type = [];
                max_freq_offset_hz = 0;
                max_phase_offset_deg = 0;
                
                target_iq = lte.iq;
                target_fs = lte.sample_rate_mhz * 1e6;
            case 'tdmb'
                channel_type = [];
                max_freq_offset_hz = 0;
                max_phase_offset_deg = 0;
                
                target_iq = tdmb.iq;
                target_fs = tdmb.sample_rate_mhz * 1e6;
            case 'tetra'
                channel_type = [];
                max_freq_offset_hz = 0;
                max_phase_offset_deg = 0;
                
                target_iq = tetra.iq;
                target_fs = tetra.sample_rate_mhz * 1e6;
            case 'wcdma'
                channel_type = [];
                max_freq_offset_hz = 0;
                max_phase_offset_deg = 0;
                
                target_iq = wcdma.iq;
                target_fs = wcdma.sample_rate_mhz * 1e6;
            otherwise
                fprintf('###### error: %s = unknown modulation name\n', modulation_name);
                return;
        end % end of switch
        
        % iq dimension = instance_length x iq_sample_length
        iq = random_select_iq_sample_and_apply_awgn(target_iq, instance_length, iq_sample_length, snr_db, ...
            channel_type, target_fs, max_freq_offset_hz, max_phase_offset_deg);
        
        row_idx = (n - 1) * mod_length + m;
        
        snr_db_set(row_idx) = snr_db;
        modulation_name_set{row_idx} = modulation_name;
        
        if PF_input_CNN
            phase_freq = pfcnn_compute_phase_freq(iq, target_fs, use_fs, normalize_freq);
            pf_set(row_idx, :, :) = phase_freq;
        else
            iq_set(row_idx, :, :) = iq;
        end
            
    end % end of modulation
    
end % end of snr

% stop stopwatch timer
elapse_time_sec = toc;
fprintf('[%d iq, %d instance, %d snr, %d modulation] elapse time = %g min\n', ...
    iq_sample_length, instance_length, snr_length, mod_length, elapse_time_sec / 60);

% make filename
if PF_input_CNN
    % 'PFCNN' string is misleading, 
    % exact string is 'PF' because data set is also used in PF input LSTM
    filename_start_string = 'PFCNN';
else
    filename_start_string = 'IQCNN';
end

if isempty(filename_append_string)
    mat_filename = sprintf('%s\\%s_%dinst_%dsnr_%dmod.mat', ...
        train_set_dir_name, filename_start_string, instance_length, snr_length, mod_length);
else
    mat_filename = sprintf('%s\\%s_%dinst_%dsnr_%dmod%s.mat', ...
        train_set_dir_name, filename_start_string, instance_length, snr_length, mod_length, filename_append_string);
end

% save iq array, modulation name cell vector, snr db vector into mat file
if PF_input_CNN
    save(mat_filename, 'snr_db_set', 'modulation_name_set', 'pf_set');
else
    save(mat_filename, 'snr_db_set', 'modulation_name_set', 'iq_set');
end
fprintf('#### phase-freq dataset is saving into "%s" file\n', mat_filename);

if call_python_for_making_dat_file
    pause(2);
    status = call_python(mat_filename, python_command);
    if status
        fprintf('### error: python command = %s failed\n', python_command);
    end
end

end

%%
function [iq] = random_select_iq_sample_and_apply_awgn(target_iq, instance_length, iq_sample_length, snr_db, ...
    channel_type, target_fs, max_freq_offset_hz, max_phase_offset_deg)

% ####### how to generate training signal
% (1) select random 128 samples among iq loaded from inf snr signal file
% (2) apply fading, snr, carrier offset
% (3) symbol synch error is NOT needed because 128 samples are random selected

fd = 0; % doppler shift freq

imax = length(target_iq) - iq_sample_length + 1;

iq = zeros(instance_length, iq_sample_length);
for n = 1 : instance_length
    
    % select random 128 samples among iq loaded from inf snr signal file
    idx = randi(imax, 1);
    pre_iq = target_iq(idx : idx + iq_sample_length - 1);
    
    % apply fading channel
    if ~isempty(channel_type)
        pre_iq = apply_fading_channel(pre_iq, channel_type, target_fs, fd);
    end
    
    % apply carrier offset
    if max_freq_offset_hz || max_phase_offset_deg
        pre_iq = apply_carrier_offset(pre_iq, target_fs, max_freq_offset_hz, max_phase_offset_deg);
    end
    
    % add awgn noise to signal
    if ~isempty(snr_db)
        pre_iq = awgn(pre_iq, snr_db, 'measured', 'db');
    end    
    
    % normalize
    pre_iq = pre_iq / max(abs(pre_iq));
    
    % vertical stack into iq
    iq(n, :) = pre_iq;
end

end

%%
function [pf] = pfcnn_compute_phase_freq(iq, fs_hz, use_fs, normalize_freq)

% iq dimension = (instance_length, iq_sample_length)
[instance_length, iq_sample_length] = size(iq);

% phase-freq array
pf = zeros(instance_length, iq_sample_length);

for n = 1 : instance_length
    % compute phase
    phase_cnn = angle(iq(n, :)) / pi;
    % compute freq which is derivate of phase
    if use_fs
        freq_cnn = diff(phase_cnn) * (fs_hz / 1e6);
        
        if normalize_freq
            freq_cnn = freq_cnn / max(abs(freq_cnn));
        end
    else
        freq_cnn = diff(phase_cnn);
    end
    
    % freq_cnn length was 127. to make 128 freq_cnn, append last element to freq_cnn
    freq_cnn = [freq_cnn, freq_cnn(end)];
    
    pf(n, :) = complex(phase_cnn, freq_cnn);
end

end


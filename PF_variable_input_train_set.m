function [] = PF_variable_input_train_set(train_set_dir_name, instance_length, filename_append_string)
% generate train set whose input length is variable 
%
% good for model: PF(Phase Frequency) variable input LSTM
%
% when 1000 instance, 7 modulation and 16 snr, program run time =  min 
% (pc spec: cpu = Intel Core i7-4930K, ram = 64 GB, main board = P9X79, os = windows 7 64-bit)
%
% [input]
% - train_set_dir_name: foler name where train set is generated.
% - instance_length: instance length per modulation class and per variable, recommend = 1000
% - filename_append_string: mat filename appended string
%   when '_new_test', RML2018_gsmRAx4c2_1000instance.mat => RML2018_gsmRAx4c2_1000instance_new_test.mat
%
% [usage]
% PF_variable_input_train_set('e:\temp\mod_signal', 1000, '')

% modulation(exactly technology) name cell
% 'fmsimple' = simple licensed(narrow band fm), 'fmbroad' = fm broadcasting(wide band fm)
modulation_name_cell = {'fmbroad', 'fmsimple', 'hdtv', 'lte', 'tdmb', 'tetra', 'wcdma'};
mod_length = length(modulation_name_cell);

% for n = 1 : mod_length
%     M(n).modulation_name = modulation_name_cell{n};
%     if n == 3
%         M(n).samle_length = [128, 256, 512];
%     else
%         M(n).samle_length = [128, 256];
%     end
%     M(n).filename = {'abd', 'dfe'};
% end
% M(3)

% signal file for model train

% ### when single sample rate, which is better? same or different file
fmbroad_filename = {'E:\iq_from_fsq\fmbroadcast\fsq_iq_181205093757_95.7_0.192_0.24.mat', ...
    'E:\iq_from_fsq\fmbroadcast\fsq_iq_181205093757_95.7_0.192_0.24.mat'};
fmbroad_sample = [256, 256];

% #### to have 'inf_snr_simpe_radio_fd2500_fs14700.mat', 
% #### use 'inf_snr_generate_simple_radio_signal.m'
fmsimple_filename = {'inf_snr_simpe_radio_fd2500_fs14700.mat', 'inf_snr_simpe_radio_fd2500_fs14700.mat'};
fmsimple_sample = [256, 256];

hdtv_filename = {'E:\iq_from_fsq\hdtv_fp5.38\fsq_iq_190320135046_473.000000_10.760000_fp5.380000.mat', ...
    'E:\iq_from_fsq\hdtv_fp5.38\fsq_iq_190320133832_473.000000_21.520000_fp5.380000.mat'};
hdtv_sample = [128, 256];

lte_filename = {'E:\iq_from_fsq\lte_ext_ref_fp9.015\fsq_iq_190625133044_879.000000_10_15.360000_fp9.015000.mat', ...
    'E:\iq_from_fsq\lte_ext_ref_fp9.015\fsq_iq_190625133044_879.000000_10_15.360000_fp9.015000.mat'};
lte_sample = [256, 256];

tdmb_filename = {'E:\iq_from_fsq\tdmb_fp1.536\fsq_iq_190409152007_199.280000_2.048000_fp1.536000.mat', ...
    'E:\iq_from_fsq\tdmb_fp1.536\fsq_iq_190409152353_199.280000_4.096000_fp1.536000.mat'};
tdmb_sample = [128, 256];

tetra_filename = {'E:\iq_from_fsq\tetra_govern_fp0.023\fsq_iq_190424142825_855.762500_0.036000_fp0.023000.mat', ...
    'E:\iq_from_fsq\tetra_govern_fp0.023\fsq_iq_190424142946_855.762500_0.072000_fp0.023000.mat'};
tetra_sample = [128, 256];

wcdma_filename = {'E:\iq_from_fsq\wcdma_ext_ref_rcos\fsq_iq_190430091112_2162.400000_7.680000_rolloff0.22_span10.mat', ...
    'E:\iq_from_fsq\wcdma_ext_ref_rcos\fsq_iq_190430091125_2162.400000_15.360000_rolloff0.22_span10.mat'};
wcdma_sample = [128, 256];

% 'wcdma' selection is for readability because 'wcdma' is last signal in alphabet order
variable_length = length(wcdma_sample);
% must be max in signal sample, current 256
max_iq_sample_length = max(wcdma_sample);

% fmbroad = struct([]);

% load signal from iq file
for m = 1 : variable_length
    fmbroad(m).S = load(fmbroad_filename{m});
    fmbroad(m).iq_sample_length = fmbroad_sample(m);
    
    fmsimple(m).S = load(fmsimple_filename{m});
    % ### only fmsimple file generated from simulation have not 'sample_rate_mhz', but 'fs'
    % ### so need trick 
    fmsimple(m).S.sample_rate_mhz = fmsimple(m).S.fs / 1e6;
    fmsimple(m).iq_sample_length = fmsimple_sample(m);
    
    hdtv(m).S = load(hdtv_filename{m});
    hdtv(m).iq_sample_length = hdtv_sample(m);
    
    lte(m).S = load(lte_filename{m});
    lte(m).iq_sample_length = lte_sample(m);
    
    tdmb(m).S = load(tdmb_filename{m});
    tdmb(m).iq_sample_length = tdmb_sample(m);
    
    tetra(m).S = load(tetra_filename{m});
    tetra(m).iq_sample_length = tetra_sample(m);
    
    wcdma(m).S = load(wcdma_filename{m});
    wcdma(m).iq_sample_length = wcdma_sample(m);
end

fprintf('########## all signal loaded from file\n');

% % use in "pfcnn_compute_phase_freq" function
% % ##################### DONT SET TO 1
% % use_fs = 1;
% use_fs = 0;
% normalize_freq = 0;

% % ### fixed for cnn model input
% max_iq_sample_length = 128;

% ################################################################
% assumed that snr of signal received from rx antenna is near infinite
% ################################################################
snr_db_vec = -10:2:20;
snr_length = length(snr_db_vec);

% % fading channel
% channel_type = 'gsmRAx4c2';

call_python_for_making_dat_file = 1;
python_command = 'E:\\modulation classification\\matlab_dataset\\pfcnn_make_dict_from_mat_file.py';

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
pf_set = zeros(mod_length * snr_length, instance_length * variable_length, max_iq_sample_length);
% iq_set = zeros(mod_length * snr_length, instance_length * variable_length, max_iq_sample_length);

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
                
                target = fmsimple;
            case 'fmbroad'
                channel_type = [];
                max_freq_offset_hz = 0;
                max_phase_offset_deg = 0;
                
                target = fmbroad;
            case 'hdtv'
                channel_type = [];
                max_freq_offset_hz = 0;
                max_phase_offset_deg = 0;
                
                target = hdtv;     
            case 'lte'
                channel_type = [];
                max_freq_offset_hz = 0;
                max_phase_offset_deg = 0;
                
                target = lte;
            case 'tdmb'
                channel_type = [];
                max_freq_offset_hz = 0;
                max_phase_offset_deg = 0;
                
                target = tdmb;
            case 'tetra'
                channel_type = [];
                max_freq_offset_hz = 0;
                max_phase_offset_deg = 0;
                
                target = tetra;
            case 'wcdma'
                channel_type = [];
                max_freq_offset_hz = 0;
                max_phase_offset_deg = 0;
                
                target = wcdma;
            otherwise
                fprintf('###### error: %s = unknown modulation name\n', modulation_name);
                return;
        end % end of switch
        
        % iq dimension = (instance_length * variable_length) x max_iq_sample_length
        % ########## instance_length is for each sample length:
        % ########## total instance length = instance_length * variable_length
        iq = random_select_iq_sample_and_apply_awgn(target, variable_length, instance_length, ...
            max_iq_sample_length, snr_db, channel_type, max_freq_offset_hz, max_phase_offset_deg);
        
        row_idx = (n - 1) * mod_length + m;
        
        snr_db_set(row_idx) = snr_db;
        modulation_name_set{row_idx} = modulation_name;
        
        phase_freq = compute_phase_freq(iq);
        pf_set(row_idx, :, :) = phase_freq;
            
    end % end of modulation
    
end % end of snr

% stop stopwatch timer
elapse_time_sec = toc;
fprintf('[%d max iq, %d instance, %d variable, %d snr, %d modulation] elapse time = %g min\n', ...
    max_iq_sample_length, instance_length, variable_length, snr_length, mod_length, elapse_time_sec / 60);

% make filename
filename_start_string = 'PF';
if isempty(filename_append_string)
    mat_filename = sprintf('%s\\%s_%dvar_%dinst_%dsnr_%dmod.mat', ...
        train_set_dir_name, filename_start_string, variable_length, instance_length, ...
        snr_length, mod_length);
else
    mat_filename = sprintf('%s\\%s_%dvar_%dinst_%dsnr_%dmod%s.mat', ...
        train_set_dir_name, filename_start_string, variable_length, instance_length, ...
        snr_length, mod_length, filename_append_string);
end

% save iq array, modulation name cell vector, snr db vector into mat file
save(mat_filename, 'snr_db_set', 'modulation_name_set', 'pf_set');
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
function [iq] = random_select_iq_sample_and_apply_awgn(target, variable_length, instance_length, ...
    max_iq_sample_length, snr_db, channel_type, max_freq_offset_hz, max_phase_offset_deg)

% ##### target: struct array whose length is variable length
% struct field: 'iq', 'sample_rate_mhz', 'iq_sample_length'
target_length = length(target);
if variable_length ~= target_length
    error('variable length(= %d): not same as target struct array length(= %d)', ...
        variable_length, target_length);
end

% iq = zeros(instance_length * variable_length, max_iq_sample_length);
iq = [];

for m = 1 : variable_length
    target_iq = target(m).S.iq;
    target_fs = target(m).S.sample_rate_mhz * 1e6;
    iq_sample_length = target(m).iq_sample_length;
    
    sub_iq = ...
        sub_random_select_iq_sample_and_apply_awgn(target_iq, instance_length, iq_sample_length, snr_db, ...
        channel_type, target_fs, max_freq_offset_hz, max_phase_offset_deg);
    % 'sub_iq' dimension = instance_length x iq_sample_length
    
    % zero padding horizontally
    if iq_sample_length < max_iq_sample_length
%         fprintf('m = %d, zero pad\n', m);
        sub_iq = [sub_iq, zeros(instance_length, max_iq_sample_length - iq_sample_length)];
    end
    
    % accumulate
    iq = [iq; sub_iq];
end
size(iq); % dimension must be (instance_length * variable_length) x max_iq_sample_length

end

%%
function [iq] = sub_random_select_iq_sample_and_apply_awgn(target_iq, instance_length, iq_sample_length, snr_db, ...
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
function [pf] = compute_phase_freq(iq)

% iq dimension = (instance_length, iq_sample_length)
[instance_length, iq_sample_length] = size(iq);

% phase-freq array
pf = zeros(instance_length, iq_sample_length);

for n = 1 : instance_length
    % compute phase
    phase_instant = angle(iq(n, :)) / pi;
    
    % compute freq which is derivate of phase
    freq_instant = diff(phase_instant);
    % freq_cnn length was 127. to make 128 freq_cnn, append last element to freq_cnn
    freq_instant = [freq_instant, freq_instant(end)];
    
    pf(n, :) = complex(phase_instant, freq_instant);
end

end


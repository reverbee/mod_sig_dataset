function [] = display_iq_RML2018(my_modulation_name_cell, my_snr)
% display iq sample in modulation signal dataset(mat file)
% modulation signal dataset is created using "generate_modulation_signal_single_mat.m"
%
% [input]
% - my_modulation_name_cell: if empty, all modulation
% - my_snr: snr in db in which iq is displayed
%
% [usage]
% display_iq_RML2018({'bpsk','qpsk','2fsk','4fsk','16qam'}, 16)
% display_iq_RML2018('', 16)

mat_filename = 'E:\temp\mod_signal\RML2018_gsmRAx4c2_1000instance.mat';

% modulation_name_cell = {'amsc','ssb','nbfm','bpsk','qpsk','2fsk','4fsk','16qam'};
% my_modulation_name_cell = {'bpsk','qpsk','2fsk','4fsk','16qam'};
if isempty(my_modulation_name_cell)
    my_modulation_name_cell = {'amsc','ssb','nbfm','bpsk','qpsk','2fsk','4fsk','16qam'};
end
my_mod_length = length(my_modulation_name_cell);

% ########## reminder: what is in param mat file 
% ########## see "generate_modulation_signal_single_mat.m"
%
% % write parameter(modulation name, sample rate, freq offset, snr_db) into mat file
% param_mat_filename = sprintf('%s\\RML2018_param.mat', signal_dir_name);
% save(param_mat_filename, ...
%     'modulation_name_cell', 'channel_fs_hz_vec', 'max_freq_offset_hz_vec', 'snr_db_vec');

% param_mat_filename = 'E:\temp\mod_signal\RML2018_param_analog.mat';
% param_mat_filename = 'E:\temp\mod_signal\RML2018_param_all.mat';
param_mat_filename = 'E:\temp\mod_signal\RML2018_param.mat';
% param_mat_filename = 'E:\temp\mod_signal\RML2018_param_digital.mat';
load(param_mat_filename);

mod_length = length(modulation_name_cell);
snr_length = length(snr_db_vec);

if ~sum(snr_db_vec == my_snr)
    fprintf('#### error: my_snr must be in snr_db_vec\n');
    return;
end

% % in later, below two array will be loaded from mat file: 
% % rewrite "generate_modulation_signal_single_mat.m"
% modulation_name_cell = {'amsc','ssb','nbfm','bpsk','qpsk','2fsk','4fsk','16qam'};
% snr_db_vec = -10:2:20;

% ########## reminder: what is in mat file 
% ########## see "generate_modulation_signal_single_mat.m"
%
% % make array which be saved into mat file.
% % python code read it from mat file
% modulation_name_set = cell(mod_length * snr_length, 1);
% snr_db_set = zeros(mod_length * snr_length, 1);
% % make dimension same as python code. (free in matlab, not in python)
% iq_set = zeros(mod_length * snr_length, instance_length, iq_sample_length);
%
% mat_filename = sprintf('%s\\RML2018_%s_%d.mat', signal_dir_name, channel_type, instance_length);
% save(mat_filename, 'snr_db_set', 'modulation_name_set', 'iq_set');

load(mat_filename);
snr_db_set;
modulation_name_set;
[tuple_length, instance_length, iq_sample_length] = size(iq_set);
if tuple_length ~= mod_length * snr_length
    fprintf('#### error: dataset dimension is wrong\n#### check paramter file\n');
    return;
end

snr_bool = snr_db_set == my_snr;
instance_idx = randi([1, instance_length]);

iq_set = squeeze(iq_set(snr_bool, instance_idx, :));
size(iq_set)

% #########################################################################################################
% ### below parameter for raised cosine filter must be same as "generate_modulation_signal_single_mat.m"
% #########################################################################################################
% design raised cosine filter for pulse shaping
rolloff = .25; % roll-off factor
span = 6; % number of symbols
sample_per_symbol = 8;
shape = 'sqrt'; % root raised cosine filter
rrc_filter = rcosdesign(rolloff, span, sample_per_symbol, shape);

for n = 1 : my_mod_length
    modulation_name = my_modulation_name_cell{n};
    
    idx = find(ismember(modulation_name_cell, modulation_name));
    
    iq = squeeze(iq_set(idx, :)).';
    
    chan_fs = channel_fs_hz_vec(idx);
    
    plot_signal(iq, chan_fs, sprintf('[%s] snr = %d dB', modulation_name, my_snr));
    
    % only plot constellation for psk ad qam 
    % to make sure "generate_modulation_signal_single_mat.m" is NOT garbage
    % to see nice constellation,
    % must set parameter in "generate_modulation_signal_single_mat.m" to ideal(not realistic):
    % ### channel_type = '';
    % ### max_freq_offset_hz_vec = [0, 0, 0, 0, 0, 0, 0, 0];
    % ### max_phase_offset_deg = 0;
    % ### iq_from_1st_sample = 1;
    switch modulation_name
        case {'bpsk', 'qpsk', '16qam'}
            % rrc filter and down sample
            iq = upfirdn(iq, rrc_filter, 1, sample_per_symbol);
            % remove filter transient
            iq = iq(span + 1 : end - span);
            length(iq);
            
            plot_constellation(iq, modulation_name);
    end
end





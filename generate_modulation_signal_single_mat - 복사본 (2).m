function [] = generate_modulation_signal_single_mat(signal_dir_name)
% generate modulation signal and save all signal into single mat file
%
% [input]
% - signal_dir_name: signal foler name where signal is generated. if not exist, folder will be created
%
% [usage]
% generate_modulation_signal_single_mat('e:\temp\mod_signal')

large_fsk_modulation_index = 1;

% 'amsc': am suppressed carrier, 'nbfm': narrow band fm
modulation_name_cell = {'amsc','ssb','nbfm','bpsk','qpsk','2fsk','4fsk','16qam'};
mod_length = length(modulation_name_cell);

% instance length per modulation class
instance_length = 10; % original = 1000

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

% length must be same as modulation_name length
channel_fs_hz_vec = [44.1e3, 44.1e3, 44.1e3, 1e6, 1e6, 1e6, 1e6, 1e6];
if length(channel_fs_hz_vec) ~= mod_length
    fprintf('###### error: channel_fs length must be same as modulation_name length\n');
    return;
end

% length must be same as modulation_name length
% max_freq_offset_hz_vec = [0, 0, 0, 0, 0, 0, 0, 0]; % no freq offset. not realistic
max_freq_offset_hz_vec = [100, 100, 100, 100, 100, 100, 100, 100];
if length(max_freq_offset_hz_vec) ~= mod_length
    fprintf('###### error: max_freq_offset length must be same as modulation_name length\n');
    return;
end

% only scalar is supported. 0 or 180 may be meaningful
% max_phase_offset_deg = 0; % no freq offset. not realistic
max_phase_offset_deg = 180;

if ~exist(signal_dir_name, 'dir')
    [status, ~, ~] = mkdir(signal_dir_name);
    if ~status
        fprintf('###### error: making signal folder is failed\n');
        return;
    end
end

snr_length = length(snr_db_vec);

% % below 3: modulation_name, snr_db, iq
% % modulation_name: 
% % snr_db: 
% % iq: dimension = iq_sample_length x instance_length, data type = single float
% iq_dataset = cell(mod_length * snr_length, 3);

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
                iq = gen_am_mod_iq(instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg);
            case 'ssb'
                iq = gen_ssb_mod_iq(instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg);
            case 'nbfm'
                iq = gen_nbfm_mod_iq(instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg);
            case 'bpsk'
                M = 2;
                iq = gen_psk_mod_iq(M, instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg);
            case 'qpsk'
                M = 4;
                iq = gen_psk_mod_iq(M, instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg);
            case '2fsk'
                M = 2;
                iq = gen_fsk_mod_iq(M, freq_sep_2fsk, instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg);
            case '4fsk'
                M = 4;
                iq = gen_fsk_mod_iq(M, freq_sep_4fsk, instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg);
            case '16qam'
                M = 16;
                iq = gen_qam_mod_iq(M, instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz, max_phase_offset_deg);
            otherwise
                fprintf('###### error: %s = unknown modulation name\n', modulation_name);
                cd(old_dir);
                return;
        end % end of switch
        
        % convert single float for small file size
        % iq dimension = instance_length x iq_sample_length
        iq = single(iq);
        
        row_idx = (n - 1) * mod_length + m;
        
        snr_db_set(row_idx) = snr_db;
        modulation_name_set{row_idx} = modulation_name;
        iq_set(row_idx, :, :) = iq;
        
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
mat_filename = sprintf('%s\\RML2018_%s_%d.mat', signal_dir_name, channel_type, instance_length);
save(mat_filename, 'snr_db_set', 'modulation_name_set', 'iq_set');
fprintf('#### iq dataset is saving into "%s" file\n', mat_filename);

% write parameter(modulation name, sample rate, freq offset) into excel file
excel_filename = sprintf('%s\\RML2018_param.xlsx', signal_dir_name);
% write header
xlswrite(excel_filename, {'modulation', 'sample rate', 'max freq offset'}, 'a1:c1');
% write modulation name
xlswrite(excel_filename, modulation_name_cell', sprintf('a2:a%d', mod_length + 1));
% write sample rate
xlswrite(excel_filename, channel_fs_hz_vec', sprintf('b2:b%d', mod_length + 1));
% write max freq offset
xlswrite(excel_filename, max_freq_offset_hz_vec', sprintf('c2:c%d', mod_length + 1));
fprintf('#### parameter is saving into "%s" file\n', excel_filename);

end

%%
function [iq] = gen_am_mod_iq(instance_length, iq_sample_length, snr_db, ...
    chan_type, chan_fs, max_freq_offset_hz, max_phase_offset_deg)

plot_modulated_signal = 0;
sound_demod = 0;
fd = 0;
save_iq = 0;
% max_phase_offset_deg = 180;

source_sample_length = iq_sample_length * 2;
start_idx = round(iq_sample_length * .5);

iq = zeros(instance_length, iq_sample_length);
for n = 1 : instance_length
    [pre_iq, ~] = ...
        am_modulation(source_sample_length, snr_db, plot_modulated_signal, sound_demod, ...
        chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
    
    % remove transient
    pre_iq = pre_iq(start_idx : start_idx + iq_sample_length - 1);
    
    % normalize
    pre_iq = pre_iq / max(abs(pre_iq));
    
    % vertical stack into iq
    iq(n, :) = pre_iq;   
end

end

%%
function [iq] = gen_ssb_mod_iq(instance_length, iq_sample_length, snr_db, ...
    chan_type, chan_fs, max_freq_offset_hz, max_phase_offset_deg)

plot_modulated_signal = 0;
sound_demod = 0;
fd = 0;
save_iq = 0;
% max_phase_offset_deg = 180;

usb = 0;

source_sample_length = iq_sample_length * 2;
start_idx = round(iq_sample_length * .5);

iq = zeros(instance_length, iq_sample_length);
for n = 1 : instance_length
    [pre_iq, ~] = ...
        ssb_modulation(source_sample_length, snr_db, usb, plot_modulated_signal, sound_demod, ...
        chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
    
    % remove transient
    pre_iq = pre_iq(start_idx : start_idx + iq_sample_length - 1);
    
    % normalize
    pre_iq = pre_iq / max(abs(pre_iq));
    
    % vertical stack into iq
    iq(n, :) = pre_iq;  
end

end

%%
function [iq] = gen_nbfm_mod_iq(instance_length, iq_sample_length, snr_db, ...
    chan_type, chan_fs, max_freq_offset_hz, max_phase_offset_deg)

plot_modulated_signal = 0;
sound_demod = 0;
fd = 0;
save_iq = 0;
% max_phase_offset_deg = 180;

freq_dev = 1e3;

source_sample_length = iq_sample_length * 2;
start_idx = round(iq_sample_length * .5);

iq = zeros(instance_length, iq_sample_length);
for n = 1 : instance_length
    [pre_iq, ~] = ...
        nbfm_modulation(source_sample_length, freq_dev, snr_db, plot_modulated_signal, sound_demod, ...
        chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
    
    % remove transient
    pre_iq = pre_iq(start_idx : start_idx + iq_sample_length - 1);
    
    % normalize
    pre_iq = pre_iq / max(abs(pre_iq));
    
    % vertical stack into iq
    iq(n, :) = pre_iq;
end

end

%%
function [iq] = gen_psk_mod_iq(M, instance_length, iq_sample_length, snr_db, ...
    chan_type, chan_fs, max_freq_offset_hz, max_phase_offset_deg)

plot_modulated = 0;
plot_stella = 0;
fd = 0;
save_iq = 0;
% max_phase_offset_deg = 180;
sample_per_symbol = 8;
fs = 1;

symbol_length = round(iq_sample_length * 2 / sample_per_symbol);
start_idx = round(iq_sample_length * .5);

iq = zeros(instance_length, iq_sample_length);
for n = 1 : instance_length
    [pre_iq] = ...
        psk_modulation(M, symbol_length, sample_per_symbol, snr_db, fs, plot_modulated, plot_stella, ...
        chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
    
    % remove transient
    pre_iq = pre_iq(start_idx : start_idx + iq_sample_length - 1);
    
    % normalize
    pre_iq = pre_iq / max(abs(pre_iq));
    
    % vertical stack into iq
    iq(n, :) = pre_iq;
end

end

%%
function [iq] = gen_fsk_mod_iq(M, freq_sep, instance_length, iq_sample_length, snr_db, ...
    chan_type, chan_fs, max_freq_offset_hz, max_phase_offset_deg)

plot_modulated = 0;
plot_stella = 0;
fd = 0;
save_iq = 0;
% max_phase_offset_deg = 180;
sample_per_symbol = 8;
fs = 1;

symbol_length = round(iq_sample_length * 2 / sample_per_symbol);
start_idx = round(iq_sample_length * .5);

iq = zeros(instance_length, iq_sample_length);
for n = 1 : instance_length
    [pre_iq] = ...
        fsk_modulation(M, freq_sep, symbol_length, sample_per_symbol, snr_db, fs, plot_modulated, plot_stella, ...
        chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
    
    % remove transient
    pre_iq = pre_iq(start_idx : start_idx + iq_sample_length - 1);
    
    % normalize
    pre_iq = pre_iq / max(abs(pre_iq));
    
    % vertical stack into iq
    iq(n, :) = pre_iq;
end

end

%%
function [iq] = gen_qam_mod_iq(M, instance_length, iq_sample_length, snr_db, ...
    chan_type, chan_fs, max_freq_offset_hz, max_phase_offset_deg)

plot_modulated = 0;
plot_stella = 0;
fd = 0;
save_iq = 0;
% max_phase_offset_deg = 180;
sample_per_symbol = 8;
fs = 1;

symbol_length = round(iq_sample_length * 2 / sample_per_symbol);
start_idx = round(iq_sample_length * .5);

iq = zeros(instance_length, iq_sample_length);
for n = 1 : instance_length
    [pre_iq] = ...
        qam_modulation(M, symbol_length, sample_per_symbol, snr_db, fs, plot_modulated, plot_stella, ...
        chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
    
    % remove transient
    pre_iq = pre_iq(start_idx : start_idx + iq_sample_length - 1);
    
    % normalize
    pre_iq = pre_iq / max(abs(pre_iq));
    
    % vertical stack into iq
    iq(n, :) = pre_iq;
end

end



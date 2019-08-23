function [] = generate_modulation_signal(signal_dir_name)
% generate modulation signal and save into mat file
% mat file is created every (modulation_name, snr_db) pair
% (example) when 8 modulation class and 16 snr, 128 mat file is created
% recommend to use "generate_modulation_signal_single_mat"
%
% [input]
% - signal_dir_name: signal foler name where signal is generated
% 
% [usage]
% generate_modulation_signal('e:\temp\mod_signal')

large_fsk_modulation_index = 1;

modulation_name_cell = {'amsc','ssb','nbfm','bpsk','qpsk','2fsk','4fsk','16qam'};
mod_length = length(modulation_name_cell);

% instance length per modulation class
instance_length = 1000;

iq_sample_length = 128;

snr_db_vec = -10:2:20;

channel_type = 'gsmRAx4c2';

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
max_freq_offset_hz_vec = [100, 100, 100, 100, 100, 100, 100, 100];
if length(max_freq_offset_hz_vec) ~= mod_length
    fprintf('###### error: max_freq_offset length must be same as modulation_name length\n');
    return;
end

if ~exist(signal_dir_name, 'dir')
    [status, ~, ~] = mkdir(signal_dir_name);
    if ~status
        fprintf('###### error: making signal folder is failed\n');
        return;
    end
end

% go to signal folder
old_dir = cd(signal_dir_name);

snr_length = length(snr_db_vec);

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
                    channel_type, channel_fs_hz, max_freq_offset_hz);
            case 'ssb'
                iq = gen_ssb_mod_iq(instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz);
            case 'nbfm'
                iq = gen_nbfm_mod_iq(instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz);
            case 'bpsk'
                M = 2;
                iq = gen_psk_mod_iq(M, instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz);
            case 'qpsk'
                M = 4;
                iq = gen_psk_mod_iq(M, instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz);
            case '2fsk'
                M = 2;
                iq = gen_fsk_mod_iq(M, freq_sep_2fsk, instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz);
            case '4fsk'
                M = 4;
                iq = gen_fsk_mod_iq(M, freq_sep_4fsk, instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz);
            case '16qam'
                M = 16;
                iq = gen_qam_mod_iq(M, instance_length, iq_sample_length, snr_db, ...
                    channel_type, channel_fs_hz, max_freq_offset_hz);
            otherwise
                fprintf('###### error: %s = unknown modulation name\n', modulation_name);
                cd(old_dir);
                return;
        end % end of switch
        
        % convert single float. iq dimension = iq_sample_length x instance_length
        iq = single(iq);
        
        % save iq sample into mat file
        mat_filename = sprintf('%s%d%s%d.mat', modulation_name, snr_db, channel_type, max_freq_offset_hz);
        save(mat_filename, 'iq', 'modulation_name', 'snr_db');
          
    end % end of mod_length
end % end of snr_length

% return to old folder
cd(old_dir);

end

%%
function [iq] = gen_am_mod_iq(instance_length, iq_sample_length, snr_db, ...
    chan_type, chan_fs, max_freq_offset_hz)

plot_modulated_signal = 0;
sound_demod = 0;
fd = 0;
save_iq = 0;
max_phase_offset_deg = 180;

source_sample_length = iq_sample_length * 2;
start_idx = round(iq_sample_length * .5);

iq = zeros(iq_sample_length, instance_length);
for n = 1 : instance_length
    [pre_iq, ~] = ...
        am_modulation(source_sample_length, snr_db, plot_modulated_signal, sound_demod, ...
        chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
    
    % remove transient
    pre_iq = pre_iq(start_idx : start_idx + iq_sample_length - 1);
    
    % normalize
    pre_iq = pre_iq / max(abs(pre_iq));
    
    % horizontal stack into iq
    iq(:, n) = pre_iq;        
end

end

%%
function [iq] = gen_ssb_mod_iq(instance_length, iq_sample_length, snr_db, ...
    chan_type, chan_fs, max_freq_offset_hz)

plot_modulated_signal = 0;
sound_demod = 0;
fd = 0;
save_iq = 0;
max_phase_offset_deg = 180;

usb = 0;

source_sample_length = iq_sample_length * 2;
start_idx = round(iq_sample_length * .5);

iq = zeros(iq_sample_length, instance_length);
for n = 1 : instance_length
    [pre_iq, ~] = ...
        ssb_modulation(source_sample_length, snr_db, usb, plot_modulated_signal, sound_demod, ...
        chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
    
    % remove transient
    pre_iq = pre_iq(start_idx : start_idx + iq_sample_length - 1);
    
    % normalize
    pre_iq = pre_iq / max(abs(pre_iq));
    
    % horizontal stack into iq
    iq(:, n) = pre_iq;  
end

end

%%
function [iq] = gen_nbfm_mod_iq(instance_length, iq_sample_length, snr_db, ...
    chan_type, chan_fs, max_freq_offset_hz)

plot_modulated_signal = 0;
sound_demod = 0;
fd = 0;
save_iq = 0;
max_phase_offset_deg = 180;

freq_dev = 1e3;

source_sample_length = iq_sample_length * 2;
start_idx = round(iq_sample_length * .5);

iq = zeros(iq_sample_length, instance_length);
for n = 1 : instance_length
    [pre_iq, ~] = ...
        nbfm_modulation(source_sample_length, freq_dev, snr_db, plot_modulated_signal, sound_demod, ...
        chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
    
    % remove transient
    pre_iq = pre_iq(start_idx : start_idx + iq_sample_length - 1);
    
    % normalize
    pre_iq = pre_iq / max(abs(pre_iq));
    
    % horizontal stack into iq
    iq(:, n) = pre_iq;
end

end

%%
function [iq] = gen_psk_mod_iq(M, instance_length, iq_sample_length, snr_db, ...
    chan_type, chan_fs, max_freq_offset_hz)

plot_modulated = 0;
plot_stella = 0;
fd = 0;
save_iq = 0;
max_phase_offset_deg = 180;
sample_per_symbol = 8;
fs = 1;

symbol_length = round(iq_sample_length * 2 / sample_per_symbol);
start_idx = round(iq_sample_length * .5);

iq = zeros(iq_sample_length, instance_length);
for n = 1 : instance_length
    [pre_iq] = ...
        psk_modulation(M, symbol_length, sample_per_symbol, snr_db, fs, plot_modulated, plot_stella, ...
        chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
    
    % remove transient
    pre_iq = pre_iq(start_idx : start_idx + iq_sample_length - 1);
    
    % normalize
    pre_iq = pre_iq / max(abs(pre_iq));
    
    % horizontal stack into iq
    iq(:, n) = pre_iq;
end

end

%%
function [iq] = gen_fsk_mod_iq(M, freq_sep, instance_length, iq_sample_length, snr_db, ...
    chan_type, chan_fs, max_freq_offset_hz)

plot_modulated = 0;
plot_stella = 0;
fd = 0;
save_iq = 0;
max_phase_offset_deg = 180;
sample_per_symbol = 8;
fs = 1;

symbol_length = round(iq_sample_length * 2 / sample_per_symbol);
start_idx = round(iq_sample_length * .5);

iq = zeros(iq_sample_length, instance_length);
for n = 1 : instance_length
    [pre_iq] = ...
        fsk_modulation(M, freq_sep, symbol_length, sample_per_symbol, snr_db, fs, plot_modulated, plot_stella, ...
        chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
    
    % remove transient
    pre_iq = pre_iq(start_idx : start_idx + iq_sample_length - 1);
    
    % normalize
    pre_iq = pre_iq / max(abs(pre_iq));
    
    % horizontal stack into iq
    iq(:, n) = pre_iq;
end

end

%%
function [iq] = gen_qam_mod_iq(M, instance_length, iq_sample_length, snr_db, ...
    chan_type, chan_fs, max_freq_offset_hz)

plot_modulated = 0;
plot_stella = 0;
fd = 0;
save_iq = 0;
max_phase_offset_deg = 180;
sample_per_symbol = 8;
fs = 1;

symbol_length = round(iq_sample_length * 2 / sample_per_symbol);
start_idx = round(iq_sample_length * .5);

iq = zeros(iq_sample_length, instance_length);
for n = 1 : instance_length
    [pre_iq] = ...
        qam_modulation(M, symbol_length, sample_per_symbol, snr_db, fs, plot_modulated, plot_stella, ...
        chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
    
    % remove transient
    pre_iq = pre_iq(start_idx : start_idx + iq_sample_length - 1);
    
    % normalize
    pre_iq = pre_iq / max(abs(pre_iq));
    
    % horizontal stack into iq
    iq(:, n) = pre_iq;
end

end



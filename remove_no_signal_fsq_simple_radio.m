function [] = remove_no_signal_fsq_simple_radio(in_dir, out_dir, signal_threshold)
% batch version: all fsq iq file is processed in input directory, "in_dir"
%
% remove no signal section from 146 mhz analog simple radio signal in fsq iq file
% used to preprocess signal for making test dataset of narrow band fm signal
%
% modified from "awgn_remove_no_signal_simple_radio.m" (190411)
%
% ######### differ from "remove_no_signal_simple_radio.m":
% (1) compute signal power of normalized iq
% (2) multiply "signal_threshold" with normalized signal power to get signal threshold
%
% to compute signal power, code in "awgn.m" was used
% #########################################################
%
% to analyze signal, use "dcs_dtmf_simple_radio_fm_demod.m"
%
% method for no signal section removal:
% (1) signal threshold for normalized magnitude of iq
% (2) moving average filter, "smooth" function
% 
% [input]
% - in_dir: directory where simple radio iq file live
% - out_dir: directory where simple radio iq file removed no signal will be saved
% - signal_threshold: signal threshold.
%   only iq whose magnitude is greater than (normalized_signal_power) * (signal_threshold) will be saved
%   other iq will be discarded as it is assumed no signal.
%   recommend = 1
%   see "remove_no_sinal_section" local function
%
% [usage]
% remove_no_signal_fsq_simple_radio('E:\iq_from_fsq\simple', 'E:\iq_from_fsq\simple_no_signal_removed', 1)
%

% % to compute signal power, copy from "awgn.m"
% sigPower = sum(abs(sig(:)).^2)/length(sig(:)); % linear

% if output directory not exist, make directory
if ~exist(out_dir, 'dir')
    [status, ~, ~] = mkdir(out_dir);
    if ~status
        fprintf('###### error: making output folder is failed\n');
        return;
    end
end

D = dir(sprintf('%s\\*.mat', in_dir));

file_length = length(D);
if ~file_length
    fprintf('##### no iq file in ''%s''\n', in_dir);
    return;
end

for n = 1 : file_length
    filename = D(n).name;
    fprintf('%s\n', filename);
    fsq_iq_filename = sprintf('%s\\%s', in_dir, filename);
    
    % ###### reminding what fsq_iq_filename have: see "get_iq_from_fsq.py"
    % # for backward compatibility: see "get_iq_from_fsq_181122.m" and "plot_fsq_iq.m"
    %     savemat(mat_filepath,
    %     dict([('iq', iq), ('center_freq_mhz', fsq_freq_mhz), ('signal_bw_mhz', bw_mhz),
    %         ('sample_rate_mhz', sample_rate_mhz), ('sample_length', iq_length),
    %         ('timestamp', timestamp)]))
    load(fsq_iq_filename);
    
    % sure shot to make column vector, "get_iq_from_fsq.py" save iq array with row vector format
    iq = iq(:);
    size(iq)
    
    % remove no signal section
    iq = remove_no_sinal_section(iq, signal_threshold);
    size(iq)
    
    if length(iq) < 128
        continue;
    end
    
    % make no signal removed iq filename
    [~, name, ~] = fileparts(filename);
    removed_iq_filename = sprintf('%s\\%s_th%g.mat', out_dir, name, signal_threshold);
    
    % save filtered iq into file
    save(removed_iq_filename, ...
        'iq', 'center_freq_mhz', 'sample_rate_mhz', 'sample_length', 'signal_threshold');
    fprintf('no signal removed iq saved into ''%s''\n', removed_iq_filename);
    
    pause(1);
end

end

%%
function [iq] = remove_no_sinal_section(iq, signal_threshold)

% normalize iq
norm_iq = iq / max(abs(iq));

% compute normalized iq magnitude
abs_norm_iq = abs(norm_iq);

% compute normalized signal power
norm_sig_power = sum(abs_norm_iq .^ 2) / length(norm_iq);

% get signal index
sig_idx = (abs_norm_iq >= (norm_sig_power * signal_threshold));

% remove no signal(noise) section
iq = iq(sig_idx);

end



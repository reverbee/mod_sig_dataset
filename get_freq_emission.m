function [] = get_freq_emission(freq_mhz_start, freq_mhz_stop, print_itu_emission, plot_strip)
% get freq, itu emission designator from "freq emission power" file
%
% "freq emission power" file = "freq_emission_power_dict(190213).mat"
% to make this file, use "load_fep_dict.py"
%
% =================================================
% (1) "get_freq_emission_multi_sheet.py":
% input = "freq_daejeon_crmo_20190213(corrected).xls" (sheet = 1 ~ 7)
% output = "freq_emission_power_dict(190213).bin"
% 
% (2) "get_freq_emission_broadcasting.py"
% input = "freq_daejeon_crmo_20190213(corrected).xls" (sheet = broadcasting)
% output = "freq_emission_broadcasting_dict(190213).bin"
% 
% (3) "load_fep_dict.py"
% input = "freq_emission_power_dict(190213).bin", 
%         "freq_emission_broadcasting_dict(190213).bin"
% output = "freq_emission_power_dict(190213).mat"
% =====================================
%
% [input]
% - freq_mhz_start: start freq mhz
% - freq_mhz_stop: stop freq mhz
% - print_itu_emission: 
%   0 = (plot freq strip) or (plot freq and necessary bw), 1 = print itu emission for each freq
%   when 1, 'plot_strip' input is ignored
% - plot_strip: 0 = plot freq strip, 1 = plot freq(x axis) and necessary bw(y axis)
%   only when print_itu_emission = 0, 'plot_strip' input have effect
% 
% [usage]
% get_freq_emission(200, 500, 1, 0)
% get_freq_emission(200, 500, 0, 0)
% get_freq_emission(200, 500, 0, 1)
%

% 1 = plot occupied freq strip, 0 = plot freq(x axis) and necessary bw(y axis)
% plot_strip = 0;

colormap_str = 'jet';
% colormap_str = 'default';

% "freq emission power" file
mat_filename = 'E:\temp\freq_emission_power_dict(190213).mat';

% ###### "load_fep_dict.py"
% savemat(mat_filename,
%         dict([('freq_hz', freq_hz), ('max_bw_khz', max_bw_khz), ('itu_emission', itu_emission)]))

load(mat_filename);

freq_mhz = double(freq_hz) / 1e6;

start_idx = find(freq_mhz >= freq_mhz_start, 1, 'first');
stop_idx = find(freq_mhz <= freq_mhz_stop, 1, 'last');
idx = start_idx : stop_idx;
if isempty(idx)
    fprintf('##### no freq in %f ~ %f mhz\n', freq_mhz_start, freq_mhz_stop);
    return;
end

[min_bw_mhz, max_bw_mhz] = get_min_max_bw_mhz(max_bw_khz, idx);
if ~print_itu_emission && (min_bw_mhz == max_bw_mhz)
    fprintf('##### [bw = %f mhz] for plot freq, bw length must be greater than 1\n', min_bw_mhz);
    fprintf('##### set freq range wider\n');
    return;
end

if ~print_itu_emission
    freq_mhz(idx)
    
    if plot_strip
        plot_occupied_freq_strip_colorbar(idx, freq_mhz, max_bw_khz, freq_mhz_start, freq_mhz_stop, ...
            colormap_str);
%         plot_occupied_freq_strip(idx, freq_mhz, max_bw_khz, freq_mhz_start, freq_mhz_stop);
    else
        figure;
        f = freq_mhz(idx);
        plot(f, max_bw_khz(idx), 's');
        grid on;
        xlabel('freq mhz'); ylabel('max necessary bw khz');
        yl = ylim;
        ylim([0, yl(2) * 1.1]);
        title(sprintf('occupied freq: %f ~ %f mhz', freq_mhz_start, freq_mhz_stop));
    end
else
    print_emission_for_each_freq(idx, freq_mhz, itu_emission, max_bw_khz);
end

end

%%
function [] = plot_occupied_freq_strip_colorbar(idx, freq_mhz, bw_khz, freq_mhz_start, freq_mhz_stop, ...
    colormap_str)
% ###### almost finished (190817)

idx_len = length(idx);

[min_bw_mhz, max_bw_mhz] = get_min_max_bw_mhz(bw_khz, idx);

x = []; y = []; c = [];
for n = 1 : idx_len
    bw_mhz = bw_khz(idx(n)) / 1e3;
    if bw_mhz == 0
        continue;
    end
    
    center_freq_mhz = freq_mhz(idx(n));
    ocfm = [center_freq_mhz - bw_mhz/2; center_freq_mhz + bw_mhz/2; ...
        center_freq_mhz + bw_mhz/2; center_freq_mhz - bw_mhz/2];
    tmp_c = get_color(bw_mhz, min_bw_mhz, max_bw_mhz);
    
    x = [x, ocfm];
    y = [y, [0; 0; 1; 1]];
    c = [c; tmp_c];
end

figure;
patch(x, y, c);
% patch(x, y, 'blue');
xlim([freq_mhz_start, freq_mhz_stop]);
ylim([0, 1.2]);
grid on;
xlabel('freq mhz');
set(gca, 'YtickLabel', {});
% set(gca, 'Ytick', []);
title(sprintf('occupied freq: %f ~ %f mhz', freq_mhz_start, freq_mhz_stop));
colormap(colormap_str);
B = colorbar;
% set colorbar appearance
set_colorbar(B, min_bw_mhz, max_bw_mhz);

end

%%
function [] = set_colorbar(B, min_bw_mhz, max_bw_mhz)

B.Label.String = 'bw mhz';
B.Label.FontWeight = 'bold';
B.Label.Color = [0 0 0];
B.Label.FontSize = 11;
% 11 x 1 cell array
B.TickLabels = num2cell(linspace(min_bw_mhz, max_bw_mhz, 11));

end

%%
function [min_bw_mhz, max_bw_mhz] = get_min_max_bw_mhz(bw_khz, idx)

bw_mhz = bw_khz(idx) / 1e3;
idx = (bw_mhz ~= 0);
bw_mhz = bw_mhz(idx);

min_bw_mhz = min(bw_mhz);
max_bw_mhz = max(bw_mhz);

end

%%
function [tmp_c] = get_color(bw_mhz, min_bw_mhz, max_bw_mhz)

if min_bw_mhz == max_bw_mhz
    % set lowest color: blue when 'jet', blue when 'parula'(r2017b default)
    tmp_c = 0;
else
    tmp_c = (bw_mhz - min_bw_mhz) / (max_bw_mhz - min_bw_mhz);
end

end

%%
function [] = plot_occupied_freq_strip(idx, freq_mhz, max_bw_khz, freq_mhz_start, freq_mhz_stop)

idx_len = length(idx);

x = []; y = [];
for n = 1 : idx_len
    bw_mhz = max_bw_khz(idx(n)) / 1e3;
    if bw_mhz == 0
        continue;
    end
    
    center_freq_mhz = freq_mhz(idx(n));
    ocfm = [center_freq_mhz - bw_mhz/2; center_freq_mhz + bw_mhz/2; ...
        center_freq_mhz + bw_mhz/2; center_freq_mhz - bw_mhz/2];
    
    x = [x, ocfm];
    y = [y, [0; 0; 1; 1]];
end

figure;
patch(x, y, 'blue');
xlim([freq_mhz_start, freq_mhz_stop]);
ylim([0, 1.2]);
grid on;
xlabel('freq mhz');
set(gca, 'YtickLabel', {});
% set(gca, 'Ytick', []);
title(sprintf('occupied freq: %f ~ %f mhz', freq_mhz_start, freq_mhz_stop));

end

%%
function [] = print_emission_for_each_freq(idx, freq_mhz, itu_emission, max_bw_khz)

idx_len = length(idx);

for n = 1 : idx_len
    fprintf('freq = %f mhz, max bw = %f khz\n', freq_mhz(idx(n)), max_bw_khz(idx(n)));
    disp(itu_emission{idx(n)});
    fprintf('=========\n');
end

end



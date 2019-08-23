function [] = learn_analog_modulation_fs_change(mod_name, fs_vec)
% this program is to pre-study the below question:
% how modulation classifier performance is degraded 
% when sample rate of analog modulation signal is changed?
% 
% but i gave up testing modulation classifier performance:
% matlab analog modulation function do not work what i want
% (see signal plot)
%
% [input]
% - mod_name: one of '
% - fs_vec:
% 
% [usage]
% learn_analog_modulation_fs_change('amsc', 44.1e3*[1,2])

fs_length = length(fs_vec);

source_sample_length = 2^10;
plot_source_signal = 0;
sound_source = 0;
max_freq_of_source_signal = 5e3; % recommend = 5e3
[x, source_fs] = analog_source(source_sample_length, max_freq_of_source_signal, plot_source_signal, sound_source);
x_length = length(x);

y = zeros(x_length, fs_length);

for n = 1 : fs_length
    switch mod_name
        case 'amsc'
            % am
            % must satisfy fs > 2(fc + BW), where BW is the bandwidth of the modulating signal x.
            ini_phase = 0;
            % suppressed carrier am
            am_modulation_index = 0;
            carramp = am_modulation_index;
            fc = max_freq_of_source_signal;
            y(:, n) = ammod(x, fc, fs_vec(n), ini_phase, carramp);
        case 'amfc'
            % am
            % must satisfy fs > 2(fc + BW), where BW is the bandwidth of the modulating signal x.
            ini_phase = 0;
            % suppressed carrier am
            am_modulation_index = 0.5;
            carramp = am_modulation_index;
            fc = max_freq_of_source_signal;
            y(:, n) = ammod(x, fc, fs_vec(n), ini_phase, carramp);
        case 'nbfm'
            % narrow band fm.
            % see carson's rule, https://en.wikipedia.org/wiki/Frequency_modulation
            % fm_bandwidth = 2 * (freq_dev + max_freq_of_source_signal)
            % fm modulation index = freq_dev / max_freq_of_source_signal
            % freq_dev: peak deviation of instantaneous freq from fc
            % [example]
            % when max_freq_of_source_signal = 5e3, freq_dev = 1e3 (modulation index = 0.2)
            % occupied(98%) fm_bandwidth = 12e3
            freq_dev = 1e3;
            occupied_fm_bw = 2 * (freq_dev + max_freq_of_source_signal);
            fc = 10e3;
            y(:, n) = fmmod(x, fc, fs_vec(n), freq_dev);
        case 'ssb'
            % ssb modulation
            fc = 10e3;
            y(:, n) = ssbmod(x, fc, fs_vec(n));
        otherwise
            fprintf('#### error: unknown modulation name. one of ''amsc'',''amfc'',''nbfm'',''ssb''\n');
            return;
    end
end
size(y);

figure;
plot([x, y], '.-');
y_lim = ylim;
ylim(y_lim * 1.2);
grid on;

end
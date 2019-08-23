function [] = learn_carrier_freq_removal(am_modulation_index, iq_sample_length)
% learn how to remove carrier freq
%
% [usage]
% learn_carrier_freq_removal(.1, 2^10 + 1)

snr_db = 10;
plot_modulated_signal = 0; sound_demod = 0;
chan_type = '';
chan_fs = 0; fd = 0; save_iq = 0; max_freq_offset_hz = 0; max_phase_offset_deg = 0;

source_sample_length = iq_sample_length * 2;
[iq, fs] = ...
    am_modulation(am_modulation_index, source_sample_length, snr_db, plot_modulated_signal, sound_demod, ...
    chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
size(iq);

iq = iq(1 : iq_sample_length);

% remove carrier freq
iqc = iq - mean(abs(iq));

p = abs(fftshift(fft(iq)));
pc = abs(fftshift(fft(iqc)));

figure;
plot([p, pc], '.-');

end

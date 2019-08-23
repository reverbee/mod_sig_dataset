function [p] = learn_phase_unwrap(am_modulation_index)
% test bed for studying modulation feature
%
% [usage]
% learn_phase_unwrap(.1)

snr_db = 10;
plot_modulated_signal = 0; sound_demod = 0;
chan_type = '';
chan_fs = 0; fd = 0; save_iq = 0; max_freq_offset_hz = 0; max_phase_offset_deg = 0;

iq_sample_length = 2^10 + 1;
% am_modulation_index = 0;
source_sample_length = iq_sample_length * 2;
[iq, fs] = ...
    am_modulation(am_modulation_index, source_sample_length, snr_db, plot_modulated_signal, sound_demod, ...
    chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
size(iq)

iq = iq(1:iq_sample_length);

iqc = iq - mean(abs(iq));

p = abs(fftshift(fft(iq)));
pc = abs(fftshift(fft(iqc)));
figure;
plot([p, pc], '.-');

return;

% symbol_length = 2^10;
% sample_per_symbol = 8;
% snr_db = 10;
% fs = 1;
% plot_modulated = 0; plot_stella = 0;
% chan_type = '';
% chan_fs = 0; fd = 0; save_iq = 0; max_freq_offset_hz = 0; max_phase_offset_deg = 0;
% 
% iq = psk_modulation(M, symbol_length, sample_per_symbol, snr_db, fs, plot_modulated, plot_stella, ...
%     chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
% 
% % figure;
% % plot([real(iq), imag(iq)], '.-');
% 
% % iq_phase = angle(iq);
% % 
% % figure;
% % plot(iq_phase);
% 
% % normalize
% iq = iq / max(abs(iq));
% 
% sample_length = length(iq)
% 
% % % amplitude of iq sample
% % amp_iq = abs(iq);
% % 
% % % mean of amplitude of iq sample
% % mu_iq = sum(amp_iq) / sample_length;
% % 
% % amp_iq = amp_iq / mu_iq;
% % max(amp_iq)
% % min(amp_iq)
% % 
% % % select iq sample whose amplitude is greater than threshold
% % valid_idx = amp_iq > amplitude_threshold;
% % iq = iq(valid_idx);
% % length(iq) / sample_length
% % % sample_length = length(iq);
% % 
% % phase_iq = angle(iq);
% % 
% % figure;
% % plot(abs(phase_iq), '.-');





end

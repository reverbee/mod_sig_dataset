function [] = ...
    learn_phase_freq_offset_analog_mod(...
    modulation_filename, snr_db, fs, max_freq_offset_hz, max_phase_offset_deg)
% learn phase and freq offset for analog modulation
% using comm.phasefrequencyoffset
% used for carrier impairment (carrier recovery in receiver)
%
% [input]
% - modulation_filename: analog modulation signal mat filename
% - snr_db: snr in db
% - fs: sample rate. recommend 44.1e3
% - max_freq_offset_hz: freq offset = randi([-max_freq_offset_hz, max_freq_offset_hz]). 
%   if 0, no freq offset
% - max_phase_offset_deg: phase offset = randi([-max_phase_offset_deg, max_phase_offset_deg]). 
%   if 0, no phase offset
%
% [usage]
% learn_phase_freq_offset_analog_mod('ssb_modulation.mat', 10, 44.1e3, 100, 180)
% learn_phase_freq_offset_analog_mod('am_modulation.mat', 10, 44.1e3, 0, 180)
% learn_phase_freq_offset_analog_mod('nbfm_modulation.mat', 10, 44.1e3, 100, 0)
% 
% [reference]
% https://kr.mathworks.com/help/comm/ref/comm.phasefrequencyoffset-system-object.html
%

% ####### constant offset is ONLY considered
% ####### time varying offset is NOT considered
if max_freq_offset_hz
    freq_offset_hz = randi([-max_freq_offset_hz, max_freq_offset_hz]);
else
    freq_offset_hz = 0; 
end

if max_phase_offset_deg
    phase_offset_deg = randi([-max_phase_offset_deg, max_phase_offset_deg]);
else
    phase_offset_deg = 0;
end

% S: struct to protect variables in loaded file
S = load(modulation_filename);

% % ########### time varying offset is NOT considered ############
% sample_length = length(S.y);
% freq_offset_hz = -max_freq_offset_hz + 2 * max_freq_offset_hz * rand(sample_length, 1);
% phase_offset_deg = -max_phase_offset_deg + 2 * max_phase_offset_deg * rand(sample_length, 1);

% % design raised cosine filter for pulse shaping
% rolloff = .25; % roll-off factor
% span = 6; % number of symbols
% sample_per_symbol = S.sample_per_symbol;
% shape = 'sqrt'; % root raised cosine filter
% rrc_filter = rcosdesign(rolloff, span, sample_per_symbol, shape);

% add noise
y_awgn = awgn(S.y, snr_db, 'measured', 'db');

plot_signal(y_awgn, fs, sprintf('[no offset] %s', modulation_filename));
% plot_signal(y_awgn, S.fs, sprintf('[no fading] %s', modulation_filename));

% % rrc filter and down sample
% y_awgn_rx = upfirdn(y_awgn, rrc_filter, 1, sample_per_symbol);
% % remove filter transient
% y_awgn_rx = y_awgn_rx(span + 1 : end - span);
% 
% plot_constellation(y_awgn_rx, sprintf('[no offset] %s', modulation_filename));

if ~freq_offset_hz && ~phase_offset_deg
    fprintf('##### no offset\n');
    return;
end

% ############# insert phase and freq offset

% create phase freq offset object
h_offset = comm.PhaseFrequencyOffset(...
    'PhaseOffset', phase_offset_deg, ...
    'FrequencyOffset', freq_offset_hz, ...
    'SampleRate', fs);

% apply phase freq offset
y_impaired = step(h_offset, S.y);

% add noise
y_awgn = awgn(y_impaired, snr_db, 'measured', 'db');

plot_signal(y_awgn, fs, sprintf('[offset: freq = %d hz, phase = %d deg] %s', ...
    freq_offset_hz, phase_offset_deg, modulation_filename));
% plot_signal(y_awgn, S.fs, sprintf('[no fading] %s', modulation_filename));

% % rrc filter and down sample
% y_awgn_rx = upfirdn(y_awgn, rrc_filter, 1, sample_per_symbol);
% % remove filter transient
% y_awgn_rx = y_awgn_rx(span + 1 : end - span);
% 
% plot_constellation(y_awgn_rx, sprintf('[offset: freq = %d hz, phase = %d deg] %s', ...
%     freq_offset_hz, phase_offset_deg, modulation_filename));

end

%%
% % ##### matlab help comm.phasefrequencyoffset example
%
% data = (0:15)';
% M = 16; % Modulation order
% hMod = comm.RectangularQAMModulator(M);
% hPFO = comm.PhaseFrequencyOffset('PhaseOffset', 20, 'SampleRate', 1e-6);
% % Modulate data
% modData = step(hMod, data);
% scatterplot(modData);
% title(' Original Constellation');xlim([-5 5]);ylim([-5 5])
% % Introduce phase offset
% impairedData = step(hPFO, modData);
% scatterplot(impairedData);
% title('Constellation after phase offset');xlim([-5 5]);ylim([-5 5])

%%
% % ###### there is already comm.PhaseFrequencyOffset, so stop coding
% %
% % reference
% % https://kr.mathworks.com/help/comm/ref/phasefrequencyoffset.html
%
% freq_offset = 
% phase_offset = 
% ts = 1 / fs;
% y(1) = y(1) .* exp(1i * phase_offset(1));
% for n = 2 : sample_length
%     y(n) = y(n) .* exp(1i * 2 * pi * cumsum(freq_offset(1 : n - 1)) * ts + phase_offset(n));
% end

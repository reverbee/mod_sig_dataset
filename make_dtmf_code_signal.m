function [dtmf_code_signal] = make_dtmf_code_signal(dtmf_code, dtmf_code_duration, fs, plot_signal)
%
% [usage]
% make_dtmf_code_signal([0,1], .05, 14700, 0)

% dtmf code freq table
% [ref] https://en.wikipedia.org/wiki/Dual-tone_multi-frequency_signaling
dtmf_code_freq = [ ...
    941, 1336; % '0'
    697, 1209; % '1'
    697, 1336; % '2'
    697, 1477; % '3'
    770, 1209; % '4'
    770, 1336; % '5'
    770, 1477; % '6'
    852, 1209; % '7'
    852, 1336; % '8'
    852, 1477; % '9'
    ];

code_len = length(dtmf_code);

sample_len_per_code = round(dtmf_code_duration * fs);

t = (0 : sample_len_per_code - 1)' / fs;

dtmf_code_signal = zeros(sample_len_per_code, code_len);

% loop for each dtmf code
for n = 1 : code_len
    % get dtmf code
    idx = dtmf_code(n) + 1;
    
    % get dtmf freq from code freq table
    freq = dtmf_code_freq(idx, :);
    
    % generate dmtf code signal
    dtmf_x = sin(2 * pi * freq(1) * t) + sin(2 * pi * freq(2) * t);
    
    % normalize
    dtmf_x = dtmf_x / max(abs(dtmf_x));
    
    % insert into array
    dtmf_code_signal(:, n) = dtmf_x;  
end

if plot_signal
    plot_signal_time_domain(dtmf_code_signal, fs, 'dtmf code signal array');
end

end

function [] = tdmb_ofdm_signal(oversample_rate, frame_length, signal_plot, save_signal)
% generate terrestrial dmb ofdm signal
%
% [ref] etsi 300 401 v010401(2006-01), transmission mode I, page 144 ~ 145
%
% [input]
% - oversample_rate: oversample rate. 
%   sample rate = 2.048e6 * oversample_rate. when 2, sample rate = 4.096e6
% - frame_length: transmission frame length
% - signal_plot: boolean
% - save_signal: boolean
%
% [usage]
% tdmb_ofdm_signal(2, 2, 1, 1)
% tdmb_ofdm_signal(1, 2, 1, 0)

% ##### [ref] etsi 300 401 v010401(2006-01) NOT explain "raised cosine windowing"
% ##### instead of "raised cosine windowing", filtering is used:
%
% [ref] etsi 300 401 v010401(2006-01), page 165
% "The level of the signal at frequencies outside the nominal 1.536 MHz bandwidth
% can be reduced by applying an appropriate filtering."
%
% ##### "raised cosine windowing" code writing is needed ? (190329)
%
% "raised cosine windowing" reference:
% (1) http://rfmw.em.keysight.com/rfcomms/n4010a/n4010aWLAN/onlineguide/ofdm_raised_cosine_windowing.htm
% (2) http://www.ieee802.org/3/bn/public/jan13/montreuil_01a_0113.pdf

% ###### excerpt from reference (page 169)
% 15.5 Permitted values of the central frequency
% The nominal central frequency fc shall be an exact multiple of 16 kHz.
% The actual central frequency may be offset by up to +-1/2 carrier spacing (1/Tu) in any transmission mode,
% where necessary, to improve spectrum sharing.

% elementary period (fs = 2.048e6) (see reference)
ep = 1 / 2.048e6;

iq = [];

for n = 1 : frame_length
    ofdm_signal = one_frame_tdmb_ofdm_signal(oversample_rate, ep);
    iq = [iq; ofdm_signal];
end
size(iq)

% add very small noise because zeros in null symbol give "nan" error
snr_db = 30;
iq = awgn(iq, snr_db, 'measured', 'db');

% normalize
iq = iq / max(abs(iq));

if signal_plot
    fs = 1 / ep * oversample_rate;
    title_text = sprintf('tdmb, fs %g mhz, %d frame', fs/1e6, frame_length);
    plot_signal(iq, fs, title_text);
end

if save_signal
    signal_filename = sprintf('inf_snr_tdmb_fs%g_fr%d.mat', fs/1e6, frame_length);
    save(signal_filename, 'iq', 'fs', 'frame_length');
    
    fprintf('### inf snr tdmb signal saved into ''%s'' file\n', signal_filename);
end

end

%%
function [ofdm_signal] = one_frame_tdmb_ofdm_signal(oversample_rate, ep)

% % elementary period (fs = 2.048e6)
% ep = 1 / 2.048e6;

% the number of OFDM symbols per transmission frame (the Null symbol being excluded)
L = 76;

% number of transmitted carriers
K = 1536;

% transmission frame duration, 196608 * ep = 96 msec
Tf = 196608 * ep;
Nf = 196608;

% null symbol duration, 2656 * ep = 1.297 msec
Tnull = 2656 * ep;
Nnull = 2656;

% duration of ofdm symbol except null symbol, 2552 * ep = 1.246 msec
Ts = 2552 * ep;
Ns = 2552;

% the inverse of carrier spacing, 2048 * ep = 1 msec
Tu = 2048 * ep;
Nu = 2048;
carrier_spacing = 1e3; % 1/(1 msec) = 1 khz

% the duration of the time interval called guard interval, 504 * ep = 0.246 msec
Tg = 504 * ep;
Ng = 504;

t = (0 : Nu * oversample_rate - 1) * ep / oversample_rate;
% t = (0 : Ns - 1)' * ep;

% code formula in page 144
% when el = 0, null symbol should be genrated,
% but i take another approach: null symbol will be prepended after all ofdm symbol is generated

ofdm_signal = zeros(Ns * oversample_rate, L - 1); % not L, but (L - 1): excluding phase reference symbol
k_vec = (-K/2) : (K/2);
k_vec_length = length(k_vec); % = (K + 1)

% dqpsk
M = 4;

for el = 1 : L - 1 % not L, but (L - 1): excluding phase reference symbol
    
    x = randi([0, M - 1], K, 1);
    % dqpsk modulation
    z = dpskmod(x, M);
    
    % central carrier is NOT trasmitted,
    % so insert 0 in the middle of dqpsk modulated symbol
    z = [z(1 : K/2); 0; z(K/2 + 1 : end)];
    
    signal_per_carrier = zeros(k_vec_length, Ns * oversample_rate);
    for n = 1 : k_vec_length
        useful_part = exp(1i * 2 * pi * k_vec(n) * carrier_spacing * t);
        cyclic_prefix = useful_part(end - Ng * oversample_rate + 1 : end);
        % prepend cyclic prefix
        signal_per_carrier(n, :) = [cyclic_prefix, useful_part] * z(n);
    end
    one_ofdm_symbol = sum(signal_per_carrier);
    
    ofdm_signal(:, el) = one_ofdm_symbol;
    
end
size(ofdm_signal);
ofdm_signal = ofdm_signal(:);

% phase reference symbol
phase_per_carrier = zeros(k_vec_length, Ns * oversample_rate);
for n = 1 : k_vec_length
    
    my_k = k_vec(n);
    if ~my_k
        z = 0;
    else
        phi_k = get_phi_k_for_phase_reference_symbol(my_k);
        z = exp(1i * phi_k);
    end
    
    useful_part = exp(1i * 2 * pi * my_k * carrier_spacing * t);
    cyclic_prefix = useful_part(end - Ng * oversample_rate + 1 : end);
    % prepend cyclic prefix
    phase_per_carrier(n, :) = [cyclic_prefix, useful_part] * z;
    
end
phase_reference_symbol = sum(phase_per_carrier);
phase_reference_symbol = phase_reference_symbol(:);

% null symbol
null_symbol = zeros(Nnull * oversample_rate, 1);

% prepend null symbol, phase reference symbol
ofdm_signal = [null_symbol; phase_reference_symbol; ofdm_signal];
size(ofdm_signal);

% if signal_plot
%     fs = 1 / ep * oversample_rate;
%     title_text = 'tdmb';
%     plot_signal(ofdm_signal, fs, title_text);
% end

end

%%
function [phi_k] = get_phi_k_for_phase_reference_symbol(my_k)
% get phi_k for phase reference symbol

% [ref] etsi 300 401 v010401(2006-01), page 148,
% Table 39: Relation between the indices i, k' and n and the carrier index k for transmission mode I
% column meaning of R: k in range of min, k in range of max, k_prime, i, n
R = [
    -768 -737 -768 0 1
    -736 -705 -736 1 2
    -704 -673 -704 2 0
    -672 -641 -672 3 1
    -640 -609 -640 0 3
    -608 -577 -608 1 2
    -576 -545 -576 2 2
    -544 -513 -544 3 3
    -512 -481 -512 0 2
    -480 -449 -480 1 1
    -448 -417 -448 2 2
    -416 -385 -416 3 3
    -384 -353 -384 0 1
    -352 -321 -352 1 2
    -320 -289 -320 2 3
    -288 -257 -288 3 3
    -256 -225 -256 0 2
    -224 -193 -224 1 2
    -192 -161 -192 2 2
    -160 -129 -160 3 1
    -128 -97 -128 0 1
    -96 -65 -96 1 3
    -64 -33 -64 2 1
    -32 -1 -32 3 2
    1 32 1 0 3
    33 64 33 3 1
    65 96 65 2 1
    97 128 97 1 1
    129 160 129 0 2
    161 192 161 3 2
    193 224 193 2 1
    225 256 225 1 0
    257 288 257 0 2
    289 320 289 3 2
    321 352 321 2 3
    353 384 353 1 3
    385 416 385 0 0
    417 448 417 3 2
    449 480 449 2 1
    481 512 481 1 3
    513 544 513 0 3
    545 576 545 3 3
    577 608 577 2 3
    609 640 609 1 0
    641 672 641 0 3
    673 704 673 3 0
    705 736 705 2 1
    737 768 737 1 1
    ];

% [ref] etsi 300 401 v010401(2006-01), page 149,
% Table 43: Time-Frequency-Phase parameter h values
h = [
    0,2,0,0,0,0,1,1,2,0,0,0,2,2,1,1,0,2,0,0,0,0,1,1,2,0,0,0,2,2,1,1
    0,3,2,3,0,1,3,0,2,1,2,3,2,3,3,0,0,3,2,3,0,1,3,0,2,1,2,3,2,3,3,0
    0,0,0,2,0,2,1,3,2,2,0,2,2,0,1,3,0,0,0,2,0,2,1,3,2,2,0,2,2,0,1,3
    0,1,2,1,0,3,3,2,2,3,2,1,2,1,3,2,0,1,2,1,0,3,3,2,2,3,2,1,2,1,3,2
    ];

row_idx = find((R(:, 1) <= my_k) & (R(:, 2) >= my_k), 1);
k_prime = R(row_idx, 3);
j_val = my_k - k_prime;
i_val = R(row_idx, 4);
n_val = R(row_idx, 5);

% [ref] etsi 300 401 v010401(2006-01), page 147
phi_k = pi / 2 * (h(i_val + 1, j_val + 1) + n_val);

end


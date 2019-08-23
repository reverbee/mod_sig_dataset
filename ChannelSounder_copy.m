function [] = ChannelSounder_copy(iq_directory)
% channel sounder using smu200a and fsq26
% bpsk modulation is used for channel probe
% but original purpose of program is changed into bpsk mod/demodulation (####### what's this?)
%
% [input] 
% - iq_directory : if empty, no iq file saved
%
% [usage]
% ChannelSounder([])
% ChannelSounder('F:\fsq26_iq')
%

% ####### smu200 installed option ######
% SMU-B106 : RF path A, 100 kHz to 6 GHz
% SMU-B11 : Baseband Generator with ARB (16 Msamples) and Digital Modulation
% SMU-B13 : Baseband Main Module
%
% ####### fsq installed option #########
% B4 = Improved aging OCXO 
% B10 = External Generator Control
% B16 = ???? 
% B25 = Electronic Attenuator, 0 to 30 dB, preamp 20 dB
% K7 = FM Measurement Demodulator 
% K70 = Firmware General Purpose Vector Signal Analyzer
% 

vsg_resource_name = 'TCPIP0::RSSMU200A101847::INSTR';
vsa_resource_name = 'GPIB0::20::INSTR';

receiver_IF_bw_mhz = [0.3, 0.5, 1, 2, 3, 5, 10, 20, 50];
transmitter_prbs_length = [9, 11, 15, 16, 20, 21, 23];
modulation_list = [0 : 2]; % modulation type designation: 0 = bpsk, 1 = qpsk
% modulation_list = [0 : 5];

% ### Define filter-related parameters.
% oversampling = 4;  
% filter_order = 40; % Filter order
% % delay must be integer, so oversampling or filter_order must be selected to meet this constraint
% delay = filter_order / (oversampling * 2); % Group delay (# of input samples)
% root raised cosine filter rolloff
filter_rolloff = 0.35;
filter_rolloff = 0.5; 

% ### if sample_length > user_max_sample_length, visa time-out error is displayed :
% ### VISA: Timeout expired before operation completed.
% ### to cure this error, set time-out
user_max_sample_length = 16776704 / 32;

delete(instrfind);

% initialize channel probe transmitter
[vsg] = InitializeChannelProbeTransmitter(vsg_resource_name);

% initialize channel probe receiver
[vsa] = InitializeChannelProbeReceiver(vsa_resource_name);

% forever loop
while 2 > 1

    % get probe parameter from user
    freq_mhz = input('freq in mhz ? (20 ~ 3000, default = 2520) => ');
    if isempty(freq_mhz) == 1
        freq_mhz = 2520;
    end
    if freq_mhz > 3000 || freq_mhz < 20
        error(sprintf('wrong freq : %g mhz', freq_mhz));
    end
    
    symbol_rate_mhz = input('symbol rate in mhz of transmitter ? (max 25) => ');
    if isempty(symbol_rate_mhz) == 1 || symbol_rate_mhz > 25
        error('symbol rate error');
    end
    
    output_dbm = input('rf output in dbm of transmitter ? (-80 ~ 0, default = -60) => ');
    if isempty(output_dbm) == 1
        output_dbm = -60;
    end
    if output_dbm > 0 || output_dbm < -80
        error('rf output : -80 ~ 0 dbm');
    end
    
    if_bw_mhz = input('IF bw in mhz of receiver ? (0.3, 0.5, 1, 2, 3, 5, 10, 20, 50) => ');
    if isempty(find(receiver_IF_bw_mhz == if_bw_mhz)) == 1
        error('IF bw in mhz must be one of 0.3, 0.5, 1, 2, 3, 5, 10, 20, 50');
    end
    
    input_string = sprintf('oversampling ? (max = 8, symbol rate = %g mhz, max sample rate = 81.6 mhz) => ', ...
        symbol_rate_mhz);
    oversampling = fix(input(input_string));
    sample_rate_mhz = symbol_rate_mhz * oversampling;
    if sample_rate_mhz > 81.6
        error('sample rate error');
    end
    
    sample_length = input('AD sample length of receiver ? (5000 ~ 524272, default = 5000) => ');
    if isempty(sample_length) == 1
        sample_length = 5000;
    end
    if sample_length > user_max_sample_length
        error('sample length error');
    end
    
    data_source = ...
        input('data source ? (0 = transmitter prbs, 1 = user prbs, 2 = user pattern, default = 1) => ');
    if isempty(data_source) == 1
        data_source = 1;
    end
    user_pattern = [];
    switch data_source
        case 0
            data_length = input('transmitter prbs length ? (9, 11, 15, 16, 20, 21, 23) => ');
            if isempty(find(transmitter_prbs_length == data_length)) == 1
                error('transmitter prbs length must be one of 9, 11, 15, 16, 20, 21, 23');
            end
        case 1
            data_length = input('user prbs length in power of two ? (2 ~ 6, default = 6) => ');
            if isempty(data_length) == 1
                data_length = 6;
            end
            if isempty(find(data_length == [2 : 6])) == 1
                error('user prbs length in power of two : 2 ~ 6');
            end
        case 2
            user_pattern = input('user pattern vector ? (max 64 bits) => ');
            if isempty(user_pattern) == 1
                error('empty user pattern');
            end
            data_length = length(user_pattern);
            if data_length > 64
                error('max user pattern length is 64 bits');
            end
        otherwise
            error('unsupported data source');
    end
    
    % select psk modulation
    modulation = input('modulation ? (0 = 2psk, 1 = 4psk, 2 = 8psk, default = 0) => ');
    %     modulation = input('modulation ? (0 = 2psk, 1 = 4psk, 2 = 8psk, 3 = 16qam, 4 = 32qam, 5 = 64qam) => ');
    if isempty(modulation) == 1
        modulation = 0;
    end
    if isempty(find(modulation_list == modulation)) == 1
        error('modulation error');
    end
    
    % input part of fsq
    if output_dbm < -60
        % input attenuation 0 db
        fprintf(vsa, 'INP:ATT:AUTO OFF');
        response = query(vsa, 'INP:ATT:AUTO?');
        fprintf(vsa, 'INP:ATT 0dB');
        response = query(vsa, 'INP:ATT?');

        % preamp on
        fprintf(vsa, 'INP:GAIN:STAT ON');
        response = query(vsa, 'INP:GAIN:STAT?');
    else
        % input attenuation auto, preamp off
        fprintf(vsa, 'INP:ATT:AUTO ON');
        fprintf(vsa, 'INP:GAIN:STAT OFF');
    end

    % Create a square root raised cosine filter for receiver.
    filter_coefficient = rcosine(1, oversampling, 'fir/sqrt', filter_rolloff);
%     figure; impz(filter_coefficient, 1); grid on;

    % create raised cosine filter coefficient for detection correlator
    corr_filter_coefficient = rcosine(1, oversampling, 'fir', filter_rolloff);
    % get impluse response from filter coefficient
    [H, T] = impz(corr_filter_coefficient, 1);
    [Y, I] = max(H);
    % max length of filter impulse response is fixed to 21
    H = H(I - 10 : I + 10);

    % transmit channel probe
    [tx_data] = ...
        TransmitChannelProbe(vsg, freq_mhz, symbol_rate_mhz, output_dbm, data_source, ...
        user_pattern, data_length, ...
        modulation, filter_rolloff);

    % #### IMPORTANT !!! : must pause some seconds for transmitter ####
    % #### if not pause, you may see unmodulated iq signal ####
    pause(1);

    % receive channel probe
    [iq, iq_filename] = ...
        ReceiveChannelProbe(vsa, freq_mhz, if_bw_mhz, sample_rate_mhz, sample_length, iq_directory);

    % off rf output of vector signal generator
    fprintf(vsg, 'OUTP:STAT OFF');
    response = query(vsg, 'OUTP:STAT?');
    
    % process received channel probe
    plus_exponential = 1;
    [inverted_rx_data] = ...
        ProcessReceivedChannelProbe(iq, iq_filename, freq_mhz, if_bw_mhz, symbol_rate_mhz, ...
        sample_rate_mhz, sample_length, modulation, tx_data, filter_rolloff, filter_coefficient, ...
        oversampling, H, plus_exponential);
    if inverted_rx_data == 1
        disp('########### carrier phase recovery is retrying ...');
        plus_exponential = 0;
        ProcessReceivedChannelProbe(iq, iq_filename, freq_mhz, if_bw_mhz, symbol_rate_mhz, ...
        sample_rate_mhz, sample_length, modulation, tx_data, filter_rolloff, filter_coefficient, ...
        oversampling, H, plus_exponential);
    end
    
    % iq file save
    if isempty(iq_directory) == 0
        % make iq filename
        [timestamp] = get_timestamp;
        iq_filename = sprintf('%s\\iq_%s_%g_%g_%g.mat', ...
            iq_directory, timestamp, freq_mhz, symbol_rate_mhz, output_dbm);

        % make parameter header structure
        header.freq_mhz = freq_mhz;
        header.if_bw_mhz = if_bw_mhz;
        header.symbol_rate_mhz = symbol_rate_mhz;
        header.sample_rate_mhz = sample_rate_mhz;
        header.oversampling = oversampling;
        header.filter_rolloff = filter_rolloff;
        header.sample_length = sample_length;
        header.output_dbm = output_dbm;
        header.tx_data = tx_data;

        % save iq and header into file
        save(iq_filename, 'header', 'iq');
    end
        
    % prompt user input to proceed next probe
    next_probe = ...
        input('proceed to next probe ? (1 = yes, 0 = no, default = 1) => ');
    if isempty(next_probe) == 1
        next_signal = 1;
    end
    if next_probe == 0
        break;   
    end

end

% % off rf output of vector signal generator
% fprintf(vsg, 'OUTP:STAT OFF');
% response = query(vsg, 'OUTP:STAT?');

disp('exiting program ...');
fclose(vsg);   delete(vsg);     fclose(vsa);    delete(vsa);

end

%%
% #### local function ####
function [inverted_rx_data] = ...
    ProcessReceivedChannelProbe(iq, iq_filename, freq_mhz, if_bw_mhz, symbol_rate_mhz, sample_rate_mhz, ...
    sample_length, modulation, tx_data, filter_rolloff, filter_coefficient, oversampling, H, plus_exponential)
%
%
% [input]
% - H : raised cosine filter impulse response for detection correlator
% - plus_exponential : if better scheme of carrier recovery is used, this input is unnecessary
% 
% [output]
% - inverted_rx_data :
%

if nargin ~= 14
    error(sprintf('use "help %s"', mfilename));
end

% oversampling vs half correlation interval look-up table
half_corr_interval = [ ...
    0;   % oversampling = 1, use decimator instead of correlator
    0;   % oversampling = 2, use decimator instead of correlator
    0;   % oversampling = 3, use decimator instead of correlator
    0;   % oversampling = 4, use decimator instead of correlator
    1;   % oversampling = 5, correlation interval = 1 * 2 + 1 = 3
    1;   % oversampling = 6, correlation interval = 1 * 2 + 1 = 3
    2;   % oversampling = 7, correlation interval = 2 * 2 + 1 = 5
    2;   % oversampling = 8, correlation interval = 2 * 2 + 1 = 5
    ];

% if isempty(iq) == 1 && isempty(iq_filename) == 0
%     load(iq_filename);
% end

iq_length = length(iq);

% filter iq with rrcos filter
% 'Fs/filter' : has sample frequency oversampling, so does not upsample rx_rrc_psk any further.
filtered_iq = rcosflt(iq, 1, oversampling, 'Fs/filter', filter_coefficient);
filtered_iq_length = length(filtered_iq);

% default filter delay in root raised cosine filtering (rcosflt function)
filter_delay = 3;
% iq sample delay due to rrcos filter
iq_delay = 2 * oversampling * filter_delay;

% remove the first and last part of filtered iq which is fir transient response
filtered_iq = filtered_iq(iq_delay / 2 + 1 : end - iq_delay / 2);
filtered_iq_length = length(filtered_iq);

% ########################## carrier phase recovery ###################################
% ### phase of tx carrier and rx carrier is not coherent.
% ### after computing phase difference from slope of iq constellation and polynomial fitting,
% ### phase difference is applied to original iq.
% ### (in bpsk, slope of iq constellation must be 0)
% ### but this scheme have problem because symbol_clock_phase have 180 deg ambiguity :
% ### symbol_clock_phase = exp(-j * atan(polynomial_filtered_iq(1)));
% ### symbol_clock_phase = (-1) * exp(-j * atan(polynomial_filtered_iq(1)));
% ### if wrong phase is applied, rx data become the inverted version of tx data,
% ### and cross-correlation of tx and rx data drop to zero periodically.
% ### i cant solve this problem, 
% ### more elaborate scheme like costas loop may be used in later.

% ### Fit polynomial to iq and filtered iq to get polynomial coefficient(y = a * x + b)
% fit for filtered iq
polynomial_filtered_iq = polyfit(real(filtered_iq), imag(filtered_iq), 1)
% fir for iq
polynomial_iq = polyfit(real(iq), imag(iq), 1)

% compute symbol clock phase by arc tangent of polynomial(a, line slope)
% ### which is better ? polynomial_filtered_iq or polynomial_iq
rad2deg(atan(polynomial_iq(1)));
% symbol_clock_phase = exp(-j * atan(polynomial_iq(1)));
if plus_exponential == 1
    symbol_clock_phase = exp(-j * atan(polynomial_filtered_iq(1)));
else
    symbol_clock_phase = (-1) * exp(-j * atan(polynomial_filtered_iq(1)));
end
% correct phase of iq with symbol clock phase
corrected_iq = filtered_iq .* symbol_clock_phase;
corrected_iq_length = length(corrected_iq);

% ########################## end of carrier phase recovery #############################


% ########## detection of binary bit from baseband signal #############
% ### detection performance mainly depends on tx symbol recovery
% ### my scheme is to detect the first of phase inversion point,
% ### and to use this point as the basis of symbol start point.
% ### but this scheme give the worst results in low snr case.
% ### more better recovery scheme must be tried in later version.

% detect phase inversion index
iq_sign = sign(real(corrected_iq));
% iq_sign = sign(real(corrected_iq(1 : oversampling * 20)));
phase_inversion_index = find(diff(iq_sign) ~= 0);
phase_pos_index = find(diff(iq_sign) == 2);
phase_neg_index = find(diff(iq_sign) == -2);
% phase_inversion_index(1 : 10);
% phase_pos_index(1 : 10);
% phase_neg_index(1 : 10);

% make symbol center index list
symbol_center_index = ...
    [phase_inversion_index(1) + floor(oversampling / 2) : oversampling : corrected_iq_length];
% symbol_center_index = ...
%     [phase_inversion_index(1) + fix(oversampling / 2) - 1 : oversampling : corrected_iq_length];
symbol_length = length(symbol_center_index);
symbol_center_index(1 : 10);

% make start and stop index for correlation detector
corr_start_index = symbol_center_index - half_corr_interval(oversampling);
corr_stop_index = symbol_center_index + half_corr_interval(oversampling);
% corr_start_index = symbol_center_index - fix(oversampling / 2) + 1;
% corr_stop_index = symbol_center_index + fix(oversampling / 2) - 1;

% truncate filter to make its coefficient length same as correlation length
[Y, I] = max(H);
H = H(I - half_corr_interval(oversampling) : I + half_corr_interval(oversampling));

% heart of binary detection
rx_data = [];   correlator_output = [];
for n = 1 : symbol_length - 1
    
    % correlate baseband signal with filter impulse response
    Y = real(sum(corrected_iq(corr_start_index(n) : corr_stop_index(n)) .* H));
    correlator_output = [correlator_output; Y];
    
    % binary decision from correlator ouput
    if Y > 0
        rx_data = [rx_data, 1];
    else
        rx_data = [rx_data, 0];
    end
    
end
rx_data_length = length(rx_data);
size(tx_data);
size(rx_data);
correlator_output_length = length(correlator_output);

% ########################## end of detection ##########################################

% compare rx data with tx data
if isempty(tx_data) ~= 1
    tx_data_length = length(tx_data);

    % compute cross correlation coefficient between tx prbs and rx prbs
    maxlag = tx_data_length * 10;
    [corr_coeff, lags] = xcorr(rx_data, tx_data, maxlag);
    
    % truncate cross correlation coefficient
    [I] = find(lags == 0);
    corr_coeff = corr_coeff(I : I + tx_data_length * 7);
    lags = lags(I : I + tx_data_length * 7);
    
    % find zero cross correlation
    % if exists and its period is tx data length, rx data is the inverted version of tx data
    % so prematurely retuned to main routine with inverted_rx_data = 1
    % (in main routine, this ProcessReceivedChannelProbe function is reentered)
    [I] = find(corr_coeff <= 10^7 * eps);
    if (isempty(I) ~= 1) && ((I(2) - I(1)) == tx_data_length)
        inverted_rx_data = 1;
        return;
    else
        inverted_rx_data = 0;
        % get max correlation coefficient index
        [Y, I] = max(corr_coeff)
        rx_data_length;

        % expand tx data and truncate rx data for display and computing symbol error rate
        repeat_length = fix(rx_data_length / tx_data_length) - fix(I / tx_data_length) - 1;
        expanded_tx_data = repmat(tx_data, 1, repeat_length);
        expanded_tx_data_length = length(expanded_tx_data);
        truncated_rx_data = rx_data(I : I + expanded_tx_data_length - 1);
                        
    end
    
    % compute symbol errors number and symbol error rate
    [symbol_error_number, symbol_error_rate] = symerr(truncated_rx_data, expanded_tx_data);
    
    % plot tx data, rx data, and correlation
    figure('Position', [31 125 785 553]);
    
    subplot(3, 1, 1);
    plot(expanded_tx_data);
    grid on;
    ylim([-1 2]);
    title(sprintf('tx prbs : one prbs length = %d, symbol rate = %d mhz', tx_data_length, symbol_rate_mhz));

    subplot(3, 1, 2);
    plot(truncated_rx_data);
    grid on;
    ylim([-1 2]);
    title(sprintf('rx prbs : error number = %d, error rate = %g', ...
        symbol_error_number, symbol_error_rate));

    subplot(3, 1, 3);
    plot(lags, abs(corr_coeff));
    title('correlation of tx and rx prbs');
    xlim([lags(1) lags(end)]);
    xlabel('sample lag');
    ylabel('coefficient');
    grid on;
end

% plot time domain sample of iq and filtered iq
figure('Position', [58 68 785 619]);

subplot(4, 1, 1);
plot([real(iq) imag(iq)]);
grid on;
title(sprintf('before rrcos filter : symbol rate = %d mhz, oversampling = %d', symbol_rate_mhz, oversampling));

subplot(4, 1, 2);
plot([real(filtered_iq) imag(filtered_iq)]);
grid on;
title('after rrcos filter');

subplot(4, 1, 3);
plot([real(corrected_iq) imag(corrected_iq)], '.');
grid on;
title('after carrier phase recovery');

subplot(4, 1, 4);
plot(correlator_output);
grid on;
title('detection correlator output');

% plot polar of iq and filtered iq
figure('Position', [31 125 785 553]);

subplot(2, 2, 1);
polar(angle(iq), abs(iq), '.');
title('before rrcos filter');

subplot(2, 2, 2);
polar(angle(filtered_iq), abs(filtered_iq), '.');
title('after rrcos filter');

subplot(2, 2, 3);
polar(angle(corrected_iq), abs(corrected_iq), '.');
title('after carrier phase recovery');

subplot(2, 2, 4);
polar(angle(correlator_output), abs(correlator_output), '.');
title('detection correlator output');

% plot freq spectrum of iq and filtered iq
figure('Position', [31 125 785 553]);

subplot(3, 1, 1);
freq_spectrum = fft(iq .* hamming(iq_length));
plot([1 : iq_length], 10 * log10(abs(freq_spectrum)));
xlim([1 iq_length]);
grid on;
title(sprintf('before filter : freq = %g MHz, IF bw = %g MHz, sample rate = %g MHz, sample length = %d', ...
    freq_mhz, if_bw_mhz, sample_rate_mhz, iq_length));

subplot(3, 1, 2);
freq_spectrum = fft(filtered_iq .* hamming(filtered_iq_length));
plot([1 : filtered_iq_length], 10 * log10(abs(freq_spectrum)));
xlim([1 filtered_iq_length]);
grid on;
title(sprintf('after filter : freq = %g MHz, IF bw = %g MHz, sample rate = %g MHz, sample length = %d', ...
    freq_mhz, if_bw_mhz, sample_rate_mhz, filtered_iq_length));

subplot(3, 1, 3);
freq_spectrum = fft(correlator_output .* hamming(correlator_output_length));
plot([1 : correlator_output_length], 10 * log10(abs(freq_spectrum)));
xlim([1 correlator_output_length]);
grid on;
title(sprintf('detection correlator : freq = %g MHz, IF bw = %g MHz, sample rate = %g MHz, sample length = %d', ...
    freq_mhz, if_bw_mhz, sample_rate_mhz, correlator_output_length));

end

%%
% #### local function ####
function [iq, iq_filename] = ...
    ReceiveChannelProbe(vsa_obj, center_freq_mhz, if_bw_mhz, sample_rate_mhz, sample_length, iq_directory)
% receive channel probe

if nargin ~= 6
    error(sprintf('use "help %s"', mfilename));
end

iq_filename = [];

% set tuning freq
command = sprintf('FREQUENCY:CENTER %gMHz', center_freq_mhz);
fprintf(vsa_obj, command);
response = query(vsa_obj, 'FREQUENCY:CENTER?');

% % set span to 0 for time domain measurement
% fprintf(vsa_obj, 'FREQUENCY:SPAN 0MHZ');
% response = query(vsa_obj, 'FREQ:SPAN?');

% ######################################################################### 
% #### assumed that rbw, vbw is dont care parameter for IQ acquisition ####
% #########################################################################

% turn on IQ acquisition
fprintf(vsa_obj, 'TRAC:IQ:STAT ON');

% set IQ acquisition parameter :
% - analog resolution filter type : NORM (fixed)
% - bandwidth of analog filters in front of the A/D converter : 2 MHz for CDMA basestation
%   (this is same as rbw in spectrum analyzer)
% - sample rate : A/D sample rate
% - trigger mode : IMM (fixed)
% - trigger slope : POS (fixed)
% - pretrigger samples : 0 (fixed)
% - sample number : iq sample length
command = sprintf('TRAC:IQ:SET NORM,%gMHz,%gMHz,IMM,POS,0,%d', ...
    if_bw_mhz, sample_rate_mhz, sample_length);
fprintf(vsa_obj, command);
response = query(vsa_obj, 'TRAC:IQ:SET?');
disp(['receiver parameter = ', response(1 : end - 1)]);

% wait for FSQ to acquire IQ
fprintf(vsa_obj, 'INIT;*WAI');

% set IQ format to 32-bit floating point binary
fprintf(vsa_obj, 'FORMAT REAL,32');

% set IQ data ouput format : IQB (= first all I and then all Q data is transferred)
fprintf(vsa_obj, 'TRAC:IQ:DATA:FORM IQB');

% error list
response = query(vsa_obj, 'SYST:ERR:LIST?');
disp(['error list in receiver = ', response(1 : end - 1)]);

% get IQ from FSQ
fprintf(vsa_obj, 'TRAC:IQ:DATA?');
% ### for IQ data output format, see page 6.1-219 in FSQ operating manual

% read start indicator, and byte length in length block
[A, count, msg] = fread(vsa_obj, 2, 'char');
% check start indicator(= #)
if char(A(1)) ~= '#'
    error('start indicator = # not found');
end

% get byte length in length block
% ascii code of '0' = 48
byte_length_in_length_block = A(2) - 48;

% read length block whose size was given in byte_length_in_length_block
[A, count, msg] = fread(vsa_obj, byte_length_in_length_block, 'char');
% convert ascii code to digit
A = A - 48;
% convert digit to number
ten_base = 10 .^ [length(A) - 1 : -1 : 0];
% get byte length in data block
byte_length_in_data_block = sum(A' .* ten_base);
if byte_length_in_data_block ~= sample_length * 8
    error(sprintf('byte length = %d, sample length * 8 = %d', ...
        byte_length_in_data_block, sample_length * 8));
end

% read i_then_q whose size was given in byte_length_in_data_block
[i_then_q, count, msg] = fread(vsa_obj, byte_length_in_data_block, 'float');
% i_then_q is column vector, which is default output of fread function
i_plus_q_length = length(i_then_q);
if i_plus_q_length ~= sample_length * 2
    error(sprintf('i+q length = %d, sample length * 2 = %d', ...
        i_plus_q_length, sample_length * 2));
end

% make complex iq from i_then_q
inphase = i_then_q(1 : sample_length);
quadrature = i_then_q(sample_length + 1 : end);
iq = complex(inphase, quadrature);

end

%%
% #### local function ####
function [prbs] = ...
    TransmitChannelProbe(vsg, freq_mhz, symbol_rate_mhz, output_dbm, data_source, ...
    user_pattern, data_length, ...
    modulation, filter_rolloff)
% transmit channel probe

% [input]
% - vsg, freq_mhz, symbol_rate_mhz, output_dbm
% - data_source : 
% - data_length : 
%

prbs = [];

% bpsk modulation
switch modulation
    case 0
        fprintf(vsg, 'BB:DM:FORM BPSK');        
    case 1
        fprintf(vsg, 'BB:DM:FORM QPSK');       
    case 2
        fprintf(vsg, 'BB:DM:FORM PSK8');        
%     case 3
%         fprintf(vsg, 'BB:DM:FORM QAM16');        
%     case 4
%         fprintf(vsg, 'BB:DM:FORM QAM32'); 
%     case 5
%         fprintf(vsg, 'BB:DM:FORM QAM64');
    otherwise
        error('unsupported modulation');
end
response = query(vsg, 'BB:DM:FORM?');

% rrcos baseband filter and roll-off factor
fprintf(vsg, 'BB:DM:FILT:TYPE RCOS');
response = query(vsg, 'BB:DM:FILT:TYPE?');
fprintf(vsg, 'BB:DM:FILT:PAR:RCOS %g', filter_rolloff);
response = query(vsg, 'BB:DM:FILT:PAR:RCOS?');

% carrier freq
fprintf(vsg, 'FREQ %g MHZ', freq_mhz);
response = query(vsg, 'FREQ?');

% symbol rate
fprintf(vsg, 'BB:DM:SRAT %g MHZ', symbol_rate_mhz);
response = query(vsg, 'BB:DM:SRAT?');

switch data_source    
    case 0
        % data source : prbs
        fprintf(vsg, 'BB:DM:SOUR PRBS');
        fprintf(vsg, 'BB:DM:PRBS %d', data_length);
        
    case 1
        % data source : pattern, max 64 bits
        fprintf(vsg, 'BB:DM:SOUR PATT');

        % create prbs
        prbs = randint(1, 2^data_length, 2);
        % convert prbs to string and pack
        prbs_str = num2str(prbs);
        prbs_str_length = length(prbs_str);
        str_index = [1 : 3 : prbs_str_length];
        prbs_str = prbs_str(str_index);

        % set prbs pattern to smu200a
        command_str = sprintf('BB:DM:PATT #B%s,%d', prbs_str, 2^data_length);
        fprintf(vsg, command_str);
        response = query(vsg, 'BB:DM:PATT?');
        disp(['prbs pattern = ', response(1 : end - 1)]);
        
    case 2
        % data source : pattern, max 64 bits
        fprintf(vsg, 'BB:DM:SOUR PATT');
        
        prbs = user_pattern;

        % convert prbs to string and pack
        prbs_str = num2str(user_pattern);
        prbs_str_length = length(prbs_str);
        str_index = [1 : 3 : prbs_str_length];
        prbs_str = prbs_str(str_index);

        % set prbs pattern to smu200a
        command_str = sprintf('BB:DM:PATT #B%s,%d', prbs_str, data_length);
        fprintf(vsg, command_str);
        response = query(vsg, 'BB:DM:PATT?');
        disp(['prbs pattern = ', response(1 : end - 1)]);       
end

fprintf(vsg, 'BB:DM:STAT ON');
response = query(vsg, 'BB:DM:STAT?');
disp(sprintf('baseband digital modulation state = %s', response(1 : end - 1)));

% modulation on
fprintf(vsg, 'MOD:STAT ON');
response = query(vsg, 'MOD:STAT?');
disp(sprintf('modulation state = %s', response(1 : end - 1)));

% what's this?
fprintf(vsg, 'IQ:WBST ON');
response = query(vsg, 'IQ:WBST?');

% iq on, but necessary ?
fprintf(vsg, 'IQ:STAT ON');
response = query(vsg, 'IQ:STAT?');
disp(sprintf('iq state = %s', response(1 : end - 1)));

% rf output power
fprintf(vsg, 'POW %g', output_dbm);
response = query(vsg, 'POW?');
disp(sprintf('rf ouput power = %s dbm', response(1 : end - 1)));

% on rf output
fprintf(vsg, 'OUTP:STAT ON');
response = query(vsg, 'OUTP:STAT?');
disp(sprintf('rf output state = %s', response(1 : end - 1)));

end

%%
% #### local function ####
function [vsg] = InitializeChannelProbeTransmitter(vsg_visa_resource_name)

% create vector signal generator(rs smu 200a)
vsg = visa('ni', vsg_visa_resource_name);
fopen(vsg);
response = query(vsg, '*IDN?');
% installed option
response = query(vsg, '*OPT?');

% external 10 mhz ref
fprintf(vsg, 'ROSC:SOUR EXT');
response = query(vsg, 'ROSC:SOUR?');
fprintf(vsg, 'ROSC:EXT:FREQ 10 MHz');
response = query(vsg, 'ROSC:EXT:FREQ?');

% clock source
response = query(vsg, 'BB:DM:CLOC:SOUR?');

end

%%
% #### local function ####
function [vsa_obj] = InitializeChannelProbeReceiver(vsa_visa_resource_name)

% create vsa control object
vsa_obj = visa('ni', vsa_visa_resource_name);

% ### if system_max_sample_length = 16776704, matlab error message is displayed :
% ### ??? There is not enough memory to create the inputbuffer. Try specifying a smaller value.
% ### to cure this error, more computer memory is needed
system_max_sample_length = 16776704 / 4;

% set 'input buffer size' properties
set(vsa_obj, 'InputBufferSize', system_max_sample_length * 8);
% ### '8' above line : I sample = 4 byte, Q sample = 4 byte

% set 'timeout' to 20 sec
set(vsa_obj, 'Timeout', 20);

fopen(vsa_obj);
% ByteOrder = littleEndian
% get(vsa_obj);
response = query(vsa_obj, '*IDN?');
response = query(vsa_obj, '*OPT?');

% reset and clear buffer
fprintf(vsa_obj, '*RST');
fprintf(vsa_obj, '*CLS');

% % set preamp on for weak signal
% fprintf(vsa_obj, 'INP:GAIN ON');

% external ref 10 mhz
fprintf(vsa_obj, 'ROSC:SOUR EXT');
response = query(vsa_obj, 'ROSC:SOUR?');
fprintf(vsa_obj, 'ROSC:EXT:FREQ 10MHz');
response = query(vsa_obj, 'ROSC:EXT:FREQ?');

% input coupling : ac
fprintf(vsa_obj, 'INP:COUP AC');
response = query(vsa_obj, 'INP:COUP?');

% % input attenuation
% fprintf(vsa_obj, 'INP:ATT:AUTO ON');
% % auto atten off, 0 db atten 
% fprintf(vsa_obj, 'INP:ATT:AUTO OFF');
% response = query(vsa_obj, 'INP:ATT:AUTO?')
% fprintf(vsa_obj, 'INP:ATT 0dB');
% response = query(vsa_obj, 'INP:ATT?')

end


function [] = change_mozart_mono(save_stereo_also)
% (1) change stereo channel mozart wav file into mono channel
% (2) remove first 2000 sample whose value is zero, which may make "nan" in modulation signal dataset
%
% selection of source for analog modulation is VERY IMPORTANT:
% original source file was 'mozart.wav',
% but first 2000 sample whose value is zero made "nan" in modulation signal dataset.
%
% ########## i spent a week to fix "nan" bug!
%
% [input]
% - save_stereo_also: boolean. 0 = only save mono, 1 = also save stereo
%
% [usage]
% change_mozart_mono(1)

% save_stereo_also = 1;

% mozart clarinet concerto in A major, K. 622
% original 'mozart.wav' have stereo channel
wav_filename = 'mozart.wav';

% get audio file info
info = audioinfo(wav_filename);
info;
channel_length = info.NumChannels;
fs = info.SampleRate;
file_sample_length = info.TotalSamples;

% read audio sample
y = audioread(wav_filename);

% % change stereo to mono
% y = y(:, 1);
% % whos;

% remove first 2000 sample whose value is zero
y = y(2001 : end, :);
whos;
max(y);
min(y);

% remove last 2000 sample whose value is almost zero
y = y(1 : end - 2000, :);
whos;
max(y);
min(y);

if save_stereo_also
    % write back audio sample into mono wav file
    wav_filename = 'mozart_stereo.wav';
    audiowrite(wav_filename, y, fs);
    
    fprintf('#### ''mozart_stereo.wav'' saved also\n');
end

% change stereo to mono
y = y(:, 1);
% whos;

% write back audio sample into mono wav file
wav_filename = 'mozart_mono.wav';
audiowrite(wav_filename, y, fs);

% check mono wav file
info = audioinfo(wav_filename);
info;
y = audioread(wav_filename);
whos;
max(y);
min(y);

end


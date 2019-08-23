function [] = mp3_to_wav(mp3_audio_filename)
%
% [usage]
% mp3_to_wav('marquez.mp3')

[y, fs] = audioread(mp3_audio_filename);
size(y)
fs;
max(y);
min(y);

y = y(:, 1);

% remove ad
remove_sec = 80;
y = y(fix(remove_sec * fs) : end);
y_len = length(y);

y = y(1 : fix(y_len / 10));

[~, name, ~] = fileparts(mp3_audio_filename);
audiowrite(sprintf('%s_part.wav', name), y, fs);

end
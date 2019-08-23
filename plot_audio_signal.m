function [] = plot_audio_signal(wav_filename)
%
% [usage]
% plot_audio_signal('never_ending_love_stereo.wav')
% plot_audio_signal('mozart_mono.wav')

A = audioinfo(wav_filename)
[x, audio_sample_rate] = audioread(wav_filename);
size(x)
max(x)
min(x)

figure;
if A.NumChannels == 2
    plot(x(1:2^18, :));
else
    plot(x(1:2^18));
end

end

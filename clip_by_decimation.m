function [iq] = clip_by_decimation(iq, audio_decimation_factor)

size(iq);
frame_length = fix(length(iq) / audio_decimation_factor);
iq = iq(1 : frame_length * audio_decimation_factor);
size(iq);

end


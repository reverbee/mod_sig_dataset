function [y] = apply_fading_channel(y, chan_type, chan_fs, fd)

ts = 1 / chan_fs;
% create standard channel
chan = stdchan(ts, fd, chan_type);
% pass signal through channel
y = filter(chan, y);

end
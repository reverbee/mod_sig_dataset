function [y] = nan_apply_fading_channel(y, chan_type, chan_fs, fd)
% ##### dont use. test only code to check nan

max_try_length = 4;

ts = 1 / chan_fs;
% create standard channel
chan = stdchan(ts, fd, chan_type);

y_copy = y;

for n = 1 : max_try_length
    % pass signal through channel
    y = filter(chan, y);
    
    if sum(isnan(y))
        chan.ResetBeforeFiltering = 1;
    else
        break;
    end
end

if n == max_try_length
    y_copy
    title_text = 'nan';
    plot_signal(y_copy, chan_fs, title_text)
    error('####### error: failed to avoid nan output in fading channel');
end

end
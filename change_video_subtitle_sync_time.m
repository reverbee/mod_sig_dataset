function [] = change_video_subtitle_sync_time(filename, change_time_sec, new_filename)
% 
% [input]
% - filename: subtitle filename (.smi)
% - change_time_sec: sync time change in sec
%   usually minus value (korean subtitle appear much later than video)
% - new_filename: if not empty, save change into new file
% 
% [usage]
% change_video_subtitle_sync_time('Mulholland.smi', -25, 'new.smi')

fid = fopen(filename, 'r');

if ~isempty(new_filename)
    new_fid = fopen(new_filename, 'w');
end

tline = fgetl(fid);
if ~isempty(new_filename)
    fprintf(new_fid, '%s\n', tline);
end

while ischar(tline)
    if contains(tline, '<SYNC Start=')
        eq_idx = strfind(tline, '=');
        cmp_idx = strfind(tline, '><');
        remain_line = tline(cmp_idx(1) : end);
        org_time = str2double(tline(eq_idx(1) + 1 : cmp_idx(1) - 1));
        new_time = org_time + change_time_sec * 1e3;
        if new_time > 0
            fprintf(new_fid, '<SYNC Start=%d%s\n', new_time, remain_line);
        end
    else
        fprintf(new_fid, '%s\n', tline);
    end
     
    tline = fgetl(fid);
end

fclose(fid);
fclose(new_fid);

end

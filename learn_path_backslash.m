function [] = learn_path_backslash(dir_name)
% how to express file path backslash in sprintf
% 
% [usage]
% learn_path_backslash('e:\temp\mod_signal')
%

% #### backslash special character: \\
filename = sprintf('%s\\test.txt', dir_name);

fid = fopen(filename, 'w+');
if fid == -1
    fprintf('### error: failed fopen(%s)\n', filename);
    return;
end

fclose(fid);

end
function [] = matlab_r2011b_file_association(action, file_type)
% 
% [input]
% - action: 'add' or 'delete'
% - file_type: '.m', '.mat', '.fig', 'mdl' or {'.m','.mat','.mdl','.fig'}
% [usage]
% matlab_r2011b_file_association('add', {'.m','.mat','.mdl','.fig'});
% matlab_r2011b_file_association('delete', '.m');
%
% ###### reference ######
% http://www.mathworks.com/help/techdoc/matlab_env/bs6j5lz.html#bsp02s3-1
%

if nargin ~= 2
    error('use "help %s"', mfilename);
end

cwd = pwd; 
cd([matlabroot '\toolbox\matlab\winfun\private']);
fileassoc(action, file_type);
cd(cwd);

return;

% fileassoc('add', '.m')
% fileassoc('add', {'.m','.mat','.mdl','.fig','.p','.mlprj','.mexw32'})



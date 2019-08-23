function [status] = call_python(mat_filename, python_command)

% ############ python must be 3.x, not 2.x

python_command_input = mat_filename;
% python_command = 'E:\\modulation classification\\matlab_dataset\\make_dict_from_mat_file.py';
command = sprintf('python "%s" "%s"', python_command, python_command_input);

status = dos(command);

end


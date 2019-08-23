function [] = learn_dos()

% ############ python must be 3.x, not 2.x

python_command_input = 'E:\\temp\\mod_signal\\RML2018_gsmRAx4c2_25instance.mat';
python_command = 'E:\\modulation classification\\matlab_dataset\\test_matlab_dos.py';
command = sprintf('python "%s" "%s"', python_command, python_command_input);

status = dos(command);
if status
    fprintf('### error: %s failed\n', command);
end

end

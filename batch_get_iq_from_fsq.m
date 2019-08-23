function [] = batch_get_iq_from_fsq(freq_mhz_vec, rbw_mhz, fs_mhz_vec, sample_length_vec)
% batch version of "get_iq_from_fsq.py"
% to get iq for channelized signal, i.e. tetra
%
% [input]
% - freq_mhz_vec: fsq freq vector
% - rbw_mhz: fsq rwb
% - fs_mhz_vec: fsq sampl rate vector
% - sample_length_vec: fsq sample length vector
%
% [usage]
% (kt wcdma downlink)
% batch_get_iq_from_fsq([2162.4,2167.2], 10, [2:10]*3.84, [2^20,2^20,2^20,2^21,2^21,2^21,2^21,2^22,2^22])
% (tetra downlink)
% batch_get_iq_from_fsq([854.7625,854.0125,853.7125,853.5625,852.6375,852.5125,851.8125,851.7625],0.3,[0.036,0.054,0.072,0.09,0.108,0.126],[2^19,2^19,2^19,2^20,2^20,2^20])
%
% ### equivalent to run below command in dos ####
% python get_iq_from_fsq.py 854.7625 0.3 0.036 2^19
% ...
% python get_iq_from_fsq.py 854.7625 0.3 0.126 2^20
% ...
% python get_iq_from_fsq.py 851.7625 0.3 0.036 2^19
% ...
% python get_iq_from_fsq.py 851.7625 0.3 0.126 2^20
% 

python_command = 'E:\\modulation classification\\matlab_dataset\\get_iq_from_fsq.py';

freq_length = length(freq_mhz_vec);

fs_length = length(fs_mhz_vec);
smpl_length = length(sample_length_vec);

if fs_length ~= smpl_length
    fprintf('### error: sample rate vector length = %d, sample length vector length = %d\n', fs_length, smpl_length);
    return;
end

for n = 1 : freq_length
    for m = 1 : fs_length
        command_input_str = sprintf('%.6f %g %.6f %d', freq_mhz_vec(n), rbw_mhz, fs_mhz_vec(m), sample_length_vec(m));
        fprintf('## freq = %.6f mhz, command input = %s\n', freq_mhz_vec(n), command_input_str);
        status = call_python(python_command, command_input_str);
        if status
            fprintf('### error: python command = %s failed\n', python_command);
            return;
        end
        
        % wait for file saving
        pause(3);
    end
end

end

%%
function [status] = call_python(python_command, command_input_str)

% ############ python must be 3.x, not 2.x

command = sprintf('python "%s" %s', python_command, command_input_str);
% ###############################################################
% ### tricky: dont use second "%s" (see below line), use %s (see above line)
% 
% if you use below line, 
% program stop with "command input error: 'iq_length' input must be power of 2"
% ###############################################################
% command = sprintf('python "%s" "%s"', python_command, command_input_str);

status = dos(command);

end



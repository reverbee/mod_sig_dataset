function [] = learn_call_multifunction_in_external_one_file

x = pi / 2;

func = multi_func()

func.fun1(x)
func.fun2(x)

% y = sin_func(x)
% 
% y = cos_func(x)

end

% %%
% function [y] = sin_func(x)
% 
% y = sin(x);
% 
% end
% 
% %%
% function [y] = cos_func(x)
% 
% y = cos(x);
% 
% end

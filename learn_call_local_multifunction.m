function [] = learn_call_local_multifunction

x = 9;

y = func1(x)

z = func2(x)

w = func3(x)

end

%%
function [y] = func1(x)

y = x;

end

%%
function [y] = func2(x)

y = x * 2;

end

%%
function [y] = func3(x)

y = func2(x) + x * 3;

end


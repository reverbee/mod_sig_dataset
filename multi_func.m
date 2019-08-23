function [func] = multi_func()

func.fun1 = @sin_func;
func.fun2 = @cos_func;

end

%%
function [y] = sin_func(x)

y = sin(x);

end

%%
function [y] = cos_func(x)

y = cos(x);

end
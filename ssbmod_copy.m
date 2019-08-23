function y = ssbmod_copy(x, Fc, Fs, varargin)
% SSBMOD Single sideband amplitude modulation.
%   Y = SSBMOD(X, Fc, Fs) uses the message signal X to modulate the carrier
%   frequency Fc (Hz) using single sideband amplitude modulation. X and Fc
%   have sample frequency Fs (Hz). The modulated signal has zero initial
%   phase, and the default sideband modulated is the lower sideband.
%   
%   Y = SSBMOD(X,Fc,Fs,INI_PHASE) specifies the initial phase(rad) of
%   the modulated signal.
%
%   Y = SSBMOD(X,Fc,Fs,INI_PHASE,'upper') uses the upper
%   sideband.
%
%   Fs must satisfy Fs >2*(Fc + BW), where BW is the bandwidth of the
%   modulating signal, X.
%
%   See also SSBDEMOD, AMMOD.

%    Copyright 1996-2016 The MathWorks, Inc.

% Number of arguments check
if(nargin > 5)
    error(message('comm:ssbmod:TooManyInp'));
end

%Check x,Fc, Fs, ini_phase
if(~isreal(x)|| ~isnumeric(x))
    error(message('comm:ssbmod:Xreal'));
end

if(~isreal(Fc) || ~isscalar(Fc) || Fc<=0 || ~isnumeric(Fc) )
    error(message('comm:ssbmod:FcReal'));
end

if(~isreal(Fs) || ~isscalar(Fs) || Fs<=0 || ~isnumeric(Fs) )
    error(message('comm:ssbmod:FsReal'));
end

% check that Fs must be greater than 2*Fc
if(Fs<=2*Fc)
    error(message('comm:ssbmod:Fs2Fc'));
end

if(nargin>=4)
    ini_phase = varargin{1};
    if(isempty(ini_phase))
        ini_phase = 0;
    elseif(~isreal(ini_phase) || ~isscalar(ini_phase)|| ~isnumeric(ini_phase) )
        error(message('comm:ssbmod:IniPhaseReal'));
    end
else 
    ini_phase = 0;
end

Method = '';
if(nargin==5)
    Method = varargin{2};
    if(~strcmpi(Method,'upper'))
        error(message('comm:ssbmod:InvStr'));
    end
end

% --- End Parameter checks --- %

% --- Assure that X, if one dimensional, has the correct orientation --- %
wid = size(x,1);
if(wid ==1)
    x = x(:);
end
t = (0:1/Fs:((size(x,1)-1)/Fs))';
t = t(:, ones(1, size(x, 2)));

if findstr(Method, 'up')
    y = x .* cos(2 * pi * Fc * t + ini_phase) - ...
        imag(hilbert(x)) .* sin(2 * pi * Fc * t + ini_phase);    
else
    y = x .* cos(2 * pi * Fc * t + ini_phase) + ...
        imag(hilbert(x)) .* sin(2 * pi * Fc * t + ini_phase);    
end 

% --- restore the output signal to the original orientation --- %
if(wid == 1)
    y = y';
end

% --- EOF --- %

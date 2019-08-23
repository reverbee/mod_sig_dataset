function [] = learn_fsk_modulation_index

% ################### fsk modulation index ###################
%
% https://www.silabs.com/community/wireless/proprietary/knowledge-base.entry.html/2015/02/04/calculation_of_them-Vx5f
%
% [Question]
% How can I calculate the modulation index for a digital frequency modulated signal (2FSK, 2GFSK, 4FSK, 4GFSK)?
% 
% [Answer]
% The general formula for the modulation index is the following:  
% 
% H = (2 * outer_deviation) / (symbol_rate * (M - 1))
% 
% where H is the modulation index, M is the modulation alphabet size (e.g. M=2 for 2FSK / 2GFSK).
% 
% For 2FSK / 2GFSK modulation the symbol rate is equal to the data rate, 
% and unlike 4FSK / 4GFSK modulation there is only one deviation. 
% This way, the formula can be simplified to the following form:
% 
% H = (2 * freq_deviation) / data_rate, where freq_deviation is from carrier center
% 
% For example, if one would like to have H = 1 modulation index, 40 kbps data rate, 
% then the necessary deviation for 2FSK / 2GFSK modulation will be 20 kHz.
% 
% For 4FSK / 4GFSK modulation the modulation alphabet size is M = 4. 
% In this case there is an inner and an outer deviation, 
% and the connection between them can be described as the following:
% 
% outer_deviation = 3 * inner_deviation
% 
% The modulation index can be expressed with inner deviation for 4FSK / 4GFSK:
% 
% H = 2 * outer_devaition / (symbol_rate * 3) = 2 * inner_deviation / symbol_rate
% 
% For example, if one would like to have H = 1 modulation index, 100 ksps symbol rate, 
% then the necessary inner deviation for 4FSK / 4GFSK modulation will be 50 kHz. 
% In this case the outer deviation will be 150 kHz.
% 


end

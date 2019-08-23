function iq = filter_iq(iq, signal_bw_mhz, sample_rate_mhz, plot_filter_response)

% plot_filter_response = 0;

% filter spec
filter_order = 74;
f_pass = signal_bw_mhz / sample_rate_mhz; % passband freq(normalized)
% f_pass = .25; % passband freq(normalized)
% f_stop = .35; % stopband freq(normalized)
% a_pass = .01; % passband ripple in db
% % a_pass = .5; % passband ripple in db
% a_stop = 65; % stopband attenuation in db

% design fir filter
filter_coeff = design_fir_filter(filter_order, f_pass, plot_filter_response);

% filtering
a = 1;
iq = filter(filter_coeff, a, iq);

end

%%
function [filter_coeff] = design_fir_filter(filter_order, f_pass, plot_filter_response)
% design fir filter
% ##### python equivalent function(fir1) is used
%
% [input]
% - filter_order: filter order, length(filter_coeff) = filter_order + 1
% - f_pass: passband freq(normalized)
% - plot_filter_response: 
%
% [usage]
% [filter_coeff] = design_fir_filter(74, .25, 0)

% ## old version used 'designfilt'
filter_coeff = fir1(filter_order, f_pass);

if plot_filter_response
    figure;
    freqz(filter_coeff, 1);
    title(sprintf('low-pass FIR filter response: pass-band freq = %g', f_pass));
end

% % save filter coefficients
% save('filter_coeff_matlab.txt', 'filter_coeff', '-ascii');

end

function [] = compute_feature_from_iq_sample()

% ######### feature selection
% 
% [reference] Automatic Modulation Classification_ Principles, Algorithms and Applications [Zhu & Nandi 2015-02-16]
%
% (signal spectral-based feature)
%
% (1) gamma_max:
% max of spectral power density of normalized and centred instantaneous amplitude of the received signal
%
% (2) sigma_ap:
% standard deviation of absolute value of non-linear component of the instantaneous phase
%
% (3) sigma_dp:
% standard deviation of non-linear component of direct instantaneous phase
%
% (4) sym_P:
% evaluation of spectrum symmetry around carrier frequency
%
% (5) sigma_aa:
% standard deviation of absolute value of normalized and centred instantaneous amplitude of signal samples
%
% (6) sigma_af:
% standard deviation of absolute value of normalized and centred instantaneous frequency
% 
% (7) sigma_a:
% standard deviation of normalized and centred instantaneous amplitude
%
% (8) mu_a42:
% kurtosis of normalized and centred instantaneous amplitude
%
% (9) mu_f42:
% kurtosis of normalized and centred instantaneous frequency
%
% (high-order moment-based feature)
%
% k-th order moment of signal phase for classifying M-PSK modulation
% page 74, eq 5.39
%
% (high-order cumulant-based feature)
%
% C_20, C_21, C_40, C_41, C_42
%
% [reference]
%
% Robust Automatic Modulation Classification Technique for Fading Channels via Deep Neural Network(korean author)
%
% (1) C_60, C_61, C_62, C_63, C_80, C_81, C_82, C_83, C_84
%
% (2) C_10_0, C_10_1, C_10_2
% 
% (3) more ... (see paper)

% ######## learning "moment" (https://en.wikipedia.org/wiki/Moment_(mathematics))
%
% In mathematics, a moment is a specific quantitative measure of the shape of a set of points.
%
% If the points represent probability density, 
% then the zeroth moment is the total probability (i.e. one), 
% the first moment is the mean, 
% the second central moment is the variance, 
% the third central moment is the skewness, 
% and the fourth central moment (with normalization and shift) is the kurtosis.








end
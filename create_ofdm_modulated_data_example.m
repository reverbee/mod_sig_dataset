% function [] = create_ofdm_modulated_data_example
% modified from "UsethestepmethodtocreateOFDMmodulateddataExample.m" matlab example

%% Create OFDM Modulated Data  
% Generate OFDM modulated symbols for use in link-level simulations.   

%% 
% Construct an OFDM modulator with an inserted DC null, seven guard-band subcarriers, 
% and two symbols having different pilot indices for each symbol. 
mod = comm.OFDMModulator('NumGuardBandCarriers',[4;3],...
'PilotInputPort',true, ...
'PilotCarrierIndices',[12 11; 26 27; 40 39; 54 55], ...
'NumSymbols',2, ...
'InsertDCNull',true);  

%% 
% Determine input data, pilot, and output data dimensions. 
modDim = info(mod);  

%%
% Generate random data symbols for the OFDM modulator. The structure variable,
% |modDim|, determines the number of data symbols. 
dataIn = complex(randn(modDim.DataInputSize),randn(modDim.DataInputSize));  

%% 
% Create a pilot signal that has the correct dimensions. 
pilotIn = complex(rand(modDim.PilotInputSize),rand(modDim.PilotInputSize));  

%% 
% Apply OFDM modulation to the data and pilot signals. 
modData = step(mod,dataIn,pilotIn);  

%% 
% Use the OFDM modulator object to create the corresponding OFDM demodulator. 
demod = comm.OFDMDemodulator(mod);  

%% 
% Demodulate the OFDM signal and output the data and pilot signals. 
[dataOut, pilotOut] = step(demod,modData);  

%% 
% Verify that, within a tight tolerance, the input data and pilot symbols
% match the output data and pilot symbols.
isSame = (max(abs([dataIn(:) - dataOut(:); ...
    pilotIn(:) - pilotOut(:)])) < 1e-10);

% end


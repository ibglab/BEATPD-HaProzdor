function featurs = extractFeautesTimeSig1Axes(signal)
% extract feautes and combine and arrange features from 1 axes of time domain signal

[mean_X,std_X,mad_X,max_X,min_X,energy_X,iqr_X,entropy_X,arCoeff1_X,arCoeff2_X,arCoeff3_X,arCoeff4_X] = extractBasicFeatures(signal, 'time');

% sma
sma = sum(abs(signal),2) / length(signal);

featurs = [mean_X,std_X,mad_X,max_X,min_X,sma, energy_X,iqr_X,entropy_X,arCoeff1_X,arCoeff2_X,arCoeff3_X,arCoeff4_X];
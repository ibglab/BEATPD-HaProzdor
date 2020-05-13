function featurs = extractFeautesFreqSig1Axes(signal, freqRange)
% extract feautes and combine and arrange features from 1 axes of time domain signal

%X
[mean_X,std_X,mad_X,max_X,min_X,energy_X,iqr_X,entropy_X] = extractBasicFeatures(signal, 'freq');  

% sma
sma = sum(abs(signal),2) / length(signal);

[~, maxInds] = max(signal, [] , 2);
% mean freq==frequency centroid (Weighted average of the frequency components)
meanFreq = sum(signal.*freqRange, 2) ./ sum(signal, 2);
skew = skewness(signal, [] ,2);
kurt = kurtosis(signal, [] ,2);


featurs = [mean_X,std_X,mad_X,max_X,min_X,sma, energy_X,iqr_X,entropy_X, maxInds, meanFreq, skew, kurt];

end




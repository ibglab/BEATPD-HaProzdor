function featurs = extractFeautesFreqSig3Axes(signalX, signalY, signalZ, freqRange)
% extract feautes and combine and arrange features from 3 axes of time domain signal

%X
[mean_X,std_X,mad_X,max_X,min_X,energy_X,iqr_X,entropy_X] = extractBasicFeatures(signalX, 'freq');  
%Y
[mean_Y,std_Y,mad_Y,max_Y,min_Y,energy_Y,iqr_Y,entropy_Y] = extractBasicFeatures(signalY, 'freq');
%Z
[mean_Z,std_Z,mad_Z,max_Z,min_Z,energy_Z,iqr_Z,entropy_Z] = extractBasicFeatures(signalZ,'freq');
% sma
sma = signalMagnitudeArea(signalX, signalY, signalZ);
% max index
[maxIndsX, meanFreqX, skewX, kurtX, bandsEnergy8X, bandsEnergy4X, bandsEnergy2X] = calcFreqFeatures(signalX, freqRange);
[maxIndsY, meanFreqY, skewY, kurtY, bandsEnergy8Y, bandsEnergy4Y, bandsEnergy2Y] = calcFreqFeatures(signalY, freqRange);
[maxIndsZ, meanFreqZ, skewZ, kurtZ, bandsEnergy8Z, bandsEnergy4Z, bandsEnergy2Z] = calcFreqFeatures(signalZ, freqRange);



featurs = [mean_X, mean_Y, mean_Z, std_X, std_Y, std_Z, mad_X, mad_Y, mad_Z, max_X, max_Y, max_Z, min_X, min_Y, min_Z, sma, energy_X, energy_Y, energy_Z,...
    iqr_X, iqr_Y, iqr_Z, entropy_X, entropy_Y, entropy_Z, maxIndsX, maxIndsY, maxIndsZ, meanFreqX, meanFreqY, meanFreqZ,...
    skewX, kurtX, skewY, kurtY,skewZ, kurtZ, bandsEnergy8X(:,1), bandsEnergy8X(:,2), bandsEnergy8X(:,3), bandsEnergy8X(:,4),...
    bandsEnergy8X(:,5), bandsEnergy8X(:,6), bandsEnergy8X(:,7), bandsEnergy8X(:,8), bandsEnergy4X(:,1), bandsEnergy4X(:,2), bandsEnergy4X(:,3),...
    bandsEnergy4X(:,4), bandsEnergy2X(:,1), bandsEnergy2X(:,2), bandsEnergy8Y(:,1), bandsEnergy8Y(:,2), bandsEnergy8Y(:,3), bandsEnergy8Y(:,4),...
    bandsEnergy8Y(:,5), bandsEnergy8Y(:,6), bandsEnergy8Y(:,7), bandsEnergy8Y(:,8), bandsEnergy4Y(:,1), bandsEnergy4Y(:,2), bandsEnergy4Y(:,3),...
    bandsEnergy4Y(:,4), bandsEnergy2Y(:,1), bandsEnergy2Y(:,2), bandsEnergy8Z(:,1), bandsEnergy8Z(:,2), bandsEnergy8Z(:,3), bandsEnergy8Z(:,4),...
    bandsEnergy8Z(:,5), bandsEnergy8Z(:,6), bandsEnergy8Z(:,7), bandsEnergy8Z(:,8), bandsEnergy4Z(:,1), bandsEnergy4Z(:,2), bandsEnergy4Z(:,3),...
    bandsEnergy4Z(:,4), bandsEnergy2Z(:,1), bandsEnergy2Z(:,2)];

end

function [maxInds, meanFreq, skew, kurt, bandsEnergy8, bandsEnergy4, bandsEnergy2] = calcFreqFeatures(signal, freqRange)

sigLen = size(signal, 2);
[~, maxInds] = max(signal, [] , 2);
% mean freq==frequency centroid (Weighted average of the frequency components)
meanFreq = sum(signal.*freqRange, 2) ./ sum(signal, 2);
skew = skewness(signal, [] ,2);
kurt = kurtosis(signal, [] ,2);

%bands energy-- divide the signal into 8, 4 and 2 bands and calculate energy
% 8 intervals
nIntervals = 8;
segmentsFirst = round(linspace(0, sigLen, nIntervals+1));
for i = 1:nIntervals
    sig = signal(:, segmentsFirst(i)+1:segmentsFirst(i+1));
    bandsEnergy8(:,i) = sum(sig.^2, 2) / size(sig,2);
end
% 4 intervals
nIntervals = 4;
segmentsFirst = round(linspace(0, sigLen, nIntervals+1));
for i = 1:nIntervals
    sig = signal(:, segmentsFirst(i)+1:segmentsFirst(i+1));
    bandsEnergy4(:,i) = sum(sig.^2, 2) / size(sig,2);
end
% 2 intervals
nIntervals = 2;
segmentsFirst = round(linspace(0, sigLen, nIntervals+1));
for i = 1:nIntervals
    sig = signal(:, segmentsFirst(i)+1:segmentsFirst(i+1));
    bandsEnergy2(:,i) = sum(sig.^2, 2) / size(sig,2);
end
end


function featurs = extractFeautesTimeSig3Axes(signalX, signalY, signalZ)
% extract feautes and combine and arrange features from 3 axes of time domain signal

nSamples = size(signalX, 1);
%X
[mean_X,std_X,mad_X,max_X,min_X,energy_X,iqr_X,entropy_X,arCoeff1_X,arCoeff2_X,arCoeff3_X,arCoeff4_X] = extractBasicFeatures(signalX, 'time');
%Y
[mean_Y,std_Y,mad_Y,max_Y,min_Y,energy_Y,iqr_Y,entropy_Y,arCoeff1_Y,arCoeff2_Y,arCoeff3_Y,arCoeff4_Y] = extractBasicFeatures(signalY, 'time');
%Z
[mean_Z,std_Z,mad_Z,max_Z,min_Z,energy_Z,iqr_Z,entropy_Z,arCoeff1_Z,arCoeff2_Z,arCoeff3_Z,arCoeff4_Z] = extractBasicFeatures(signalZ, 'time');
% sma
sma = signalMagnitudeArea(signalX, signalY, signalZ);
% correlations
corrXY = zeros(nSamples, 1);
corrXZ = zeros(nSamples, 1);
corrYZ = zeros(nSamples, 1);

for i = 1:nSamples
    c = corrcoef(signalX(i, :), signalY(i,:));
    corrXY(i) = c(1, 2);
    c = corrcoef(signalX(i, :), signalZ(i,:));
    corrXZ(i) = c(1, 2);
    c = corrcoef(signalY(i, :), signalZ(i,:));
    corrYZ(i) = c(1, 2);
end
featurs = [mean_X, mean_Y, mean_Z, std_X, std_Y, std_Z, mad_X, mad_Y, mad_Z, max_X, max_Y, max_Z, min_X, min_Y, min_Z, sma, energy_X, energy_Y, energy_Z,...
    iqr_X, iqr_Y, iqr_Z, entropy_X, entropy_Y, entropy_Z, arCoeff1_X,arCoeff2_X,arCoeff3_X,arCoeff4_X,...
    arCoeff1_Y,arCoeff2_Y,arCoeff3_Y,arCoeff4_Y, arCoeff1_Z,arCoeff2_Z,arCoeff3_Z,arCoeff4_Z, corrXY, corrXZ, corrYZ];
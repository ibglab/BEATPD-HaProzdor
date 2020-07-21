clear; clc;
sampRate = 50;
numWindows = 10;
winLen = sampRate*numWindows ;
overlap = winLen/2;
datasetName = 'REAL';
trainOrTests = {'train', 'test'};   % choose which data to use


for t = 1:length(trainOrTests)
    dataFolder = ['..\data\'];
    trainOrTest = trainOrTests{t};
    if strcmp(trainOrTest, 'train')
        sessionFiles = dir ([dataFolder, datasetName,'-PD_training_data']);  % training or testing
            allLabelsData = readtable([dataFolder, datasetName, '-PD_Training_Data_IDs_Labels.csv']);      % training or testing
        dataFolder = [dataFolder, datasetName,'-PD_training_data\'];
    else
        sessionFiles = dir ([dataFolder, datasetName,'-PD_Test_data']);  % training or testing
        allLabelsData = readtable([dataFolder, datasetName, '-PD_Test_Data_IDs_Labels.csv']);      % training or testing
        dataFolder = [dataFolder, datasetName,'-PD_Test_data\'];
    end


    % filters to seperate grivity from body acceleration
    [bLow,aLow] = butter(4, 0.3/(sampRate/2), 'low');
    [bHigh,aHigh] = butter(4, 0.3/(sampRate/2), 'high');
    % frequency parameters
    freqRange = sampRate*(0:(winLen/2))/winLen;

    subjects = unique(allLabelsData.subject_id);
    parfor id = 1:length(subjects)
        subjectID = subjects{id};
        % get only specified subject
        labelsData = allLabelsData(strcmp(string(allLabelsData.subject_id), subjectID),:);
        allSessionsFeatures = [];
        allOnOffLabels = [];
        allDyskLabels = [];
        allTremorLabels = [];
        tTotalAccXseg_all_watch_1 = [];
        tTotalAccYseg_all_watch_1 = [];
        tTotalAccZseg_all_watch_1 = [];
        tBodyAccXseg_all_watch_1 = [];
        tBodyAccYseg_all_watch_1 = [];
        tBodyAccZseg_all_watch_1 = [];
        tTotalAccXseg_all_watch_2 = [];
        tTotalAccYseg_all_watch_2 = [];
        tTotalAccZseg_all_watch_2 = [];
        tBodyAccXseg_all_watch_2 = [];
        tBodyAccYseg_all_watch_2 = [];
        tBodyAccZseg_all_watch_2 = [];
        tTotalAccXseg_all_phone = [];
        tTotalAccYseg_all_phone = [];
        tTotalAccZseg_all_phone = [];
        tBodyAccXseg_all_phone= [];
        tBodyAccYseg_all_phone= [];
        tBodyAccZseg_all_phone= [];
        tGyroXseg_all_1 = [];
        tGyroYseg_all_1 = [];
        tGyroZseg_all_1 = [];
        tGyroXseg_all_2 = [];
        tGyroYseg_all_2 = [];
        tGyroZseg_all_2 = [];
        sessionIDs = {};
        subjectIDs =  [];
        trainIdx = [];
        testIdx = [];

        for i = 1: size(labelsData,1)
            sessionID = labelsData.measurement_id{i};
            accWatch_fileName = [dataFolder, '\smartwatch_accelerometer\', sessionID, '.csv'];
            gyro_fileName = [dataFolder, '\smartwatch_gyroscope\', sessionID, '.csv'];

            try
                accData_watch = readtable(accWatch_fileName);
                gyroData = readtable(gyro_fileName);
            catch
                disp(['ERROR loading file: sessionID not found:   ', sessionID]);
                continue;
            end
            accX_watch = accData_watch.x(1:end)';
            accY_watch = accData_watch.y(1:end)';
            accZ_watch = accData_watch.z(1:end)';
            accWatch_timeStamps  = accData_watch.t(1:end);
            accDevice_id = accData_watch.device_id(1:end);
            gyrX = gyroData.x(1:end)';
            gyrY = gyroData.y(1:end)';
            gyrZ = gyroData.z(1:end)';
            gyrWatch_timeStamps = gyroData.t(1:end);
            gyrDevice_id = gyroData.device_id(1:end);

            labels = labelsData(ismember(labelsData.measurement_id, sessionID),:);
            subjID = labels.subject_id{1};

            % watch data can be divided to 2 devices-2 seperate signals
            [accWatch_timeStamps1, accX_watch1, accY_watch1, accZ_watch1, accWatch_timeStamps2, accX_watch2, accY_watch2, accZ_watch2, accTwoDevicesFlag] = seperateDataInto2Devices(accDevice_id, accWatch_timeStamps, accX_watch, accY_watch, accZ_watch);
            [gyrWatch_timeStamps1, gyrX1, gyrY1, gyrZ1, gyrWatch_timeStamps2, gyrX2, gyrY2, gyrZ2, gyrTwoDevicesFlag] = seperateDataInto2Devices(gyrDevice_id, gyrWatch_timeStamps, gyrX, gyrY, gyrZ);

            %resample signals due to varying sampling frequency
            [accWatch_timeStamps1, accX_watch1, accY_watch1, accZ_watch1] = resampleVaryingSampRate(accWatch_timeStamps1, sampRate, accX_watch1, accY_watch1, accZ_watch1);
            [accWatch_timeStamps2, accX_watch2, accY_watch2, accZ_watch2] = resampleVaryingSampRate(accWatch_timeStamps2, sampRate, accX_watch2, accY_watch2, accZ_watch2);
            [gyrWatch_timeStamps1, gyrX1, gyrY1, gyrZ1] = resampleVaryingSampRate(gyrWatch_timeStamps1, sampRate, gyrX1, gyrY1, gyrZ1);
            [gyrWatch_timeStamps2, gyrX2, gyrY2, gyrZ2] = resampleVaryingSampRate(gyrWatch_timeStamps2, sampRate, gyrX2, gyrY2, gyrZ2);

            minLen = min([length(accWatch_timeStamps1), length(gyrWatch_timeStamps1)]);
            if abs(length(accWatch_timeStamps1)-length(gyrWatch_timeStamps1)) > 10
                disp(sessionID)
            end
            accX_watch1 = accX_watch1(1:minLen);     accY_watch1 = accY_watch1(1:minLen);    accZ_watch1 = accZ_watch1(1:minLen);
            gyrX1 = gyrX1(1:minLen);    gyrY1 = gyrY1(1:minLen);    gyrZ1 = gyrZ1(1:minLen);

            % in case of very short sessions, skip (like session61741f87-aea6-40b8-b28a-850e856e7b8d)
            if minLen < winLen*2
                disp(['Session very short:   ', sessionID]);
                continue;
            end
            if strcmp(trainOrTest, 'train')
                onOffLabel = str2double(labels.on_off{1});
                dyskinesiaLabel = str2double(labels.dyskinesia{1});
                tremorLabel = str2double(labels.tremor{1});
            end

            features = [];

            % time domain signals - smartwatch
            % X
            % watch
            [tTotalAccX_watch1, tGravityAccX_watch1, tGravityAccXseg_watch1, tBodyAccX_watch1, tBodyAccXseg_watch1, tBodyAccJerkX_watch1, tBodyAccJerkXseg_watch1] = preProcessAccData(accX_watch1, winLen, overlap, bLow, aLow, bHigh,aHigh);
            tTotalAccXseg_all_watch_1 = [tTotalAccXseg_all_watch_1; tTotalAccX_watch1];
            tBodyAccXseg_all_watch_1 = [tBodyAccXseg_all_watch_1; tBodyAccXseg_watch1];
            %gyro
            [tGyroXseg1, tGyroJerkX1, tGyroJerkXseg1] = preProcessGyroData(gyrX1, winLen, overlap);
            tGyroXseg_all_1 = [tGyroXseg_all_1; tGyroXseg1];

            % Y
            % watch
            [tTotalAccY_watch1, tGravityAccY_watch1, tGravityAccYseg_watch1, tBodyAccY_watch1, tBodyAccYseg_watch1, tBodyAccJerkY_watch1, tBodyAccJerkYseg_watch1] = preProcessAccData(accY_watch1, winLen, overlap, bLow, aLow, bHigh,aHigh);
            tTotalAccYseg_all_watch_1 = [tTotalAccYseg_all_watch_1; tTotalAccY_watch1];
            tBodyAccYseg_all_watch_1 = [tBodyAccYseg_all_watch_1; tBodyAccYseg_watch1];
            %gyro
            [tGyroYseg1, tGyroJerkY1, tGyroJerkYseg1] = preProcessGyroData(gyrY1, winLen, overlap);
            tGyroYseg_all_1 = [tGyroYseg_all_1; tGyroYseg1];

            % Z
            % watch
            [tTotalAccZ_watch1, tGravityAccZ_watch1, tGravityAccZseg_watch1, tBodyAccZ_watch1, tBodyAccZseg_watch1, tBodyAccJerkZ_watch1, tBodyAccJerkZseg_watch1] = preProcessAccData(accZ_watch1, winLen, overlap, bLow, aLow, bHigh,aHigh);
            tTotalAccZseg_all_watch_1 = [tTotalAccZseg_all_watch_1; tTotalAccZ_watch1];
            tBodyAccZseg_all_watch_1 = [tBodyAccZseg_all_watch_1; tBodyAccZseg_watch1];
            %gyro
            [tGyroZseg1, tGyroJerkZ1, tGyroJerkZseg1] = preProcessGyroData(gyrZ1, winLen, overlap);
            tGyroZseg_all_1 = [tGyroZseg_all_1; tGyroZseg1];


            %Magnitudes
            tBodyAccMagSeg_watch1 = calcMagnitude(tBodyAccX_watch1, tBodyAccY_watch1, tBodyAccZ_watch1, winLen, overlap);
            tGravityAccMagSeg_watch1 = calcMagnitude(tGravityAccX_watch1, tGravityAccY_watch1, tGravityAccZ_watch1, winLen, overlap);
            tBodyAccJerkMagSeg_watch1 = calcMagnitude(tBodyAccJerkX_watch1, tBodyAccJerkY_watch1, tBodyAccJerkZ_watch1, winLen, overlap);
            tGyroMagSeg1 = calcMagnitude(gyrX1, gyrY1, gyrX1, winLen, overlap);
            tGyroJerkMagSeg1 = calcMagnitude(tGyroJerkX1, tGyroJerkY1, tGyroJerkZ1, winLen, overlap);


            % extract basic time domain features
            features = extractFeautesTimeSig3Axes(tBodyAccXseg_watch1, tBodyAccYseg_watch1, tBodyAccZseg_watch1);
            features = [features, extractFeautesTimeSig3Axes(tGravityAccXseg_watch1, tGravityAccYseg_watch1, tGravityAccZseg_watch1)];
            features = [features, extractFeautesTimeSig3Axes(tBodyAccJerkXseg_watch1, tBodyAccJerkYseg_watch1, tBodyAccJerkZseg_watch1)];
            features = [features, extractFeautesTimeSig3Axes(tGyroXseg1, tGyroYseg1, tGyroZseg1)];
            features = [features, extractFeautesTimeSig3Axes(tGyroJerkXseg1, tGyroJerkYseg1, tGyroJerkZseg1)];
            features = [features, extractFeautesTimeSig1Axes(tBodyAccMagSeg_watch1)];
            features = [features, extractFeautesTimeSig1Axes(tGravityAccMagSeg_watch1)];
            features = [features, extractFeautesTimeSig1Axes(tBodyAccJerkMagSeg_watch1)];
            features = [features, extractFeautesTimeSig1Axes(tGyroMagSeg1)];
            features = [features, extractFeautesTimeSig1Axes(tGyroJerkMagSeg1)];

            % frequency domain
            fBodyAccXseg_watch1 = []; fBodyAccYseg_watch1 = []; fBodyAccZseg_watch1 = [];
            fBodyAccJerkXseg_watch1 = []; fBodyAccJerkYseg_watch1 = []; fBodyAccJerkZseg_watch1 = [];
            fGyroXseg1 = []; fGyroYseg1 = []; fGyroZseg1 = [];
            fBodyAccMagSeg_watch1 = []; fBodyAccJerkMagSeg_watch1 = []; fGyroMagSeg1 = []; fGyroJerkMagSeg1 = [];

            nSegments = size(tBodyAccXseg_watch1, 1);
            for j = 1:nSegments
                fBodyAccXseg_watch1(j, :) = computFftForWindow(tBodyAccXseg_watch1(j, :));
                fBodyAccYseg_watch1(j,:) = computFftForWindow(tBodyAccYseg_watch1(j, :));
                fBodyAccZseg_watch1(j,:) = computFftForWindow(tBodyAccZseg_watch1(j, :));
                fBodyAccJerkXseg_watch1(j,:) = computFftForWindow(tBodyAccJerkXseg_watch1(j, :));
                fBodyAccJerkYseg_watch1(j,:) = computFftForWindow(tBodyAccJerkYseg_watch1(j, :));
                fBodyAccJerkZseg_watch1(j,:) = computFftForWindow(tBodyAccJerkZseg_watch1(j, :));
                fGyroXseg1(j, :) = computFftForWindow(tGyroXseg1(j, :));
                fGyroYseg1(j, :) = computFftForWindow(tGyroYseg1(j, :));
                fGyroZseg1(j, :) = computFftForWindow(tGyroZseg1(j, :));
                fGyroJerkXseg1 = gradient(fGyroXseg1(j,:));
                fGyroJerkYseg1 = gradient(fGyroYseg1(j,:));
                fGyroJerkZseg1 = gradient(fGyroZseg1(j,:));

                fBodyAccMagSeg_watch1(j,:) = sqrt(sum([fBodyAccXseg_watch1(j, :); fBodyAccYseg_watch1(j, :); fBodyAccZseg_watch1(j, :)]'.^2, 2))';
                fBodyAccJerkMagSeg_watch1(j,:) = sqrt(sum([fBodyAccJerkXseg_watch1(j, :); fBodyAccJerkYseg_watch1(j, :); fBodyAccJerkZseg_watch1(j, :)]'.^2, 2))';
                fGyroMagSeg1(j,:) = sqrt(sum([fGyroXseg1(j, :); fGyroYseg1(j, :); fGyroZseg1(j, :)]'.^2, 2))';
                fGyroJerkMagSeg1(j,:) = sqrt(sum([fGyroJerkXseg1; fGyroJerkYseg1; fGyroJerkZseg1]'.^2, 2))';
            end

            features = [features, extractFeautesFreqSig3Axes(fBodyAccXseg_watch1, fBodyAccYseg_watch1, fBodyAccZseg_watch1, freqRange)];
            features = [features, extractFeautesFreqSig3Axes(fBodyAccJerkXseg_watch1, fBodyAccJerkYseg_watch1, fBodyAccJerkZseg_watch1, freqRange)];
            features = [features, extractFeautesFreqSig3Axes(fGyroXseg1, fGyroYseg1, fGyroZseg1, freqRange)];
            features = [features, extractFeautesFreqSig1Axes(fBodyAccMagSeg_watch1, freqRange)];
            features = [features, extractFeautesFreqSig1Axes(fBodyAccJerkMagSeg_watch1, freqRange)];
            features = [features, extractFeautesFreqSig1Axes(fGyroMagSeg1, freqRange)];
            features = [features, extractFeautesFreqSig1Axes(fGyroJerkMagSeg1, freqRange)];


            % get labels
            if strcmp(trainOrTest, 'train')
                % duplicate yLabels and session numbers
                onOffLabelSeg = onOffLabel.*ones(size(tBodyAccXseg_watch1, 1),1);
                dyskLabelSeg = dyskinesiaLabel.*ones(size(tBodyAccXseg_watch1, 1),1);
                tremorLabelSeg = tremorLabel.*ones(size(tBodyAccXseg_watch1, 1),1);

                allOnOffLabels = [allOnOffLabels; onOffLabelSeg];
                allDyskLabels = [allDyskLabels ; dyskLabelSeg];
                allTremorLabels = [allTremorLabels ; tremorLabelSeg];
            end
            sessionIDs = [sessionIDs; repelem({sessionID}, size(tBodyAccXseg_watch1,1),1)];
            subjectIDs = [subjectIDs ; repelem({subjID}, size(tBodyAccXseg_watch1,1),1)];


            allSessionsFeatures = [allSessionsFeatures; features];

        end

        % save all
        if strcmp(trainOrTest, 'train')
            folderName = sprintf('SegmentedData_winLen%d_overlap%d_%s', winLen, overlap, subjectID);
        else
            folderName = sprintf('SegmentedData_winLen%d_overlap%d_%s_test', winLen, overlap, subjectID);   % add test
        end
        mkdir(folderName);
        dlmwrite([folderName,'\X_data.txt'], allSessionsFeatures, ' ');
        if strcmp(trainOrTest, 'train')
            dlmwrite([folderName,'\y_on_off.txt'], allOnOffLabels, ' ');
            dlmwrite([folderName,'\y_dyskinesia.txt'], allDyskLabels, ' ');
            dlmwrite([folderName,'\y_tremor.txt'], allTremorLabels, ' ');
        end
        dlmwrite([folderName,'\sessionIDs.txt'], sessionIDs, ' ');
        dlmwrite([folderName,'\subjectIDs.txt'], subjectIDs, ' ');  
    end
end

%%
function [timeStamps1, dataX1, dataY1, dataZ1, timeStamps2, dataX2, dataY2, dataZ2, twoDevicesFlag] = seperateDataInto2Devices(deviceIDs, timeStamps, dataX, dataY, dataZ)
% in case of 2 devices in watch, get data from first or second device
% in case there only one device, duplicate original data in first and
% second variables
[~,deviceUniqueIdx]=unique(cell2mat(deviceIDs),'rows');
if length(deviceUniqueIdx)==2
    twoDevicesFlag = true;
    device1Idx1 = find(strcmp(deviceIDs, deviceIDs{deviceUniqueIdx(1)}));
    device1Idx2 = find(strcmp(deviceIDs, deviceIDs{deviceUniqueIdx(2)}));
    % make the first device the longer one
    if length(device1Idx1) < length(device1Idx2)
        a = device1Idx1;
        device1Idx1 = device1Idx2;
        device1Idx2 = a;
    end
    timeStamps1 = timeStamps(device1Idx1);
    dataX1 = dataX(device1Idx1);
    dataY1 = dataY(device1Idx1);
    dataZ1 = dataZ(device1Idx1);
    timeStamps2 = timeStamps(device1Idx2);
    dataX2 = dataX(device1Idx2);
    dataY2 = dataY(device1Idx2);
    dataZ2 = dataZ(device1Idx2);
else
    twoDevicesFlag = false;
    timeStamps1 = timeStamps;
    dataX1 = dataX;
    dataY1 = dataY;
    dataZ1 = dataZ;
    timeStamps2 = timeStamps;
    dataX2 = dataX;
    dataY2 = dataY;
    dataZ2 = dataZ;
end
end

function [newTimestamps,dataXres, dataYres, dataZres] = resampleVaryingSampRate(timeStamps, fixedSampRate, dataX, dataY, dataZ)
% resample signals from phone and watch having varying sampling rate
[timeStamps, tsIndex] = unique(timeStamps);
newTimestamps = [timeStamps(1) : 1/fixedSampRate : timeStamps(end)];
dataXres = interp1(timeStamps,dataX(tsIndex),newTimestamps,'pchip');
dataYres = interp1(timeStamps,dataY(tsIndex),newTimestamps,'pchip');
dataZres = interp1(timeStamps,dataZ(tsIndex),newTimestamps,'pchip');
end

function [tTotalAcc, tGravityAcc, tGravityAccSeg, tBodyAcc, tBodyAccSeg, tBodyAccJerk, tBodyAccJerkSeg] = preProcessAccData(accData, winLen, overlap, bLow, aLow, bHigh, aHigh)
% divide accleretion data to gravity, body and jerk. and segment data

tTotalAcc = segmentData(accData, winLen, overlap);
% seperate to gravity and body
tGravityAcc = filtfilt(bLow, aLow, accData);
tGravityAccSeg = segmentData(tGravityAcc, winLen, overlap);

tBodyAcc = filtfilt(bHigh, aHigh, accData);
tBodyAccSeg = segmentData(tBodyAcc, winLen, overlap);
% jerk
tBodyAccJerk = gradient(tBodyAcc);
tBodyAccJerkSeg = segmentData(tBodyAccJerk, winLen, overlap);
end

function [tGyroSeg, tGyroJerk, tGyroJerkSeg] = preProcessGyroData(gyrX, winLen, overlap)
% segment gyro data and extract jerk
tGyroSeg = segmentData(gyrX, winLen, overlap);
tGyroJerk = gradient(gyrX);
tGyroJerkSeg = segmentData(tGyroJerk, winLen, overlap);
end

function magnitudeSeg = calcMagnitude(Xdata, Ydata, Zdata, winLen, overlap)
%get x,y,z signal and calc segmented magnitude
magnitude = sqrt(sum([Xdata; Ydata; Zdata]'.^2, 2))';
magnitudeSeg = segmentData(magnitude, winLen, overlap);
end

function fftRes = computFftForWindow(signal)
len = length(signal);
Y = fft(signal);
P2 = abs(Y/len);
fftRes = P2(1:len/2+1);
fftRes(2:end-1) = fftRes(2:end-1).^2;
end

function angle= angleBetweenVectors(sig1, sig2)
angle = zeros(size(sig1, 1), 1);
for i = 1:size(sig1, 1)
    x = sig1(i,:);
    y = sig2(i,:);
    angle(i) = acosd(dot(x, y) / norm(x) / norm(y));
end
end



clear; clc;
sampRate = 50;
numWindows = 10;
winLen = sampRate*numWindows;
overlap = winLen/2;
datasetName = 'cis';
trainOrTests = {'train', 'test'};   % choose which data to use

for t = 1:length(trainOrTests)
    trainOrTest = trainOrTests{t};
    dataFolder = ['..\data\'];
    
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
        subjectID = num2str(subjects(id));
        % get only specified subject
        labelsData = allLabelsData(strcmp(string(allLabelsData.subject_id), subjectID),:);
        
        allSessionsFeatures = [];
        allOnOffLabels = [];
        allDyskLabels = [];
        allTremorLabels = [];
        tTotalAccXseg_all = [];
        tTotalAccYseg_all = [];
        tTotalAccZseg_all = [];
        tBodyAccXseg_all = [];
        tBodyAccYseg_all = [];
        tBodyAccZseg_all = [];
        sessionIDs = {};
        subjectIDs =  [];
        trainIdx = [];
        testIdx = [];
        
        for i = 1: size(labelsData,1)
            %     fileName = sessionFiles(i).name;
            sessionID = labelsData.measurement_id{i};
            fileName = [dataFolder, sessionID, '.csv'];
            
            try
                accData = csvread(fileName, 1, 1);
            catch
                sprintf('ERROR loading file: file %s not found', sessionID);
                continue;
            end
            accX = accData(:,1)';
            accY = accData(:,2)';
            accZ = accData(:,3)';
            labels = labelsData(ismember(labelsData.measurement_id, sessionID),:);
            if strcmp(datasetName, 'cis')
                subjID = labels.subject_id;
            else
                subjID = labels.subject_id{1};
            end
            if strcmp(trainOrTest, 'train')
                onOffLabel = str2double(labels.on_off{1});
                dyskinesiaLabel = str2double(labels.dyskinesia{1});
                tremorLabel = str2double(labels.tremor{1});
            end
            
            features = [];
            
            % time domain signals
            % X
            tTotalAccXseg_all = [tTotalAccXseg_all; segmentData(accX, winLen, overlap)];
            tGravityAccX = filtfilt(bLow, aLow, accX);
            tGravityAccXseg = segmentData(tGravityAccX, winLen, overlap);
            tBodyAccX = filtfilt(bHigh, aHigh, accX);
            tBodyAccXseg = segmentData(tBodyAccX, winLen, overlap);
            tBodyAccXseg_all = [tBodyAccXseg_all; tBodyAccXseg];
            tBodyAccJerkX = gradient(tBodyAccX);
            tBodyAccJerkXseg = segmentData(tBodyAccJerkX, winLen, overlap);
            % Y
            tTotalAccYseg_all = [tTotalAccYseg_all; segmentData(accY, winLen, overlap)];
            tGravityAccY = filtfilt(bLow, aHigh, accY);
            tGravityAccYseg = segmentData(tGravityAccY, winLen, overlap);
            tBodyAccY = filtfilt(bLow, aHigh, accY);
            tBodyAccYseg = segmentData(tBodyAccY, winLen, overlap);
            tBodyAccYseg_all = [tBodyAccYseg_all; tBodyAccYseg];
            tBodyAccJerkY = gradient(tBodyAccY);
            tBodyAccJerkYseg = segmentData(tBodyAccJerkY, winLen, overlap);
            % Z
            tTotalAccZseg_all = [tTotalAccZseg_all; segmentData(accZ, winLen, overlap)];
            tGravityAccZ = filtfilt(bLow, aHigh, accZ);
            tGravityAccZseg = segmentData(tGravityAccZ, winLen, overlap);
            tBodyAccZ = filtfilt(bLow, aHigh, accZ);
            tBodyAccZseg = segmentData(tBodyAccZ, winLen, overlap);
            tBodyAccZseg_all = [tBodyAccZseg_all; tBodyAccZseg];
            tBodyAccJerkZ = gradient(tBodyAccZ);
            tBodyAccJerkZseg = segmentData(tBodyAccJerkZ, winLen, overlap);
            %Magnitudes
            tBodyAccMag = sqrt(sum([tBodyAccX; tBodyAccY; tBodyAccZ]'.^2, 2))';
            tBodyAccMagSeg = segmentData(tBodyAccMag, winLen, overlap);
            tGravityAccMag = sqrt(sum([tGravityAccX; tGravityAccY; tGravityAccZ]'.^2, 2))';
            tGravityAccMagSeg = segmentData(tGravityAccMag, winLen, overlap);
            tBodyAccJerkMag = sqrt(sum([tBodyAccJerkX; tBodyAccJerkY; tBodyAccJerkZ]'.^2, 2))';
            tBodyAccJerkMagSeg = segmentData(tBodyAccJerkMag, winLen, overlap);
            
            % extract basic time domain features
            features = extractFeautesTimeSig3Axes(tBodyAccXseg, tBodyAccYseg, tBodyAccZseg);
            features = [features, extractFeautesTimeSig3Axes(tGravityAccXseg, tGravityAccYseg, tGravityAccZseg)];
            features = [features, extractFeautesTimeSig3Axes(tBodyAccJerkXseg, tBodyAccJerkYseg, tBodyAccJerkZseg)];
            features = [features, extractFeautesTimeSig1Axes(tBodyAccMagSeg)];
            features = [features, extractFeautesTimeSig1Axes(tGravityAccMagSeg)];
            features = [features, extractFeautesTimeSig1Axes(tBodyAccJerkMagSeg)];
            
            % frequency domain
            fBodyAccXseg = []; fBodyAccYseg = []; fBodyAccZseg = [];
            fBodyAccJerkXseg = []; fBodyAccJerkYseg = []; fBodyAccJerkZseg = [];
            fBodyAccMagSeg = []; fBodyAccJerkMagSeg = [];
            
            nSegments = size(tBodyAccXseg, 1);
            for j = 1:nSegments
                fBodyAccXseg(j, :) = computFftForWindow(tBodyAccXseg(j, :));
                fBodyAccYseg(j,:) = computFftForWindow(tBodyAccYseg(j, :));
                fBodyAccZseg(j,:) = computFftForWindow(tBodyAccZseg(j, :));
                fBodyAccJerkXseg(j,:) = computFftForWindow(tBodyAccJerkXseg(j, :));
                fBodyAccJerkYseg(j,:) = computFftForWindow(tBodyAccJerkYseg(j, :));
                fBodyAccJerkZseg(j,:) = computFftForWindow(tBodyAccJerkZseg(j, :));
                
                fBodyAccMagSeg(j,:) = sqrt(sum([fBodyAccXseg(j, :); fBodyAccYseg(j, :); fBodyAccZseg(j, :)]'.^2, 2))';
                fBodyAccJerkMagSeg(j,:) = sqrt(sum([fBodyAccJerkXseg(j, :); fBodyAccJerkYseg(j, :); fBodyAccJerkZseg(j, :)]'.^2, 2))';
            end
            
            features = [features, extractFeautesFreqSig3Axes(fBodyAccXseg, fBodyAccYseg, fBodyAccZseg, freqRange)];
            features = [features, extractFeautesFreqSig3Axes(fBodyAccJerkXseg, fBodyAccJerkYseg, fBodyAccJerkZseg, freqRange)];
            features = [features, extractFeautesFreqSig1Axes(fBodyAccMagSeg, freqRange)];
            features = [features, extractFeautesFreqSig1Axes(fBodyAccJerkMagSeg, freqRange)];
            
            if strcmp(trainOrTest, 'train')
                % duplicate yLabels and session numbers
                onOffLabelSeg = onOffLabel.*ones(size(tBodyAccXseg, 1),1);
                dyskLabelSeg = dyskinesiaLabel.*ones(size(tBodyAccXseg, 1),1);
                tremorLabelSeg = tremorLabel.*ones(size(tBodyAccXseg, 1),1);
                %     subjectIDseg = subjID.*ones(size(tBodyAccXseg, 1),1);
                allOnOffLabels = [allOnOffLabels; onOffLabelSeg];
                allDyskLabels = [allDyskLabels ; dyskLabelSeg];
                allTremorLabels = [allTremorLabels ; tremorLabelSeg];
            end
            
            sessionIDs = [sessionIDs; repelem({sessionID}, size(tBodyAccXseg,1),1)];
            subjectIDs = [subjectIDs ; repelem({subjID}, size(tBodyAccXseg,1),1)];
            
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



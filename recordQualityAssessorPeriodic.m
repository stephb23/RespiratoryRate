function recordQualityAssessorPeriodic()
% Initialization stuff
close all;
clear;
clc;

fileID = fopen('D:\Documents\2019\PhD\Deep Learning\AragogII\allFilenamesRR.txt', 'r');
fileNamesCell = textscan(fileID, '%s', 8834, 'Delimiter', '\n', 'HeaderLines', 0);
fileNames = fileNamesCell{:};
fclose(fileID);

iterationFile = fopen('allIterationsPeriodic20s.txt', 'wt');

% DEBUGGING ONLY: Find usable segments in files
totalSegments = 0;
usableFiles = 0;
goodSegments = 0;

inputsFile = fopen('allInputsPeriodic20s.txt', 'wt');
outputsFile = fopen('allOutputsPeriodic20s.txt', 'wt');

% For all input files in the list
for f = 1:length(fileNames)
    isFileUsable = 0;
    % All filenames include the path; split by '/' and extract the actual
    % file name from the resultant array
    fileNameSplit = strsplit(fileNames{f}, '/');
    fileName = '';
    if strcmp(fileNameSplit(end), '')
        fileName = fileNameSplit(end-1);
    else 
        fileName = fileNameSplit(end);
    end
    
    % Add the correct filename ending to get the .info and .mat files
    % Print info about what file we're up to
    infoName = strcat('D:\Documents\2019\PhD\Deep Learning\AragogII\', fileName, 'm.info');
    matName = strcat('D:\Documents\2019\PhD\Deep Learning\AragogII\', fileName, 'm.mat');
    fprintf('\nUp to file %s, iteration = %d\n\n', matName{1}, f);
%     fprintf('Iteration = %d\n', f);
    fprintf(iterationFile, '%d\n', f);
    
    % Open the info file
    if(exist(infoName{1}, 'file') && exist(matName{1}, 'file'))
        try
            fileID = fopen(infoName{1}, 'rt');
        catch
            disp("Could not load " + infoName{1})
            continue;
        end
        
        % Skip the file preamble
        for i = 1:2
            fgetl(fileID);
        end
        
        % Extract the duration
        [durationInfo] = sscanf(fgetl(fileID), 'Duration:  %f:%f:%f');
        
        if length(durationInfo) == 2
            durationInfo = [0, durationInfo(1), durationInfo(2)];
        elseif length(durationInfo) > 3
            % Time exceeds required hours, replace first no. with
            % unreasonable value so that it will be skipped
            durationInfo(1) = 30;
        end
        
        if exist(matName{1}, 'file') && durationInfo(1) <= 6
            try 
                matFile = load(matName{1});
            catch
                disp("Could not load " + matName{1})
                continue;
            end
        elseif durationInfo(1) >= 6
            disp("File too large, skipping");
            fclose(fileID);
            continue;
        else
            disp("Mat file doesn't exist");
            fclose(fileID);
            continue;
        end
                

        % Extract the sampling interval
        [frequencyInfo] = sscanf(fgetl(fileID), 'Sampling frequency: %f Hz  Sampling interval: %f sec');
        Fs = frequencyInfo(1);
        interval = frequencyInfo(2);
        period = 20;

        fgetl(fileID); % this line of the file contains no relevant info
        valSize = size(matFile.val, 1);
        
        % Get all signals from the file
        for i = 1:valSize
            [row(i), signal(i), gain(i), base(i), units(i)]=strread(fgetl(fileID),'%d%s%f%f%s','delimiter','\t');
        end

        row = row(1:valSize);
        signal = signal(1:valSize);
        gain = gain(1:valSize);
        base = base(1:valSize);
        units = units(1:valSize);

        % Set all NaN values to actually being NaN
        %val(val==-32768) = NaN;

        % Close file, no longer needed
        fclose(fileID);

        % If none of the signals are missing
        ecg = matFile.val(3, :);
        ecg = (ecg - base(3))/gain(3);
        [p,~,mu] = polyfit((1:numel(ecg)),ecg,6);
        f_y = polyval(p,(1:numel(ecg)),[],mu);
        ecgFiltered = ecg - f_y;
        ecgFiltered = sgolayfilt(ecgFiltered, 7, 21);
        
        ppg = matFile.val(1, :);
        ppg = (ppg - base(1))/gain(1);
        
        % Try to find baseline wander signal
        Fn = Fs/2; %nyquist
        Wp = 0.5/Fn;
        Ws = 0.8/Fn;
        Rp = 5;
        Rs = 50;
        [n, Ws] = cheb2ord(Wp, Ws, Rp, Rs);
        [b, a] = cheby2(n, Rs, Ws);
        [sos,g] = tf2sos(b,a);
        bwEcg = filtfilt(sos, g, ecg);
        bwPpg = filtfilt(sos, g, ppg);
        
        ppg = ppg - bwPpg;
        
        resp = matFile.val(2, :);
        resp = (resp - base(2))/gain(2);
        
        matFileLength = length(matFile.val);
        
        % For each segment of the signal (segment length is set manually)
        for i = 1:period:(matFileLength*interval - 2*period)
            % Get start & stop time as an index, then get the segment
            startTime = i/interval;
            stopTime = (i + period)/interval;
            ecgSegment = ecgFiltered(startTime:stopTime);
            ppgSegment = ppg(startTime:stopTime);
            respSegment = resp(startTime:stopTime);
            bwEcgSegment = bwEcg(startTime:stopTime);
            bwPpgSegment = bwPpg(startTime:stopTime);
            totalSegments = totalSegments + 1;

            [ecgPeaks, ecgLocations] = findpeaks(ecgSegment, startTime:stopTime, 'MinPeakProminence', 0.4);
            [ppgPeaks, ppgLocations] = findpeaks(ppgSegment, startTime:stopTime, 'MinPeakProminence', 0.1);
            [respPeaks, respLocations] = findpeaks(respSegment, startTime:stopTime, 'MinPeakProminence', 0.25, 'MinPeakDistance', 125);
            [bwEcgPeaks, bwEcgPeakLocations] = findpeaks(bwEcgSegment, startTime:stopTime, 'MinPeakDistance', 125);
            [bwPpgPeaks, bwPpgPeakLocations] = findpeaks(bwPpgSegment, startTime:stopTime, 'MinPeakDistance', 125);
            [bwEcgTroughs, bwEcgTroughLocations] = findpeaks(-bwEcgSegment, startTime:stopTime, 'MinPeakDistance', 125);
            [bwPpgTroughs, bwPpgTroughLocations] = findpeaks(-bwPpgSegment, startTime:stopTime, 'MinPeakDistance', 125);
            
            % Amplitude modulation
            amEcgPeaks = [];
            amEcgPeakLocations = [];
            amEcgTroughs = [];
            amEcgTroughLocations = [];
            for k = 2:length(ecgPeaks)-1
                if ecgPeaks(k) > ecgPeaks(k-1) && ecgPeaks(k) > ecgPeaks(k+1)
                    amEcgPeaks(end+1) = ecgPeaks(k);
                    amEcgPeakLocations(end+1) = ecgLocations(k);
                elseif ecgPeaks(k) < ecgPeaks(k-1) && ecgPeaks(k) < ecgPeaks(k+1)
                    amEcgTroughs(end+1) = ecgPeaks(k);
                    amEcgTroughLocations(end+1) = ecgLocations(k);
                end
            end
            
            amPpgPeaks = [];
            amPpgPeakLocations = [];
            amPpgTroughs = [];
            amPpgTroughLocations = [];
            for k = 2:length(ppgPeaks)-1
                if ppgPeaks(k) > ppgPeaks(k-1) && ppgPeaks(k) > ppgPeaks(k+1)
                    amPpgPeaks(end+1) = ppgPeaks(k);
                    amPpgPeakLocations(end+1) = ppgLocations(k);
                elseif ppgPeaks(k) < ppgPeaks(k-1) && ppgPeaks(k) < ppgPeaks(k+1)
                    amPpgTroughs(end+1) = ppgPeaks(k);
                    amPpgTroughLocations(end+1) = ppgLocations(k);
                end
            end
            
            %RSA modulation/Frequency modulation
            ecgBtbs = ecgLocations(2:end) - ecgLocations(1:end-1);
            fmEcgPeaks = [];
            fmEcgPeakLocations = [];
            fmEcgTroughs = [];
            fmEcgTroughLocations = [];
            for k = 2:length(ecgBtbs)-1
                if ecgBtbs(k) > ecgBtbs(k-1) && ecgBtbs(k) >= ecgBtbs(k+1)
                    fmEcgPeaks(end+1) = ecgBtbs(k);
                    fmEcgPeakLocations(end+1) = k;
                elseif ecgBtbs(k) < ecgBtbs(k-1) && ecgBtbs(k) <= ecgBtbs(k+1)
                    fmEcgTroughs(end+1) = ecgBtbs(k);
                    fmEcgTroughLocations(end+1) = k;
                end
            end
            
            ppgBtbs = ppgLocations(2:end) - ppgLocations(1:end-1);
            fmPpgPeaks = [];
            fmPpgPeakLocations = [];
            fmPpgTroughs = [];
            fmPpgTroughLocations = [];
            for k = 2:length(ppgBtbs)-1
                if ppgBtbs(k) > ppgBtbs(k-1) && ppgBtbs(k) >= ppgBtbs(k+1)
                    fmPpgPeaks(end+1) = ppgBtbs(k);
                    fmPpgPeakLocations(end+1) = k;
                elseif ppgBtbs(k) < ppgBtbs(k-1) && ppgBtbs(k) <= ppgBtbs(k+1)
                    fmPpgTroughs(end+1) = ppgBtbs(k);
                    fmPpgTroughLocations(end+1) = k;
                end
            end
            
            heartRateECG = length(ecgPeaks)*(60/period);
            heartRatePPG = length(ppgPeaks)*(60/period);

            respRate = 60./mean((respLocations(2:end) - respLocations(1:end-1)).*interval);

            ecgBeatToBeats = diff(ecgLocations);
            %meanEcgBTB = mean(ecgBeatToBeats);
            %medianEcgBTB = median(ecgBeatToBeats);

            ppgBeatToBeats = diff(ppgLocations);
            %meanPpgBTB = mean(ppgBeatToBeats);
            %medianPpgBTB = median(ppgBeatToBeats);
            
            respBreathToBreaths = diff(respLocations);

            SBPs = findpeaks(respSegment);
            DBPs = -findpeaks(-respSegment); %invert so troughs are peaks, find the trough-peaks, invert again
            SBP = mean(SBPs);
            DBP = mean(DBPs);
            pulsePressure = SBP - DBP;

            segment = 1;
            if (abs(heartRatePPG - heartRateECG) > 10)
                segment = 0;
                %disp('Bad at first check');
            elseif(heartRatePPG < 40 || heartRatePPG > 180)
                segment = 0;
                %disp('Bad at second check');
            elseif(max(ppgPeaks)/min(ppgPeaks) > 1.5)
                segment = 0;
            elseif(max(ecgPeaks)/min(ecgPeaks) > 1.5)
                segment = 0;
            elseif(max(ecgBeatToBeats)/min(ecgBeatToBeats) > 1.5)
                segment = 0;
                %disp('Bad at fifth check');
            elseif(max(ppgBeatToBeats)/min(ppgBeatToBeats) > 1.5)
                segment = 0;
                %disp('Bad at sixth check');
            elseif(respRate < 8 || respRate > 35 || isnan(respRate))
                segment = 0;
            elseif(max(respPeaks)/min(respPeaks) > 1.5)
                segment = 0;
            elseif(max(respBreathToBreaths)/min(respBreathToBreaths) > 1.5)
                segment = 0;
            end

            if (segment == 1)
                isFileUsable = 1;
%                 figure(1);
%                 subplot(3, 1, 1);
%                 plot(startTime:stopTime, ecgSegment);
%                 hold on;
%                 scatter(ecgLocations, ecgPeaks);
%                 
%                 subplot(3, 1, 2);
%                 plot(startTime:stopTime, ppgSegment);
%                 hold on;
%                 scatter(ppgLocations, ppgPeaks);
% 
%                 subplot(3, 1, 3);
%                 plot(startTime:stopTime, respSegment);
%                 hold on;
%                 scatter(respLocations, respPeaks);
% 
%                 figure(2)
%                 subplot(4, 2, [1,2]);
%                 plot(startTime:stopTime, respSegment);
%                 hold on;
%                 scatter(respLocations, respPeaks);
%                 
%                 subplot(4, 2, 3);
%                 plot(startTime:stopTime, bwEcgSegment)
%                 hold on;
%                 scatter(bwEcgPeakLocations, bwEcgPeaks);
%                 
%                 subplot(4, 2, 4);
%                 plot(startTime:stopTime, bwPpgSegment);
%                 hold on;
%                 scatter(bwPpgPeakLocations, bwPpgPeaks);
%                 
%                 subplot(4, 2, 5);
%                 plot(ecgLocations, ecgPeaks);
%                 hold on;
%                 scatter(amEcgPeakLocations, amEcgPeaks);
%                 
%                 subplot(4, 2, 6);
%                 plot(ppgLocations, ppgPeaks);
%                 hold on;
%                 scatter(amPpgPeakLocations, amPpgPeaks);
%                 
%                 subplot(4, 2, 7);
%                 plot(1:numel(ecgBtbs), ecgBtbs);
%                 hold on;
%                 scatter(fmEcgPeakLocations, fmEcgPeaks);
%                 
%                 subplot(4, 2, 8);
%                 plot(1:numel(ppgBtbs), ppgBtbs);
%                 hold on;
%                 scatter(fmPpgPeakLocations, fmPpgPeaks);
%                 
                [bwEcgQuality, bwEcgRR] = calculateSignalQuality(bwEcgPeakLocations, bwEcgPeaks, bwEcgTroughLocations, bwEcgTroughs, interval);
                [bwPpgQuality, bwPpgRR] = calculateSignalQuality(bwPpgPeakLocations, bwPpgPeaks, bwPpgTroughLocations, bwPpgTroughs, interval);
                [amEcgQuality, amEcgRR] = calculateSignalQuality(amEcgPeakLocations, amEcgPeaks, amEcgTroughLocations, amEcgTroughs, interval);
                [amPpgQuality, amPpgRR] = calculateSignalQuality(amPpgPeakLocations, amPpgPeaks, amPpgTroughLocations, amPpgTroughs, interval);
                [fmEcgQuality, fmEcgRR] = calculateSignalQuality(fmEcgPeakLocations, fmEcgPeaks, fmEcgTroughLocations, fmEcgTroughs, 1);
                [fmPpgQuality, fmPpgRR] = calculateSignalQuality(fmPpgPeakLocations, fmPpgPeaks, fmPpgTroughLocations, fmPpgTroughs, 1);
%                 
                featureVector = [bwEcgQuality, bwEcgRR, bwPpgQuality, bwPpgRR, amEcgQuality, amEcgRR, amPpgQuality, amPpgRR, fmEcgQuality, ...
                    fmEcgRR, fmPpgQuality, fmPpgRR];
                
                if ~any(isnan(featureVector))
                    featureString = mat2str(featureVector, 4);
                    featureString = strip(featureString, '[');
                    featureString = strip(featureString, ']');
                    featureString = replace(featureString, ' ', ',');
                    fprintf(inputsFile, '%s\n', featureString);

                    fprintf(outputsFile, '%.2f\n', respRate);

                    goodSegments = goodSegments + 1;
                end
%                 
%                 pause;
%                 close all;
%                     
%                     if (mod(goodSegments, 25000) == 0)
%                         fclose(inputFile);
%                         fclose(outputFile);
%                         inputFileName = strcat("allInputsV5-", num2str(goodSegments/25000), ".txt");
%                         outputFileName = strcat("allOutputsV5-", num2str(goodSegments/25000), ".txt");
%                         inputFile = fopen(inputFileName, 'wt');
%                         outputFile = fopen(outputFileName, 'wt');
%                     end
%                     goodSegments = goodSegments + 1;
%                     
%                     % Convert the ECG amplitudes to a string
%                     ecgString = mat2str(ecgSegment);
%                     ecgString = strip(ecgString, '[');
%                     ecgString = strip(ecgString, ']');
%                     ecgString = replace(ecgString, ' ', ',');
%                     fprintf(inputFile, '%s\n', ecgString);
% 
%                     % Convert the PPG amplitudes to a string
%                     ppgString = mat2str(ppgSegment);
%                     ppgString = strip(ppgString, '[');
%                     ppgString = strip(ppgString, ']');
%                     ppgString = replace(ppgString, ' ', ',');
%                     fprintf(inputFile, '%s\n\n', ppgString);
%                    
%                     fprintf(outputFile, '%.2f, %.2f\n\n', SBP, DBP);
            end
        end
        clear matFile
        fprintf("So far %d usable segments out of a possible %d", goodSegments, totalSegments);
    
    end
    usableFiles = usableFiles + isFileUsable;
end

    function [signalQuality, derivedRR] = calculateSignalQuality(peakLocations, peaks, troughLocations, troughs, interval)
        peakBtbs = peakLocations(2:end) - peakLocations(1:end-1);
        troughBtbs = troughLocations(2:end) - troughLocations(1:end-1);

        % Differential coefficient of variation: (1 - coefficient of
        % variation) divided by 4 
        peakBtbVar = 1 - std(peakBtbs)/mean(peakBtbs);
        troughBtbVar = 1 - std(troughBtbs)/mean(troughBtbs);
        peakVar = 1 - std(peaks)/mean(peaks);
        troughVar = 1 - std(troughs)/mean(troughs);
        derivedRR = 60./mean((peakLocations(2:end) - peakLocations(1:end-1)).*interval);
        
        signalQuality = max(mean([peakBtbVar, troughBtbVar, peakVar, troughVar]), 0);
        
        if derivedRR < 0
            signalQuality = 0;
        end
            
%         if derivedRR < 8 || derivedRR > 35
%             signalQuality = 0;
%         end
        
    end


% x = (1:size(signalSegment, 2)) * interval;
% plot(x', signalSegment(1:2, :)');
% 
% figure(2)
% plot(x', signalSegment(3,:)');
% 
% figure(3)
% x2 = (1:size(val,2)) * interval;
% plot(x2', val(1:2, :)');
% 
% figure(4)
% plot(x2', val(3, :)');

% Labels not currently set up right, come back to it
% for i = 1:length(signalsOfInterest-1)
%     strcat(signal{signalsOfInterest(i)}, ' (', units{i}, ')');
%     labels{i} = strcat(signal{signalsOfInterest(i)}, ' (', units{i}, ')'); 
% % end
% 
% legend(labels);
% xlabel('Time (sec)');

% grid on
            
end

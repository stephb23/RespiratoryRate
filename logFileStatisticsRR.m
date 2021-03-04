function [uniqueExpectedValues, correctPredictions, occurancesOfExpectedValue, meanAbsErrorByExpectedValue, uniqueErrors, occurancesOfUniqueError] = logFileStatisticsRR(logFileName)
fileID = fopen(logFileName, 'r');
fileContent = fscanf(fileID, "y_pred = [%f], y_true = [%f]\n", [2, Inf]);

acc = 0.25;

% ROUND THIS ONLY FOR GRAPHS
fileContent = round(fileContent'/acc)*acc;
sortedFileContent = sortrows(fileContent, 2);
uniquePredictionValues = unique(sortedFileContent(:, 1));
uniqueExpectedValues = unique(sortedFileContent(:, 2));

errors = round((fileContent(:, 1) - fileContent(:, 2))/acc)*acc;
absErrors = abs(errors);
errorPercentage = (absErrors ./ fileContent(:, 2)) * 100;
accuracy = (sum(absErrors == 0) / length(absErrors))*100;
rmse = sqrt(mean(absErrors.^2));
mae = mean(absErrors);
me = mean(errors);
sd = std(errors);
uniqueErrors = unique(sort(errors));

errorsBelow5 = sum(absErrors(:) < 5)/length(absErrors) * 100;
errorsBelow10 = sum(absErrors(:) < 10)/length(absErrors) * 100;
errorsBelow15 = sum(absErrors(:) < 15)/length(absErrors) * 100;
errorsBelow20 = sum(absErrors(:) < 20)/length(absErrors) * 100;
errorsBelow25 = sum(absErrors(:) < 25)/length(absErrors) * 100;
errorsBelow30 = sum(absErrors(:) < 30)/length(absErrors) * 100;

minErrorByExpectedValue = zeros(1, length(uniqueExpectedValues));
medianErrorByExpectedValue = zeros(1, length(uniqueExpectedValues));
maxErrorByExpectedValue = zeros(1, length(uniqueExpectedValues));
meanErrorByExpectedValue = zeros(1, length(uniqueExpectedValues));
meanAbsErrorByExpectedValue = zeros(1, length(uniqueExpectedValues));
accuracyByExpectedValue = zeros(1, length(uniqueExpectedValues));
occurancesOfExpectedValue = zeros(1, length(uniqueExpectedValues));
occurancesOfUniqueError = zeros(1, length(uniqueErrors));
correctPredictions = zeros(1, length(uniqueExpectedValues));

for i = 1:length(uniqueErrors)
    occurancesOfUniqueError(i) = sum(errors == uniqueErrors(i));
end

for i = 1:length(uniqueExpectedValues)
    % Find all records with the given expected value
    % ROUND FOR GRAPHS
    relevantRecords = (round(sortedFileContent(:, 2)/acc)*acc == uniqueExpectedValues(i));
    
    % Find the start and stop index for the relevant records
    relevantIndices = find(relevantRecords);
    occurancesOfExpectedValue(i) = length(relevantIndices);
    if ~isempty(relevantIndices)
    startIndex = relevantIndices(1);
    stopIndex = relevantIndices(end);
    
    % Find the mean error per expected value
    relevantErrors = errors(startIndex:stopIndex);
    meanErrorByExpectedValue(i) = mean(relevantErrors);
    minErrorByExpectedValue(i) = min(relevantErrors);
    maxErrorByExpectedValue(i) = max(relevantErrors);
    medianErrorByExpectedValue(i) = median(relevantErrors);
    
    % Find how many times predictions were correct for this value
    correctPredictions(i) = sum(abs(errors(startIndex:stopIndex)) ==0);
    
    % Find the mean abs error per expected value
    relevantAbsErrors = absErrors(startIndex:stopIndex);
    meanAbsErrorByExpectedValue(i) = mean(relevantAbsErrors);
    
    % Find the accuracy per expected value
    accuracyByExpectedValue(i) = sum(relevantAbsErrors == 0)/length(relevantAbsErrors);
    end
end

%bar(uniqueExpectedValues, [medianErrorByExpectedValue', meanErrorByExpectedValue', meanAbsErrorByExpectedValue'])

minErrorByPrediction = zeros(1, length(uniquePredictionValues));
maxErrorByPrediction = zeros(1, length(uniquePredictionValues));
meanErrorByPrediction = zeros(1, length(uniquePredictionValues));
meanAbsErrorByPrediction = zeros(1, length(uniquePredictionValues));
accuracyByPrediction = zeros(1, length(uniquePredictionValues));
occurancesOfPredictions = zeros(1, length(uniquePredictionValues));
sortedFileContent = sortrows(fileContent, 1);

for i = 1:length(uniquePredictionValues)
    % Find all records with the given expected value
    % ROUND FOR GRAPHS
    relevantRecords = (round(sortedFileContent(:, 1)) == uniquePredictionValues(i));
    
    % Find the start and stop index for the relevant records
    relevantIndices = find(relevantRecords);
    occurancesOfPredictions(i) = length(relevantIndices);
    if ~isempty(relevantIndices)
        startIndex = relevantIndices(1);
        stopIndex = relevantIndices(end);
        
        % Find the mean, min, max error per expected value
        relevantErrors = absErrors(startIndex:stopIndex);
        minErrorByPrediction(i) = min(relevantErrors);
        maxErrorByPrediction(i) = max(relevantErrors);
        meanErrorByPrediction(i) = mean(relevantErrors);
        
        % Find the mean abs error per expected value
        relevantAbsErrors = absErrors(startIndex:stopIndex);
        meanAbsErrorByPrediction(i) = mean(relevantAbsErrors);
        
        % Find the accuracy per expected value
        accuracyByPrediction(i) = sum(relevantAbsErrors < 0)/length(relevantAbsErrors);
    end
end

end
function regressionPlots
close all;
sbpFileID = fopen('albusRRPeriodicBiLSTM60s.txt', 'r');
fileContent = fscanf(sbpFileID, "y_pred = [%f], y_true = [%f]\n", [2, Inf]);
fileContent = fileContent';
predictedValues = fileContent(:, 1);
expectedValues = fileContent(:, 2);
colours = ['b', 'g', 'y'];

expectedValuesJittered = expectedValues + (randn(1, length(expectedValues))/10)';
figure(1);
hold on;

counter = 0;
for i = 1:length(expectedValues)
    if (expectedValues(i)) == 62 & ceil(predictedValues(i)) == 62
        counter = counter + 1;
    end
end
counter 

[p, errorEst] = polyfit(expectedValues, predictedValues, 1);
predictedValFit = polyval(p, (5:35));
correlation = corrcoef(expectedValues, predictedValues);
r = correlation(2)
scatter(expectedValues, predictedValues, 16, 'Filled')
min(expectedValues)
max(expectedValues)
plot(linspace(4, 36), linspace(4, 36), 'k--', 'LineWidth', 2)
% plot(linspace(min(expectedValues), max(expectedValues)), linspace(min(expectedValues), max(expectedValues)), 'k--', 'LineWidth', 2)
plot(5:35, predictedValFit, 'k-', 'LineWidth', 2);
title('Regression Plot (60-second PPG & ECG segments)', 'FontSize', 35);
xlabel('True Values (BrPM)', 'FontSize', 25, 'FontWeight', 'bold');
ylabel('Predicted Values (BrPM)', 'FontSize', 25, 'FontWeight', 'bold');
xlim([5 35])
ylim([5 35])
xtick = get(gca,'XTickLabel');
set(gca,'XTickLabel',xtick,'FontName','Times','fontsize',28)    
grid on;
grid minor;
end
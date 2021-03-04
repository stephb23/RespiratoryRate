function generateGraphsRR()
    close all;
    [uniqueExpectedValues, correctPredictions, occurancesOfExpectedValue, rrMAE, uniqueErrors, occurancesOfUniqueError] = logFileStatisticsRR('albusRRPeriodicV2BiLSTM.txt');
    
    sum(occurancesOfExpectedValue)
    
    figure();
    bar(uniqueExpectedValues, rrMAE');
    xlabel('True RR (BrPM)', 'FontSize', 30, 'FontWeight', 'bold');
    ylabel('MAE (BrPM)', 'FontSize', 30, 'FontWeight', 'bold');
    xlim([87, 133])
    ylim([0, 1.6])
    xtick = get(gca,'XTickLabel');
    set(gca,'XTickLabel',xtick,'FontName','Times','fontsize',28)    
    grid on;
    grid minor;
    
    
    indices = uniqueErrors > 3;
    negIndices = uniqueErrors < -3;
    sum(occurancesOfUniqueError(indices)) + sum(occurancesOfUniqueError(negIndices))
    figure();
    bar(uniqueErrors, occurancesOfUniqueError)
    xlabel('Error (BrPM)', 'FontSize', 30, 'FontWeight', 'bold');
    ylabel('Frequency', 'FontSize', 30, 'FontWeight', 'bold');
    xlim([-20, 20])
    xtick = get(gca,'XTickLabel');
    set(gca,'XTickLabel',xtick,'FontName','Times','fontsize',28)
    title('Error Histogram (20-second PPG & ECG segments)')
    grid on;
    grid minor;
    
    figure();
    bar(uniqueExpectedValues, occurancesOfExpectedValue, 'DisplayName', 'Total Records')
    hold on;
    bar(uniqueExpectedValues, correctPredictions, 'DisplayName', 'RR Correctly Predicted')
    legend;
    title('Accurate Predictions by True RR', 'FontSize', 40);
    xlabel('True RR (BrPM)', 'FontSize', 30, 'FontWeight', 'bold');
    ylabel('Frequency', 'FontSize', 30, 'FontWeight', 'bold');
    xtick = (get(gca, 'XTickLabel'));
    set(gca,'XTickLabel',xtick,'FontName','Times','fontsize',28)
    grid on;
    grid minor;

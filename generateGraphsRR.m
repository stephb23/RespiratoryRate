function generateGraphsRR()
    close all;
    [uniqueExpectedValues, correctPredictions, occurancesOfExpectedValue, rrMAE, uniqueErrors, occurancesOfUniqueError] = logFileStatisticsRR('albusRRPeriodicV2BiLSTM.txt');
    
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

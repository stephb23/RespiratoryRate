# Respiratory Rate
Files for the paper "Determining respiratory rate from photoplethysmogram and electrocardiogram signals using respiratory quality indices and neural networks"

## Model code
* machineLearningRR.py - contains the deep learning code, which has several package dependencies including Keras and Tensorflow-GPU.

## Analysis code
* logFileStatisticsRR.m - contains code for calculating key statistics, is required to run the "generateGraphsRR.m" code

## Graphing code
* generateGraphsRR.m - generates error histogram for selected file
* blandAltman.m - generates Bland Altman plot for selected file
* regressionPlots.m - generates regression plot for selected file

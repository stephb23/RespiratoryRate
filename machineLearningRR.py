import numpy as np
import keras
from keras.models import Sequential
from keras.layers import Dense, LSTM, Bidirectional
from keras.models import load_model
from keras.callbacks import EarlyStopping, ModelCheckpoint
from sklearn.metrics import r2_score, accuracy_score, mean_squared_error, mean_absolute_error
from sklearn.model_selection import train_test_split
from keras.callbacks import History

from keras.wrappers.scikit_learn import KerasRegressor
history = History()

from tensorflow.python.client import device_lib

minRR = 8
maxRR = 35
lastLoss = 100000

numHiddenUnits = 128
numFeatures = 6
batchSize = 1024
numEpochs = 5000

seed = 5

# BiLSTM Model structure
model = Sequential()
model.add(Bidirectional(LSTM(numHiddenUnits, return_sequences=True), input_shape=(numFeatures,1)))
model.add(Bidirectional(LSTM(numHiddenUnits, return_sequences=True)))
model.add(Bidirectional(LSTM(numHiddenUnits, return_sequences=False)))
model.add(Dense(1, activation='sigmoid'))
model.compile(loss='mae', optimizer='adam', metrics=['mae', 'accuracy'])


modelName = "albusRRPeriodicBiLSTM60s-RROnly.h5"
logfileName = "albusRRPeriodicBiLSTM60s-RROnly.txt"
weightsFileName = "albusRRPeriodicBiLSTM60s-RROnly.hdf5"
# model = load_model(modelName)


logFile = open(logfileName, "w")
# Firstly, will need to import the database when it's made
# x_train, y_train, x_test, y_test = 0

# Set up error counters
sumError = 0
maxError = 0
errorsBelow1 = 0
errors1to3 = 0
errors3to5 = 0
errors5to10 = 0
errorsAbove10 = 0

# Open up 4 files at a time to try and save on training/testing time with manual epochs
# Open up our input (PPG & ECG) file, as well as our output (labels) file
inputFileName = 'D:\Documents/2019/PhD/Albus - Resp Rate 2/allInputsPeriodic60s.txt'
outputFileName = 'D:\Documents/2019/PhD/Albus - Resp Rate 2/allOutputsPeriodic60s.txt'
inputFile = open(inputFileName)
outputFile = open(outputFileName)

# Read all lines from the files
inputFileLines = inputFile.readlines()
outputFileLines = outputFile.readlines()

numRecords = len(inputFileLines)
# Create empty arrays for X & Y to populate with data
X = np.zeros((numRecords, numFeatures))
Y = np.zeros((numRecords, 1))
countX = 0
countY = 0

for x in range(0, len(inputFileLines)):
    featureLine = [float(s) for s in inputFileLines[x].split(',')]
    X[countX, :] = featureLine[1::2]
    countX += 1

for y in range(0, len(outputFileLines)):
    try:
        Y[countY, :] = outputFileLines[y].strip('\n')
    except ValueError:
        Y[countY, :] = -1

    countY += 1

# Normalize Y's
Y = (Y - minRR)/(maxRR - minRR)

X_train, X_test, Y_train, y_test = train_test_split(X, Y, test_size=0.1, random_state=7, shuffle=True)

X_train = X_train.reshape(len(X_train), numFeatures, 1)
X_test = X_test.reshape(len(X_test), numFeatures, 1)

modelCheckpoint = ModelCheckpoint(filepath=weightsFileName, save_best_only=True, save_weights_only=False, monitor='val_loss')

model.fit(X_train, Y_train, validation_split=0.1, batch_size=batchSize, epochs=numEpochs, verbose=2,
                    callbacks=[modelCheckpoint], shuffle=True)

print(model.summary())

model.save(modelName)
model.load_weights(weightsFileName)
performance_metrics = model.evaluate(X_test, y_test, batch_size=batchSize, verbose=1)
print('metrics' + str(performance_metrics))


pred = model.predict(X_test, batch_size=batchSize)
y_true = np.zeros((len(pred), 1))
y_pred = np.zeros((len(pred), 1))

for j in range(0, len(y_pred)):
    y_pred[j] = pred[j] * (maxRR - minRR) + minRR
    y_true[j] = y_test[j] * (maxRR - minRR) + minRR
    thisError = abs((y_pred[j] - y_true[j]))
    sumError += thisError

    if thisError > maxError:
        maxError = thisError

    if thisError <= 1:
        errorsBelow1 = errorsBelow1 + 1
    elif thisError <= 3:
        errors1to3 = errors1to3 + 1
    elif thisError <= 5:
        errors3to5 = errors3to5 + 1
    elif thisError <= 10:
        errors5to10 = errors5to10 + 1
    else:
        errorsAbove10 = errorsAbove10 + 1

    logFile.write("y_pred = " + str(y_pred[j]) + ", y_true = " + str(y_true[j]) + "\n")

#print("After dataset " + str(i) + ":")
print("Average error = " + str(sumError / (len(y_pred))))
print("Max error = " + str(maxError))
print("Number of errors below 1 breath: " + str(errorsBelow1))
print("Number of errors between 1-3 breaths: " + str(errors1to3))
print("Number of errors between 3-5 breaths: " + str(errors3to5))
print("Number of errors between 5-10 breaths = " + str(errors5to10))
print("Number of errors over 10 breaths = " + str(errorsAbove10))

#accuracy = accuracy_score(y_true, y_pred)
rmse = np.sqrt(mean_squared_error(y_true, y_pred))
mae = mean_absolute_error(y_true, y_pred)

#print("Accuracy = " + str(accuracy))
print("Root Mean Square Error = " + str(rmse))
print("Mean Average Error = " + str(mae))

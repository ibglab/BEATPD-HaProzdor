import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.utils import resample
import matplotlib.pyplot as plt
import numpy as np
import itertools
from sklearn import metrics
from datetime import datetime
from IPython.core.debugger import set_trace
import os
import getpass
from sklearn.decomposition import PCA
from keras.layers import Input, Dense
from keras.models import Model
from sklearn.preprocessing import minmax_scale

def splitData(data, labelName='onOff', testSize=0.3, seed=34):
    # divide by whole sessions
    dataToSplit = data.drop_duplicates('sessionID', keep='first')
    compressedTrain, compressedTest = train_test_split(dataToSplit, test_size=testSize, random_state=seed)
    train = data[data['sessionID'].isin(compressedTrain['sessionID'])]
    test = data[data['sessionID'].isin(compressedTest['sessionID'])]

    return train, test


def cutSession(data):
    sessionIDs = data['sessionID'].unique()
    originalData = data
    data = pd.DataFrame([])
    for session in sessionIDs:
        wholeSession = originalData[originalData['sessionID']==session]
        halfSession = wholeSession.head(round(wholeSession.shape[0]/2))
        data = data.append(halfSession, ignore_index=True)
    return data



def calcPredictionPerSession(all_y_pred, test, labelName):
    sessionIDs = test['sessionID'].unique()
    y_pred = np.zeros(len(sessionIDs))
    y_true = np.zeros(len(sessionIDs))
    y_pred_mean = np.zeros(len(sessionIDs))
    for i, sessionID in enumerate(sessionIDs):
        sessionIdx = test.index[test['sessionID']==sessionID].tolist()
        y_true[i] = test.iloc[sessionIdx[0]][labelName]
        y_pred[i] = np.bincount(all_y_pred[sessionIdx].astype(np.intp)).argmax()
        y_pred_mean[i] = all_y_pred[sessionIdx].astype(np.intp).mean()
    return y_true, y_pred, y_pred_mean


def analyzeModelPerformance(modelResults, y_test, y_pred, class_labels, y_pred_mean=[]):

    # MSE is the challenge's assesment
    mse = metrics.mean_squared_error(y_test, y_pred)
    modelResults['mse'] = mse
    
    mseMean = metrics.mean_squared_error(y_test, y_pred_mean)
    modelResults['mseMean'] = mseMean

    return modelResults

def runModel(model, X_train, y_train, X_test, y_test, test, class_labels, labelName = ''):

    modelResults = dict()

    # time at which model starts training
    train_start_time = datetime.now()
    model.fit(X_train, y_train)
    train_end_time = datetime.now()

    # predict test data
    test_start_time = datetime.now()
    y_pred = model.predict(X_test)
    test_end_time = datetime.now()


    wholeSession_y_true, wholeSession_y_pred, wholeSession_y_pred_mean = calcPredictionPerSession(y_pred, test, labelName)
    modelResults = analyzeModelPerformance(modelResults, wholeSession_y_true, wholeSession_y_pred, class_labels, y_pred_mean=wholeSession_y_pred_mean)
    
    modelResults['y_pred'] = wholeSession_y_pred_mean
    modelResults['y_true'] = wholeSession_y_true
    # save the trained  model
    modelResults['model'] = model
    
    return modelResults

#get train data for some label, and retuen it naive score(mean of labels)
def getNaiveScore(dataset, subjectID, labelName):
    if getpass.getuser() == 'Ayala':
        labels_folder = os.path.join('data', dataset, 'data_labels')
    else: 
        # Izhar and Yuval
        labels_folder = 'data'
        
    cis_file = os.path.join(labels_folder,dataset.upper()+'-PD_Training_Data_IDs_Labels.csv')
    cis_labels = pd.read_csv(cis_file)
    subject_indexes = cis_labels['subject_id'] == subjectID  
    y_labels = cis_labels.loc[subject_indexes, labelName]        
    naiveScore = y_labels.mean()
    return naiveScore


# run function on dataframe before adding sessionID, and yLabels!!
def addPCAfeatures(data, n_components):
    
    pca = PCA(n_components)
    principalComponents = pca.fit_transform(data)
    pcaColumns = []
    for i in range(1, n_components+1):
        pcaColumns.append('PCA_'+str(i))
    dfPC=pd.DataFrame(principalComponents, columns = pcaColumns, index = data.index)    
    data = pd.concat([data, dfPC], axis=1, sort=False)
    return data



def addAutoencoderFeatures(data, encoding_dim=20, lossFunc='binary_crossentropy',nEpochs=50, batchSize=100):
    
    df = data.filter(regex='^((?!PCA).)*$')
    nFaetures = df.shape[1]
    auColumns = []
    for i in range(1, encoding_dim+1):
        auColumns.append('AE_'+str(i))
    input_df = Input(shape=(nFaetures,))
    # DEFINE THE ENCODER LAYER
    encoded = Dense(encoding_dim, activation='relu')(input_df)
    # DEFINE THE DECODER LAYER
    decoded = Dense(nFaetures, activation='sigmoid')(encoded)
    # SCALE EACH FEATURE INTO [0, 1] RANGE
    df= minmax_scale(df, axis = 0)
    X_train, X_test = train_test_split(df, train_size = 0.8)

    # COMBINE ENCODER AND DECODER INTO AN AUTOENCODER MODEL
    autoencoder = Model(input = input_df, output = decoded)
    # CONFIGURE AND TRAIN THE AUTOENCODER
    autoencoder.compile(optimizer='adadelta', loss=lossFunc)    # mean_squared_error
    autoencoder.fit(X_train, X_train, epochs=nEpochs, batch_size=batchSize, shuffle=True, validation_data=(X_test, X_test), verbose=0)

    # THE ENCODER TO EXTRACT THE REDUCED DIMENSION FROM THE ABOVE AUTOENCODER
    encoder = Model(input = input_df, output = encoded)
    encoded_input = Input(shape = (encoding_dim, ))
    encoded_out = encoder.predict(df)
                                  
    dfAU = pd.DataFrame(encoded_out, columns = auColumns, index = data.index)    
    data = pd.concat([data, dfAU], axis=1, sort=False)

#     recon = autoencoder.predict(df)
#     print(np.abs(recon - df).mean())
    
    return data
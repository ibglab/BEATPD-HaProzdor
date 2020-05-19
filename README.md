# BEATPD-HaProzdor

Repository of the submission of HaProzdor team to the BEATPD Challenge

Team members: Ayala Matzner, Yuval El-Hanani, Izhar Bar-Gad

## Installation instructions

### Stage 1: Environment installation instructions

Start by cloning the repository.

The prepocessing stage utilizes MATLAB code while the rest of the project is based on Python code.

MATLAB (Tested on Windows only):
    1. Install MATLAB 2017A (with Signal Processing, Statistics and Distributed Computing toolboxes)
Python (Tested on both Linux and Windows): 
1. Install python (Tested on 3.6.9) and cython (0.29.15).
2. Generate virtual environment and activate it.
3. Install the required packages from requirements.txt

### Stage 2 - Data installation instructions:

Download the data from the BEATPD site: [data](https://www.synapse.org/#!Synapse:syn20825169)

Generate "data" directory under the root and place the label files in it.
Generate "CIS-PD_test_data" and "CIS-PD-training_data" and place the CIS sessions data in them.
Generate "REAL-PD_test_data" and "REAL-PD-training_data", each containing "smartphone_accelerometer", "smartwatch_accelerometer", "smartwatch_gyroscope" and place the REAL session data in them.

### Stage 3 - Pre process instructions: 

Stage 3.1 - files in "pre_process" directory, MATLAB files Windows only (segment and generate most features).
1. Install Matlab 2017A (with Signal Processing, Statistics and Distributed Computing toolboxes)
2. Run "preProcess_cis.m" to create the CIS 10 second segment features
3. Run "preProcess_real.m" to create the REAL 10 second segment features

Stage 3.2 - files in root directory, Python files Linux/Windows (add additional dimensionality reduction features: PCA and auto-encoder)
1. Run Jupyter notebook "AddDimReductionFeatures.ipynb"

### Stage 4 - Ensemble model predictions

Run the following Jupyter notebooks sequentially: 
     4.1: "EnsembleModels.ipynb" (in the final submission we used seeds 1-32)  
     4.2: "SessionScore.ipynb" for generating test data predictions  
     4.3: "CherryPick.ipynb" for adjusting the mean scores and dropping naive subjects

In the end of the process, the 3 final prediction files are generated under the main directory with the suffix "Predict.csv".

### Final directory hierarchy

BEATPD-HaProzdor  
```
├── data  
│   ├── CIS-PD_test_data  
│   ├── CIS-PD_training_data  
│   ├── REAL-PD_test_data  
│   │   ├── smartphone_accelerometer  
│   │   ├── smartwatch_accelerometer  
│   │   └── smartwatch_gyroscope  
│   └── REAL-PD_training_data  
│       ├── smartphone_accelerometer  
│       ├── smartwatch_accelerometer  
│       └── smartwatch_gyroscope  
├── features  
│   └── Submit_Final  
├── features_seeds_summary  
│   ├── cis  
│   │   └── Submit_Final  
│   └── real  
│       └── Submit_Final  
└── pre_process  
```

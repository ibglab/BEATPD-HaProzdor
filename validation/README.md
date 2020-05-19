## Validation:

Assessment of "naïve" subjects was done using a k-fold validation method. The results of this process are a list of "naïve" subjects, for each of the symptoms (on-off, dyskinesia and tremor). The results are "hard-coded" in the "CherryPick.ipynb" which generates the predictions for the test data.  In order to reproduce these results, run the following Jupyter notebooks under the "validation" folder, sequentially:

1. "BEATPD_kfold.ipynb": Creates 5 sub-datasets for validation (folder "data" and "features" are created under "validation")

2. "EnsembleModels_validation.ipynb": for generating the ensembles for each of the sub-datasets.

3. "SessionScore_validation.ipynb": for generating the validation data predictions

4. "KCherryPick.ipynb": for generating the final list of "naïve" subjects for each of the symptoms.

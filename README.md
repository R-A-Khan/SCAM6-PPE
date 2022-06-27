# SCAM6-PPE
A sample workflow for generating a perturbed parameter ensemble using the SCAM6 atmospheric model, in order to build a statistical surrogate model.

### Generating the ensemble of input parameters
- A sample for the input parameters and specified ranges is generated using a Latin Hypercube Sampling (LHS) strategy.
- LHS is available in many packages across different platforms. I use the [SAFE](https://www.safetoolbox.info/) toolbox for python.
- A sample input file is the text file __parameter_file__ .

### Generating the model simulations for each perturbed parameter case
- The parameters are passed into the atmospheric model settings and the simulation is run via __run_model_loop.sh__ .
- The thermodynamic profiles are adjusted based on the input parameters in the __inv.py__ script.
- The simulations are run in a loop with 32 model evaluations run concurrently on 1 core each, for a total of 20 (e.g) loops, via the __emulator_runs_loop.sh__ script.

### Post-processing of simulation output data
- The results for the ensemble are evaluated and subsequently filtered, via the Jupyter notebook __notebook.ipynb__ .
- A separate set of input samples are used to generate output required to validate the surrogate model.

### Building the emulator
- The filtered input and output data is used to build an emulator. Methodologies tested include:
  - Gaussian Process Emulation (Kriging)
  - Polynomial Chaos Expansion (PCE)
- There are many existing omputational frameworks for building surrogate models e.g. scikit-learn, PyTorch. I use the [uncertainty quantification with python](https://uqpylab.uq-cloud.io/) toolbox provided by UQLabs.

### Conducting Sensitivity Analysis to identify influential parameters.
- Sensitivity Analysis conducted via:
  - Variance Based Sensitivity Analysis
  - Density Based Sensitibity Analysis
- The [SAFE](https://www.safetoolbox.info/) toolbox for python is used.






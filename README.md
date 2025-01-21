# C1D-PAPA `WORK IN PROGRESS`

`DOI:XXXXX.XXXXX`

## Context and Motivation

Purpose of this experiment is to perform the 1D column [C1D_PAPA](https://doi.org/10.5194/gmd-8-69-2015) NEMO config with different vertical turbulent-mixing parameterizations. Results are written in an output file with the NEMO output system (XIOS).


#### Variations
- L22DNN : Boundary layer turbulence computed with Deep Neural Network proposed by [Liang et al. 2022](https://doi.org/10.1016/j.ocemod.2022.102059).


## Requirements

**This part must list libraries versions and codes patches used to run the experiments and facilitates reproducibility.
If one of the experiment variations needs a different software environment, please create another repository from this template.**

### Compilation

- NEMO version : [v4.2.1](https://forge.nemo-ocean.eu/nemo/nemo/-/releases/4.2.1) patched with [morays](https://github.com/morays-community/Patches-NEMO/tree/main/NEMO_v4.2.1) and local `CONFIG/my_src` sources.

- Code Compilation manager : none, use standard `makenemo` script


### Python

- Eophis version : [v1.0.1](https://github.com/alexis-barge/eophis/tree/v1.0.1)
- **L22DNN** dependencies:
  ```bash
  TO_BE_COMPLETED
  ```


### Run

- NEMO Production Manager : none, use submission script `job.ksh` in `RUN`


### Post-Process

- No Post-Process libraries

- Plotting : Python scripts `plots_res.py` and `plots_diff.py` in `POSTPROCESS`


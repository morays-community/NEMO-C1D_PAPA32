# C1D-PAPA32 `WORK IN PROGRESS`

`DOI:XXXXX.XXXXX`

## Context and Motivation

Purpose of this experiment is to perform the 1D column [C1D_PAPA](https://doi.org/10.5194/gmd-8-69-2015) NEMO test case with different vertical turbulent-mixing parameterizations. Here, we use a slightly modified version of the reference case in which the vertical grid is regurlaly discretized on 32 depth levels over 200m. Results are written in an output file with the NEMO output system (XIOS).


#### Variations
- **L22DNN** : Boundary layer turbulence computed with Deep Neural Network proposed by [Liang et al. 2022](https://doi.org/10.1016/j.ocemod.2022.102059).
- **AirSeaFlux** : Bulk formula parameterizations computed with [AirSeaFluxCode](https://github.com/NOCSurfaceProcesses/AirSeaFluxCode/tree/master) software from [Biri et al. 2023](https://doi.org/10.3389/fmars.2022.1049168 ).

## Requirements

### Compilation

- NEMO version : [v4.2.1](https://forge.nemo-ocean.eu/nemo/nemo/-/releases/4.2.1) patched with [morays](https://github.com/morays-community/Patches-NEMO/tree/main/NEMO_v4.2.1) and local `CONFIG/my_src` sources.

- Code Compilation manager : none, use standard `makenemo` script


### Python

- Eophis version : [v1.0.1](https://github.com/alexis-barge/eophis/tree/v1.0.1)
- **L22DNN** dependencies:
  ```bash
  TO_BE_COMPLETED
  ```
- **AirSeaFlux** dependencies:
  ```
  cd C1D_PAPA32.AirSeaFlux/INFERENCES/AirSeaFluxCode/AirSeaFluxCode
  pip install -e .
  ```

### Run

- NEMO Production Manager : none, use submission script `job.ksh` in `RUN`


### Post-Process

- No Post-Process libraries

- Plotting : Python scripts `plots_res.py` and `plots_diff.py` in `POSTPROCESS`


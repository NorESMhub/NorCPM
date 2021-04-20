# NorCPM Structure

### Scientific description:
  [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1169902.svg)](https://doi.org/10.5281/zenodo.1169902)

### Overview
  NorCPM is a set of scripts to do ensemble with or without data assimilation with NorESM2.

### NorCPM is organised as follows:
  * __Analysis__: contains scripts to run NorCPM with data assimilation.
  * __Prediction__: contains scripts to create NorCPM case, and run without data assimilation.
  * __Tools__: Side kicks.
  * __SourceMods.noresm2__: The necessary modifications to NorESM.

### Quick start:
  __Create NorCPM case__:

  1. Create a new setting file from modify Prediction/use_cases/template.in

  2. Use following command to create NorCPM case and first member:
    <pre>
    Prediction/create_template.sh Prediction/use_cases/template.in
    </pre>

  3. Use following command to create other members:
    <pre>
    Prediction/create_ensemble.sh Prediction/use_cases/template.in
    </pre>

  A. __Run NorCPM without data assimilation__:
    <pre>
    Prediction/submit_ensemble.sh Prediction/use_cases/template.in
    </pre>

  B. __Run NorCPM with data assimilation__:

  1. Create a setting file from moodify Analysis/setting/test_noresm2_02.sh

  2. Modify Analysis/submit_reanalysis.sh to read setting file.

  3. Submit Analysis/submit_reanalysis.sh:
    <pre>
    sbatch Analysis/submit_reanalysis.sh
    </pre>

### Check HOWTOs in Doc/ for more details.

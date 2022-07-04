# NorCPM Structure

### Scientific description:
  [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1169902.svg)](https://doi.org/10.5281/zenodo.1169902)

### NorCPM is organised as follows:
  * __Analysis__: Codes and files for NorCPM with data assimilation.
  * __Tools__: Side kicks.
  * __SourceMods.noresm2__: The necessary modifications to NorESM.
  * __Script__: 
  * __Modelsrc__: NorESM2 model source

### Quick start:
  A. __Run NorCPM without data assimilation__:

    <pre>
    cd Scripts/
    setup_experiment.sh  use_case/withoutDA.sh
    submit_experiment.sh use_case/withoutDA.sh
    </pre>

  B. __Run NorCPM with data assimilation__:

    <pre>
    cd Scripts/
    setup_experiment.sh  use_case/withDA.sh
    submit_experiment.sh use_case/withDA.sh
    </pre>

### Check Docs/Details.md for more details.

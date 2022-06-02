# NorCPM Structure

### Scientific description:
  [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1169902.svg)](https://doi.org/10.5281/zenodo.1169902)

### NorCPM is organised as follows:
  * __Analysis__: contains scripts to run NorCPM with data assimilation.
  * __Prediction__: contains scripts to create NorCPM case, and run without data assimilation.
  * __Tools__: Side kicks.
  * __SourceMods.noresm2__: The necessary modifications to NorESM.
  * __Modelsrc__: NorESM2 model source

### Quick start:
  A. __Run NorCPM without data assimilation__:

    <pre>
    cd Prediction
    make edit       ## edit settings
    make check      ## check is restart files available
    make build      ## create and build
    make submit     ## submit job to run prediction
    </pre>

  B. __Run NorCPM with data assimilation__:

    <pre>
    cd Analysis
    make edit       ## edit NorESM settings
    make editana    ## edit NorCPM DA settings
    make check      ## check is restart files available
    make build      ## create and build
    make checkana   ## check files for analysis run
    make submitana  ## submit job to run analysis
    </pre>

### Check HOWTOs in Doc/ for more details.

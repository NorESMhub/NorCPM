## Overview

NorCPM is a set of scripts and modifications designed as a frontend of NorESM. Which included running multiple members and calculation of reanalysis.

This HOWTO introduce the process of generate reanalysis data with NorCPM.

### Scientific description:
  [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1169902.svg)](https://doi.org/10.5281/zenodo.1169902)


### NorCPM analysis work flow

__With data assimilution__:

<pre>
NorCPM: create_template.sh                                NorCPM: submit_analysis.sh
+-------------------------------------------------------+ +-------------------------------------------------+
| Member 001                                            | |  +----------+ +--------------+ +----------+     |
| +------------+       +----------+       +----------+  | |  | case.run | | Data         | | case.run |     |
| |create_case | ----> |case.setup| ----> |case.build| ----> |          | | Assimilation | |          |     |
| +------------+       +----------+       +----------+  | |  |          | | with EnKF    | |          |     |
+-------------------------------------------------------+ |  |          | |              | |          |     |
                            |                             |  |          | |              | |          |     |
NorCPM: create_ensemble.sh  v                             |  |          | |              | |          |     |
+---------------------------+---------------------------+ |  |          | |              | |          |     |
| Member 002                                            | |  |          | |              | |          |     |
| +------------+       +----------+       +----------+  | |  |          | |              | |          |     |
| |create_clone| ----> |case.setup| ----> |case.build| ----> |         ----->           ----->        | ... |
| +------------+       +----------+       +----------+  | |  |          | |              | |          |     |
|                                                       | |  |          | |              | |          |     |
| Member 003                                            | |  |          | |              | |          |     |
| +------------+       +----------+       +----------+  | |  |          | |              | |          |     |
| |create_clone| ----> |case.setup| ----> |case.build| ----> |          | |              | |          |     |
| +------------+       +----------+       +----------+  | |  |          | |              | |          |     |
|                                                       | |  |          | |              | |          |     |
| Member 004                                            | |  +----------+ +--------------+ +----------+     |
| ...                                                   | |                                                 |
+-------------------------------------------------------+ +-------------------------------------------------+
</pre>

## Requirements
1. Worked NorESM2 installed.
2. A set of NorESM2 restart files for each member.  
    If start with only one set of restart files. You may need to perturb it to create multiple sets.  
    There is an example at NorCPM/Tools/create_perturb_SST.sh. Which perturb variable 'temp' in BLOM restart with 10^-10 order random number. And make directory structure for NorCPM read.  
3. Observation data.
4. NorCPM (this)


## Procedures

### Create NorCPM case

See HOWTO-Predict_with_NorESM2.md. "Modify setting file", "Create first member" and "Create other members".

Set the STOP_OPTION to 'nday' and STOP_N to 14 in setting file. Which allowed model start from 15th of the month.

### Modify the analysis setting file

Check the setting file in NorCPM/Analysis/setting/template.sh. Some of the settings can be retrieved from NorESM case directory. Others should be set.

### Modify the submit script

The script submit_reanalysis.sh run both data assimilation and model until $ENDYEAR set in setting file. Some variables need be modified directly in script. One can use it as a template.

1. Check the parameters for queue system. Such as those lines begin with "#SBATCH". The variable 'wallTime' should be same as time requested from queue system. That is the line begin with "#SBATCH --time=".

2. Set the settingFile variable to the filename modified above.

### Submit job with data assimilation
    sbatch NorCPM/Analysis/submit_reanalysis.sh

If the job finish normally, output data would be at $WORK/archive/. Or one can run following command for each member:  
./case.submit case.st_archive


## Default directory structure
This is the directory settings at NorCPM/Prediction/use_cases/template.in and NorCPM/Analysis/setting/template.sh
<pre>
    ${WORK}
    ├── archive   ## Output data directory
    │   ├── ${PREFIX}_${MEMBERTAG}001
    │   ├── ${PREFIX}_${MEMBERTAG}002
    │   └── ...
    ├── norcpm_cases   ## Case dir of each member
    │   ├── ${PREFIX}_${MEMBERTAG}001
    │   ├── ${PREFIX}_${MEMBERTAG}002
    │   └── ...
    └── noresm         ## bld and run, slightly different from original NorESM.
        ├── ${PREFIX}
        │   ├── ${PREFIX}_${MEMBERTAG}001  ## bld
        │   │   └── run                    ## run
        │   ├── ${PREFIX}_${MEMBERTAG}002  ## bld
        │   │   └── run                    ## run
        │   └── ...
        ├── ANALYSIS   ## Data assimilation work directory
        └── RESULT     ## Data assimilation result
    ${REST_PATH_LOCAL}  ## restart file
    └── cases
        ├── ${REST_CASE}
        │   └── ${START_YEARS}-${START_MONTHS}-${START_DAYS}-00000
        ├── ${REST_CASE}_${MEMBERTAG}001  
        │   └── ${START_YEARS}-${START_MONTHS}-${START_DAYS}-00000
        ├── ${REST_CASE}_${MEMBERTAG}002
        │   └── ${START_YEARS}-${START_MONTHS}-${START_DAYS}-00000
        └── ...
    ${WORKSHARED}  ## Prepared data and prebuild binaries for data assimilation. Should be available on Fram and Betzy
    ├── bin
    ├── Input
    └── Obs
</pre>

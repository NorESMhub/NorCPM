## Overview

NorCPM is a set of scripts and modifications designed as a frontend of NorESM. Which included running multiple members and calculation of reanalysis.

The procedure of NorESM2 muiltiple members simulation and analysis run will be introduced in this HOWTO.

### Scientific description:
  [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1169902.svg)](https://doi.org/10.5281/zenodo.1169902)

### NorESM2 (CESM2) work flow     
<pre>
+-------------------------------------------------------------------------+
|                                                           +-----------+ |
| +-----------+       +----------+       +----------+       |case.submit| |
| |create_case| ----> |case.setup| ----> |case.build| ----> |   case.run| |
| +-----------+       +----------+       +----------+       | st_archive| |
|                                                           +-----------+ |
+-------------------------------------------------------------------------+
</pre>

### NorCPM prediction work flows

__Without data assimilution__:

<pre>
NorCPM: setup_experiment.sh                               NorCPM: submit_experiment.sh
+-------------------------------------------------------+ +----------------------------+
| Member 01                                             | |  +------------------------+|
| +------------+       +----------+       +----------+  | |  |case.submit             ||
| |create_case | ----> |case.setup| ----> |case.build| ----> |   case.run(all members)||
| +------------+       +----------+       +----------+  | |  | st_archive             ||
|                                                       | |  +------------------------+|
| Member 02                                             | |                            |
| +------------+       +----------+       +----------+  | |  +-----------------------+ |
| |create_clone| ----> |case.setup| ----> |case.build| ----> |case.submit st_archive | |
| +------------+       +----------+       +----------+  | |  +-----------------------+ |
|                                                       | |                            |
| Member 03                                             | |                            |
| +------------+       +----------+       +----------+  | |  +-----------------------+ |
| |create_clone| ----> |case.setup| ----> |case.build| ----> |case.submit st_archive | |
| +------------+       +----------+       +----------+  | |  +-----------------------+ |
|                                                       | |                            |
| Member 04                                             | |                            |
| ...                                                   | |                            |
+-------------------------------------------------------+ +----------------------------+
</pre>

__With data assimilution__:

<pre>
NorCPM: setup_experiment.sh                               NorCPM: submit_experiment.sh
+-------------------------------------------------------+ +-------------------------------------------------+
| Member 01                                             | |  +----------+ +--------------+ +----------+     |
| +------------+       +----------+       +----------+  | |  | case.run | | Data         | | case.run |     |
| |create_case | ----> |case.setup| ----> |case.build| ----> |          | | Assimilation | |          |     |
| +------------+       +----------+       +----------+  | |  |          | | with EnKF    | |          |     |
|                                                       | |  |          | |              | |          |     |
| Member 02                                             | |  |          | |              | |          |     |
| +------------+       +----------+       +----------+  | |  |          | |              | |          |     |
| |create_clone| ----> |case.setup| ----> |case.build| ----> |         ----->           ----->        | ... |
| +------------+       +----------+       +----------+  | |  |          | |              | |          |     |
|                                                       | |  |          | |              | |          |     |
| Member 03                                             | |  |          | |              | |          |     |
| +------------+       +----------+       +----------+  | |  |          | |              | |          |     |
| |create_clone| ----> |case.setup| ----> |case.build| ----> |          | |              | |          |     |
| +------------+       +----------+       +----------+  | |  |          | |              | |          |     |
|                                                       | |  |          | |              | |          |     |
| Member 04                                             | |  +----------+ +--------------+ +----------+     |
| ...                                                   | |                                                 |
+-------------------------------------------------------+ +-------------------------------------------------+
</pre>

### Requirements
1. A set of NorESM2 restart files for each member.
    If start with only one set of restart files. You may need to perturb it to create multiple sets.
    There is an example at NorCPM/Tools/create_perturb_SST.shWhich perturb variable 'temp' in BLOM restart with 10^-10 order random number. And make directory structure for NorCPM read.
2. NorCPM (this)
3. Observation data. (For analysis run)

### Run NorCPM2 Prediction (without data assimilation)
1. cd NorCPM/Scripts/
2. Modify setting file (ex. use_case/withoutDA.sh)
3. ./setup_experiment.sh use_cases/withoutDA.sh   ## Create casedir for each member
4. ./submit_experiment.sh use_cases/withoutDA.sh  ## Submit model job

### Run NorCPM2 Analysis (with data assimilation)
1. cd NorCPM/Scripts/
2. Modify setting file (ex. use_case/withDA.sh)
3. ./setup_experiment.sh use_cases/withDA.sh   ## Create casedir for each member
4. ./submit_experiment.sh use_cases/withDA.sh  ## Submit model job

### Setting file
The settings and its default values are set in setting file. Add settings at top of file.
Here list some useful settings:
- CASENAME: The run casename. The cases of ensemble members will be CASENAME_mem01 and so on.
- NMEMBERS: How many ensemble members in this run.
- Start dates: STARTS_YYYYMM, START_YEARS, START_MONTHS, START_DAY
    - Can be multiple date for prediction runs. But only 1 allowed in analysis run.
    - STARTS_YYYYMM will override START_YEARS and START_MONTHS if not empty.
    - For example, START_YEARS='1991 1992', START_MONTH='1 4'. Equivalent to START_YYYYMM='199101 199104 199201 199204'.
    - Set additional REF_YEAR, REF_MONTH and REF_DAY to use hybrid run.
- RESTART: Run months of analysis run. Do not set in prediction run.
- REST_CASE, REST_PATH: See comments in setting file.
- PRECASESETUP: Commands to run before case.setup. Things like copy SourceMods or user name lists.
- PRECASESETUP01: Only appliied at first member.
- NORESMROOT: The path to NorESM2 code. 

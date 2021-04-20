## Overview

NorCPM is a set of scripts and modifications designed as a frontend of NorESM. Which included running multiple members and calculation of reanalysis.

The progress of NorESM2 muiltiple members simulation will be introduced in this HOWTO.


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

### NorCPM prediction work flow

__Without data assimilution__:

<pre>
NorCPM: create_template.sh                                NorCPM: submit_ensemble.sh
+-------------------------------------------------------+ +----------------------------+
| Member 001                                            | |  +------------------------+|
| +------------+       +----------+       +----------+  | |  |case.submit             ||
| |create_case | ----> |case.setup| ----> |case.build| ----> |   case.run(all members)||
| +------------+       +----------+       +----------+  | |  | st_archive             ||
+-------------------------------------------------------+ |  +------------------------+|
                            |                             |                            |
NorCPM: create_ensemble.sh  v                             |                            |
+-------------------------------------------------------+ |                            |
| Member 002                                            | |                            |
| +------------+       +----------+       +----------+  | |  +-----------------------+ |
| |create_clone| ----> |case.setup| ----> |case.build| ----> |case.submit st_archive | |
| +------------+       +----------+       +----------+  | |  +-----------------------+ |
|                                                       | |                            |
| Member 003                                            | |                            |
| +------------+       +----------+       +----------+  | |  +-----------------------+ |
| |create_clone| ----> |case.setup| ----> |case.build| ----> |case.submit st_archive | |
| +------------+       +----------+       +----------+  | |  +-----------------------+ |
|                                                       | |                            |
| Member 004                                            | |                            |
| ...                                                   | |                            |
+-------------------------------------------------------+ +----------------------------+
</pre>

## Requirements
1. Worked NorESM2 installed.
2. A set of NorESM2 restart files for each member.
    If start with only one set of restart files. You may need to perturb it to create multiple sets.
    There is an example at NorCPM/Tools/create_initial_CMIP6_1850_nco.sh. Which perturb variable 'temp' in BLOM restart with 10^-10 order random number. And make directory structure for NorCPM read.
3. NorCPM (this)


## Procedures

### Modify setting file
Most of NorCPM use a setting file as first argument. The file will be sourced in script. It defined all of the settings required by NorESM.
There is an example file at NorCPM/Prediction/use_cases/template.in:
* WORK: The root of work directory.
* MACH: The machine setting in NorESM2. Ex. fram.
* REST_CASE: Case name and file name prefix of restart files. 
* REST_PREFIX: 

    The directory name prefix of restart file case. 

    The directory should be:

    $REST_PATH_LOCAL/$REST_PREFIX{001..$MAX_MEMBERS}/$START_YEARS-$START_MONTHS-$START_DAYS-00000

* REST_PATH_LOCAL: The abslute path where restart files 
* PREFIX: The NorCPM case name. First Member will be named as ${PREFIX}_${MEMTAG}001 and so on.
* START_YEARS: Restart file year.
* START_MONTHS: Restart file month.
* START_DAYS: Restart file day.
* MAX_MEMBERS: Max members NorCPM will be run. Start from 001.

* SCRIPTPATH: Script path. No need to edit.

* CASESROOT: The diectory place NorCPM cases.
* ANAPATH: The place put analysis script. Use in submit_reanalysis.sh only. No need to modify.
* CCSMROOT: Ths directory of NorESM2.
* COMPSET: The compset of NorESM case.
* PECOUNT: Resource size to use. But no effect here.
* RES: The resolution of model.
* ACCOUNT: The project used to create_case in NorESM.

* ASK_BEFORE_REMOVE: 1 means ask before removeing exiting cases when create case.
 
* MEMBERTAG: The 'mem' of '$CASENAME_mem001'.
* MAX_PARALLEL_STARCHIVE: The limitation of submit short-term archiving process, not use in NorESM2.
* DOWNSCALING: Output variable for NEMO. Not use here.
* ANOM_CPL: Anomaly coupled (Koseki et al. 2017). Not use here.
 
* START_YEAR1, START_MONTH1, START_DAY1: Date for first member. No need to modify.
* SCRIPTSROOT: Path to NorESM CIME scripts. No need to change.
* CESMVERSION: The version of NorESM(CESM). The only vaild value is '2'. Other value or unset will be treat as NorESM 1.x.

* NTASKS, NTASKS_OCN, STOP_OPTION, STOP_N, WALLTIME, TOTALPE, COST_PES, SCRIPTDIR: This variables are only use in setting PRECASESETUP and PRECASESETUP001. 


* PRECASESETUP: Commands set in this variable will be executed in case directory of each member before case.setup. 
* PRECASESETUP001: Same as PRECASESETUP, but only execute in first member.

Assume settings are save as settingfile.in.

### Create first member 
    NorCPM/prediction/create_template.sh path/to settingfile.in
This script create, setup and build a new case as first member. It also make soft links of restart files to run directory.

The RUNDIR is located at $EXECROOT/run. Which is slightly different from origiinal NorESM.

### Create other members 
    NorCPM/prediction/create_ensemble.sh path/to/settingfile.in
This script use 'create_clone' create other members. And link the object files from first member to save compile time. Other process is same as first member.

### Submit job without data assimilation
    NorCPM/prediction/submit_ensemble.sh path/to/settingfile.in

In NorESM2(CESM2) the short-term archiving is separated from main simulation. This script runs case.submit at first member, and submits st_archive of other members.

If the job finish normally, output data would be at $WORK/archive/.

## Default directory structure
This is the directory settings at NorCPM/prediction/use_cases/example_NorESM2/template.in.
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
        └── ${PREFIX}
            ├── ${PREFIX}_${MEMBERTAG}001  ## bld
            │   └── run                   ## run
            ├── ${PREFIX}_${MEMBERTAG}002  ## bld
            │   └── run                   ## run
            └── ...
    ${REST_PATH_LOCAL}  ## restart file
    └── cases
        ├── ${REST_CASE}
        │   └── ${START_YEARS}-${START_MONTHS}-${START_DAYS}-00000
        ├── ${REST_CASE}_${MEMBERTAG}001  
        │   └── ${START_YEARS}-${START_MONTHS}-${START_DAYS}-00000
        ├── ${REST_CASE}_${MEMBERTAG}002
        │   └── ${START_YEARS}-${START_MONTHS}-${START_DAYS}-00000
        └── ...
</pre>

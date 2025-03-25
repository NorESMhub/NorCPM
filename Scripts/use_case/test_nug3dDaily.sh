#!/bin/bash
######################################################################################
### This script is used to setup and run NorCPM2 case.
### 
### A NorCPM2 case contains multiple members of NorESM2.
### The directory structure will be like following:
### Casedir: 
###     CASESROOT/CASENAME/CASENAME_mem01
###     CASESROOT/CASENAME/CASENAME_mem02
###     CASESROOT/CASENAME/CASENAME_mem03
###     ...
### Build: 
###     EXESROOT/CASENAME/CASENAME_mem01
###     EXESROOT/CASENAME/CASENAME_mem02
###     EXESROOT/CASENAME/CASENAME_mem03
###     ...
### Run:
###     EXESROOT/CASENAME/CASENAME_mem01/run
###     EXESROOT/CASENAME/CASENAME_mem02/run
###     EXESROOT/CASENAME/CASENAME_mem03/run
###     ...
###
######################################################################################

# Experiment default setting, can be set below to override default.
# example:

CASENAME=test_nudge3dDaily_05
CASESROOT=/cluster/projects/nn9039k/people/pgchiu/norcpm_cases
REST_PATH=/cluster/projects/nn9039k/people/pgchiu/restarts
NMEMBER=1
START_YEARS=1982
START_MONTHS=11
START_DAY=15
STOP_OPTION=nyear
STOP_OPTION=nmonth
STOP_N=1
WALLTIME='0-12:00:00'

## 3d nudge setting
### true:  nudge anomaly
### false: nudge full field
export ADD_DO_3DDAILYNUDGEANO='false' 
## if ADD_DO_3DDAILYNUDGEANO is true
export ADD_OBSCLM365='/path/to/nudge/data/VARNAME_daily_clim_DDD.nc'
export ADD_MODCLM365='/path/to/nudge/data/VARNAME_daily_clim_DDD.nc'

## Horizontal weighting (region setting)
export ADD_SSTNUDGEWFILE='/cluster/projects/nn9039k/people/pgchiu/NorCPM_togit/rewritted/NorCPM/weighting_files/weighting_tropical.nc'
## Nudge data file pattern, VARNAME, YYYY, DDD will be replaced by model
export ADD_NUGPATH='/cluster/work/users/ach051/ECCO_daily/tnx1v4/clim/VARNAME_daily_clim_DDD.nc'
export ADD_NUGPATH='/cluster/work/users/ach051/ECCO_daily/clim/VARNAME_daily_clim_DDD.nc'
## Nudge coefficient at every time step
## 3600 sec per 1 time step, restoring time scale of 1 day is 0.41667
export ADD_NUGCOEFF=0.041667



## for Betzy
##PRECASESETUP01='./xmlchange USER_REQUESTED_QUEUE=normal --subgroup=case.run ; ./xmlchange DEBUG=TRUE'
PRECASESETUP01='./xmlchange USER_REQUESTED_QUEUE=normal --subgroup=case.run'

# Default variables below.
# Do not modify. Override them by assign value up.
# experiment settings
: ${CASENAME:='norcpm2_case'} ## case_name 
: ${APPENDSTARTDATE:='false'} ## case_name_YYYYMMDD, will be overrided to true for multiple start dates
: ${NMEMBER:=10} ## number of members

: ${STARTS_YYYYMM:=''}  ## init dates to create case, overrided the setting below. Split by space
: ${START_YEARS:='1988'}        ## init dates, will multiple START_YEARS and START_MONTHS
: ${START_MONTHS:='2 5 8 11'}   ## ex: START_YEARS='1990 1991', START_MONTH='1 4 7 10'
: ${START_DAY:=15}              ##     will create 8 runs, 4 runs per year.

: ${RUNTYPE:='branch'} ## if use 'hybrid', set additional REF_YEAR, REF_MONTH and REF_DAY of restart file

## run length
: ${STOP_OPTION:='nmonth'} # units for run length specification STOP_N
: ${STOP_N:=13}    # run continuesly for this length

### Restart file settings
##### The restart file should be in directories like following:
#####    ${REST_PATH}/${REST_PREFIX}01/${START_YEARS}-00000/
#####    ${REST_PATH}/${REST_PREFIX}02/${START_YEARS}-00000/
#####    ${REST_PATH}/${REST_PREFIX}03/${START_YEARS}-00000/
#####    ...
##### or 
#####    ${REST_PATH}/${REST_PREFIX}01/rest/${START_YEARS}-00000/
#####    ${REST_PATH}/${REST_PREFIX}02/rest/${START_YEARS}-00000/
#####    ${REST_PATH}/${REST_PREFIX}03/rest/${START_YEARS}-00000/
#####    ...
: ${REST_CASE:='norcpm_ana_f09_tn14'}
: ${REST_PATH:="/cluster/shared/NS9039K/archive/${REST_CASE}"}
: ${REST_PREFIX:="${REST_CASE}_mem"} # reference prefix, including everything but member id
: ${RESTART_NOT_DA:=''}
        ## If restart file arcived before data assimilation. 
        ## This option will start prediction from next month.
        ## Keep it empty to disable.

## case setting
: ${MACH:='betzy'}
: ${COMPSET:='NHISTfrc2'} ## NorESM components setting compset
: ${RES:='f09_tn14'}  ## resolution, f09_tn14 (MM) or f19_tn14 (LM)
: ${ACCOUNT:='nn9039k'}  ## account of queue system
: ${WALLTIME:='0-24:00:00'}


## CPU usage, override NorESM2 default settings
: ${NTASKS:=512}     ## set all component, can be 128, 256, 512 on betzy
: ${NTASKS_OCN:=354} ## NTASKS of BLOM, must be set to specific numbers.
	## blom_dimensions: Available processor counts: 32 42 63 77 91 123 156 186 256 354
: ${MEMBER_PES:=$NTASKS}  ## This value is the number of PE for each member.

## directories (betzy)
: ${WORK:="/cluster/work/users/$USER"}
: ${CASESROOT:="$WORK/norcpm_cases"}
: ${EXESROOT:="$WORK/noresm/"}
: ${ARCHIVESROOT:="$WORK/archive"}

# general settings
: ${PRECASESETUP:=''}    ## command run in all members case dir before case.setup
: ${PRECASESETUP01:=''}  ## only run in member01
: ${MEMTAG:='mem'}
: ${MEM01:='01'}

# derived settings
: ${NORESMROOT:="$(readlink -f ../Modelsrc/NorESM)"}
: ${NORCPMROOT:="$(readlink -f ../)"}
TOTALPE=$(($MEMBER_PES * $NMEMBER))


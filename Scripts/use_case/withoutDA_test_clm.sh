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

CASENAME=norcpm2_test_lnd_timeseries
NMEMBER=1
START_YEARS=1982
START_MONTHS=11
STOP_OPTION='nmonth'
STOP_N=13
REST_CASE=norcpm_ana_f09_tn14
REST_PATH=/cluster/projects/nn9039k/people/pgchiu/restarts


## for Betzy
#PRECASESETUP01='./xmlchange USER_REQUESTED_QUEUE=normal --subgroup=case.run'
PRECASESETUP="echo flanduse_timeseries = \\'/cluster/shared/noresm/inputdata/lnd/clm2/surfdata_map/landuse.timeseries_0.9x1.25_hist_78pfts_CMIP6_simyr1850-2015_reduced80_tropical_c170824.nc\\' >> user_nl_clm"

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


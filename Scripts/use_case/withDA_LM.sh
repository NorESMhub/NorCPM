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

CASENAME=newNorCPM2_02_f19_tn14
REST_CASE=noresm_ctl_19700101_19700101
START_YEARS=1984
START_MONTHS=01
START_DAY=01
RES=f19_tn14
NMEMBER=3
RESTART=12

## for Betzy
PRECASESETUP01='./xmlchange USER_REQUESTED_QUEUE=normal --subgroup=case.run'

# experiment settings
: ${CASENAME:='norcpm2_case'} ## case_name 
: ${APPENDSTARTDATE:='false'} ## case_name_YYYYMMDD, will be overrided to true for multiple start dates
: ${NMEMBER:=10}
: ${STARTS_YYYYMM:=''}  ## init dates to create case, overrided the setting below. Only 1 for analysis
: ${START_YEARS:='1988'}  ## init dates, only 1 for analysis run is allowed
: ${START_MONTHS:='2'}    ## also connected to restart files (for branch run)
: ${START_DAY:=15}      
: ${RUNTYPE:='branch'} ## if use 'hybrid', set additional REF_YEAR, REF_MONTH and REF_DAY of restart file

## run length
: ${RESTART:=60}   # run length for analysis run, override STOP_OPTION and STOP_N

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
## : ${RUN_REFCASE:=''}      ## sometimes RUN_REFCASE is different from REST_CASE
    ## Keep it empty if casename of restart files are $REST_CASE_mem01 (restart files are generated from NorCPM case)
          ## Or fill it with casename if restart files are pertubed from single case.
    ## (implied, wait for delete)
: ${RESTART_NOT_DA:=''}
        ## If restart file arcived before data assimilation. This option will start prediction from next month.
        ## Keep it empty to disable the function.

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


## DA setting
## 0: disable, 1: enable
: ${EnKF_Version:=1}
: ${ASSIMULATEMONTHDAY:=15}  ## day of DA each month
: ${WORKSHARED:='/cluster/shared/noresm/norcpm'}
: ${GRIDPATH:='/cluster/shared/noresm/inputdata/ocn/micom/tnx1v4/20170601/grid.nc'}
  PRODUCERLIST=(${PRODUCERLIST:='HADISST2 EN421 EN421'})  ## norcpm_ana_f09_tn14 1980-2010
  OBSLIST=(${OBSLIST:='SST TEM SAL'})    ## data to assimilate
  REF_PERIODLIST=(${REF_PERIODLIST:='1980-2010 1980-2010 1980-2010'}) ## ref. period of climatology
  MONTHLY_ANOM=(${MONTHLY_ANOM:='1 1 1'})      ## Use anomaly data to 
  COMBINE_ASSIM=(${COMBINE_ASSIM:='0 0 1'})      ## Run assimilation individually
: ${ANOMALYASSIM:=1}  # Anomaly assimilation, need consistant with MONTHLY_ANOM
: ${SUPERLAYER:='1'}  # use upscaling method (Wang et al. 2016)
: ${ATMO_NUDGING:=0}  # relaxation of atmosphere (atmos. nudging)
: ${ANOM_CPL:='0'}    # anomaly coupled (Koseki et al. 2017)
: ${OSAS:='0'}        # Param estimation

## Arrays for pbs_enkf, array element number should be consistant with num of '1' in $COMBINE_ASSIM
## Variable to DA in model. Format: <varname> <1 or 0> <levels>
ANALYSIS_FIELDS=('u         1 53
    v         1 53
    dp        1 53
    temp      1 53
    saln      1 53
    uflx      1 53
    vflx      1 53
    utflx     1 53
    vtflx     1 53
    usflx     1 53
    vsflx     1 53
    pb        1 1
    ub        1 1
    vb        1 1
    ubflx     1 1
    vbflx     1 1
    ubflxs    1 1
    vbflxs    1 1
    ubcors_p  0 0
    vbcors_p  0 0
    phi       0 0
    sealv     0 0
    ustar     0 0
    buoyfl    0 0 '
)
## Namelist for EnKF.F90
: ${RFACTOR:=1}   # Slow assimilation start
ENKF_PRM=("
    &method
        methodtag = 'DEnKF'
    /
    &ensemble
        enssize = ${NMEMBER}
    /
    &localisation
        locfuntag = 'Gaspari-Cohn'
        locrad = 1500.0
    /
    &moderation
        infl = 1.00
        rfactor1 = ${RFACTOR}
        rfactor2 = 4.0
        kfactor = 2.0
    /
    &files
    /
    &prmest /"
)

#FOLLOWING are used to developing
: ${SKIPASSIM:=0} # skip the first assimilation
: ${SKIPPROP:=0}  # skip the first model intergration
: ${TEST:=0}      # do only 2 cycles of DA and simulation
: ${ANALYSIS_DIRNAME:=ANALYSIS}  ## DA work dirname, located at EXESROOT/CASENAME/
: ${RESULT_DIRNAME:=RESULT}      ## DA diag data dirname, located at EXESROOT/CASENAME/

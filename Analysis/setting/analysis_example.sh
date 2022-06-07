#!/bin/bash
MACH=betzy
WORK=/cluster/work/users/$USER

## CPUACCOUNT: Account in batch system.
CPUACCOUNT=nn9039k

## NORCPM_CASE: Case name of NorCPM.
##              The members will be ${NORCPM_CASE}_mem01...etc
NORCPM_CASE=norcpm2_template

## NORCPM_CASEDIR: The directory contain cases of every member
##   example: ${NORCPM_CASEDIR}/${NORCPM_CASE}_mem01
NORCPM_CASEDIR=/cluster/work/users/$USER/norcpm_cases/${NORCPM_CASE}

## NORCPM_RUNDIR: The directory contain bld/run dir of every member
##   example: ${NORCPM_RUNDIR}/${NORCPM_CASE}_mem01/run
##   detect in case dir.
NORCPM_RUNDIR=$(cd ${NORCPM_CASEDIR}/${NORCPM_CASE}_mem01 && ./xmlquery RUNDIR --value)
NORCPM_RUNDIR=$(readlink -f $NORCPM_RUNDIR/../..)

## ENDYEAR: Stop until end of this year.
SELFRESUBMIT='1'  ## resubmit if not reach ENDYEAR, empty means no resubmit
ENDYEAR=1987
## need be revised

## RES: Resolution of model
##   detect in case dir.
RES=$(cd ${NORCPM_CASEDIR}/${NORCPM_CASE}_mem01 && ./xmlquery OCN_GRID --value)
    case $RES in 
        tnx1v4 )
            RES=f09_tn14 
            grid_type='tp'   #tripolar grid 
            ;;
        * )
            echo "Unknow resolution: $RES"
            exit 1
            ;;
    esac

## RUN_TYPE: 'branch' or 'hybrid'
##   detect in case dir.
##      branch_run: branch start needed if model configuration or version different
##      hybrid_run: hybrid start needed if model configuration or version or model time different
RUN_TYPE=$(cd ${NORCPM_CASEDIR}/${NORCPM_CASE}_mem01 && ./xmlquery RUN_TYPE --value)
    case $RUN_TYPE in
        branch )
            hybrid_run=0  
            branch_run=1 
            ;;
        hybrid )
            hybrid_run=1  
            branch_run=0 
            ;;
    esac

## WORKSHARED: Contains input and executable binaries
##   Binarys: ${WORKSHARED}/bin
##   Input data: ${WORKSHARED}/Input
## This is the default WORKSHARED on BETZY. There is an example in Analysis/lib/WORKSHARED
WORKSHARED=/cluster/shared/noresm/norcpm

## GRIDPATH: Grid file (grid.nc) location
## BETZY default:
GRIDPATH=/cluster/shared/noresm/inputdata/ocn/micom/tnx1v4/20170601/grid.nc

## ENSSIZE: Ensemble numbers of NorCPM case.
##   Detect with list directory, must be less than 100.
ENSSIZE=$(ls ${NORCPM_CASEDIR} | grep -c "^${NORCPM_CASE}_mem..$")

WORKDIR=${WORK}/noresm/
PREFIX=${NORCPM_CASE}
CASES=${NORCPM_CASEDIR}/${PREFIX}
   #The following are necessary to set path to the miseryous cam2.i file 

CASEDIR=${PREFIX}
VERSION=${CASEDIR}'_mem'

####  Data Assimilation settings
skip_micom_ensemble_init='true'
#Possible to assimilate all observations 
#OBSLIST=("SST" "ICEC" "SSH" "TEM" "SAL")
#PRODUCERLIST=('HADISST2' 'HADISST2' 'CLS' 'EN4' 'EN4')
#ANOMALYASSIM=0  #1 is for TRUE
#MONTHLY_ANOM=('1' '1' '1' '1' '1' '1')
# with the following sst icec and ssh are assimilated together and t and s are assimiliated together
#COMBINE_ASSIM=(0 0 1 0 1)
#REF_PERIODLIST=('1980-2010' '1980-2010' '1993-2010' '1980-2010' '1980-2010')
OBSLIST=("SST" "TEM" "SAL")
EnKF_Version=1
COMBINE_ASSIM=( '0' '0' '1')

## Data sets
PRODUCERLIST=('HADISST2' 'EN421' 'EN421')  ## norcpm_ana_f09_tn14 1980-2010
REF_PERIODLIST=('1980-2010' '1980-2010' '1980-2010') 

##PRODUCERLIST=('NOAA' 'EN421' 'EN421')  ## norcpm_ana_f09_tn14 2011-
##REF_PERIODLIST=('1982-2010' '1980-2010' '1980-2010')  ## NOAA

ANOMALYASSIM=1  #1 is for TRUE
MONTHLY_ANOM=('1' '1' '1')
SUPERLAYER='1'  #1 means you use upscaling method (Wang et al. 2016)
ATMO_NUDGING=0  #1 means that you use relaxation of atmosphere
ANOM_CPL='0'  #1 means you use anomaly coupled (Koseki et al. 2017)
OSAS='0'  #Param estimation

#FOLLOWING are used to developing
SKIPASSIM=0 #if 1 we skip the first assimilation
SKIPPROP=0 #if 1 we skip the first model intergration
RFACTOR=1  #Slow assimilation start
TEST=0 # if 1 This is a test and will do only 2 cycles
export WORKDIR VERSION ENSSIZE CASEDIR


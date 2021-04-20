#!/bin/bash
MACH=betzy  ## depend on what environment you used to compile binaries.
            ## See NorCPM/Analysis/env/
WORK=/cluster/work/users/$USER
            ## determined the WORKDIR

## NORCPM_CASE: Case name of NorCPM.
##              The members will be ${NORCPM_CASE}_mem001...etc
NORCPM_CASE=Casename

## NORCPM_CASEDIR: The directory contain cases of every member
##   example: ${NORCPM_CASEDIR}/${NORCPM_CASE}_mem001
NORCPM_CASEDIR=/cluster/work/users/$USER/norcpm_cases/${NORCPM_CASE}

## NORCPM_RUNDIR: The directory contain bld/run dir of every member
##   example: ${NORCPM_RUNDIR}/${NORCPM_CASE}_mem001/run
##   detect in case dir.
NORCPM_RUNDIR=$(cd ${NORCPM_CASEDIR}/${NORCPM_CASE}_mem001 && ./xmlquery RUNDIR --value)
NORCPM_RUNDIR=$(readlink -f $NORCPM_RUNDIR/../..)

## RES: Resolution of model
##   detect in case dir.
RES=$(cd ${NORCPM_CASEDIR}/${NORCPM_CASE}_mem001 && ./xmlquery OCN_GRID --value)
    case $RES in 
        tnx1v4 )
            RES=f19_tn14 
            grid_type='tp'   #tripolar grid 
            ;;
        * )
            echo "Unknow resolution: $RES"
            exit
            ;;
    esac

## RUN_TYPE: 'branch' or 'hybrid'
##   detect in case dir.
##      hybrid_run: hybrid start needed if model configuration or version different
##      branch_run: branch start needed if model configuration or version different
##          If you are starting from the same model with same configuration set hybrib_run=0

RUN_TYPE=$(cd ${NORCPM_CASEDIR}/${NORCPM_CASE}_mem001 && ./xmlquery RUN_TYPE --value)
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
##   Observation: ${WORKSHARED}/Obs
## betzy ##WORKSHARED=/cluster/shared/noresm/norcpm
WORKSHARED=/path/to/NorCPM

## GRIDPATH: Grid file (grid.nc) location
##   which should be at input data of NorESM
GRIDPATH=/cluster/shared/noresm/inputdata/ocn/micom/tnx1v4/20170601/grid.nc

## ENSSIZE: Ensemble numbers of NorCPM case.
##   Detect with list directory, must be less than 1000.
ENSSIZE=$(ls ${NORCPM_CASEDIR} | grep -c "^${NORCPM_CASE}_mem...$")



WORKDIR=${WORK}/noresm/
PREFIX=${NORCPM_CASE}
CASES=${NORCPM_CASEDIR}/${PREFIX}
   #The following are necessary to set path to the miseryous cam2.i file 

CASEDIR=${PREFIX}
VERSION=${CASEDIR}'_mem'

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
COMBINE_ASSIM=('1' '1' '1')
PRODUCERLIST=('HADISST2' 'EN4' 'EN4')
ANOMALYASSIM=1  #1 is for TRUE
MONTHLY_ANOM=('1' '1' '1')
REF_PERIODLIST=('1970-1983' '1970-1983' '1970-1983')  ## test 
SUPERLAYER='1'  #1 means you use upscaling method (Wang et al. 2016)
ATMO_NUDGING=0  #1 means that you use relaxation of atmosphere
ANOM_CPL='0'  #1 means you use anomaly coupled (Koseki et al. 2017)
OSAS='0'  #Param estimation

NIRD_path="/trd-project4/NS9039K/shared/norcpm/cases/NorCPM/True_Obs-2006-2017/"

#FOLLOWING is related to the Reanalysis
SKIPASSIM=0 #if 1 we skip the first assimilation
SKIPPROP=0 #if 1 we skip the first model intergration
RFACTOR=1  #Slow assimilation start
ENDYEAR=1984
TEST=0 # if 1 This is a test and will do only 2 cycles
export WORKDIR VERSION ENSSIZE CASEDIR


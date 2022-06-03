#!/bin/bash -e
##############################################################################
## This script create and submit script to 
## do data assimilation with existed NorCPM2 case
##
##
##
##
##
## Ping-Gin.Chiu@uib.no  May2022
##############################################################################

## read setting
settingFile="$1"
source $settingFile
NORCPM_ROOT=$(cd .. ; pwd -P)

function xmlq {
    items=$*
    cd ${NORCPM_CASEDIR}/${NORCPM_CASE}_mem01/ && \
    ./xmlquery --value $items
    }
JOBTIME=$(xmlq --subgroup case.run JOB_WALLCLOCK_TIME)
NTASKSPERNODE=$(xmlq MAX_TASKS_PER_NODE)
NTASKS=$(xmlq --subgroup case.run task_count)
NODES=$(($NTASKS / $NTASKSPERNODE))

## create submit script
sfn=$(basename $settingFile)
sed  \
    -e "s;NORCPMROOT;${NORCPM_ROOT};"        \
    -e "s/JOBACCOUNT/${CPUACCOUNT}/"    \
    -e "s/JOBNAME/${NORCPM_CASE}/"      \
    -e "s/JOBTIMEREQUEST/${JOBTIME}/"   \
    -e "s/JOBNODES/${NODES}/"           \
    -e "s/JOBNTASKS/${NTASKS}/"          \
    -e "s/NTASKSPERNODE/${NTASKSPERNODE}/"          \
    -e "s/ASSIMULATEMONTHDAY/15/"       \
    -e "s/ISITTEEST/0/"                 \
    -e "s;SETTINGFILE;${sfn};"  \
    template/submit.template > ${NORCPM_CASE}_submit.sh

## submit script
sbatch ${NORCPM_CASE}_submit.sh

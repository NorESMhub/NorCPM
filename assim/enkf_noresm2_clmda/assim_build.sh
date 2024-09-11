#!/bin/sh -e

# settings used for standalone build 
: ${ASSIMROOT:=`readlink -f \`dirname $0\``} 
: ${ASSIMCODE_ENKF:=$ASSIMROOT/EnKF}
: ${ASSIMCODE_PREP_OBS:=$ASSIMROOT/prep_obs}
: ${SETUPROOT:=../../setup/noresm2} ; . $SETUPROOT/settings/setmach.sh 
: ${ANALYSISROOT:=$WORK/noresm/assim_standalone/`basename $ASSIMROOT`} 

echo + create empty file CLM_DA to activate assimilation in CLM 
cd $ANALYSISROOT
touch CLM_DA

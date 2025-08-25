#!/bin/sh -e

# settings used for standalone build 
: ${ASSIMROOT:=`readlink -f \`dirname $0\``} 
: ${ASSIMCODE_ENKF:=$ASSIMROOT/EnKF}
: ${ASSIMCODE_PREP_OBS:=$ASSIMROOT/prep_obs}
: ${SETUPROOT:=../../setup/noresm2} ; . $SETUPROOT/settings/setmach.sh 
: ${ANALYSISROOT:=$WORK/noresm/assim_standalone/`basename $ASSIMROOT`} 

echo + build EnKF
mkdir -p $ANALYSISROOT/bld/EnKF/TMP
cd $ANALYSISROOT/bld/EnKF
cp -f $ASSIMROOT/shared/* . 
cp -f $ASSIMROOT/EnKF/* . 
make clean
make  

echo + build prep_obs
mkdir -p $ANALYSISROOT/bld/prep_obs/TMP
cd $ANALYSISROOT/bld/prep_obs
cp -f $ASSIMROOT/shared/* . 
cp -f $ASSIMROOT/prep_obs/* . 
make clean
make

echo + create empty file BLOM_DA to activate assimilation in BLOM 
cd $ANALYSISROOT
touch BLOM_DA

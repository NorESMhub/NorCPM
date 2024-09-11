#!/bin/sh -e

# settings used for standalone build 
: ${ASSIMROOT:=`readlink -f \`dirname $0\``} 
: ${ASSIMCODE_ENKF:=$ASSIMROOT/EnKF}
: ${ASSIMCODE_PREP_OBS:=$ASSIMROOT/prep_obs}
: ${ASSIMCODE_ENSAVE_FIXENKF:=$ASSIMROOT/ensave_fixenkf} 
: ${ASSIMCODE_MICOM_INIT:=$ASSIMROOT/micom_init}
: ${SETUPROOT:=../../setup/noresm1} ; . $SETUPROOT/settings/setmach.sh 
: ${ANALYSISROOT:=$WORK/noresm/assim_standalone/`basename $ASSIMROOT`} 
: ${CLMDAROOT:=$WORK/noresm/clmda_standalone/`basename $ASSIMROOT`}

# Create folder for CLM
echo + build CLM DA
mkdir -p $CLMDAROOT
cd $CLMDAROOT
cp -r $ASSIMROOT/SM_DAstandaloneApplication .
cp -r $ASSIMROOT/clmda.sh .
#cp -r $ASSIMROOT/LDAstandaloneApplication .
#cp -r $ASSIMROOT/SM_DAl1standaloneApplication .
#sed -e "s+enssize=en+enssize=${ENSSIZE}+g" -e "s+infl_fac=infl+infl_fac=${infl}+g" $ASSIMROOT/clmda.sh > clmda.sh
#sed -e "s+LDA_START=YYYYMM+LDA_START=${LDA_START}+g" -e "s+LDA_END=YYYYMM+LDA_END=${LDA_END}+g" $ASSIMROOT/clmda.sh > clmda.sh
#touch DOCLMDA

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

echo + build ensave and fixenkf
mkdir -p $ANALYSISROOT/bld/ensave_fixenkf/TMP
cd $ANALYSISROOT/bld/ensave_fixenkf
cp -f $ASSIMROOT/shared/* . 
cp -f $ASSIMROOT/ensave_fixenkf/* . 
make clean
make

echo + build micom_init
mkdir -p $ANALYSISROOT/bld/micom_init
cd $ANALYSISROOT/bld/micom_init
cp -f $ASSIMROOT/micom_init/* . 
make clean
make

#!/bin/sh -e

echo "USAGE: ./`basename $0` <path to settings file>" 
echo "EXAMPLE: ./`basename $0` use_cases/predictiontest.in" 
echo "PURPOSE: creates NorCPM ensemble from case template" 
echo + READING SETTINGS FROM FILE 
if [ ! $1 ]
then
  echo cannot read settings file $1 
  exit
fi
. $1

if [ -z "$START_YYYYMM" ]; then
    for y in $START_YEARS; do
    for m in $START_MONTHS; do
        mm=$(printf '%2.2d' $m)
        START_YYYYMM="${START_YYYYMM} $y$mm"
    done #START_YEAR0
    done #START_MONTH0
fi



echo + BEGIN LOOP OVER START DATES AND MEMBERS 

for START_YYYYMM0 in $START_YYYYMM; do
START_YEAR0=$(echo $START_YYYYMM0 | cut -c -4)
START_MONTH0=$(echo $START_YYYYMM0 | cut -c 5-)
for START_DAY0 in $START_DAYS ; do
MEM01=${MEMBER1:-01}
echo + CHECK THAT TEMPLATE CASE EXISTS
if [ -z "$RESTART_NOT_DA" ] ;then
    START_YEAR1=$START_YEAR0
    START_MONTH1=$START_MONTH0
    START_DAY1=$START_DAY0
    ENSEMBLE_PREFIX1=${ENSEMBLE_PREFIX:-${PREFIX}_${START_YEAR1}${START_MONTH1}${START_DAY1}}
else
    START_MONTH1=$(($START_MONTH0 + 1 ))
    if [ $START_MONTH1 -gt 12 ];then
        START_YEAR1=$(($START_YEAR0 + 1 ))
        START_MONTH1=$(($START_MONTH1 - 12 ))
    else
        START_YEAR1=$START_YEAR0
    fi
    START_DAY1=$START_DAY0
    START_MONTH1=$(printf '%2.2d' $START_MONTH1 )
    START_DAY1=$(printf '%2.2d' $START_DAY1 )
    ENSEMBLE_PREFIX1=${ENSEMBLE_PREFIX:-${PREFIX}_${START_YEAR0}${START_MONTH0}${START_DAY0}}
fi
CASE1=${ENSEMBLE_PREFIX1}_${MEMBERTAG}${MEM01}
if [ ! -e $CASESROOT/${ENSEMBLE_PREFIX1}/${CASE1} ]
then
  echo Template case $CASE1 does not exist. Please use create_template.sh to create.  
  exit
fi
for MEMBER in `seq -w $MEM01 $(($MEM01+$NMEMBER-1))` ; do


  CASE=${ENSEMBLE_PREFIX1}_${MEMBERTAG}${MEMBER}
  if [ $CASE == $CASE1 ] 
  then 
    echo SKIP EXISTING TEMPLATE $CASE1 
    continue 
  fi   
  echo ++ PREPARE CASE $CASE 
 
  echo ++ REMOVE OLD CASE 
  CASEROOT=$CASESROOT/$ENSEMBLE_PREFIX1/$CASE
  EXEROOT=$EXESROOT/$ENSEMBLE_PREFIX1/$CASE
  DOUT_S_ROOT=$ARCHIVESROOT/$ENSEMBLE_PREFIX1/$CASE
  for ITEM in $CASEROOT $EXEROOT $DOUT_S_ROOT
  do
    if [ -e $ITEM ]
    then
      if [ $ASK_BEFORE_REMOVE -eq 1 ] 
      then 
        echo "remove existing $ITEM? (y/n)"
        if [ `read line ; echo $line` == "y" ]
        then
          rm -rf $ITEM
        fi
      else
        rm -rf $ITEM
      fi
    fi
  done

  echo ++ CLONE CASE1 $CASE clone.log
  $SCRIPTSROOT/create_clone --clone $CASESROOT/$ENSEMBLE_PREFIX1/$CASE1 --case $CASEROOT >& clone.log

  echo ++ LINK BUILD OBJECTS AND EXECUTABLE FROM CASE1  
  mkdir -p $EXEROOT/run
  cd $EXEROOT
  for ITEM in atm cpl cesm.exe esp glc ice intel lib lnd ocn rof wav
  do
    ln -s  $EXESROOT/$ENSEMBLE_PREFIX1/$CASE1/$ITEM .
  done
  cd run


  echo ++ CONFIGURE CASE setup.log
  cd $CASEROOT

  ## execute script defined in setting file
  eval $PRECASESETUP
  ./xmlchange --id EXEROOT --val $EXEROOT
  ./xmlchange --id DOUT_S_ROOT --val $DOUT_S_ROOT
  if [ -z "$RUN_REFCASE" ] ; then
      ./xmlchange --id RUN_REFCASE --val ${REST_PREFIX}${MEMBER}
  else
      ./xmlchange --id RUN_REFCASE --val ${RUN_REFCASE}
  fi
  ./xmlchange --id GET_REFCASE --val FALSE
  ./xmlchange --id RUNDIR --val $EXEROOT/run  ## for consistant RUNDIR
  if [[ $RUN_TYPE && $RUN_TYPE == "hybrid" ]]
  then
    ./xmlchange --id RUN_TYPE --val hybrid
    ./xmlchange --id RUN_STARTDATE --val ${START_YEAR1}-${START_MONTH1}-${START_DAY1}
  else
    ./xmlchange --id RUN_TYPE --val branch
    ./xmlchange --id RUN_REFDATE --val ${START_YEAR1}-${START_MONTH1}-${START_DAY1}
  fi 
  ./case.setup >& setup.log

  echo ++ MODIFY RESTART PATH IN NAMELISTS
  if [[ $RUN_TYPE && $RUN_TYPE == "hybrid" ]]
  then
    REST_PATH=$REST_PATH_LOCAL/${REST_PREFIX}${REF_MEMBER}/${REF_YEAR}-${REF_MONTH}-${REF_DAY}-00000
    if [ ! -e $REST_PATH ]
    then
      REST_PATH=$REST_PATH_LOCAL/${REST_PREFIX}${REF_MEMBER}/${REF_YEAR}-${REF_MONTH}-${REF_DAY}_${MEMBERTAG}$MEMBER
      if [ ! -e $REST_PATH ]
      then
        echo 'cannot locate restart data' 
        exit
      fi
    fi
    sed -i "s%${REST_PREFIX}${MEM01}.cice.r.${REF_YEAR1}-${REF_MONTH1}-${REF_DAY1}%${REST_PREFIX}${REF_MEMBER}.cice.r.${REF_YEAR}-${REF_MONTH}-${REF_DAY}%" Buildconf/cice.buildnml.csh
    sed -i "s%${REST_PREFIX}${MEM01}.clm2.r.${REF_YEAR1}-${REF_MONTH1}-${REF_DAY1}%${REST_PREFIX}${REF_MEMBER}.clm2.r.${REF_YEAR}-${REF_MONTH}-${REF_DAY}%" Buildconf/clm.buildnml.csh
    #Fanf: typically ifile does not have the same date than restart file
    ifile=$(basename `find $REST_PATH/ -name '*cam2.i*'`)
    sed -i s/ncdata.*/ncdata = ${ifile} /g Buildconf/cam.input_data_list
  else
    REST_PATH=$REST_PATH_LOCAL/${REST_PREFIX}${MEMBER}/${START_YEAR1}-${START_MONTH1}-${START_DAY1}-00000
    if [ ! -e "$REST_PATH" ] ; then
        REST_PATH="$REST_PATH_LOCAL/${REST_PREFIX}${MEMBER}/rest/${START_YEAR1}-${START_MONTH1}-${START_DAY1}-00000"
    fi
  fi 

  echo ++ DUMMY BUILD $CASE, build.log
  ./xmlchange --id BUILD_COMPLETE --val TRUE 

  if ((${ANOM_CPL})) ; then
     cp `dirname $SCRIPTPATH`/use_cases/ANOM_CPL/src.micom/* SourceMods/src.micom/
     cp `dirname $SCRIPTPATH`/use_cases/ANOM_CPL/src.drv/*   SourceMods/src.drv/
     cp `dirname $SCRIPTPATH`/use_cases/ANOM_CPL/src.share/* SourceMods/src.share/
     sed -i '/SRF_SST/ a\  SRF_SST_ATM  = 2,   2,\ '       Buildconf/micom.buildnml.csh
     sed -i '/SRF_SURFLX/ a\  SRF_SURFLX_ATM  = 2,   2,\ ' Buildconf/micom.buildnml.csh
     sed -i '/SRF_UICE/ a\  SRF_TAUX_ATM = 2,   2,\ '      Buildconf/micom.buildnml.csh
     sed -i '/SRF_TAUX_ATM/ a\  SRF_TAUY_ATM = 2,   2,\ '  Buildconf/micom.buildnml.csh
  fi

  #./case.build >& build.log
  ./preview_namelists

  echo ++ STAGE RESTART DATA 
  cd $EXEROOT/run 
  if [ ! -z "$(ls $REST_PATH/*.nc 2> /dev/null)" ] ; then
      ln -sf $REST_PATH/*.nc . 
  fi
  if [ ! -z "$(ls $REST_PATH/*.nc.gz 2> /dev/null)" ] ; then
      for i in $REST_PATH/*.nc.gz ; do
        ofn=$(basename "$i")
        ofn=${ofn%.gz}
        gunzip -c "$i" > "$ofn"
      done
  fi
  cp -f $REST_PATH/rpointer* . 
  if [ -z "$(ls *.nc)" ] ; then
      echo "Restart files link failed. please check REST_PATH: "
      echo "$REST_PATH"
      exit 1
  fi
  echo ++ CREATE SUBDIRS FOR TIMING AND SHORT TERM ARCHIVING
  mkdir -p timing/checkpoints $WORK/archive/$ENSEMBLE_PREFIX1

done ; done ; done 
echo + END LOOP OVER START DATES AND MEMBERS 

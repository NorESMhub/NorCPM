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

MEM01=${MEMBER1:-001}
echo + CHECK THAT TEMPLATE CASE EXISTS
ENSEMBLE_PREFIX1=${ENSEMBLE_PREFIX:-${PREFIX}_${START_YEAR1}${START_MONTH1}${START_DAY1}} 
CASE1=${ENSEMBLE_PREFIX1}_${MEMBERTAG}${MEM01}
if [ ! -e $CASESROOT/${ENSEMBLE_PREFIX1}/${CASE1} ]
then
  echo Template case $CASE1 does not exist. Please use create_template.sh to create.  
  exit
fi

echo + BEGIN LOOP OVER START DATES AND MEMBERS 
for START_YEAR in $START_YEARS
do
for START_MONTH in $START_MONTHS
do
for START_DAY in $START_DAYS
do
for MEMBER in `seq -w $MEM01 $(($MEM01+$NMEMBER-1))`
do

  echo ++ pick reference date
  COUNT=0
  for YEAR in $REF_YEARS
  do
  for MONTH in $REF_MONTHS
  do
  for DAY in $REF_DAYS
  do
    COUNT=`expr $COUNT + 1`
    if [ $COUNT -eq 1 ] 
    then 
      REF_YEAR=$YEAR
      REF_MONTH=$MONTH
      REF_DAY=$DAY
      REF_YEAR1=$YEAR
      REF_MONTH1=$MONTH
      REF_DAY1=$DAY
    fi  
    if [ $COUNT -eq $MEMBER ] 
    then 
      REF_YEAR=$YEAR
      REF_MONTH=$MONTH
      REF_DAY=$DAY
    fi
  done ; done ; done  


  ENSEMBLE_PREFIX=${ENSEMBLE_PREFIX:-${PREFIX}_${START_YEAR}${START_MONTH}${START_DAY}}
  CASE=${ENSEMBLE_PREFIX}_${MEMBERTAG}${MEMBER}
  if [ $CASE == $CASE1 ] 
  then 
    echo SKIP EXISTING TEMPLATE $CASE1 
    continue 
  fi   
  echo ++ PREPARE CASE $CASE 
 
  echo ++ REMOVE OLD CASE 
  CASEROOT=$CASESROOT/$ENSEMBLE_PREFIX/$CASE
  EXEROOT=$EXESROOT/$ENSEMBLE_PREFIX/$CASE
  DOUT_S_ROOT=$ARCHIVESROOT/$ENSEMBLE_PREFIX/$CASE
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

  echo ++ CLONE CASE1 CASE
  if [ "$CESMVERSION" == '2' ];then
      $SCRIPTSROOT/create_clone --clone $CASESROOT/$ENSEMBLE_PREFIX1/$CASE1 --case $CASEROOT
  else
      $SCRIPTSROOT/create_clone -clone $CASESROOT/$ENSEMBLE_PREFIX1/$CASE1 -case $CASEROOT
  fi

  echo ++ LINK BUILD OBJECTS AND EXECUTABLE FROM CASE1  
  mkdir -p $EXEROOT/run
  cd $EXEROOT
  if [ "$CESMVERSION" == '2' ];then
      for ITEM in atm cpl cesm.exe esp glc ice intel lib lnd ocn rof wav
      do
        ln -s  $EXESROOT/$ENSEMBLE_PREFIX1/$CASE1/$ITEM .
      done
  else
      for ITEM in atm cpl ccsm csm_share glc ice ocn pio lib
      do
        ln -s  $EXESROOT/$ENSEMBLE_PREFIX1/$CASE1/$ITEM .
      done
  fi
  cd run
  if [ "$CESMVERSION" == '2' ];then
      ln -s $EXESROOT/$ENSEMBLE_PREFIX1/$CASE1/run/cesm.exe . 
  else
      ln -s $EXESROOT/$ENSEMBLE_PREFIX1/$CASE1/run/ccsm.exe . 
  fi


  echo ++ CONFIGURE CASE 
  cd $CASEROOT

  if [ "$CESMVERSION" == '2' ];then
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
  else
      ./xmlchange -file env_build.xml -id EXEROOT -val $EXEROOT
      ./xmlchange -file env_run.xml -id DOUT_S_ROOT -val $DOUT_S_ROOT
      ./xmlchange -file env_conf.xml -id RUN_REFCASE -val ${REST_PREFIX}${MEMBER}
      ./xmlchange -file env_conf.xml -id GET_REFCASE -val FALSE
  fi
  if [[ $RUN_TYPE && $RUN_TYPE == "hybrid" ]]
  then
    if [ "$CESMVERSION" == '2' ];then
        ./xmlchange --id RUN_TYPE --val hybrid
        ./xmlchange --id RUN_REFDATE --val ${REF_YEAR}-${REF_MONTH}-${REF_DAY}
        ./xmlchange --id RUN_STARTDATE --val ${START_YEAR1}-${START_MONTH1}-${START_DAY1}
    else
        ./xmlchange -file env_conf.xml -id RUN_TYPE -val hybrid
        ./xmlchange -file env_conf.xml -id RUN_REFDATE -val ${REF_YEAR}-${REF_MONTH}-${REF_DAY}
        ./xmlchange -file env_conf.xml -id RUN_STARTDATE -val ${START_YEAR1}-${START_MONTH1}-${START_DAY1}
    fi
  else
    if [ "$CESMVERSION" == '2' ];then
        #./xmlchange --id BRNCH_RETAIN_CASENAME --val TRUE
        ./xmlchange --id RUN_TYPE --val branch
        ./xmlchange --id RUN_REFDATE --val ${START_YEAR}-${START_MONTH}-${START_DAY}
    else
        ./xmlchange -file env_conf.xml -id BRNCH_RETAIN_CASENAME -val TRUE
        ./xmlchange -file env_conf.xml -id RUN_TYPE -val branch
        ./xmlchange -file env_conf.xml -id RUN_REFDATE -val ${START_YEAR}-${START_MONTH}-${START_DAY}
    fi
  fi 
  if [ "$CESMVERSION" == '2' ];then
      ./case.setup
  else
      ./configure -case
  fi

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
    if [ "$CESMVERSION" == '2' ];then
        sed -i s/ncdata.*/ncdata = ${ifile} /g Buildconf/cam.input_data_list
    else
        sed -i s/"ncdata".*/"ncdata = ${ifile} "/g Buildconf/cam.input_data_list
        sed -i s/"ncdata".*/"ncdata     = '${ifile}'"/g Buildconf/cam.buildnml.csh
        sed -i s/"ncdata".*/"ncdata  = '${ifile}'"/g Buildconf/camconf/ccsm_namelist
    fi
  else
    REST_PATH=$REST_PATH_LOCAL/${REST_PREFIX}${MEMBER}/${START_YEAR}-${START_MONTH}-${START_DAY}-00000
  if [ ! -e "$REST_PATH" ] ; then
      REST_PATH="$REST_PATH_LOCAL/${REST_PREFIX}${MEMBER}/rest/${START_YEAR1}-${START_MONTH1}-${START_DAY1}-00000"
  fi
    if [ "$CESMVERSION" == '2' ];then  
        #sed -i "s%${ENSEMBLE_PREFIX1}/${CASE1}/run/${REST_PREFIX}${MEM01}.cam2.r.${START_YEAR1}-${START_MONTH1}-${START_DAY1}%${ENSEMBLE_PREFIX}/${CASE}/run/${REST_PREFIX}${MEMBER}.cam2.r.${START_YEAR}-${START_MONTH}-${START_DAY}%" Buildconf/cam.buildnml.csh 
        ##sed -i "s%${REST_PREFIX}${MEM01}.cice.r.${START_YEAR1}-${START_MONTH1}-${START_DAY1}%${REST_PREFIX}${MEMBER}.cice.r.${START_YEAR}-${START_MONTH}-${START_DAY}%" Buildconf/cice.buildnml.csh
        ##sed -i "s%${REST_PREFIX}${MEM01}.clm2.r.${START_YEAR1}-${START_MONTH1}-${START_DAY1}%${REST_PREFIX}${MEMBER}.clm2.r.${START_YEAR}-${START_MONTH}-${START_DAY}%" Buildconf/clm.buildnml.csh
        echo pass for NorESM2
    else
        sed -i "s%${ENSEMBLE_PREFIX1}/${CASE1}/run/${REST_PREFIX}${MEM01}.cam2.r.${START_YEAR1}-${START_MONTH1}-${START_DAY1}%${ENSEMBLE_PREFIX}/${CASE}/run/${REST_PREFIX}${MEMBER}.cam2.r.${START_YEAR}-${START_MONTH}-${START_DAY}%" Buildconf/cam.buildnml.csh 
        sed -i "s%${REST_PREFIX}${MEM01}.cice.r.${START_YEAR1}-${START_MONTH1}-${START_DAY1}%${REST_PREFIX}${MEMBER}.cice.r.${START_YEAR}-${START_MONTH}-${START_DAY}%" Buildconf/cice.buildnml.csh
        sed -i "s%${REST_PREFIX}${MEM01}.clm2.r.${START_YEAR1}-${START_MONTH1}-${START_DAY1}%${REST_PREFIX}${MEMBER}.clm2.r.${START_YEAR}-${START_MONTH}-${START_DAY}%" Buildconf/clm.buildnml.csh
    fi
    #IB: why is this line here?  $REST_PATH_LOCAL/${REST_PREFIX}${MEMBER}/${START_YEAR}-${START_MONTH}-${START_DAY}-00000/
  fi 
  if [ "$CESMVERSION" == '2' ];then  
      echo pass for NorESM2
  else
      sed -i "s/start_ymd      =.*/start_ymd      = ${START_YEAR}${START_MONTH}${START_DAY}/" Buildconf/cpl.buildnml.csh 
  fi

  echo ++ DUMMY BUILD
  if [ "$CESMVERSION" == '2' ];then
      ./xmlchange --id BUILD_COMPLETE --val TRUE 
      ##sed -i '/source $CASETOOLS\/ccsm_buildexe/d' ${CASE}.${MACH}.build
  else
      ./xmlchange -file env_build.xml -id BUILD_COMPLETE -val TRUE 
      sed -i '/source $CASETOOLS\/ccsm_buildexe/d' ${CASE}.${MACH}.build
  fi
  if ((${ANOM_CPL})) ; then
     cp `dirname $SCRIPTPATH`/use_cases/ANOM_CPL/src.micom/* SourceMods/src.micom/
     cp `dirname $SCRIPTPATH`/use_cases/ANOM_CPL/src.drv/*   SourceMods/src.drv/
     cp `dirname $SCRIPTPATH`/use_cases/ANOM_CPL/src.share/* SourceMods/src.share/
     sed -i '/SRF_SST/ a\  SRF_SST_ATM  = 2,   2,\ '       Buildconf/micom.buildnml.csh
     sed -i '/SRF_SURFLX/ a\  SRF_SURFLX_ATM  = 2,   2,\ ' Buildconf/micom.buildnml.csh
     sed -i '/SRF_UICE/ a\  SRF_TAUX_ATM = 2,   2,\ '      Buildconf/micom.buildnml.csh
     sed -i '/SRF_TAUX_ATM/ a\  SRF_TAUY_ATM = 2,   2,\ '  Buildconf/micom.buildnml.csh
  fi
  if [ "$CESMVERSION" == '2' ];then
      ./case.build 
  else
      ./${CASE}.${MACH}.build 
  fi

  echo ++ STAGE RESTART DATA 
  cd $EXEROOT/run 
  ln -sf $REST_PATH/*nc . 
  cp -f $REST_PATH/rpointer* .  
  echo ++ CREATE SUBDIRS FOR TIMING AND SHORT TERM ARCHIVING
  mkdir -p timing/checkpoints $WORK/archive/$ENSEMBLE_PREFIX

done ; done ; done ; done 
echo + END LOOP OVER START DATES AND MEMBERS 

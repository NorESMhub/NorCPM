#!/bin/sh -e

echo "USAGE: ./`basename $0` <path to settings file>" 

echo "EXAMPLE: ./`basename $0` use_cases/predictiontest.in" 

echo "PURPOSE: sets up a case template for the creation of NorCPM ensembles" 

echo + READING SETTINGS FROM FILE 
if [ ! $1 ]
then
  echo cannot read settings from file $1 
  exit
fi
. $1


echo + REMOVE OLD TEMPLATE 
ENSEMBLE_PREFIX=${ENSEMBLE_PREFIX:-${PREFIX}_${START_YEAR1}${START_MONTH1}${START_DAY1}}
logfile=`basename $0`_${ENSEMBLE_PREFIX}.log
CASE=${ENSEMBLE_PREFIX}_${MEMBERTAG}${MEMBER1:-001}
CASEROOT=$CASESROOT/$ENSEMBLE_PREFIX/$CASE 
EXEROOT=$EXESROOT/$ENSEMBLE_PREFIX/$CASE
RUNDIR=$EXEROOT/run   ## for consistant with create_ensemble.sh
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

echo + CREATE CASES DIRECTORY 
mkdir -p $CASESROOT/$ENSEMBLE_PREFIX $EXESROOT/$ENSEMBLE_PREFIX $ARCHIVESROOT/$ENSEMBLE_PREFIX 

echo + CREATE CASE1 CASE, logfile: ${logfile}
if [ $CESMVERSION == '2' ]; then
    echo $SCRIPTSROOT/create_newcase --case $CASEROOT --compset $COMPSET --res $RES --mach $MACH --project $ACCOUNT --run-unsupported
    $SCRIPTSROOT/create_newcase --case $CASEROOT --compset $COMPSET --res $RES --mach $MACH --project $ACCOUNT --run-unsupported  >& ${logfile}
    #$SCRIPTSROOT/create_newcase --case $CASEROOT --compset $COMPSET --res $RES --mach $MACH --pecount $PECOUNT --project $ACCOUNT --run-unsupported -q short   ## for testing
else
    $SCRIPTSROOT/create_newcase -case $CASEROOT -compset $COMPSET -res $RES -mach $MACH -pecount $PECOUNT
fi

echo + SET INITIALISATION 
cd $CASEROOT
if [ $CESMVERSION == '2' ]; then
    ./xmlchange --id EXEROOT --val $EXEROOT 
    ./xmlchange --id DOUT_S_ROOT --val $DOUT_S_ROOT
    ./xmlchange --id RUNDIR --val $RUNDIR
else
    ./xmlchange -file env_build.xml -id EXEROOT -val $EXEROOT 
    ./xmlchange -file env_run.xml -id DOUT_S_ROOT -val $DOUT_S_ROOT
fi
if [[ $RUN_TYPE && $RUN_TYPE == "hybrid" ]] 
then 
## not changed for NorESM2 yet
  REST_PATH=$REST_PATH_LOCAL/${REST_PREFIX}${REF_MEMBER}/${REF_YEAR1}-${REF_MONTH1}-${REF_DAY1}-00000
  if [ ! -e $REST_PATH ]
  then
    REST_PATH=$REST_PATH_LOCAL/${REST_PREFIX}${REF_MEMBER}/${REF_YEAR1}-${REF_MONTH1}-${REF_DAY1}_mem${MEMBER1:-001}
    if [ ! -e $REST_PATH ]
    then
      echo 'cannot locate restart data' 
      exit
    fi
  fi
  if [ $CESMVERSION == '2' ]; then
      ./xmlchange --id RUN_TYPE --val hybrid
      ./xmlchange --id RUN_REFDATE --val ${REF_YEAR1}-${REF_MONTH1}-${REF_DAY1}
      ./xmlchange --id RUN_STARTDATE --val ${START_YEAR1}-${START_MONTH1}-${START_DAY1}
  else
      ./xmlchange -file env_conf.xml -id RUN_TYPE -val hybrid
      ./xmlchange -file env_conf.xml -id RUN_REFDATE -val ${REF_YEAR1}-${REF_MONTH1}-${REF_DAY1}
      ./xmlchange -file env_conf.xml -id RUN_STARTDATE -val ${START_YEAR1}-${START_MONTH1}-${START_DAY1}
  fi
else
  REST_PATH=$REST_PATH_LOCAL/${REST_PREFIX}${MEMBER1:-01}/${START_YEAR1}-${START_MONTH1}-${START_DAY1}-00000
  if [ ! -e "$REST_PATH" ] ; then
      REST_PATH="$REST_PATH_LOCAL/${REST_PREFIX}${MEMBER1:-01}/rest/${START_YEAR1}-${START_MONTH1}-${START_DAY1}-00000"
  fi
  if [ $CESMVERSION == '2' ]; then
      ##need be check## ./xmlchange --id BRNCH_RETAIN_CASENAME --val TRUE
      ./xmlchange --id RUN_TYPE --val branch
      ./xmlchange --id RUN_REFDATE --val ${START_YEAR1}-${START_MONTH1}-${START_DAY1}
  else
      ./xmlchange -file env_conf.xml -id BRNCH_RETAIN_CASENAME -val TRUE
      ./xmlchange -file env_conf.xml -id RUN_TYPE -val branch
      ./xmlchange -file env_conf.xml -id RUN_REFDATE -val ${START_YEAR1}-${START_MONTH1}-${START_DAY1}
  fi
fi
if [ $CESMVERSION == '2' ]; then
    if [ -z "$RUN_REFCASE" ] ; then
        ./xmlchange --id RUN_REFCASE --val ${REST_PREFIX}${MEMBER1:-001}
    else
        ./xmlchange --id RUN_REFCASE --val ${RUN_REFCASE}   ## avoid change refcase restart file name
    fi
    ./xmlchange --id GET_REFCASE --val FALSE
else
    ./xmlchange -file env_conf.xml -id RUN_REFCASE -val ${REST_PREFIX}${MEMBER1:-001}
    ./xmlchange -file env_conf.xml -id GET_REFCASE -val FALSE
fi

## execute script defined in setting file
eval $PRECASESETUP
eval $PRECASESETUP001   ## mem001 only

echo + CONFIGURE CASE, logfile: ${logfile}
if [ $CESMVERSION == '2' ]; then
    ./case.setup >& ${logfile}
else
    ./configure -case
fi


echo + BUILD CASE, logfile: ${logfile}
set +e 
if [ $CESMVERSION == '2' ]; then
    ./case.build >& ${logfile}
else
    ./${CASE}.${MACH}.build 
fi
set -e 

echo + STAGE RESTART DATA 
mkdir -p $RUNDIR
cd $RUNDIR
ln -sf $REST_PATH/*nc . 
cp -f $REST_PATH/rpointer* . 

echo + WRITE INFO
echo "A template case has been created in ${CASEROOT}. Any simulation ensembles based on it will inherit the template's output customization as well as its executable."  

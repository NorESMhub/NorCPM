#!/bin/sh

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


if [ -z "$START_YYYYMM" ]; then
    for y in $START_YEARS; do
    for m in $START_MONTHS; do
        mm=$(printf '%2.2d' $m)
        START_YYYYMM="${START_YYYYMM} $y$mm"
    done #START_YEAR0
    done #START_MONTH0
fi
echo $START_YYYYMM

## check all restart files first
toexit=false
for START_YYYYMM0 in $START_YYYYMM; do
START_YEAR0=$(echo $START_YYYYMM0 | cut -c -4)
START_MONTH0=$(echo $START_YYYYMM0 | cut -c 5-)
for START_DAY0 in $START_DAYS; do
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
    for MEMBER in $(seq -w ${MEMBER1:-01} $((${MEMBER1:-01}+$NMEMBER-1))); do
        REST_PATH=$REST_PATH_LOCAL/${REST_PREFIX}${MEMBER}/${START_YEAR1}-${START_MONTH1}-${START_DAY1}-00000
        test -d "$REST_PATH" ||  REST_PATH=$REST_PATH_LOCAL/${REST_PREFIX}${MEMBER}/rest/${START_YEAR1}-${START_MONTH1}-${START_DAY1}-00000
        ok=true
        test -z "$(ls $REST_PATH/*.nc 2>/dev/null)" && test -z "$(ls $REST_PATH/*.nc.gz 2>/dev/null)" && ok=false
        if [ $ok = false ]; then
            echo "$REST_PATH/ restart missing"
            toexit=true
        fi
    done #MEMBER
done #START_DAYS
done #START_YYYYMM
test $toexit = true && exit 1

## start 
for START_YYYYMM0 in $START_YYYYMM; do
START_YEAR0=$(echo $START_YYYYMM0 | cut -c -4)
START_MONTH0=$(echo $START_YYYYMM0 | cut -c 5-)
for START_DAY0 in $START_DAYS; do
    echo + REMOVE OLD TEMPLATE 
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

    logfile=`basename $0`.${ENSEMBLE_PREFIX1}.log
    CASE=${ENSEMBLE_PREFIX1}_${MEMBERTAG}${MEMBER1:-01}
    CASEROOT=$CASESROOT/$ENSEMBLE_PREFIX1/$CASE 
    EXEROOT=$EXESROOT/$ENSEMBLE_PREFIX1/$CASE
    RUNDIR=$EXEROOT/run   ## for consistant with create_ensemble.sh
    DOUT_S_ROOT=$ARCHIVESROOT/$ENSEMBLE_PREFIX1/$CASE 

    for ITEM in $CASEROOT $EXEROOT #$DOUT_S_ROOT 
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
    mkdir -p $CASESROOT/$ENSEMBLE_PREFIX1 $EXESROOT/$ENSEMBLE_PREFIX1 $ARCHIVESROOT/$ENSEMBLE_PREFIX1 

    echo + CREATE CASE1 CASE, logfile: ${logfile}
    $SCRIPTSROOT/create_newcase --case $CASEROOT --compset $COMPSET --res $RES --mach $MACH --project $ACCOUNT  > ${logfile}

    echo + SET INITIALISATION 
    cd $CASEROOT
    ./xmlchange --id EXEROOT --val $EXEROOT 
    ./xmlchange --id DOUT_S_ROOT --val $DOUT_S_ROOT
    ./xmlchange --id RUNDIR --val $RUNDIR

    if [[ $RUN_TYPE && $RUN_TYPE == "hybrid" ]] 
    then 
    ## not changed for NorESM2 yet
      REST_PATH=$REST_PATH_LOCAL/${REST_PREFIX}${REF_MEMBER}/${REF_YEAR1}-${REF_MONTH1}-${REF_DAY1}-00000
      if [ ! -e $REST_PATH ]
      then
        REST_PATH=$REST_PATH_LOCAL/${REST_PREFIX}${REF_MEMBER}/${REF_YEAR1}-${REF_MONTH1}-${REF_DAY1}_mem${MEMBER1:-01}
        if [ ! -e $REST_PATH ]
        then
          echo 'cannot locate restart data' 
          exit
        fi
      fi
      ./xmlchange --id RUN_TYPE --val hybrid
      ./xmlchange --id RUN_REFDATE --val ${REF_YEAR1}-${REF_MONTH1}-${REF_DAY1}
      ./xmlchange --id RUN_STARTDATE --val ${START_YEAR1}-${START_MONTH1}-${START_DAY1}
    else
      REST_PATH=$REST_PATH_LOCAL/${REST_PREFIX}${MEMBER1:-01}/${START_YEAR1}-${START_MONTH1}-${START_DAY1}-00000
      if [ ! -e "$REST_PATH" ] ; then
          REST_PATH="$REST_PATH_LOCAL/${REST_PREFIX}${MEMBER1:-01}/rest/${START_YEAR1}-${START_MONTH1}-${START_DAY1}-00000"
      fi
      ##need be check## ./xmlchange --id BRNCH_RETAIN_CASENAME --val TRUE
      ./xmlchange --id RUN_TYPE --val branch
      ./xmlchange --id RUN_REFDATE --val ${START_YEAR1}-${START_MONTH1}-${START_DAY1}
    fi
    if [ -z "$RUN_REFCASE" ] ; then
        ./xmlchange --id RUN_REFCASE --val ${REST_PREFIX}${MEMBER1:-01}
    else
        ./xmlchange --id RUN_REFCASE --val ${RUN_REFCASE}   ## avoid change refcase restart file name
    fi
    ./xmlchange --id GET_REFCASE --val FALSE

    ## execute script defined in setting file
    eval $PRECASESETUP
    eval $PRECASESETUP01   ## mem01 only

    echo + CONFIGURE CASE, logfile: ${logfile}
    ./case.setup >& ${logfile}

    echo + BUILD CASE, logfile: ${logfile}
    set +e 
    ./case.build >& ${logfile}
    set -e 

    echo + STAGE RESTART DATA 
    mkdir -p $RUNDIR
    cd $RUNDIR
    if [ ! -z "$(ls $REST_PATH/*.nc 2>/dev/null)" ] ; then
        ln -sf $REST_PATH/*.nc . 
    elif [ ! -z "$(ls $REST_PATH/*.nc.gz 2>/dev/null)" ] ; then
        for i in $REST_PATH/*.nc.gz ; do
            ofn=$(basename "$i")
            ofn=${ofn%.gz}
            gunzip -c "$i" > "$ofn"
        done
    fi
    cp -f $REST_PATH/rpointer* . 
    if [ -z "$(ls *.i.*.nc rpointer* 2> /dev/null)" ] ; then
        echo "Restart files link failed. please check REST_PATH: "
        echo "$REST_PATH"
        exit 1
    fi

    echo + WRITE INFO
    echo "A template case has been created in ${CASEROOT}. Any simulation ensembles based on it will inherit the template's output customization as well as its executable."  

done #START_DAY0
done #START_YYYYMM

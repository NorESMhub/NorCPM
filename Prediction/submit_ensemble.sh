#!/bin/sh -e

echo "USAGE: ./`basename $0` <path to settings file>" 

echo "EXAMPLE: ./`basename $0` use_cases/predictiontest.in" 

echo "PURPOSE: submits prediction ensemble to queue" 

echo + READING SETTINGS FROM FILE 
if [ ! $1 ]
then
  echo cannot read settings file $1 
  exit
fi
. $1


MEM01=${MEMBER1:-01}
if [ -z "$START_YYYYMM" ]; then
    for y in $START_YEARS; do
    for m in $START_MONTHS; do
        mm=$(printf '%2.2d' $m)
        START_YYYYMM="${START_YYYYMM} $y$mm"
    done #START_YEAR0
    done #START_MONTH0
fi

echo + CHECK IF SIMULATION SHOULD BE CONTINUED 
for START_YYYYMM0 in $START_YYYYMM; do
START_YEAR0=$(echo $START_YYYYMM0 | cut -c -4)
START_MONTH0=$(echo $START_YYYYMM0 | cut -c 5-)
for START_DAY0 in $START_DAYS ; do

    if [ -z "$RESTART_NOT_DA" ] ;then
        START_YEAR1=$START_YEAR0
        START_MONTH1=$START_MONTH0
        START_DAY1=$START_DAY0
        ENSEMBLE_PREFIX=${ENSEMBLE_PREFIX:-${PREFIX}_${START_YEAR1}${START_MONTH1}${START_DAY1}}
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
        ENSEMBLE_PREFIX=${PREFIX}_${START_YEAR0}${START_MONTH0}${START_DAY0}
    fi
    CASE1=${ENSEMBLE_PREFIX}_${MEMBERTAG}${MEM01}
    REST_YYYYMMDD1=`head -1 $EXESROOT/$ENSEMBLE_PREFIX/$CASE1/run/rpointer.atm | cut -d. -f4 | cut -d- -f1-3 | sed 's/-//g'`
    if [ "$REST_YYYYMMDD1" == "${START_YEAR1}${START_MONTH1}${START_DAY1}" ] 
    then 
      CONTINUE_RUN=FALSE
    else 
      CONTINUE_RUN=TRUE
      CASE2=${ENSEMBLE_PREFIX}_${MEMBERTAG}$(printf "%2.2d" $(($MEM01 +1)))
      REST_YYYYMMDD2=`head -1 $EXESROOT/$ENSEMBLE_PREFIX/$CASE2/run/rpointer.atm | cut -d. -f4 | cut -d- -f1-3 | sed 's/-//g'`
      if [ ! "$REST_YYYYMMDD1" == "$REST_YYYYMMDD2" ]
      then 
        echo rpointer files of $CASE1 ahead of remaining ensemble. exiting  
      exit 
      fi 
    fi 
    echo ++ CONTINUE_RUN set to $CONTINUE_RUN

    ## set all members to CONTINUE_RUN, and build namelists
    for i in $(seq -w ${MEM01} $((${MEM01}+$NMEMBER-1))) ; do
        ##
        cd "${CASESROOT}/${ENSEMBLE_PREFIX}/${ENSEMBLE_PREFIX}_${MEMBERTAG}${i}"
        echo "${CASESROOT}/${ENSEMBLE_PREFIX}/${ENSEMBLE_PREFIX}_${MEMBERTAG}${i}"
        ./xmlchange CONTINUE_RUN=${CONTINUE_RUN}
        ./xmlchange STOP_N=${STOP_N}
        ./xmlchange STOP_OPTION=${STOP_OPTION}
        ./xmlchange RESUBMIT=${RESUBMIT}
        if [ ! -z "$REST_N" ] ; then
            ./xmlchange REST_N=${REST_N}
        fi
        if [ ! -z "$REST_OPTION" ] ; then
            ./xmlchange REST_OPTION=${REST_OPTION}
        fi 
        ./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=${WALLTIME}
        #./xmlchange --subgroup case.st_archive JOB_WALLCLOCK_TIME='01:00:00'
        ./preview_namelists > namelists_renew.log &
    done
    wait

    ## submit mem01
    echo ++ Submit first member
    cd "${CASESROOT}/${ENSEMBLE_PREFIX}/${ENSEMBLE_PREFIX}_${MEMBERTAG}${MEM01}"
    ./case.submit
    ## get jobid
    jobid=$(./xmlquery --value JOB_IDS| sed -e's/.*case.run:\([0-9]*\).*/\1/')
    ## submit case.st_archive of other members
    #echo ++ Submit st_archive of other members
    #for i in $(seq -w $(($MEM01 +1)) $(($MEM01+$NMEMBER-1))) ; do
        #cd "${CASESROOT}/${ENSEMBLE_PREFIX}/${ENSEMBLE_PREFIX}_${MEMBERTAG}${i}"
        #./xmlchange RESUBMIT=0
        #./case.submit --job case.st_archive --prereq ${jobid}
    #done

    echo ++ Submit done.  $CASE1

done #START_DAY0
done #START_YYYYMM0

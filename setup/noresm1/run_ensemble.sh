#!/bin/sh -evx

. $SETUPROOT/source_settings.sh $*

echo + BEGIN RESTART LOOP 
for RESTART_COUNT in `seq 0 $RESTART`
do 

  echo ++ CHECK IF SIMULATION SHOULD BE CONTINUED
  if [ $CASE1 == `head -1 $EXEROOT1/run/rpointer.atm | cut -d. -f1` ]
  then
    CONTINUE_RUN=TRUE
  else
    CONTINUE_RUN=FALSE
  fi
  echo ++ CONTINUE_RUN set to $CONTINUE_RUN

  echo ++ SET CONTINUE_RUN, STOP_OPTION AND STOP_N
  for MEMBER in `seq -w $MEMBER1 $MEMBERN`
  do 
    CASE=${EXPERIMENT}_$SDATE_PREFIX${SDATE}_$MEMBER_PREFIX$MEMBER
    RELPATH=$EXPERIMENT/${EXPERIMENT}_$SDATE_PREFIX$SDATE/$CASE
    CASEROOT=$CASESROOT/$RELPATH
    EXEROOT=$WORK/noresm/$RELPATH
    cd $CASEROOT
    if [[ $STOP_N_FORECAST && $RESTART_COUNT -eq $RESTART ]]
    then 
      ./xmlchange -file env_run.xml -id STOP_OPTION -val $STOP_OPTION_FORECAST
      ./xmlchange -file env_run.xml -id STOP_N -val $STOP_N_FORECAST
    else
      ./xmlchange -file env_run.xml -id STOP_OPTION -val $STOP_OPTION 
      ./xmlchange -file env_run.xml -id STOP_N -val $STOP_N
    fi
    ./xmlchange -file env_run.xml -id CONTINUE_RUN -val $CONTINUE_RUN 
    cd $EXEROOT/run
    if [[ $STOP_N_FORECAST && $RESTART_COUNT -eq $RESTART ]]
    then 
      sed -i "s/stop_option    =.*/stop_option    ='${STOP_OPTION_FORECAST}'/" drv_in 
      sed -i "s/restart_option =.*/restart_option ='${STOP_OPTION_FORECAST}'/" drv_in 
      sed -i "s/stop_n         =.*/stop_n         =${STOP_N_FORECAST}/" drv_in 
      sed -i "s/restart_n      =.*/restart_n      =${STOP_N_FORECAST}/" drv_in 
    else
      sed -i "s/stop_option    =.*/stop_option    ='${STOP_OPTION}'/" drv_in 
      sed -i "s/restart_option =.*/restart_option ='${STOP_OPTION}'/" drv_in 
      sed -i "s/stop_n         =.*/stop_n         =${STOP_N}/" drv_in 
      sed -i "s/restart_n      =.*/restart_n      =${STOP_N}/" drv_in 
    fi
    if [ $CONTINUE_RUN == "TRUE" ] 
    then 
      sed -i "s/start_type    =.*/start_type    = 'continue'/" drv_in 
    else
    if [[ $RUN_TYPE && $RUN_TYPE == "hybrid" ]] 
      then 
        sed -i "s/start_type    =.*/start_type    = 'startup'/" drv_in 
      else 
        sed -i "s/start_type    =.*/start_type    = 'branch'/" drv_in 
      fi
    fi 
  done
  yr=`head -1 rpointer.atm | cut -d. -f4 | cut -c1-4`
  mm=`head -1 rpointer.atm | cut -d. -f4 | cut -c6-7`
  echo ++ year $yr month $mm

  echo + PERFORM ASSIMILATION UPDATE IF NEEDED 
  if [[ $ASSIMROOT ]]
  then 
    if [[ $SKIP_ASSIM_FIRST && $SKIP_ASSIM_FIRST -eq 1 ]]
    then 
        echo ++ SKIP_ASSIM_FIRST set to 1. will skip assimilation update 
        SKIP_ASSIM_FIRST=0
        SKIP_ASSIM_START=0 
    elif [[ $SKIP_ASSIM_START && $SKIP_ASSIM_START -eq 1 ]] # 1=skip assimilation at start of experiment 
    then
      if [[ $((10#$yr)) -eq $((10#$START_YEAR)) || $((10#$mm)) -eq $((10#$START_MONTH)) ]]
      then
        echo ++ SKIP_ASSIM_START set to 1 and at start of experiment. will skip assimilation update 
        SKIP_ASSIM_FIRST=0
        SKIP_ASSIM_START=0 
      else 
        . $ASSIMROOT/assim_step.sh
      fi
    else 
      . $ASSIMROOT/assim_step.sh
    fi
  fi 
    
  echo + LAUNCH FIRST MEMBER - WILL RUN THE ENTIRE ENSEMBLE
  cd $CASEROOT1 
  ./${CASE1}.${MACH}.run

  echo + SHORT TERM ARCHIVING OF REMAINING MEMBERS 
  N_PARALLEL_STARCHIVE=0 
  MEMBER2=`printf %02d $((10#$MEMBER1+1))`
  for MEMBER in `seq -w $MEMBER2 $MEMBERN`
  do 
    export MACH
    export CASE=${EXPERIMENT}_$SDATE_PREFIX${SDATE}_$MEMBER_PREFIX$MEMBER
    RELPATH=$EXPERIMENT/${EXPERIMENT}_$SDATE_PREFIX$SDATE/$CASE
    export RUNDIR=$WORK/noresm/$RELPATH/run
    export DOUT_S_ROOT=$WORK/archive/$RELPATH
    cd ${RUNDIR}
    $CASEROOT1/Tools/st_archive.sh &
    N_PARALLEL_STARCHIVE=`expr $N_PARALLEL_STARCHIVE + 1` 
    if [ $N_PARALLEL_STARCHIVE -eq $MAX_PARALLEL_STARCHIVE ] 
    then 
      N_PARALLEL_STARCHIVE=0
      wait 
    fi 
  done 
  wait 

  CONTINUE_RUN=TRUE 
done  
echo  END RESTART LOOP 

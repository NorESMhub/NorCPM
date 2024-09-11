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
      ./xmlchange --file env_run.xml --id STOP_OPTION --val $STOP_OPTION_FORECAST
      ./xmlchange --file env_run.xml --id STOP_N --val $STOP_N_FORECAST
    else
      ./xmlchange --file env_run.xml --id STOP_OPTION --val $STOP_OPTION 
      ./xmlchange --file env_run.xml --id STOP_N --val $STOP_N
    fi
    ./xmlchange --file env_run.xml --id CONTINUE_RUN --val $CONTINUE_RUN 
    cd $EXEROOT/run
    mkdir -p timing/checkpoints
    if [[ $STOP_N_FORECAST && $RESTART_COUNT -eq $RESTART ]]
    then 
      sed -i "s/stop_option .*/stop_option    ='${STOP_OPTION_FORECAST}'/" drv_in 
      sed -i "s/restart_option .*/restart_option ='${STOP_OPTION_FORECAST}'/" drv_in 
      sed -i "s/stop_n .*/stop_n         =${STOP_N_FORECAST}/" drv_in 
      sed -i "s/restart_n .*/restart_n      =${STOP_N_FORECAST}/" drv_in 
    else
      sed -i "s/stop_option .*/stop_option    ='${STOP_OPTION}'/" drv_in 
      sed -i "s/restart_option .*/restart_option ='${STOP_OPTION}'/" drv_in 
      sed -i "s/stop_n .*/stop_n         =${STOP_N}/" drv_in 
      sed -i "s/restart_n .*/restart_n      =${STOP_N}/" drv_in 
    fi
    if [ $CONTINUE_RUN == "TRUE" ] 
    then 
      sed -i "s/start_type .*/start_type    = 'continue'/" drv_in 
    else
    if [[ $RUN_TYPE && $RUN_TYPE == "hybrid" ]] 
      then 
        sed -i "s/start_type .*/start_type    = 'startup'/" drv_in 
      else 
        sed -i "s/start_type .*/start_type    = 'branch'/" drv_in 
      fi
    fi 
  done
  yr=`head -1 rpointer.atm | cut -d. -f4 | cut -c1-4`
  mm=`head -1 rpointer.atm | cut -d. -f4 | cut -c6-7`
  echo ++ year $yr month $mm

  echo + LAUNCH ASSIMILATION SCRIPT AS CHILD PROCESS IN BACKGROUND 
  if [[ $ASSIMROOT ]]
  then
    rm -f $ANALYSISROOT/NORESM_FINISHED
    $ASSIMROOT/assim_step.sh $* & 
  fi  
    
  echo + LAUNCH FIRST MEMBER - WILL RUN THE ENTIRE ENSEMBLE
  cd $CASEROOT1 
  scontrol show hostname $SLURM_NODELIST > hostfile 
  echo EXEROOT1=$EXEROOT1
  tail -$NODES_NORESM hostfile > $EXEROOT1/run/hostfile_noresm 
  if [[ $ASSIMROOT && $NODES_TOTAL -gt $NODES_NORESM ]] 
  then 
    NODES_DA=$((NODES_TOTAL-NODES_NORESM))
    head -$((NODES_TOTAL-NODES_NORESM)) hostfile > $ANALYSISROOT/hostfile_da 
  fi  
  sed -i -e "s%<executable>srun.*%<executable>srun -n $NTASKS_NORESM -N $NODES_NORESM -F hostfile_noresm </executable>%" env_mach_specific.xml 
  ./case.submit --no-batch
  while true
  do
    sleep 60 
    [[ `tail -2 CaseStatus | head -1 | grep "submit success" | wc -l ` -eq 1 ]] && break
    [[ `tail -5 CaseStatus | grep error | wc -l ` -ge 1 ]] && exit 0 
  done   
  [[ $ASSIMROOT ]] && touch $ANALYSISROOT/NORESM_FINISHED   
  wait

  CONTINUE_RUN=TRUE 
done  
echo  END RESTART LOOP 

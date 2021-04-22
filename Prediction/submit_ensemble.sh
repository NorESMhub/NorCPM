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
## WORK should be set in $1
#if [ $MACH == "fram" ]
#then
#  WORK=/cluster/work/users/$USER
#else
#  WORK=/work/$USER
#fi


echo + CHECK IF SIMULATION SHOULD BE CONTINUED 
MEM001=${MEMBER1:-001}
ENSEMBLE_PREFIX1=${ENSEMBLE_PREFIX:-${PREFIX}_${START_YEAR1}${START_MONTH1}${START_DAY1}}
CASE1=${ENSEMBLE_PREFIX1}_${MEMBERTAG}${MEM001}
REST_YYYYMMDD1=`head -1 $EXESROOT/$ENSEMBLE_PREFIX1/$CASE1/run/rpointer.atm | cut -d. -f4 | cut -d- -f1-3 | sed 's/-//g'`
if [ "$REST_YYYYMMDD1" == "${START_YEAR1}${START_MONTH1}${START_DAY1}" ] 
then 
  CONTINUE_RUN=FALSE
else 
  CONTINUE_RUN=TRUE
  CASE2=${ENSEMBLE_PREFIX1}_${MEMBERTAG}$(printf "%3.3d" $(($MEM001 +1)))
  REST_YYYYMMDD2=`head -1 $EXESROOT/$ENSEMBLE_PREFIX1/$CASE2/run/rpointer.atm | cut -d. -f4 | cut -d- -f1-3 | sed 's/-//g'`
  if [ ! "$REST_YYYYMMDD1" == "$REST_YYYYMMDD2" ]
  then 
    echo rpointer files of $CASE1 ahead of remaining ensemble. exiting  
  exit 
  fi 
fi 
echo ++ CONTINUE_RUN set to $CONTINUE_RUN

if [ $CESMVERSION == '2' ]; then   ## much differences in CESM2
    ## set all members to CONTINUE_RUN, and build namelists
    for i in $(seq -w ${MEM001} $((${MEM001}+$NMEMBER-1))) ; do
        ##
        cd "${CASESROOT}/${ENSEMBLE_PREFIX1}/${ENSEMBLE_PREFIX1}_${MEMBERTAG}${i}"
        echo "${CASESROOT}/${ENSEMBLE_PREFIX1}/${ENSEMBLE_PREFIX1}_${MEMBERTAG}${i}"
        ./xmlchange CONTINUE_RUN=${CONTINUE_RUN}
        ./xmlchange STOP_N=${STOP_N}
        ./xmlchange STOP_OPTION=${STOP_OPTION}
        if [ ! -z "$REST_N" ] ; then
            ./xmlchange REST_N=${REST_N}
        fi
        if [ ! -z "$REST_OPTION" ] ; then
            ./xmlchange REST_OPTION=${REST_OPTION}
        fi 
        ./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=${WALLTIME}
        #./xmlchange --subgroup case.st_archive JOB_WALLCLOCK_TIME='01:00:00'
        ./preview_namelists
    done

    ## submit mem001
    echo ++ Submit first member
    cd "${CASESROOT}/${ENSEMBLE_PREFIX1}/${ENSEMBLE_PREFIX1}_${MEMBERTAG}${MEM001}"
    ./case.submit
    ## get jobid
    jobid=$(./xmlquery --value JOB_IDS| sed -e's/.*case.run:\([0-9]*\).*/\1/')
    ## submit case.st_archive of other members
    echo ++ Submit st_archive of other members
    for i in $(seq -w $(($MEM001 +1)) $(($MEM001+$NMEMBER-1))) ; do
        ii=$(printf "%3.3d" ${i})
        cd "${CASESROOT}/${ENSEMBLE_PREFIX1}/${ENSEMBLE_PREFIX1}_${MEMBERTAG}${ii}"
        ./xmlchange RESUBMIT=0
        ./case.submit --job case.st_archive --prereq ${jobid}
    done

echo ++ Submit done.
    exit 0
fi

## Following line is for NorESM1. Pending for remove.

echo + DETERMINE PES NUMBER FOR ENSEMBLE 
if [ `echo $MACH | cut -d_ -f1` == "hexagon" ] 
then 
  MPPWIDTHOLD=`grep mppwidth $CASESROOT/$ENSEMBLE_PREFIX1/$CASE1/${CASE1}.${MACH}.run | cut -d"=" -f2`
  MPPWIDTHNEW=`expr $MPPWIDTHOLD \* $NMEMBER` 
  PBS_PES_SPECS="#PBS -l mppwidth="$MPPWIDTHNEW
elif [ `echo $MACH | cut -d_ -f1` == "vilje" ] 
then
  SELECTOLD=`grep select $CASESROOT/$ENSEMBLE_PREFIX1/$CASE1/${CASE1}.${MACH}.run | cut -d"=" -f2 | cut -d":" -f1`
  SELECTNEW=`expr $SELECTOLD \* $NMEMBER` 
  MPPWIDTHOLD=`expr $SELECTOLD \* 16` 
  MPPWIDTHNEW=`expr $SELECTNEW \* 16` 
  PBS_PES_SPECS="#PBS -l select=${SELECTNEW}:ncpus=32:mpiprocs=16:ompthreads=1"
else 
  MPPWIDTHOLD=`grep "\-ntasks" $CASESROOT/$ENSEMBLE_PREFIX1/$CASE1/${CASE1}.${MACH}.run | cut -d"=" -f2 | cut -d":" -f1`
  MPPWIDTHNEW=`expr $MPPWIDTHOLD \* $NMEMBER` 
  NODESNEW=`expr $MPPWIDTHNEW / 32` 
  if [ $NODESNEW -lt 4 ] 
  then 
    NODESNEW=4
  elif [ `expr $NODESNEW \* 32` -lt $MPPWIDTHNEW ] 
  then
    NODESNEW=`expr $NODESNEW + 1` 
  fi
fi  

echo + WRITE PBS-SCRIPT 
# IMPORTANT: local variables and evaluations in pbs-script have to be escaped 
#            with \$ and \`
PBSSCRIPT=$CASESROOT/$ENSEMBLE_PREFIX1/$CASE1/${PREFIX}.pbs 
SHORT_PREFIX=`echo $PREFIX | head -15c`
if [ $MACH == "fram" ] 
then 
cat <<EOF> $PBSSCRIPT
#!/bin/sh -evx
#SBATCH --account=${ACCOUNT}
#SBATCH --job-name=${SHORT_PREFIX}
#SBATCH --time=${WALLTIME}
#SBATCH --nodes=${NODESNEW}
#SBATCH --ntasks=${MPPWIDTHNEW}
#SBATCH --switches=1
#SBATCH --error=$CASESROOT/$ENSEMBLE_PREFIX1/$CASE1/${PREFIX}.err
#SBATCH --output=$CASESROOT/$ENSEMBLE_PREFIX1/$CASE1/${PREFIX}.log
EOF
else
cat <<EOF> $PBSSCRIPT
#!/bin/sh -evx
#PBS -A ${ACCOUNT}
#PBS -W group_list=noresm
#PBS -N ${SHORT_PREFIX}
${PBS_PES_SPECS}
#PBS -l walltime=${WALLTIME}
#PBS -j oe
#PBS -o $CASESROOT/$ENSEMBLE_PREFIX1/$CASE1/${PREFIX}.log
#PBS -S /bin/sh
EOF
fi 
cat <<EOF>> $PBSSCRIPT

echo + BEGIN LOOP OVER START DATES 
for START_YEAR in `echo $START_YEARS`
do
for START_MONTH in `echo $START_MONTHS`
do
for START_DAY in `echo $START_DAYS`
do

  echo ++ INITIALISE LOCAL CONTINUE_RUN VARIABLE 
  CONTINUE_RUN=$CONTINUE_RUN
  
  echo ++ BEGIN RESTART LOOP 
  for RESTART_COUNT in \`seq 0 $RESTART\`
  do 

    echo +++ SET CONTINUE_RUN, STOP_OPTION AND STOP_N
    ENSEMBLE_PREFIX=${PREFIX}_\${START_YEAR}\${START_MONTH}\${START_DAY} 
    for MEMBER in \`seq -w 001 $NMEMBER\`
    do 
      CASE=\${ENSEMBLE_PREFIX}_${MEMBERTAG}\$MEMBER
      cd $CASESROOT/\${ENSEMBLE_PREFIX}/\${CASE}
      ./xmlchange -file env_run.xml -id STOP_OPTION -val $STOP_OPTION 
      ./xmlchange -file env_run.xml -id STOP_N -val $STOP_N 
      ./xmlchange -file env_run.xml -id CONTINUE_RUN -val \$CONTINUE_RUN 
      cd $WORK/noresm/\${ENSEMBLE_PREFIX}/\${CASE}/run/
      sed -i "s/stop_option    =.*/stop_option    ='${STOP_OPTION}'/" drv_in 
      sed -i "s/restart_option =.*/restart_option ='${STOP_OPTION}'/" drv_in 
      sed -i "s/stop_n         =.*/stop_n         =${STOP_N}/" drv_in 
      sed -i "s/restart_n      =.*/restart_n      =${STOP_N}/" drv_in 
      if [ \$CONTINUE_RUN == "TRUE" ] 
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

    echo +++ LAUNCH FIRST MEMBER 
    CASE=\${ENSEMBLE_PREFIX}_${MEMBERTAG}001 
    cd $CASESROOT/\${ENSEMBLE_PREFIX}/\${CASE} 
    if [ `echo $MACH | cut -d_ -f1` == "hexagon" ] 
    then 
      sed "s/aprun -n ${MPPWIDTHOLD}/aprun -n ${MPPWIDTHNEW}/" \${CASE}.${MACH}.run > \${CASE}.${MACH}.runens 
    elif [ `echo $MACH | cut -d_ -f1` == "vilje" ] 
    then
      sed "s/mpiexec_mpt -stats -n ${MPPWIDTHOLD}/mpiexec_mpt -stats -n ${MPPWIDTHNEW}/" \${CASE}.${MACH}.run > \${CASE}.${MACH}.runens
    else 
      cat \${CASE}.${MACH}.run > \${CASE}.${MACH}.runens
    fi
    chmod +x \${CASE}.${MACH}.runens 
    ./\${CASE}.${MACH}.runens 

    echo +++ SHORT TERM ARCHIVING OF REMAINING MEMBERS 
    N_PARALLEL_STARCHIVE=0 
    for MEMBER in \`seq -w 02 $NMEMBER\`
    do 
      export MACH=$MACH
      export CASE=${PREFIX}_\${START_YEAR}\${START_MONTH}\${START_DAY}_${MEMBERTAG}\$MEMBER
      export RUNDIR=$WORK/noresm/\${ENSEMBLE_PREFIX}/\${CASE}/run
      export DOUT_S_ROOT=$WORK/archive/\${ENSEMBLE_PREFIX}/\${CASE}
      cd \${RUNDIR}
      $CASESROOT/\${ENSEMBLE_PREFIX}/\${CASE}/Tools/st_archive.sh &
      N_PARALLEL_STARCHIVE=\`expr \${N_PARALLEL_STARCHIVE} + 1\` 
      if [ \${N_PARALLEL_STARCHIVE} -eq $MAX_PARALLEL_STARCHIVE ] 
      then 
        N_PARALLEL_STARCHIVE=0
        wait 
      fi 
    done 
    wait 

    CONTINUE_RUN=TRUE 
  done  
  echo ++ END RESTART LOOP 

done ; done ; done 
echo + END LOOP OVER START DATES 

EOF
echo ++ PBS-script written to $PBSSCRIPT

echo + SUBMIT PBS-SCRIPT 
if [ $MACH == "fram" ] 
then 
  sbatch $PBSSCRIPT
else 
  qsub $PBSSCRIPT
fi
echo ++ log written to $CASESROOT/$ENSEMBLE_PREFIX1/$CASE1/${PREFIX}.log

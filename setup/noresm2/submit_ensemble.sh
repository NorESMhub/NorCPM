#!/bin/sh -e

echo Determine absolute path of script directory and source settings file
SETUPROOT=`dirname \`readlink -f $0\` `
echo SETUPROOT is $SETUPROOT
. $SETUPROOT/source_settings.sh $*

echo Prepare logging 
mkdir -p $SETUPROOT/../../logs
LOGFILE=$SETUPROOT/../../logs/submit-`date +%Y%m%d%H%M`_${EXPERIMENT}.log
echo Write log file to $LOGFILE  
npipe=/tmp/$$.tmp
trap "rm -f $npipe" EXIT
mknod $npipe p
tee <$npipe $LOGFILE &
exec 1>& -
exec 1> $npipe 2>&1
echo Executed command: $0 $*
echo Git repository hashtag: `git log -1 --pretty=format:%H 2> /dev/null || echo not available`
echo

echo Submitting experiment $EXPERIMENT 
echo + DETERMINE PES NUMBER FOR ENSEMBLE 
RELPATH1=$EXPERIMENT/${EXPERIMENT}_${SDATE_PREFIX}$SDATE/$CASE1
CASEROOT1=$CASESROOT/$RELPATH1
MPPWIDTHOLD=`grep "\--ntasks=" $CASEROOT1/.case.run | cut -d"=" -f2 | cut -d":" -f1`
MPPWIDTHNEW=`expr $MPPWIDTHOLD \* $ENSSIZE` 
NTASKS_NORESM=`expr $MPPWIDTHOLD \* $ENSSIZE`
if [[ $NTASKS_DA ]]
then
  MPPWIDTHNEW=`expr $NTASKS_NORESM + $NTASKS_DA`
else 
  MPPWIDTHNEW=$NTASKS_NORESM 
fi  
NODES_NORESM=`expr $NTASKS_NORESM / $TASKS_PER_NODE` 
NODES_TOTAL=`expr $MPPWIDTHNEW / $TASKS_PER_NODE` 
if [ $NODES_TOTAL -lt $MIN_NODES ] 
then 
  NODES_TOTAL=$MIN_NODES
elif [ `expr $NODES_TOTAL \* $TASKS_PER_NODE` -lt $MPPWIDTHNEW ] 
then
  NODES_TOTAL=`expr $NODES_TOTAL + 1` 
fi

echo + WRITE ENSEMBLE JOB-SCRIPT 
JOB_SCRIPT=$CASEROOT1/${EXPERIMENT}.runens
cat <<EOF> $JOB_SCRIPT
#!/bin/sh -e
#SBATCH --account=${ACCOUNT}
#SBATCH --job-name=${EXPERIMENT}
#SBATCH --time=${WALLTIME}
#SBATCH --nodes=${NODES_TOTAL}
#SBATCH --ntasks=${MPPWIDTHNEW}
#SBATCH --output=${LOGFILE}

export MEMBER_PES=${MPPWIDTHOLD} NTASKS_NORESM=${NTASKS_NORESM} NODES_NORESM=${NODES_NORESM} NODES_TOTAL=${NODES_TOTAL} SETUPROOT=${SETUPROOT}
source ${SETUPROOT}/run_ensemble.sh $* 
EOF

echo + SUBMIT JOB
JOBID=`sbatch ${JOB_SCRIPT} | awk '{print $4}'`
echo ++ log written to ${LOGFILE}

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
MPPWIDTHOLD=`grep "\-ntasks" $CASEROOT1/${CASE1}.${MACH}.run | cut -d"=" -f2 | cut -d":" -f1`
MPPWIDTHNEW=`expr $MPPWIDTHOLD \* $ENSSIZE` 
NODESNEW=`expr $MPPWIDTHNEW / $TASKS_PER_NODE` 
if [ $NODESNEW -lt $MIN_NODES ] 
then 
  NODESNEW=$MIN_NODES
elif [ `expr $NODESNEW \* $TASKS_PER_NODE` -lt $MPPWIDTHNEW ] 
then
  NODESNEW=`expr $NODESNEW + 1` 
fi

echo + WRITE ENSEMBLE JOB-SCRIPT 
JOB_SCRIPT=$CASEROOT1/${EXPERIMENT}.runens
cat <<EOF> $JOB_SCRIPT
#!/bin/sh -e
#SBATCH --account=${ACCOUNT}
#SBATCH --job-name=${EXPERIMENT}
#SBATCH --time=${WALLTIME}
#SBATCH --nodes=${NODESNEW}
#SBATCH --ntasks=${MPPWIDTHNEW}
#SBATCH --output=${LOGFILE}

SETUPROOT=${SETUPROOT}
source ${SETUPROOT}/run_ensemble.sh $* 
EOF

echo + SUBMIT JOB
JOBID=`sbatch ${JOB_SCRIPT} | awk '{print $4}'`
echo ++ log written to ${LOGFILE}

#!/bin/sh -e

echo Determine absolute path of script directory and source settings file
SETUPROOT=`dirname \`readlink -f $0\` `
echo SETUPROOT is $SETUPROOT
. $SETUPROOT/source_settings.sh $*

echo Prepare logging 
mkdir -p $SETUPROOT/../../logs
LOGFILE=$SETUPROOT/../../logs/archive-`date +%Y%m%d%H%M`_${EXPERIMENT}.log
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

echo Perform short-term archiving of $EXPERIMENT 

echo + WRITE ENSEMBLE JOB-SCRIPT 
JOB_SCRIPT=$CASEROOT1/case.st_archive.ens
cat <<EOF> $JOB_SCRIPT
#!/bin/sh -e
#SBATCH --account=${ACCOUNT}
#SBATCH --job-name=${EXPERIMENT}
#SBATCH --time=01:00:00 
#SBATCH --ntasks=1
#SBATCH --mem=2GB 
#SBATCH --qos=preproc
#SBATCH --output=${LOGFILE}

for MEMBER in \`seq -w $MEMBER1 $MEMBERN\`
do
  CASE=${EXPERIMENT}_$SDATE_PREFIX${SDATE}_$MEMBER_PREFIX\$MEMBER
  RELPATH=$EXPERIMENT/${EXPERIMENT}_$SDATE_PREFIX$SDATE/\$CASE
  CASEROOT=$CASESROOT/\$RELPATH
  cd \$CASEROOT
  echo \$CASEROOT 
  sed -i -e '/convert_loop >>/d' noresm2netcdf4.sh  
  ./case.submit --job case.st_archive --no-batch  
  wait 
done

EOF

echo + SUBMIT JOB
JOBID=`sbatch ${JOB_SCRIPT} | awk '{print $4}'`
echo ++ log written to ${LOGFILE}

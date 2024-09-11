#!/bin/sh -e

echo Determine absolute path of script directory and source settings file
SETUPROOT=`dirname \`readlink -f $0\` `
echo SETUPROOT is $SETUPROOT
. $SETUPROOT/source_settings.sh $*

echo Prepare logging 
mkdir -p $SETUPROOT/../../logs
LOGFILE=$SETUPROOT/../../logs/compress-`date +%Y%m%d%H%M`_${EXPERIMENT}.log
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

echo Compress archived output of $EXPERIMENT 
for MEMBER in `seq -w $MEMBER1 $MEMBERN`
do
  CASE=${EXPERIMENT}_$SDATE_PREFIX${SDATE}_$MEMBER_PREFIX$MEMBER
  RELPATH=$EXPERIMENT/${EXPERIMENT}_$SDATE_PREFIX$SDATE/$CASE
  DOUT_S_ROOT=$WORK/archive/$RELPATH
  $SETUPROOT/../../tools/noresm2nc4mpi/noresm2nc4mpi.betzy.sh $DOUT_S_ROOT
done 
echo DONE

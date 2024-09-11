#!/bin/sh -e

DATE_RESTART=$1 

echo Determine absolute path of script directory and source settings file
SETUPROOT=`dirname \`readlink -f $0\` `
echo SETUPROOT is $SETUPROOT
ARGS=`echo $* | awk '{for(i=2;i<=NF;i++) print $i}'`
. $SETUPROOT/source_settings.sh $ARGS

echo Prepare logging 
mkdir -p $SETUPROOT/../../logs
LOGFILE=$SETUPROOT/../../logs/create-`date +%Y%m%d%H%M`_${EXPERIMENT}.log
echo Write log file at $LOGFILE  
npipe=/tmp/$$.tmp
trap "rm -f $npipe" EXIT
mknod $npipe p
tee <$npipe $LOGFILE &
exec 1>& -
exec 1> $npipe 2>&1
echo Executed command: $0 $*
echo Git repository hashtag: `git log -1 --pretty=format:%H 2> /dev/null || echo not available`
echo

echo Setting up experiment ${EXPERIMENT}, this can take some time  
echo + BEGIN LOOP OVER MEMBERS 
for MEMBER in `seq -w $MEMBER1 $MEMBERN`
do

  CASE=${EXPERIMENT}_${SDATE_PREFIX}${SDATE}_${MEMBER_PREFIX}$MEMBER
  RELPATH=$EXPERIMENT/${EXPERIMENT}_${SDATE_PREFIX}$SDATE/$CASE
  EXEROOT=$WORK/noresm/$RELPATH
  DOUT_S_ROOT=$WORK/archive/$RELPATH

  echo ++ STAGE RESTART DATA 
  REF_PATH=$DOUT_S_ROOT/rest/${DATE_RESTART}-00000
  cd $EXEROOT/run
  for ITEM in `ls $REF_PATH`
  do
    if [[ `echo $ITEM | tail -c4` == .gz ]]
    then
      cp -f --no-preserve=mode $REF_PATH/$ITEM . 
      gunzip -f $ITEM
    elif [[ `echo $ITEM | tail -c4` == .nc ]]
    then
      ln -f $REF_PATH/$ITEM .
    else
      cp -f --no-preserve=mode $REF_PATH/$ITEM . 
    fi
  done
  
done
echo + END LOOP OVER MEMBERS 


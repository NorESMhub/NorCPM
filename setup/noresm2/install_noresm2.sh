#!/bin/sh -e

echo Determine absolute path of script directory and source settings file
SETUPROOT=`dirname \`readlink -f $0\` `
echo SETUPROOT is $SETUPROOT

echo Prepare logging 
mkdir -p $SETUPROOT/../../logs
LOGFILE=$SETUPROOT/../../logs/install_noresm-`date +%Y%m%d%H%M`_${EXPERIMENT}.log 
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

cd $SETUPROOT/../../model 

git clone -b release-noresm2.0.7 --single-branch https://github.com/NorESMhub/NorESM.git noresm2

cd noresm2

./manage_externals/checkout_externals 
echo + INSTALL COMPLETED

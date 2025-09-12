#!/bin/sh -e

echo Determine absolute path of script directory and source settings file
SETUPROOT=`dirname \`readlink -f $0\` `
echo SETUPROOT is $SETUPROOT

echo Prepare logging 
mkdir -p $SETUPROOT/../../logs
LOGFILE=$SETUPROOT/../../logs/install_noresm2-`date +%Y%m%d%H%M`.log 
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

git clone -b release-noresm2.0.8 --single-branch https://github.com/NorESMhub/NorESM.git noresm2

cd noresm2

./manage_externals/checkout_externals 

echo + PERFORMING POST-INSTALL MODIFICATIONS 
sed -i 's/\[dmy\]/\[hdmy\]/g' components/blom/cime_config/config_archive.xml 
sed -i 's/\[dmy\]/\[hdmy\]/g' cime/config/cesm/config_archive.xml
find ../../setup/noresm2/user_mods -name "*patch.input*" -exec cp -v {} components/blom/bld/tnx1v4/ \;

echo + INSTALL COMPLETED

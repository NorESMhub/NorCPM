#!/bin/sh -evx 

# check input argument and print help blurb if check fails
EXPERIMENT=$1
if [[ ! $1 || $1 == "-h" || $1 == "--help" ]]
then
cat <<EOF
Usage: `basename $0` <experiment name> 

Example: `basename $0` norcpm1-1_piControl
  
Purpose: Performs precision preserving compression of atmospheric NorESM output
EOF
  exit 1 
fi 

: ${ARCHIVE:=/cluster/work/users/$USER/archive}
: ${PPCDIR=`dirname \`readlink -f $0\``/../../tools/ppc} 
: ${PPC:=${PPCDIR}/ppc_atm.betzy.sh}

for STARTDATE in `ls $ARCHIVE/$EXPERIMENT`
do 
  if [ -d $ARCHIVE/$EXPERIMENT/$STARTDATE ]
  then 
    for MEMBER in `ls $ARCHIVE/$EXPERIMENT/$STARTDATE`
    do 
      CASEDIR=$ARCHIVE/$EXPERIMENT/$STARTDATE/$MEMBER
      if [ -d $CASEDIR ] 
      then 
        $PPC $CASEDIR 
      fi 
    done 
  fi 
done 
echo ALL JOBS SUBMITTED  

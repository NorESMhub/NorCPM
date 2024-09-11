#!/bin/sh -e

if [[ ! $1 || $1 == "-h" || $1 == "--help"  ]]
then 
  echo "USAGE: ./`basename $0` <path to settings file> [var1=value var2=value]" 
  echo 
  echo "EXAMPLE: ./`basename $0` settings/predictiontest.sh MACH=betzy" 
  exit 
fi 

# OVERRIDE DEFAULTS
for ARG in $* 
do
 if [ `echo $ARG | grep =` ] 
 then
   declare `echo $ARG | cut -d= -f1`=`echo $ARG | cut -d= -f2`
 fi
done 

# SET MACHINE SPECIFIC SETTINGS
. $SETUPROOT/settings/setmach.sh

# READING SETTINGS FROM FILE 
if [ ! $SETUPROOT/settings/`basename $1 .sh`.sh ]
then
  echo cannot read settings file $SETUPROOT/settings/`basename $1 .sh`.sh 
  exit
fi
. $SETUPROOT/settings/`basename $1 .sh`.sh

# SET VERBOSITY
if (( $VERBOSE ))
then
  set -vx
  echo set logging verbose
fi

# derived settings
MEMBER1=`printf %03d $((10#$MEMBER1))`
ENSSIZE=$((10#$ENSSIZE))
: ${SDATE:=`echo $START_DATE | sed 's/-//g'`}
: ${START_YEAR:=`echo $SDATE | cut -c1-4`}
: ${START_MONTH:=`echo $SDATE | cut -c5-6`}
: ${START_DAY:=`echo $SDATE | cut -c7-8`}
: ${SCRIPTSROOT:=$NORESMROOT/cime/scripts}
: ${ANALYSISROOT:=$WORK/noresm/${EXPERIMENT}/${EXPERIMENT}_${SDATE}/ANALYSIS}
: ${MEMBERN:=$((10#$MEMBER1 + 10#$ENSSIZE - 1))}
: ${CASE1:=${EXPERIMENT}_${SDATE_PREFIX}${SDATE}_${MEMBER_PREFIX}$MEMBER1}
: ${RELPATH1:=$EXPERIMENT/${EXPERIMENT}_$SDATE_PREFIX$SDATE/$CASE1}
: ${CASEROOT1:=$CASESROOT/$RELPATH1}
: ${EXEROOT1:=$WORK/noresm/$RELPATH1}
: ${REF_DATE1:=`echo $REF_DATES | cut -d" " -f1`} 

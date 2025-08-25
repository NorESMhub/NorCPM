#!/bin/sh -e

SETTINGS_FILE=$1 
shift 
START_DATES=$* 

: ${PARALLEL:=false}
: ${CREATE:=true}
: ${SUBMIT:=true}

function hindcast_wrapper () {
  echo $SETTINGS_FILE START_DATE=$1
  $CREATE && ./create_ensemble.sh $SETTINGS_FILE START_DATE=$1
  $SUBMIT && ./submit_ensemble.sh $SETTINGS_FILE START_DATE=$1 
}

for START_DATE in $START_DATES
do
  if $PARALLEL 
  then
    hindcast_wrapper $START_DATE & 
  else
    hindcast_wrapper $START_DATE  
  fi
done 
wait
echo DONE 

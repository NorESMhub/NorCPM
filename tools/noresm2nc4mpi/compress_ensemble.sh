#!/bin/sh -evx 

# check input argument and print help blurb if check fails
EXPERIMENT=$1
if [[ ! $1 || $1 == "-h" || $1 == "--help" ]]
then
cat <<EOF
Usage: `basename $0` <experiment name> 

Example: `basename $0` norcpm1-1_piControl
  
Purpose: Converts NorESM output to compressed netcdf 4 format and gzips restarts
EOF
  exit 1 
fi 

: ${ARCHIVE:=/cluster/work/users/$USER/archive}
: ${NORESM2NC4MPIDIR=`dirname \`readlink -f $0\``} 
: ${NORESM2NC4MPI:=${NORESM2NC4MPIDIR}/noresm2nc4mpi.betzy.sh}

for STARTDATE in `ls $ARCHIVE/$EXPERIMENT`
do 
  if [ -d $ARCHIVE/$EXPERIMENT/$STARTDATE ]
  then 
    for MEMBER in `ls $ARCHIVE/$EXPERIMENT/$STARTDATE`
    do 
      CASEDIR=$ARCHIVE/$EXPERIMENT/$STARTDATE/$MEMBER
      if [ -d $CASEDIR ] 
      then 
        $NORESM2NC4MPI $CASEDIR 
      fi 
    done 
  fi 
done 
echo ALL JOBS SUBMITTED  

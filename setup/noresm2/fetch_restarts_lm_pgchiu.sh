#!/bin/sh -evx 

ADIR=/nird/projects/NS9039K/shared/pgchiu/archive_betzy/noresm_ctl_19700101_19700101
CASE_PREFIX=`basename $ADIR`
RESDIR=/cluster/work/users/$USER/restarts/$CASE_PREFIX 
START_DATE=2015-01-01-00000 
START_DATE=1996-01-01-00000 
START_DATE=1985-01-01-00000 

for CASE in `ls $ADIR`
do 
  mkdir -p $RESDIR/$CASE/rest/$START_DATE
  cd $RESDIR/$CASE/rest/$START_DATE 
  cp -uv $ADIR/$CASE/rest/$START_DATE/* . 
  find . -name "*.gz" -exec gunzip -f {} \; 
done 
echo DONE


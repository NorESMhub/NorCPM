#!/bin/sh -evx 

ADIR=/nird/datalake/NS9873K/norcpm/raw/noresm2/NHISTfrc2_f19_tn14_LESFMIPhist-all
CASE_PREFIX=`basename $ADIR`
RESDIR=/cluster/work/users/$USER/restarts/$CASE_PREFIX 
START_DATE=1976-01-01-00000 
START_DATE=1982-01-01-00000 

for CASE in `ls $ADIR`
do 
  mkdir -p $RESDIR/$CASE/rest/$START_DATE
  cd $RESDIR/$CASE/rest/$START_DATE 
  cp -uv $ADIR/$CASE/rest/$START_DATE/* . 
  find . -name "*.gz" -exec gunzip -f {} \; 
done 
echo DONE


#!/bin/sh -evx 

# comment: NHIST_2051_f19_tn14_20230201esm is empty 

CASES='NHIST_f19_tn14_20191104esm NHIST_1901_f19_tn14_20230201esm NHIST_1951_f19_tn14_20230201esm NHIST_2001_f19_tn14_20230201esm NHIST_2051_f19_tn14_20230201esm NHIST_2201_f19_tn14_20230201esm NHIST_2251_f19_tn14_20230201esm NHIST_2291_f19_tn14_20230201esm NHIST_2231_f19_tn14_20230201esm NHIST_2311_f19_tn14_20230201esm'
RESDIR=/cluster/work/users/$USER/restarts
START_DATES='1975-01-01-00000' 

for CASE in $CASES
do
  if [ $CASE == 'NHIST_f19_tn14_20191104esm' ]
  then
    PROJECT=NS9560K
  else
    PROJECT=NS10013K 
  fi
  ADIR=/nird/projects/$PROJECT/noresm/cases
  for START_DATE in $START_DATES
  do
    mkdir -p $RESDIR/$CASE/rest/$START_DATE
    cd $RESDIR/$CASE/rest/$START_DATE 
    for FNAME in `ls $ADIR/$CASE/rest/$START_DATE`
    do 
      if [ ! -e `basename $FNAME .gz` ]
      then 
        cp -uv $ADIR/$CASE/rest/$START_DATE/$FNAME . 
      fi
    done
    find . -name "${CASE}.*.gz" -exec gunzip -f {} \; 
  done
done
echo DONE


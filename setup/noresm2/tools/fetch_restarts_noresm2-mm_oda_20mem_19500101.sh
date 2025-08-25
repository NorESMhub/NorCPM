#!/bin/sh -evx 



CASES='noresm2-mm_oda_20mem_19500101_mem001 noresm2-mm_oda_20mem_19500101_mem002 noresm2-mm_oda_20mem_19500101_mem003 noresm2-mm_oda_20mem_19500101_mem004 noresm2-mm_oda_20mem_19500101_mem005 noresm2-mm_oda_20mem_19500101_mem006 noresm2-mm_oda_20mem_19500101_mem007 noresm2-mm_oda_20mem_19500101_mem008 noresm2-mm_oda_20mem_19500101_mem009 noresm2-mm_oda_20mem_19500101_mem010 noresm2-mm_oda_20mem_19500101_mem011 noresm2-mm_oda_20mem_19500101_mem012 noresm2-mm_oda_20mem_19500101_mem013 noresm2-mm_oda_20mem_19500101_mem014 noresm2-mm_oda_20mem_19500101_mem015 noresm2-mm_oda_20mem_19500101_mem016 noresm2-mm_oda_20mem_19500101_mem017 noresm2-mm_oda_20mem_19500101_mem018 noresm2-mm_oda_20mem_19500101_mem019 noresm2-mm_oda_20mem_19500101_mem020'
RESDIR=/cluster/work/users/$USER/restarts/noresm2-mm_oda_20mem/noresm2-mm_oda_20mem_19500101 
START_DATES='1981-11-01-00000' 
PROJECT=NS11071K

for CASE in $CASES
do
  ADIR=/nird/datalake/NS11071K/data/noresm/output/raw/noresm2-mm_oda_20mem/noresm2-mm_oda_20mem_19500101
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


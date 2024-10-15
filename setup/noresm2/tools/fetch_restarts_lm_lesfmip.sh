#!/bin/sh -evx 

#ADIR=nird.sigma2.no:/nird/datalake/NS11071K/norcpm/raw/noresm2/NHISTfrc2_f19_tn14_LESFMIPhist-all

ADIR=nird.sigma2.no:/nird/datalake/NS11071K/data/noresm/output/raw/NHISTfrc2_f19_tn14_LESFMIPhist-all
CASE_PREFIX=`basename $ADIR`
RESDIR=/cluster/work/users/$USER/restarts/$CASE_PREFIX 
START_DATES="1976-01-01-00000 1982-01-01-00000" 

CASES="NHISTfrc2_f19_tn14_LESFMIPhist-all_001 NHISTfrc2_f19_tn14_LESFMIPhist-all_002 NHISTfrc2_f19_tn14_LESFMIPhist-all_003 NHISTfrc2_f19_tn14_LESFMIPhist-all_004 NHISTfrc2_f19_tn14_LESFMIPhist-all_005 NHISTfrc2_f19_tn14_LESFMIPhist-all_006 NHISTfrc2_f19_tn14_LESFMIPhist-all_007 NHISTfrc2_f19_tn14_LESFMIPhist-all_008 NHISTfrc2_f19_tn14_LESFMIPhist-all_009 NHISTfrc2_f19_tn14_LESFMIPhist-all_010 NHISTfrc2_f19_tn14_LESFMIPhist-all_011 NHISTfrc2_f19_tn14_LESFMIPhist-all_012 NHISTfrc2_f19_tn14_LESFMIPhist-all_013 NHISTfrc2_f19_tn14_LESFMIPhist-all_014 NHISTfrc2_f19_tn14_LESFMIPhist-all_015 NHISTfrc2_f19_tn14_LESFMIPhist-all_016 NHISTfrc2_f19_tn14_LESFMIPhist-all_017 NHISTfrc2_f19_tn14_LESFMIPhist-all_018 NHISTfrc2_f19_tn14_LESFMIPhist-all_019 NHISTfrc2_f19_tn14_LESFMIPhist-all_020"
for START_DATE in $START_DATES
do
  for CASE in $CASES # `ls $ADIR`
  do 
    mkdir -p $RESDIR/$CASE/rest/$START_DATE
    cd $RESDIR/$CASE/rest/$START_DATE 
    rsync -uav $ADIR/$CASE/rest/$START_DATE/* . 
    find . -name "*.gz" -exec gunzip -f {} \; 
  done 
done 
echo DONE


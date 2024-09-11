#! /bin/sh -e
rdate=$1
echo $rdate
today=$(date -d "$rdate" +%d)
enssize=60
echo "Land Ensemble:"
echo $enssize

infl_fac=1.05
echo "LDA inflation:"
echo $infl_fac


until [ $(ls clm2.rda.??-${rdate}.nc | wc -l) -eq 60 ]  && [ $(ls PAUSE* | wc -l) -eq 60 ];
do
  echo "Waiting for all restart files"

done


./SM_DAstandaloneApplication/run_SM_DA.sh /cluster/software/MATLAB/2022b/ ${rdate} ${enssize} ${infl_fac}

while ! test -f "./Innovation-${rdate}.nc"; do
       sleep .5
       echo "still waiting for DA to end"
done

echo "CLMDA OVER: NorCPM will resume now"

rm  PAUSE*

yesterday=$(date -d "$rdate - 2 day" +%Y%m%d)
rm clm2.rda.*-${yesterday}.nc
rm Update-${yesterday}.nc
rm analyis-${yesterday}.nc

#LDA_START=YYYYMM
#LDA_END=YYYYMM
 
#echo LDA_START
#echo $LDA_START

#echo rm PAUSE01
#rm PAUSE01


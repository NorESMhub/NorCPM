#!/bin/sh -e

. $SETUPROOT/source_settings.sh $*
. $SETUPROOT/settings/setmach.sh 
cd $ANALYSISROOT
rm -f *_PAUSE_* 
touch BLOM_DA 

ODA () {
  set -xv 

  DATE=`ls BLOM_PAUSE_* | head -1 | tail -c11`
  YYYY=`echo $DATE | cut -c1-4`   
  MM=`echo $DATE | cut -c6-7`   
  DD=`echo $DATE | cut -c9-10`   

  echo ++ SET RFACTOR TO $RFACTOR
  RFACTOR=1

  echo ++ LINK FORECASTS
  for MEMBER in `seq -w $MEMBER1 $MEMBERN`
  do
    ln -sf blom.rda.${MEMBER}.${DATE}.nc forecast${MEMBER}.nc 
  done    

  ENKF_CNT=0 # Counter of EnKF sequential call
  echo ++ PREPARE OBSERVATIONS AND DO SEQUENTIAL/CONCURRENT ASSIMILATION
  OBSLIST=(${OBSLIST[*]}) # convert list to array 
  PRODUCERLIST=(${PRODUCERLIST[*]})
  FREQUENCYLIST=(${FREQUENCYLIST[*]})
  REF_PERIODLIST=(${REF_PERIODLIST[*]})
  COMBINE_ASSIM=(${COMBINE_ASSIM[*]})
  for iobs in ${!OBSLIST[*]}
  do
    OBSTYPE=${OBSLIST[$iobs]}
    PRODUCER=${PRODUCERLIST[$iobs]}
    FREQUENCY=${FREQUENCYLIST[$iobs]}
    REF_PERIOD=${REF_PERIODLIST[$iobs]}
    COMB_ASSIM=${COMBINE_ASSIM[$iobs]}    #sequential/joint observation assim 

    echo +++ Link model and observation data
    if [ $FREQUENCY == 'MONTH' ]
    then
      [ ! $DD == '15' ] && continue # do monthly assim only on 15th 
      if [ -e $INPUTDATA_ASSIM/obs/$OBSTYPE/$PRODUCER/${YYYY}_${MM}.nc ]
      then  
        ln -sf $INPUTDATA_ASSIM/obs/$OBSTYPE/$PRODUCER/${YYYY}_${MM}.nc .
      elif [ -e $INPUTDATA_ASSIM/obs/$OBSTYPE/$PRODUCER/${YYYY}_${MM}_pre.nc ]
      then 
        ln -sf $INPUTDATA_ASSIM/obs/$OBSTYPE/$PRODUCER/${YYYY}_${MM}_pre.nc ${YYYY}_${MM}.nc
      else
        echo "$INPUTDATA_ASSIM/obs/$OBSTYPE/$PRODUCER/${YYYY}_${MM}.nc missing, we quit" ; exit 1
      fi
      if [ -e $MEAN_MOD_DIR/Free-average${MM}-${REF_PERIOD}.nc ]
      then
        ln -sf $MEAN_MOD_DIR/Free-average${MM}-${REF_PERIOD}.nc mean_mod.nc
      else
        echo "$MEAN_MOD_DIR/Free-average${MM}-${REF_PERIOD}.nc missing, we quit" ; exit 1
      fi
      if [ -f $INPUTDATA_ASSIM/enkf/$RES/$PRODUCER/${RES}_${OBSTYPE}_obs_unc_anom.nc ]
      then
        ln -sf $INPUTDATA_ASSIM/enkf/$RES/$PRODUCER/${RES}_${OBSTYPE}_obs_unc_anom.nc  obs_unc_${OBSTYPE}.nc
      fi
      ln -sf $INPUTDATA_ASSIM/obs/$OBSTYPE/$PRODUCER/${OBSTYPE}_avg_${MM}-${REF_PERIOD}.nc mean_obs.nc || { echo "Error $INPUTDATA_ASSIM/obs/$OBSTYPE/$PRODUCER/${OBSTYPE}_avg_$MM-${REF_PERIOD}.nc missing, we quit" ; exit 1 ; }
      cat $INPUTDATA_ASSIM/enkf/infile.data.${OBSTYPE}.$PRODUCER | sed  -e "s/yyyy/${YYYY}/" -e "s/mm/${MM}/" > infile.data
    else
      if [ -e $INPUTDATA_ASSIM/obs/$OBSTYPE/$PRODUCER/${YYYY}_${MM}_${DD}.nc ]
      then
        ln -sf $INPUTDATA_ASSIM/obs/$OBSTYPE/$PRODUCER/${YYYY}_${MM}_${DD}.nc .
      elif [ -e $INPUTDATA_ASSIM/obs/$OBSTYPE/$PRODUCER/${YYYY}_${MM}_${DD}_pre.nc ]
      then
        ln -sf $INPUTDATA_ASSIM/obs/$OBSTYPE/$PRODUCER/${YYYY}_${MM}_${DD}_pre.nc ${YYYY}_${MM}_${DD}.nc
      else
        echo "$INPUTDATA_ASSIM/obs/$OBSTYPE/$PRODUCER/${YYYY}_${MM}_${DD}.nc missing, we quit" ; exit 1
      fi
      if [ -e $MEAN_MOD_DIR/Free-average${MM}d${DD}-${REF_PERIOD}.nc ]
      then
        ln -sf $MEAN_MOD_DIR/Free-average${MM}d${DD}-${REF_PERIOD}.nc mean_mod.nc
      else
        echo "$MEAN_MOD_DIR/Free-average${MM}d${DD}-${REF_PERIOD}.nc missing, we quit" ; exit 1
      fi
      if [ -f $INPUTDATA_ASSIM/enkf/$RES/$PRODUCER/${RES}_${OBSTYPE}_obs_unc_anom.nc ]
      then
        ln -sf $INPUTDATA_ASSIM/enkf/$RES/$PRODUCER/${RES}_${OBSTYPE}_obs_unc_anom.nc  obs_unc_${OBSTYPE}.nc
      fi
      ln -sf $INPUTDATA_ASSIM/obs/$OBSTYPE/$PRODUCER/${OBSTYPE}_avg_${MM}d${DD}-${REF_PERIOD}.nc mean_obs.nc || { echo "Error $INPUTDATA_ASSIM/obs/$OBSTYPE/$PRODUCER/${OBSTYPE}_avg_${MM}d${DD}-${REF_PERIOD}.nc missing, we quit" ; exit 1 ; }
      cat $INPUTDATA_ASSIM/enkf/infile.data.${OBSTYPE}.$PRODUCER | sed  -e "s/yyyy/${YYYY}/" -e "s/mm/${MM}/" -e "s/.nc/_${DD}.nc/" > infile.data
    fi
    ln -sf $OCNGRIDFILE grid.nc 

    echo +++ prepare observations
    time mpirun -n 1 --hostfile hostfile_da ./prep_obs
    mv observations.uf observations.uf_${OBSTYPE}.$PRODUCER

    if (( $COMB_ASSIM ))
    then
      let ENKF_CNT=ENKF_CNT+1
      cat observations.uf_* > observations.uf
      rm -f observations.uf_*
      cp -f $ASSIMROOT/analysisfields_${ENKF_CNT}.in analysisfields.in
      cat $ASSIMROOT/enkf.prm_${ENKF_CNT} | sed -e "s/XXX/$RFACTOR/" -e "s/enssize =.*/enssize = $ENSSIZE/g" > enkf.prm

      echo +++ CALL ENKF
      time mpirun -n $NTASKS_ENKF --hostfile hostfile_da ./EnKF enkf.prm
      mv enkf_diag.nc enkf_diag_${ENKF_CNT}.nc      
      mv tmpX5.uf tmpX5_${ENKF_CNT}.uf

    fi
  done #OBS list

  echo + FINISHED ASSIMILATION UPDATE $YYYY-$MM-$DD 
  rm BLOM_PAUSE_???_$DATE forecast???.nc 
  date

  set +xv
} # ODA end 


while [ ! -e NORESM_FINISHED ]
do
  [ `ls | grep BLOM_PAUSE_ | wc -l` -eq $ENSSIZE ] && ODA
  sleep 0.1 
done 

echo + NorESM finished - will stop assimilation script

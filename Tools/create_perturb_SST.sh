#!/bin/sh -ev

# NCO on fram
#module load NCO/4.7.2-intel-2018a
module load NCO/4.8.1-intel-2019a  ## betzy

CASENAME='NHISTfrc2_f09_tn14_20191025'

RESBASEDIR="/cluster/projects/nn9039k/people/pgchiu/restarts/cases"
DATESTR='1970-01-01-00000'
NMEM=30
PWDDIR=`pwd`

## check $CASENAME/$DATESTR  or  $CASENAME/rest/$DATESTR
if [ -d "$RESBASEDIR/$CASENAME/$DATESTR" ] ;then
    REST=''
elif [ -d "$RESBASEDIR/$CASENAME/rest/$DATESTR" ] ;then
    REST='rest'
else
    echo "No restart found at "
    echo "    $RESBASEDIR/$CASENAME/$DATESTR"
    echo "    $RESBASEDIR/$CASENAME/rest/$DATESTR"
    echo "exit..."
    exit
fi

# loop over members and perturb MICOM restarts
echo "do in $RESBASEDIR/ "
cd $RESBASEDIR/
for MEM in `seq -w 01 $NMEM`
do 
  cp -as "${RESBASEDIR}/${CASENAME}/${REST}/" "${CASENAME}_mem$MEM"  ## make link
  rm -f ${CASENAME}_mem${MEM}/*/rpointer.*
  cp ${RESBASEDIR}/${CASENAME}/${REST}/${DATESTR}/rpointer.*  ${CASENAME}_mem$MEM/$DATESTR/

  ## perturb micom temperature
  FNAME=${CASENAME}.blom.r.${DATESTR}.nc
  FNAME=${CASENAME}.micom.r.${DATESTR}.nc
  rm -f "${CASENAME}_mem${MEM}/${DATESTR}/${FNAME}"
  export GSL_RNG_SEED="$RANDOM$MEM"
  $PWDDIR/$(dirname $0)/perturb_restart.sh "${CASENAME}/${REST}/${DATESTR}/${FNAME}" "${CASENAME}_mem${MEM}/${DATESTR}/${FNAME}"

done 



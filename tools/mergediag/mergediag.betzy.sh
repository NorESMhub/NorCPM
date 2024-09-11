#!/bin/sh -e
#SBATCH --account=nn9039k
#SBATCH --job-name=mergediag
#SBATCH --time=04:00:00
#SBATCH --nodes=4
#SBATCH --output=mergediag.out

BASEDIR=$1
if [[ ! $BASEDIR || ! -d $BASEDIR ]]
then
  echo "Usage: sbatch $0 <archive directory of hindcast experiment>"
  echo 
  echo "Example: sbatch $0 /cluster/work/users/ingo/archive/norcpm-cf-system1_hindcast1/norcpm-cf-system1_hindcast1_20230615"
  echo
  exit 
fi

: ${COMPRESSION:=deflateppcsafe} # one of "nocomp deflate deflateppc deflatepccsafe"   
: ${MAXTHREAD:=128}

source /cluster/installations/lmod/lmod/init/sh
module --quiet restore system
module load StdEnv
module load NCO/4.9.5-iompi-2020a	

MEMBER1=`ls $BASEDIR | head -1 | tail -c3`
MEMBERN=`ls $BASEDIR | tail -1 | tail -c3`
echo $MEMBER1 
IPREFIX=`basename $BASEDIR`
OPREFIX=${IPREFIX}_mem${MEMBER1}-${MEMBERN}

OBASE=$BASEDIR/$OPREFIX
touch $BASEDIR/${OPREFIX}.CompressionInProgress

function setppc () {
  M0=' '
  M1='PSL PS'
  M2=' '
  M3=' '
  M4=' '
  M5='transix transiy'
  M6=' '
  M7=' '
  M8=' '
  M9=' '
  M10=' '
  P0=' '
  P1='CLDTOT SST TDEW TREFHT TREFHTMN TREFHTMX TS UAS VAS U10 FLDS FLNS FLNT FLNTC FLUT FLUTC FSDS FSNS FSNT LHFLX aice uice vice FSNO SOILWATER_10CM fice sst templvl RHREFHT T010 T030 T050 T100 T200 T300 T400 T500 T700 T850 T925 TSMN TSMX U010 U030 U050 U10 U100 U200 U300 U400 U500 U700 U850 U925 V010 V030 V050 V100 V200 V300 V400 V500 V700 V850 V925 Z Z010 Z030 Z050 Z100 Z200 Z300 Z400 Z500 Z700 Z850 Z925'
  P2='SNOWHICE SNOWHLN SOLIN CLDTOT FLDS FLNS FLNT FSDS FSNS FSNT LHFLX SHFLX hi hs SNOWDP'
  P3='ICEFRAC TAUX TAUY sealv OMEGA500 OMEGA850' 
  P4=' '
  P6='QFLX'
  P7=' '
  P8='Q Q010 Q030 Q050 Q100 Q200 Q300 Q400 Q500 Q700 Q850 Q925 QREFHT'
  P9=' ' 
  P10='PRECS PRECT'
  res='--ppc default=.10'  
  FIELDS="`ncdump -h $1 | grep float | grep time | cut -d' ' -f2 | cut -d'(' -f1`" 
  for FIELD in $FIELDS
  do  
    for P in `seq 0 10`
    do 
      PNAME=M$P
      for FIELD2 in ${!PNAME} ; do
        if [ $FIELD == $FIELD2 ] ; then res="$res --ppc $FIELD=.-$P" ; fi
      done 
      PNAME=P$P
      for FIELD2 in ${!PNAME} ; do
        if [ $FIELD == $FIELD2 ] ; then res="$res --ppc $FIELD=.$P" ; fi
      done 
    done 
  done
  echo $res
} 

function setppc_safe () {
  M0=' '
  M1=' '
  M2=' '
  M3=' '
  M4=' '
  M5='transix transiy'
  M6=' '
  M7=' '
  M8=' '
  M9=' '
  M10=' '
  P0='PSL PS'
  P1=' '
  P2='SNOWHICE SNOWHLN SOLIN CLDTOT FLDS FLNS FLNT FSDS FSNS FSNT LHFLX SHFLX hi hs SNOWDP CLDTOT SST TDEW TREFHT TREFHTMN TREFHTMX TS UAS VAS U10 FLDS FLNS FLNT FLNTC FLUT FLUTC FSDS FSNS FSNT LHFLX aice uice vice FSNO SOILWATER_10CM fice sst templvl RHREFHT T010 T030 T050 T100 T200 T300 T400 T500 T700 T850 T925 TSMN TSMX U010 U030 U050 U10 U100 U200 U300 U400 U500 U700 U850 U925 V010 V030 V050 V100 V200 V300 V400 V500 V700 V850 V925 Z Z010 Z030 Z050 Z100 Z200 Z300 Z400 Z500 Z700 Z850 Z925'
  P2='SNOWHICE SNOWHLN SOLIN CLDTOT FLDS FLNS FLNT FSDS FSNS FSNT LHFLX SHFLX hi hs SNOWDP'
  P3='ICEFRAC TAUX TAUY sealv OMEGA500 OMEGA850'
  P4=' '
  P6='QFLX'
  P7=' '
  P8='Q Q010 Q030 Q050 Q100 Q200 Q300 Q400 Q500 Q700 Q850 Q925 QREFHT'
  P9=' '
  P10='PRECS PRECT'
  res='--ppc default=.10'
  FIELDS="`ncdump -h $1 | grep float | grep time | cut -d' ' -f2 | cut -d'(' -f1`"
  for FIELD in $FIELDS
  do
    for P in `seq 0 10`
    do
      PNAME=M$P
      for FIELD2 in ${!PNAME} ; do
        if [ $FIELD == $FIELD2 ] ; then res="$res --ppc $FIELD=.-$P" ; fi
      done
      PNAME=P$P
      for FIELD2 in ${!PNAME} ; do
        if [ $FIELD == $FIELD2 ] ; then res="$res --ppc $FIELD=.$P" ; fi
      done
    done
  done
  echo $res
}

function merge () { 
  RELPATH=`dirname $1`
  IFILE1=`basename $1`
  FILELIST=' ' 
  for MEMBER in `seq -w $MEMBER1 $MEMBERN`
  do
    FILELIST="$FILELIST ${IPREFIX}_mem${MEMBER}/$RELPATH/`echo $IFILE1 | sed "s/${IPREFIX}_mem${MEMBER1}/${IPREFIX}_mem${MEMBER}/"`"
  done
  OPATH=$OBASE/$RELPATH
  OFILE=`echo $IFILE1 | sed "s/${IPREFIX}_mem${MEMBER1}/${IPREFIX}_mem${MEMBER1}-${MEMBERN}/"`
  echo $OPATH/$OFILE
  mkdir -p $OPATH 
  case $COMPRESSION in
  deflate)
    echo $FILELIST | ncecat -o $OPATH/$OFILE -p $BASEDIR -O -7 -t 1 -L 9 -u ensemble --cnk_dmn ensemble,1 --cnk_dmn time,1
    ;; 
  deflateppc)
    echo $FILELIST | ncecat -o $OPATH/$OFILE -p $BASEDIR -O -7 -t 1 -L 9 -u ensemble --cnk_dmn ensemble,1 --cnk_dmn time,1 `setppc $1`
    ;;
  deflateppcsafe)
    echo $FILELIST | ncecat -o $OPATH/$OFILE -p $BASEDIR -O -7 -t 1 -L 9 -u ensemble --cnk_dmn ensemble,1 --cnk_dmn time,1 `setppc_safe $1`
    ;;
  *)  
    echo $FILELIST | ncecat -o $OPATH/$OFILE -p $BASEDIR -O -6 -t 1 -u ensemble 
    ;;
  esac
}


cd $BASEDIR/${IPREFIX}_mem${MEMBER1}
for ITEM in `find . -path "*/hist/*.nc"`
do 
  merge $ITEM &
  while [ `pgrep -P $$ | wc -l` -gt $MAXTHREAD ] 
  do
    sleep 1 
  done 
done 
wait   

rm $BASEDIR/${OPREFIX}.CompressionInProgress  
echo COMPLETE 


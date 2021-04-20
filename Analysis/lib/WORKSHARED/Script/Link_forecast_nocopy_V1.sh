#Script called by main.sh, it links the corresponding restart file to the ANALYSIS forlder with name forecastxxx.nc 
#It also make a copy of forecastxxx.nc to analysisxxx.nc


year=$1
month=$2
mm=`echo 0$month | tail -3c`
yr=`echo 000$year | tail -5c`

cd ${WORKDIR}/${CASEDIR}/ANALYSIS/
for (( proc = 1; proc <= ${ENSSIZE}; ++proc ))
do
    mem=`echo 0$proc | tail -3c`
    mem3=`echo 00$proc | tail -4c`
    fn="${WORKDIR}/${CASEDIR}/${VERSION}${mem}/run/${VERSION}${mem}.micom.r.${yr}-${mm}-15-00000.nc" 
    if [ ! -f "$fn" ] ;then
        fn="${WORKDIR}/${CASEDIR}/${VERSION}${mem}/run/${VERSION}${mem}.blom.r.${yr}-${mm}-15-00000.nc" 
    fi
    if [ ! -f "$fn" ] ;then
             echo "The file  ${WORKDIR}/${CASEDIR}/${VERSION}${mem}/run/${VERSION}${mem}.{blom,micom}.r.${yr}-${mm}-15-00000.nc is missing !! we quit"
             exit 1
    fi
    ln -sf ${fn} forecast${mem3}.nc
done


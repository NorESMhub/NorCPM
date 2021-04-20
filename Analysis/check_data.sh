#!/bin/bash

## NorCPM prediction and analysis setting check
## Usage: 
## 	./check_analysis.sh <setting file>

RED='[\033[0;91m'
GREEN='[\033[0;92m'
BLUE='[\033[0;34m'
NC='\033[0m]' # No Color

check () {
    ## arguments: 
    ##     $1: name
    ##     $2: file or dir path
    ## color setting
    printf "%-30.30s" "$1"
    firstarg=''
    err=''
    for i in "${@}" ; do
        if [ -z "$firstarg" ] ; then
            firstarg=$i
            continue
        fi
        if [ ! -e "$i" ];then
            err=$err"    $i\n"
        fi
    done
    if [ -z "$err" ] ; then
        printf "    ${GREEN}OK${NC}\n"
    else
        printf "    ${RED}FAILED${NC}\n"
        printf "$err\n"
    fi 
    }

settingFile=$1
if [ -z "$settingFile" ] ; then
    echo "Usage: "
    echo "    ./check_analysis.sh <setting file>"
    echo ''
    exit
elif [ ! -f "$settingFile" ];then
    echo "$settingFile not found"
    exit
else
    echo "Checking $settingFile"
fi

# Prediction use_case check
source "$settingFile"

## Assimulation with full field or anomaly field
if  (( ${ANOMALYASSIM} ))  ; then
    fforano=anom
else
    fforano=ff
fi

## Check case dir
printf "NorCPM case: $BLUE$NORCPM_CASEDIR$NC\n"
check 'Case dir' $NORCPM_CASEDIR
check '  First member'  "${NORCPM_CASEDIR}/${NORCPM_CASE}_mem001"

## Check grid path
printf "grid.nc: $BLUE$GRIDPATH$NC\n"
check '  grid.nc' $GRIDPATH 

## Check workshared
printf "WORKSHARED: $BLUE$WORKSHARED$NC\n"
check "WORKSHARED" $WORKSHARED
#### Check binary
check "  bin" "${WORKSHARED}/bin"
check "  bin/ensave" "${WORKSHARED}/bin/ensave"
check "  bin/prep_obs_${fforano}_V${EnKF_Version}" "${WORKSHARED}/bin/prep_obs_${fforano}_V${EnKF_Version}"
check "  bin/EnKF" "${WORKSHARED}/bin/EnKF_tp_${fforano}_V${EnKF_Version}"
check "  bin/micom_ensemble_init" "${WORKSHARED}/bin/micom_ensemble_init_${RES}"

check "  Script" "${WORKSHARED}/Script"
check "  Script/Link_forecast_nocopy_V${EnKF_Version}.sh" "${WORKSHARED}/Script/Link_forecast_nocopy_V${EnKF_Version}.sh"
check "  Script/pbs_enkf.sh_V1_mal" "${WORKSHARED}/Script/pbs_enkf.sh_V1_mal"
    
check "  Input"  "${WORKSHARED}/Input"
check "  Obs"    "${WORKSHARED}/Obs"

## Check data files for data assimilation
#### Data files and mean files(for anomaly)
NOWDATE=$(cat ${NORCPM_RUNDIR}/${NORCPM_CASE}_mem001/run/rpointer.ocn| sed 's/.*\.r\.\(....-..-..-.....\)\.nc/\1/')
mmNow=`echo $NOWDATE | cut -c6-7`
yrNow=`echo $NOWDATE | cut -c1-4` 
day=`echo $NOWDATE | cut -c9-10` 

printf "Obs files check:\n"

for iobs in ${!OBSLIST[*]}; do
    OBSTYPE=${OBSLIST[$iobs]}
    PRODUCER=${PRODUCERLIST[$iobs]}
    MONTHLY=${MONTHLY_ANOM[$iobs]}  ## need mean data
    REF_PERIOD=${REF_PERIODLIST[$iobs]}  ## for mean data
    COMB_ASSIM=${COMBINE_ASSIM[$iobs]}    #sequential/joint observation assim 
    printf "  $OBSTYPE,$PRODUCER:\n"

    #### check obs data
    mm=$mmNow
    obsfiles=''
    for y in $(seq $yrNow $ENDYEAR) ; do
    for m in $(seq -w $mm 12) ; do
        obsfiles="$obsfiles ${WORKSHARED}/Obs/${OBSTYPE}/${PRODUCER}/${y}_${m}.nc"
    done
    mm=01
    done
    check "   ObsData:" $obsfiles
    if [ ! "$PRODUCER" == "HADISST2" ] ; then  ## HADISST2 does not need unc file(?)
        #### check obsunc file
        uncfile=${WORKSHARED}/Input/NorESM/${RES}/${PRODUCER}/${RES}_${OBSTYPE}_obs_unc_${fforano}.nc
        check "    ObsUnc:" "$uncfile"
    fi

        ## copy/paste from submit_reanalysis
        if (( ${ANOMALYASSIM} )) ; then
            if (( ${MONTHLY} )) ; then ## monthly anomaly or yearly
                meanobs=$(echo ${WORKSHARED}/Obs/${OBSTYPE}/${PRODUCER}/${OBSTYPE}_avg_{01..12}-${REF_PERIOD}.nc)
                check "    meanobs" ${meanobs}
                if ((${ANOM_CPL})) ; then
                    anomcpl=$(echo ${WORKSHARED}/Input/NorESM/${RES}/Anom-cpl-average{01..12}-${REF_PERIOD}.nc)
                    check "    anomcpl" ${anomcpl}
                else
                    avgcpl=$(echo ${WORKSHARED}/Input/NorESM/${RES}/Free-average{01..12}-${REF_PERIOD}.nc)
                    check "    avgcpl" ${avgcpl}
                fi # ${ANOM_CPL}
            else
                meanobs=$(echo ${WORKSHARED}/Obs/${OBSTYPE}/${PRODUCER}/${OBSTYPE}_avg_${REF_PERIOD}.nc)
                check "    meanobs" ${meanobs}
                if ((${ANOM_CPL})) ; then
                    anomcpl=$(echo ${WORKSHARED}/Input/NorESM/${RES}/Anom-cpl-average${REF_PERIOD}.nc)
                    check "    anomcpl" ${anomcpl}
                else
                    avgcpl=$(echo ${WORKSHARED}/Input/NorESM/${RES}/Free-average${REF_PERIOD}.nc)
                    check "    avgcpl" ${avgcpl}
                fi # ${ANOM_CPL}
            fi # ${MONTHLY}
        fi # ${ANOMALYASSIM}
  
done

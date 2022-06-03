#!/bin/bash

## NorCPM prediction and analysis setting check
## Usage: 
## 	./check_case.sh <setting file>

## color setting
RED='[\033[0;91m'
GREEN='[\033[0;92m'
NC='\033[0m]' # No Color

settingFile=$1
if [ -z "$settingFile" ] ; then
    echo "Usage: "
    echo "    ./check_case.sh <setting file>"
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
MEM01=${MEMBER1:-01}

## Location of NorESM
printf "NorESM location: $CCSMROOT"
if [ ! -d "$CCSMROOT" ];then
    printf "  ${RED}Path not exist.${NC}\n"
elif [ ! -f "${CCSMROOT}/cime/scripts/create_newcase" ]; then
    printf "  ${RED}create_newcase not exist.${NC}\n"
elif [ ! -f "${CCSMROOT}/cime/scripts/create_clone" ]; then
    printf "  ${RED}create_newcase not exist.${NC}\n"
else
    printf "  ${GREEN}OK${NC}\n"
fi 


if [ -z "$START_YYYYMM" ]; then
    for y in $START_YEARS; do
    for m in $START_MONTHS; do
        mm=$(printf '%2.2d' $m)
        START_YYYYMM="${START_YYYYMM} $y$mm"
    done #START_YEAR0
    done #START_MONTH0
fi

for START_YYYYMM0 in $START_YYYYMM; do
START_YEAR0=$(echo $START_YYYYMM0 | cut -c -4)
START_MONTH0=$(echo $START_YYYYMM0 | cut -c 5-)
for START_DAY0 in $START_DAYS; do
## Restart files for each member
echo "Total ${NMEMBER} members, check restart"
if [ "$RESTART_NOT_DA" == "True" ];then
    START_MONTH0=$(($START_MONTH0 + 1))
    if [ "$START_MONTH0" == 13 ];then
        START_YEAR0=$(($START_YEAR0 +1))
        START_MONTH0=1
    fi
fi
for i in $(seq $MEM01 $(($MEM01 + $NMEMBER -1))) ; do
    restdir=${REST_PATH_LOCAL}/${REST_PREFIX}$(printf '%2.2d' ${i})
    test -d "${restdir}/rest" && restdir="${restdir}/rest"
    printf ${restdir}
    if [ ! -d ${restdir} ] ;then
        printf "  ${RED}Restart not found${NC}\n"
    elif [ ! -d ${restdir}/${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000 ] ;then
        printf "  ${RED}Date not found${NC}\n"
        echo "    ${restdir}/${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000"
    elif [ -z ${RUN_REFCASE} ] && [ -z $(ls ${restdir}/${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000/${REST_PREFIX}$(printf '%2.2d' ${i}).{micom,blom}.r.${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000.nc* 2> /dev/null) ] ; then
        printf "  ${RED}Restart file not found${NC}\n"
    	echo "    ${restdir}/${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000/${REST_PREFIX}$(printf '%2.2d' ${i}).micom.r.${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000.nc[.gz]"
    	echo "    ${restdir}/${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000/${REST_PREFIX}$(printf '%2.2d' ${i}).blom.r.${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000.nc[.gz]"
    elif [ ! -z ${RUN_REFCASE} ] && [ -z $(ls ${restdir}/${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000/${RUN_REFCASE}.{micom,blom}.r.${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000.nc* 2> /dev/null) ] ; then
        printf "  ${RED}Restart file not found${NC}\n"
    	echo "    ${restdir}/${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000/${RUN_REFCASE}.micom.r.${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000.nc[.gz]"
    	echo "    ${restdir}/${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000/${RUN_REFCASE}.blom.r.${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000.nc[.gz]"
        
    else
        printf "  ${GREEN}OK${NC}\n"
    fi
done
done ## START_DAYS
done ## START_YYYYMM
## RUN_REFCASE , not yet


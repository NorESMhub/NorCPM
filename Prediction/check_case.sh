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
MEM01=${MEMBER1:-001}

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

## Restart files for each member
echo "Total ${NMEMBER} members, check restart"
for i in $(seq $MEM01 $(($MEM01 + $NMEMBER -1))) ; do
    restdir=${REST_PATH_LOCAL}/${REST_PREFIX}$(printf '%3.3d' ${i})
    printf ${restdir}
    if [ ! -d ${restdir} ] ;then
        printf "  ${RED}Restart not found${NC}\n"
    elif [ ! -d ${restdir}/${START_YEARS}-${START_MONTHS}-${START_DAYS}-00000 ] ;then
        printf "  ${RED}Date not found${NC}\n"
        echo "    ${restdir}/${START_YEARS}-${START_MONTHS}-${START_DAYS}-00000"
    elif [ -z ${RUN_REFCASE} ] && [ -z $(ls ${restdir}/${START_YEARS}-${START_MONTHS}-${START_DAYS}-00000/${REST_PREFIX}$(printf '%3.3d' ${i}).{micom,blom}.r.${START_YEARS}-${START_MONTHS}-${START_DAYS}-00000.nc 2> /dev/null) ] ; then
        printf "  ${RED}Restart file not found${NC}\n"
    	echo "    ${restdir}/${START_YEARS}-${START_MONTHS}-${START_DAYS}-00000/${REST_PREFIX}$(printf '%3.3d' ${i}).micom.r.${START_YEARS}-${START_MONTHS}-${START_DAYS}-00000.nc"
    	echo "    ${restdir}/${START_YEARS}-${START_MONTHS}-${START_DAYS}-00000/${REST_PREFIX}$(printf '%3.3d' ${i}).blom.r.${START_YEARS}-${START_MONTHS}-${START_DAYS}-00000.nc"
    elif [ ! -z ${RUN_REFCASE} ] && [ -z $(ls ${restdir}/${START_YEARS}-${START_MONTHS}-${START_DAYS}-00000/${RUN_REFCASE}.{micom,blom}.r.${START_YEARS}-${START_MONTHS}-${START_DAYS}-00000.nc 2> /dev/null) ] ; then
        printf "  ${RED}Restart file not found${NC}\n"
    	echo "    ${restdir}/${START_YEARS}-${START_MONTHS}-${START_DAYS}-00000/${RUN_REFCASE}.micom.r.${START_YEARS}-${START_MONTHS}-${START_DAYS}-00000.nc"
    	echo "    ${restdir}/${START_YEARS}-${START_MONTHS}-${START_DAYS}-00000/${RUN_REFCASE}.blom.r.${START_YEARS}-${START_MONTHS}-${START_DAYS}-00000.nc"
        
    else
        printf "  ${GREEN}OK${NC}\n"
    fi
done
## RUN_REFCASE , not yet


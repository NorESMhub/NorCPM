#!/bin/bash -e

## Source setting file
test -f "$1" && (echo "Usage: $0 use_case/settingfile.sh" ; exit 1) || source $1
envfile="${NORCPMROOT}/Analysis/env/env.${MACH}"
source $envfile
MEM01=$(printf "%2.2d" $((10#$MEM01))

## def functions
create () { ## create case 
    ## eye candy
    local GREEN='[\033[0;92m'
    local NC='\033[0m]' # No Color
    ## arguments
    local CASENAME="$1" ## NorCPM case name
    local MEM="$(printf '%2.2d' $((10#$2)))"
    local STARTDATE="$3" ## should be YYYY-MM-DD

    echo "Creating $CASENAME member $MEM of $STARTDATE"
    ## derived variables
    local CASEPATH="${CASESROOT}/${CASENAME}/${CASENAME}_${MEMTAG}${MEM}"
    local CASE01PATH="${CASESROOT}/${CASENAME}/${CASENAME}_${MEMTAG}${MEM01}"
    local EXEROOT="${EXESROOT}/${CASENAME}/${CASENAME}_${MEMTAG}${MEM}"
    local EXE01ROOT="${EXESROOT}/${CASENAME}/${CASENAME}_${MEMTAG}${MEM01}"
    local RUNDIR="${EXEROOT}/run"
    local RUN01DIR="${EXE01ROOT}/run"
    local DOUT_S_ROOT="${ARCHIVESROOT}/${CASENAME}/${CASENAME}_${MEMTAG}${MEM}"

    local RESTART_DATE="${STARTDATE}"
    test "$RESTART_NOT_DA" == "true" && local RESTART_DATE=$(date -d "$RESTART_DATE +1 month" +%Y-%m-%d)
    local RESTPATH="${REST_PATH}/${REST_PREFIX}${MEM}/${RESTART_DATE}-00000"
    test -d "$RESTPATH" || local RESTPATH="${REST_PATH}/${REST_PREFIX}${MEM}/rest/${RESTART_DATE}-00000"

    ### testing, remove it before 
    #echo $CASEPATH
    #echo "Testing, remove this at newcreate.sh:29"
    #return

    ## remove existed case dir (not yet)

    ## create case
    mkdir -p "${CASESROOT}/${CASENAME}"
    logfile="${CASESROOT}/${CASENAME}/create_${CASENAME}_${MEMTAG}${MEM}.log"
    echo "  logfile: ${logfile}"
    ## create 1st case, clone to others
    if [ "$MEM" -eq "$MEM01" ];then
        ${NORESMROOT}/cime/scripts/create_newcase \
            --case "$CASEPATH" --compset "$COMPSET" --res "$RES" --mach "$MACH" --project "$ACCOUNT" \
            >& ${logfile}
    else
        ${NORESMROOT}/cime/scripts/create_clone \
            --case "$CASEPATH" --clone "$CASE01PATH" \
            >& ${logfile}
    fi

    ## init case
    cd "$CASEPATH"
    ./xmlchange EXEROOT=${EXEROOT},RUNDIR=${RUNDIR},DOUT_S_ROOT=${DOUT_S_ROOT}
    ./xmlchange --id GET_REFCASE --val FALSE
    ./xmlchange --id RUN_TYPE --val "$RUNTYPE"
    ## check RUN_REFCASE, not done yet
    ./xmlchange --id RUN_REFCASE --val ${REST_PREFIX}${MEMBER}
    if [ "$RUNTYPE" == "hybrid" ]; then
        ./xmlchange --id RUN_REFDATE   --val "${REF_YEAR}-${REF_MONTH}-${REF_DAY}"
        ./xmlchange --id RUN_STARTDATE --val "$STARTDATE"
    else
        ./xmlchange --id RUN_REFDATE   --val "$STARTDATE"
    fi

    ## setup for NorCPM2
    ### set CPU usage
    ./xmlchange NTASKS=${NTASKS},NTASKS_OCN=${NTASKS_OCN},NTASKS_ESP=1,ROOTPE=0
    ### add environment for modified cime_comp_mod.F90
    if [ "$MEM" -eq "$MEM01" ];then
        sed -i -e'/<\/environment_variables>/i\ \ \ \ <env\ name=\"MEMBER_PES\">'${MEMBER_PES}'<\/env>' \
            env_mach_specific.xml
        sed -i -e'/<group id=.case.run.>/a    <entry id=\"task_count\" value=\"'${TOTALPE}'\"><type>char<\/type><\/entry>' env_batch.xml
    fi

    cp ${NORCPMROOT}/SourceMods.noresm2/src.drv/cime_comp_mod.F90 ./SourceMods/src.drv/
    cp ${NORCPMROOT}/SourceMods.noresm2/src.clm/controlMod.F90 ./SourceMods/src.clm/

    if [ ! -z "$STOP_N" ] ; then ## analysis run has own STOP_N 
        ./xmlchange STOP_N=${STOP_N},STOP_OPTION=${STOP_OPTION}
    fi
    ./xmlchange --subgroup 'case.run' JOB_WALLCLOCK_TIME=${WALLTIME}
    ./xmlchange --subgroup 'case.st_archive' JOB_WALLCLOCK_TIME=24:00:00
    #./xmlchange --subgroup 'case.st_archive' template=template.st_archive_NorCPM_mem01

    eval $PRECASESETUP
    test "$MEM" -eq "$MEM01" && eval $PRECASESETUP01 || true

    ## stage restart data
    echo "  Staging restart data"
    mkdir -p "$RUNDIR"
    mkdir -p "${RUNDIR}/timing/checkpoints/"  ## if not, run will stucked at 1 day run

    if [ ! -z "$(ls $RESTPATH/*.nc 2>/dev/null)" ] ; then
        ln -sf $RESTPATH/*.nc "$RUNDIR"/
    elif [ ! -z "$(ls $RESTPATH/*.nc.gz 2>/dev/null)" ] ; then
        for i in $RESTPATH/*.nc.gz ; do
            ofn=$(basename "$i")
            ofn=${ofn%.gz}
            echo -n "    gunzip ${ofn}"
            gunzip -c "$i" > "${RUNDIR}/${ofn}"
            printf    "  ${GREEN}DONE${NC}\n"
        done
    fi
    cp -f $RESTPATH/rpointer* "${RUNDIR}/" 

    ## check result
    if [ -z "$(ls $RUNDIR/*.r.*.nc rpointer* 2> /dev/null)" ] ; then
        echo "Restart files link failed. please check RESTPATH: "
        echo "$RESTPATH"
        exit 1
    fi

    ## check RUN_REFCASE
    if [ -z "$(ncdump -h $RUNDIR/*.cam.r.*.nc |grep $REST_PREFIX)" ];then
        RUN_REFCASE=$(ncdump -h "$RUNDIR/*.cam.r.*.nc" | grep caseid | sed 's/[^"]*"\([^"]*\)".*/\1/')
        ./xmlchange --id RUN_REFCASE --val ${RUN_REFCASE}
    else
        ./xmlchange --id RUN_REFCASE --val ${REST_PREFIX}${MEM}
    fi

    ## case.setup
    './case.setup' >>  "${logfile}" 2>&1

    ## case.build
    ### build first case, link to others
    if [ "$MEM" -eq "$MEM01" ];then
        echo -n "  Building $CASENAME member $MEM of $STARTDATE"
        './case.build' >> "${logfile}" 2>&1
        printf "  ${GREEN}DONE${NC}"
    else
        echo "  Link binaries from mem01 $CASENAME member $MEM of $STARTDATE"
        for ITEM in atm cpl esp glc ice lnd ocn rof wav; do
            ln -sf  "${EXE01ROOT}/${ITEM}/obj/*" "${EXEROOT}/${ITEM}/obj/"
        done
        ln -sf  "${EXE01ROOT}/cesm.exe" "${EXEROOT}/cesm.exe"
        ln -sf  "${EXE01ROOT}/intel" "${EXEROOT}/intel"
        ln -sf  "${EXE01ROOT}/lib/*" "${EXEROOT}/lib/"
        ./xmlchange BUILD_COMPLETE=TRUE
        ./preview_namelists >> "${logfile}" 2>&1
    fi

    echo "${CASENAME}_${MEMTAG}${MEM} created."
}

check_restart () { ## check data 
    ## color setting
    local RED='[\033[0;91m'
    local GREEN='[\033[0;92m'
    local NC='\033[0m]' # No Color
    # Prediction use_case check
    local err=''

    ## Location of NorESM
    printf "NorESM location: $NORESMROOT"
    if [ ! -d "$NORESMROOT" ];then
        printf "  ${RED}Path not exist.${NC}\n"
        err="$err Path not exist"
    elif [ ! -f "${NORESMROOT}/cime/scripts/create_newcase" ]; then
        printf "  ${RED}create_newcase not exist.${NC}\n"
        err="$err create_newcase not exist"
    elif [ ! -f "${NORESMROOT}/cime/scripts/create_clone" ]; then
        printf "  ${RED}create_clone not exist.${NC}\n"
        err="$err create_clone not exist"
    else
        printf "  ${GREEN}OK${NC}\n"
    fi 

    for START_YYYYMM0 in $STARTS_YYYYMM; do
    START_YEAR0=$(echo $START_YYYYMM0 | cut -c -4)
    START_MONTH0=$(echo $START_YYYYMM0 | cut -c 6-)
    ## Restart files for each member
    for START_DAY0 in $START_DAY; do
    echo "Total ${NMEMBER} members, check restart"
    if [ "$RESTART_NOT_DA" == "True" ];then
        START_MONTH0=$(($START_MONTH0 + 1))
        if [ "$START_MONTH0" == 13 ];then
            START_YEAR0=$(($START_YEAR0 +1))
            START_MONTH0=1
        fi
    fi
    for i in $(seq $MEM01 $(($MEM01 + $NMEMBER -1))) ; do
        local ii=$(printf '%2.2d' $((10#$i))
        local restdir=${REST_PATH}/${REST_PREFIX}${ii}
        test -d "${restdir}/rest" && restdir="${restdir}/rest" || true
        printf "  ${restdir}"
        
        if [ ! -d ${restdir} ] ;then
            printf "  ${RED}Restart not found${NC}\n"
            err="$err Restart not found"
        elif [ ! -d ${restdir}/${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000 ] ;then
            printf "  ${RED}Date not found${NC}\n"
            echo "    ${restdir}/${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000"
            err="$err Data not found"
        elif [ -z ${RUN_REFCASE} ] &&   [ -z "$(ls ${restdir}/${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000/${REST_PREFIX}${ii}.blom.r.${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000{.nc,.nc.gz} 2> /dev/null)" ] ; then
            printf "  ${RED}Restart file not found${NC}\n"
            echo "    ${restdir}/${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000/${REST_PREFIX}${ii}.blom.r.${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000.nc"
            err="$err Restart file not found"
        elif [ ! -z ${RUN_REFCASE} ] && [ -z $(ls ${restdir}/${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000/${RUN_REFCASE}.blom.r.${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000{.nc,.nc.gz} 2> /dev/null) ] ; then
            printf "  ${RED}Restart file not found${NC}\n"
            echo "    ${restdir}/${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000/${RUN_REFCASE}.blom.r.${START_YEAR0}-${START_MONTH0}-${START_DAY0}-00000.nc"
            err="$err Restart file not found"
            
        else
            printf "  ${GREEN}OK${NC}\n"
        fi
    done
    done ## START_DAY
    done ## STARTS_YYYYMM
    ## RUN_REFCASE , not yet
    if [ ! -z "$err" ];then
        echo "$err"
        exit 1
    fi 
}

## The init date of each run
if [ -z "$STARTS_YYYYMM" ]; then
    for y in $START_YEARS; do
    for m in $START_MONTHS; do
        STARTS_YYYYMM="${STARTS_YYYYMM} ${y}-$(printf '%2.2d' $m)"
    done #START_YEARS
    done #START_MONTHS
fi

## more than 1 date: append year month to case name
read -r -a STARTDATES <<< "$STARTS_YYYYMM"
test "${#STARTDATES[@]}" -gt '1' && APPENDSTARTDATE=true

check_restart

## create cases (parallel not imply yet)
for STARTDATE in ${STARTDATES[@]}; do
for MEM in $(seq $MEM01 $(($MEM01 + $NMEMBER -1))); do
    CN="${CASENAME}"
    test "${APPENDSTARTDATE}" == 'true'  \
        && CN=${CASENAME}_$(echo ${STARTDATE}|tr -d '-' )

    create "$CN" "$MEM" "${STARTDATE}-${START_DAY}"

done ## MEM
done ## STARTDATE

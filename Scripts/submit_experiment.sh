#!/bin/bash -e
##############################################################################
## This script create and submit script to 
## do data assimilation with existed NorCPM2 case
##
##
##
##
##
## Ping-Gin.Chiu@uib.no  May2022
##############################################################################

## read setting
settingFile="$1"
source $settingFile
MEM01=$(printf "%2.2d" $((10#$MEM01)))

xmlq (){
    items=$*
    cd ${CASESROOT}/${CASENAME}/${CASENAME}_${MEMTAG}${MEM01}/ && \
    ./xmlquery --value $items
}

submit_analysis () {
    JOBTIME=$(xmlq --subgroup case.run JOB_WALLCLOCK_TIME)
    NTASKSPERNODE=$(xmlq MAX_TASKS_PER_NODE)
    NTASKS=$(xmlq --subgroup case.run task_count)
    NODES=$(($NTASKS / $NTASKSPERNODE))

    ## create submit script
    sfn=$(readlink -f $settingFile)
    sed  \
        -e "s/JOBACCOUNT/${ACCOUNT}/"    \
        -e "s/JOBNAME/${CASENAME}/"      \
        -e "s/JOBTIMEREQUEST/${JOBTIME}/"   \
        -e "s/JOBNODES/${NODES}/"           \
        -e "s/JOBNTASKS/${NTASKS}/"          \
        -e "s/NTASKSPERNODE/${NTASKSPERNODE}/"          \
        -e "s;SETTINGFILE;${sfn};"  \
        template/submit.template > ${CASENAME}_submit.sh

    ## submit script
    sbatch ${CASENAME}_submit.sh
}

submit_prediction  () {
    ## check all members start at same date
    if [ ! -z "$1" ] && [ -d ${EXESROOT}/${CASENAME}_${1} ] ; then
        local CASENAME=${CASENAME}_${1}
    fi
    RESTDATES=$(grep '\.r\.' ${EXESROOT}/${CASENAME}/${CASENAME}_${MEMTAG}*/run/rpointer.atm \
                | cut -d. -f4 | uniq | wc -l)
    test "$RESTDATES" -gt 1 && ( echo 'members time inconsistant, exit...' ; exit 1)

    ## update STOP_N and STOP_OPTION for all members
    NOWPWD=$PWD
    for c in ${CASESROOT}/${CASENAME}/${CASENAME}_${MEMTAG}* ; do
        cd "$c"
        if [ ! -z "$STOP_OPTION" ] ;then
            ./xmlchange STOP_OPTION=${STOP_OPTION},STOP_N=${STOP_N}
        fi
        ./xmlchange --subgroup 'case.run' JOB_WALLCLOCK_TIME=${WALLTIME}
        preview_namelists > preview_namelists.log 2>&1 & 
    done
    wait
    cd "$NOWPWD"
    
    ## submit first member
    cd ${CASESROOT}/${CASENAME}/${CASENAME}_${MEMTAG}${MEM01}/
    './case.submit'
    jobid=$(./xmlquery --value JOB_IDS| sed -e's/.*case.run:\([0-9]*\).*/\1/')

    ## submit others st_archive, if not subgroup template=template.st_archive_NorCPM_mem01
    if [ "$(./xmlquery  --value --subgroup case.st_archive template)" != 'template.st_archive_NorCPM_mem01' ] ;then
        NOWPWD=$PWD
        for c in ${CASESROOT}/${CASENAME}/${CASENAME}_${MEMTAG}* ; do
            test "$c" == "${CASESROOT}/${CASENAME}/${CASENAME}_${MEMTAG}${MEM01}" && continue
            cd "$c"
            ./xmlchange RESUBMIT=0
            './case.submit' --job 'case.st_archive' --prereq "${jobid}" > /dev/null &
        done
        wait
    fi

    cd "$NOWPWD"
}

submit_predictions () {
    n=0
    if [ -z "$STARTS_YYYYMM" ]; then
        for y in $START_YEARS; do
        for m in $START_MONTHS; do
            STARTS_YYYYMM="${STARTS_YYYYMM} $y$(printf '%2.2d' $((10#$m)))"
            n=$((n + 1))
        done #START_YEAR0
        done #START_MONTH0
    fi
    if [ $n -gt 1 ];then
        for yyyymm in $STARTS_YYYYMM ; do
            submit_prediction $yyyymm
        done
    else
        submit_prediction
    fi
}

check_input_analysis () { ## check obs data in analysis
    local RED='[\033[0;91m'
    local GREEN='[\033[0;92m'
    local BLUE='[\033[0;34m'
    local NC='\033[0m]' # No Color
    err=''

    check () {
        ## arguments: 
        ##     $1: name
        ##     $2: file or dir path
        ## color setting
        printf "  %-30.30s" "$1"
        local firstarg=''
        for i in "${@}" ; do
            if [ -z "$firstarg" ] ; then
                local firstarg=$i
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

    ## Assimulation with full field or anomaly field
    if  (( ${ANOMALYASSIM} ))  ; then
        local fforano=anom
    else
        local fforano=ff
    fi

    ## Check case dir
    printf "NorCPM case: ${BLUE}${CASESROOT}/${CASENAME}${NC}\n"
    check 'Case dir' ${CASESROOT}/${CASENAME}
    check '  First member'  "${CASESROOT}/${CASENAME}/${CASENAME}_${MEMTAG}${MEM01}"
    test -z "$err" || (echo "Error at case" ; exit 1)

    ## Check grid path
    printf "grid.nc: $BLUE$GRIDPATH$NC\n"
    check '  grid.nc' $GRIDPATH 
    test -z "$err" || (echo "Error at grid file" ; exit 1)

    ## Check workshared
    printf "WORKSHARED: $BLUE$WORKSHARED$NC\n"
    check "WORKSHARED" $WORKSHARED
    #### Check binary
    check "  bin" "${WORKSHARED}/bin"
    check "  bin/ensave" "${WORKSHARED}/bin/ensave"
    check "  bin/prep_obs_${fforano}_V${EnKF_Version}" "${WORKSHARED}/bin/prep_obs_${fforano}_V${EnKF_Version}"
    check "  bin/EnKF" "${WORKSHARED}/bin/EnKF_tp_${fforano}_V${EnKF_Version}"
    check "  bin/micom_ensemble_init" "${WORKSHARED}/bin/micom_ensemble_init_${RES}"
        
    check "  Input"  "${WORKSHARED}/Input"
    check "  Obs"    "${WORKSHARED}/Obs"

    test -z "$err" || (echo "Error at WORKSHARED" ; exit 1)

    ## Check data files for data assimilation
    #### Data files and mean files(for anomaly)
    local NOWDATE=$(cat ${EXESROOT}/${CASENAME}/${CASENAME}_${MEMTAG}${MEM01}/run/rpointer.ocn| sed 's/.*\.r\.\(....-..-..-.....\)\.nc/\1/')
    local mmNow=`echo $NOWDATE | cut -c6-7`
    local yrNow=`echo $NOWDATE | cut -c1-4` 
    local day=`echo $NOWDATE | cut -c9-10` 

    printf "Obs files check:\n"

    for iobs in ${!OBSLIST[*]}; do
        local OBSTYPE=${OBSLIST[$iobs]}
        local PRODUCER=${PRODUCERLIST[$iobs]}
        local MONTHLY=${MONTHLY_ANOM[$iobs]}  ## need mean data
        local REF_PERIOD=${REF_PERIODLIST[$iobs]}  ## for mean data
        local COMB_ASSIM=${COMBINE_ASSIM[$iobs]}    #sequential/joint observation assim 
        printf "  $OBSTYPE,$PRODUCER:\n"

        #### check obs data
        local mm=$mmNow
        local bsfiles=''
        ## ENDYEAR:
            #for y in $(seq $yrNow $ENDYEAR) ; do
            #for m in $(seq -w $mm 12) ; do
            #    local obsfiles="$obsfiles ${WORKSHARED}/Obs/${OBSTYPE}/${PRODUCER}/${y}_${m}.nc"
            #done
            #local mm=01
            #done
        for i in $(seq 0 $RESTART) ; do
            y=$(( $yrNow + ($i / 12) ))
            m=$(( 1 + ($i %12)))
            m=$(printf "%2.2d" $((10#$m)))
            local obsfiles="$obsfiles ${WORKSHARED}/Obs/${OBSTYPE}/${PRODUCER}/${y}_${m}.nc"
        done

        check "   ObsData:" $obsfiles
        if [ ! "$PRODUCER" == "HADISST2" ] ; then  ## HADISST2 does not need unc file(?)
            #### check obsunc file
            local uncfile=${WORKSHARED}/Input/NorESM/${RES}/${PRODUCER}/${RES}_${OBSTYPE}_obs_unc_${fforano}.nc
            check "    ObsUnc:" "$uncfile"
        fi

            ## copy/paste from submit_reanalysis
            if (( ${ANOMALYASSIM} )) ; then
                if (( ${MONTHLY} )) ; then ## monthly anomaly or yearly
                    local meanobs=$(echo ${WORKSHARED}/Obs/${OBSTYPE}/${PRODUCER}/${OBSTYPE}_avg_{01..12}-${REF_PERIOD}.nc)
                    check "    meanobs" ${meanobs}
                    if ((${ANOM_CPL})) ; then
                        local anomcpl=$(echo ${WORKSHARED}/Input/NorESM/${RES}/Anom-cpl-average{01..12}-${REF_PERIOD}.nc)
                        check "    anomcpl" ${anomcpl}
                    else
                        local avgcpl=$(echo ${WORKSHARED}/Input/NorESM/${RES}/Free-average{01..12}-${REF_PERIOD}.nc)
                        check "    avgcpl" ${avgcpl}
                    fi # ${ANOM_CPL}
                else
                    local meanobs=$(echo ${WORKSHARED}/Obs/${OBSTYPE}/${PRODUCER}/${OBSTYPE}_avg_${REF_PERIOD}.nc)
                    check "    meanobs" ${meanobs}
                    if ((${ANOM_CPL})) ; then
                        local anomcpl=$(echo ${WORKSHARED}/Input/NorESM/${RES}/Anom-cpl-average${REF_PERIOD}.nc)
                        check "    anomcpl" ${anomcpl}
                    else
                        local avgcpl=$(echo ${WORKSHARED}/Input/NorESM/${RES}/Free-average${REF_PERIOD}.nc)
                        check "    avgcpl" ${avgcpl}
                    fi # ${ANOM_CPL}
                fi # ${MONTHLY}
            fi # ${ANOMALYASSIM}
      
    done
    test -z "$err" || (echo "Analysis data check failed... exit 1" ; exit 1)
}


if [ -z "$ASSIMULATEMONTHDAY" ];then ## analysis run
    echo "submit prediction run(s)"
    submit_predictions
else
    echo "Checking data and programs"
    check_input_analysis
    ## check date of members
    NOWDATE=$(cat ${EXESROOT}/${CASENAME}/${CASENAME}_${MEMTAG}*/run/rpointer.ocn| sed 's/.*\.r\.\(....-..-..-.....\)\.nc/\1/' | uniq | wc -l)
    test $NOWDATE -gt 1 && (echo "Date of members are not consistant" ; exit 1) 

    echo "submit analysis run"
    submit_analysis
fi
echo 'Done'

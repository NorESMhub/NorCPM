# EXPERIMENT DEFAULT SETTINGS 
# USE VARNAME=VALUE ARGUMENT WHEN CALLING SCRIPT TO OVERRIDE DEFAULTS 

# experiment settings
: ${EXPERIMENT:=noresm2-mm_pi-cmip6} # case prefix, not including _YYYYMMDD_memXX suffix 
: ${MEMBER1:=1} # first member  
: ${ENSSIZE:=1} # number of members 
: ${COMPSET:=N1850frc2}
: ${USER_MODS_DIR:=$SETUPROOT/user_mods/noresm2-mm_pi-cmip6_640pes}   
: ${RES:=f09_tn14}
: ${START_DATE:=1500-01-01} # YYYY-MM-DD 

# initialisation settings
: ${RUN_TYPE:=branch}  
: ${REF_CASE_LIST:='N1850frc2_f09_tn14_20191113'} # loop over these cases 
: ${REF_PATH_LOCAL:=/cluster/shared/noresm/inputdata/ccsm4_init}
: ${LINK_RESTART_FILES:=1}
: ${REF_DATE:=$START_DATE} 
: ${ADD_PERTURBATION:=1} # only for RUN_TYPE=hybrid

# job settings
: ${STOP_OPTION:=nyears} # units for run length specification STOP_N 
: ${STOP_N:=10} # run continuesly for this length 
: ${RESTART:=19} # restart this many times  
: ${WALLTIME:='96:00:00'}
: ${ACCOUNT:=nn11071k}
: ${MAX_PARALLEL_STARCHIVE:=10}

# general settings 
: ${CASESROOT:=$SETUPROOT/../../cases}
: ${NORESMROOT:=$SETUPROOT/../../model/noresm2}
: ${ASK_BEFORE_REMOVE:=0} # 1=will ask before removing existing cases 
: ${VERBOSE:=1} # set -vx option in all scripts
: ${SKIP_CASE1:=0} # skip creating first/template case, assume it exists already 
: ${SDATE_PREFIX:=} # recommended are either empty or "s" 
: ${MEMBER_PREFIX:=mem} # recommended are either empty or "mem" 


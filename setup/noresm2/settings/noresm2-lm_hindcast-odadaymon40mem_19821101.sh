# EXPERIMENT DEFAULT SETTINGS 
# USE VARNAME=VALUE ARGUMENT WHEN CALLING SCRIPT TO OVERRIDE DEFAULTS 

# experiment settings
: ${EXPERIMENT:=noresm2-lm_hindcast-odadaymon40mem} # case prefix, not including _YYYYMMDD_memXX suffix 
: ${MEMBER1:=1} # first member  
: ${ENSSIZE:=10} # number of members 
: ${COMPSET:=NHISTfrc2}
: ${USER_MODS_DIR:=$SETUPROOT/user_mods/noresm2-lm_128pes}   
: ${RES:=f19_tn14}
: ${START_DATE:=1982-11-01} # YYYY-MM-DD 

# initialisation settings
: ${RUN_TYPE:=branch}  
: ${REF_CASE_LIST:='noresm2-lm_odadaymon_40mem_19820101_mem001 noresm2-lm_odadaymon_40mem_19820101_mem002 noresm2-lm_odadaymon_40mem_19820101_mem003 noresm2-lm_odadaymon_40mem_19820101_mem004 noresm2-lm_odadaymon_40mem_19820101_mem005 noresm2-lm_odadaymon_40mem_19820101_mem006 noresm2-lm_odadaymon_40mem_19820101_mem007 noresm2-lm_odadaymon_40mem_19820101_mem008 noresm2-lm_odadaymon_40mem_19820101_mem009 noresm2-lm_odadaymon_40mem_19820101_mem010'} # loop over these cases 
: ${REF_PATH_LOCAL:=/cluster/work/users/$USER/archive/noresm2-lm_odadaymon_40mem/noresm2-lm_odadaymon_40mem_19820101}
: ${LINK_RESTART_FILES:=1}
: ${REF_DATE:=$START_DATE} 
: ${ADD_PERTURBATION:=0} # only for RUN_TYPE=hybrid

# job settings
: ${STOP_OPTION:=nmonths} # units for run length specification STOP_N 
: ${STOP_N:=124} # run continuesly for this length 
: ${RESTART:=0} # restart this many times  
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

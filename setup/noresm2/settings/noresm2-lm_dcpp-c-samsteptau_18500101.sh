# EXPERIMENT DEFAULT SETTINGS 
# USE VARNAME=VALUE ARGUMENT WHEN CALLING SCRIPT TO OVERRIDE DEFAULTS 

# experiment settings
: ${EXPERIMENT:=noresm2-lm_dcpp-c-samsteptau} # case prefix, not including _YYYYMMDD_memXX suffix 
: ${MEMBER1:=1} # first member  
: ${ENSSIZE:=10} # number of members 
: ${COMPSET:=N1850frc2}
: ${USER_MODS_DIR:=$SETUPROOT/user_mods/noresm2-lm_dcpp-c-samsteptau_128pes}   
: ${RES:=f19_tn14}
: ${START_DATE:=1950-01-01} # YYYY-MM-DD 

# initialisation settings
: ${RUN_TYPE:=hybrid}  
: ${REF_CASE_LIST:='N1850_f19_tn14_20190621'} # loop over these cases 
: ${REF_PATH_LOCAL:= /cluster/projects/nn9039k/inputdata/ccsm4_init/}
: ${LINK_RESTART_FILES:=1}
: ${REF_DATE_LIST:='1601-01-01 1611-01-01 1621-01-01 1631-01-01 1641-01-01 1651-01-01 1661-01-01 1671-01-01 1681-01-01 1691-01-01'} 
: ${ADD_PERTURBATION:=0} # only for RUN_TYPE=hybrid

# job settings
: ${STOP_OPTION:=nyears} # units for run length specification STOP_N 
: ${STOP_N:=10} # run continuesly for this length 
: ${RESTART:=0} # restart this many times  
: ${WALLTIME:='72:00:00'}
: ${ACCOUNT:=nn9039k}
: ${MAX_PARALLEL_STARCHIVE:=10}

# general settings 
: ${CASESROOT:=$SETUPROOT/../../cases}
: ${NORESMROOT:=$SETUPROOT/../../model/noresm2}
: ${ASK_BEFORE_REMOVE:=0} # 1=will ask before removing existing cases 
: ${VERBOSE:=1} # set -vx option in all scripts
: ${SKIP_CASE1:=0} # skip creating first/template case, assume it exists already 
: ${SDATE_PREFIX:=} # recommended are either empty or "s" 
: ${MEMBER_PREFIX:=mem} # recommended are either empty or "mem" 


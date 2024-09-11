# EXPERIMENT DEFAULT SETTINGS 
# USE VARNAME=VALUE ARGUMENT WHEN CALLING SCRIPT TO OVERRIDE DEFAULTS 

# experiment settings
: ${EXPERIMENT:=noresm2-lmesm_freetest} # case prefix, not including _YYYYMMDD_memXX suffix 
: ${MEMBER1:=1} # first member  
: ${ENSSIZE:=4} # number of members 
: ${COMPSET:=NHISTfrc2esm}
: ${USER_MODS_DIR:=$SETUPROOT/user_mods/noresm2-lmesm_128pes}   
: ${RES:=f19_tn14}
: ${START_DATE:=1970-01-01} # YYYY-MM-DD 

# initialisation settings
: ${RUN_TYPE:=hybrid}   
: ${REF_CASE_LIST:='NHIST_f19_tn14_20191104esm NHIST_1901_f19_tn14_20230201esm NHIST_1951_f19_tn14_20230201esm NHIST_2001_f19_tn14_20230201esm NHIST_2201_f19_tn14_20230201esm NHIST_2231_f19_tn14_20230201esm NHIST_2251_f19_tn14_20230201esm NHIST_2291_f19_tn14_20230201esm NHIST_2311_f19_tn14_20230201esm'} # full name of reference cases
: ${REF_PATH_LOCAL:=/cluster/work/users/$USER/restarts}
: ${REF_DATE:=1975-01-01}
: ${ADD_PERTURBATION:=1} # only for RUN_TYPE=hybrid

# job settings
: ${STOP_OPTION:=nyears} # units for run length specification STOP_N 
: ${STOP_N:=1} # run continuesly for this length 
: ${RESTART:=0} # restart this many times  
: ${WALLTIME:='00:59:00 --qos=devel'}
: ${ACCOUNT:=nn9039k}
: ${MAX_PARALLEL_STARCHIVE:=30}

# general settings 
: ${CASESROOT:=$SETUPROOT/../../cases}
: ${NORESMROOT:=$SETUPROOT/../../model/noresm2}
: ${ASK_BEFORE_REMOVE:=0} # 1=will ask before removing existing cases 
: ${VERBOSE:=1} # set -vx option in all scripts
: ${SKIP_CASE1:=0} # skip creating first/template case, assume it exists already 
: ${SDATE_PREFIX:=} # recommended are either empty or "s" 
: ${MEMBER_PREFIX:=mem} # recommended are either empty or "mem" 

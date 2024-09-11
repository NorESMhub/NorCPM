# EXPERIMENT DEFAULT SETTINGS 
# USE VARNAME=VALUE ARGUMENT WHEN CALLING SCRIPT TO OVERRIDE DEFAULTS 

# experiment settings
: ${EXPERIMENT:=norcpm-cf-system1_hindcast} # case prefix, not including _YYYYMMDD_memXX suffix 
: ${MEMBER1:=01} # first member  
: ${ENSSIZE:=60} # number of members 
: ${COMPSET:=N20TREXTAERCNCF1}
: ${RES:=f19_g16}
: ${START_DATE:=2023-04-15} # YYYY-MM-DD 

# initialisation settings
: ${RUN_TYPE:=branch} # branch: reference ensemble, hybrid: single reference simulation  
: ${REF_EXPERIMENT:=norcpm-cf-system1_assim_19811115} # name of reference experiment, including start date if necessary
: ${REF_SUFFIX_MEMBER1:=_mem01} # reference run used to initialise first member for 'branch', all members for 'hybrid' 
: ${REF_PATH_LOCAL_MEMBER1:=/cluster/work/users/$USER/archive/norcpm-cf-system1_assim/$REF_EXPERIMENT/$REF_EXPERIMENT$REF_SUFFIX_MEMBER1}
#: ${REF_PATH_LOCAL_MEMBER1:=/cluster/work/users/$USER/archive/$REF_EXPERIMENT/$REF_EXPERIMENT$REF_SUFFIX_MEMBER1}
: ${REF_PATH_REMOTE_MEMBER1:=}
: ${REF_DATES:=2023-04-15} # multiple reference dates only for RUN_TYPE=hybrid

# job settings
: ${STOP_OPTION:=nmonths} # units for run length specification STOP_N 
: ${STOP_N:=1} # run continuesly for this length 
: ${RESTART:=6} # restart this many times  
: ${WALLTIME:='24:00:00'}
: ${PECOUNT:=T} # T=32, S=64, M=96, L=128, X1=502
: ${ACCOUNT:=nn9873k}
: ${MAX_PARALLEL_STARCHIVE:=30}

# general settings 
: ${CASESROOT:=$SETUPROOT/../../cases}
: ${CCSMROOT:=$SETUPROOT/../../model/noresm1}
: ${SUBMIT_AFTER_SETUP:=0} # auto-submit after setting up experiment  
: ${ASK_BEFORE_REMOVE:=0} # 1=will ask before removing existing cases 
: ${VERBOSE:=1} # set -vx option in all scripts
: ${SKIP_CASE1:=0} # skip creating first/template case, assume it exists already 
: ${SDATE_PREFIX:=} # recommended are either empty or "s" 
: ${MEMBER_PREFIX:=mem} # recommended are either empty or "mem" 

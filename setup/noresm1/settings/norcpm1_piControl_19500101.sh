# EXPERIMENT DEFAULT SETTINGS   
# USE VARNAME=VALUE ARGUMENT WHEN CALLING SCRIPT TO OVERRIDE DEFAULTS 

# experiment settings
: ${EXPERIMENT:=noresm1-cmip6_preindustrial} # case prefix, not including _YYYYMMDD_memXX suffix 
: ${MEMBER1:=01} # first member  
: ${ENSSIZE:=1} # number of members 
: ${COMPSET:=N1850AERCNOCCMIP6}
: ${RES:=f19_g16}
: ${START_DATE:=1950-01-01} # YYYY-MM-DD  

# initialisation settings
: ${RUN_TYPE:=hybrid} # branch: reference ensemble, hybrid: single reference simulation  
: ${REF_EXPERIMENT:=noresm1-cmip6_preindustrial_00010101} # name of reference experiment, including start date if necessary
: ${REF_SUFFIX_MEMBER1:=_mem01} # reference run used to initialise first member for 'branch', all members for 'hybrid' 
: ${REF_PATH_LOCAL_MEMBER1:=$INPUTDATA/ccsm4_init/$REF_EXPERIMENT/$REF_EXPERIMENT$REF_SUFFIX_MEMBER1}
: ${REF_PATH_REMOTE_MEMBER1:=}
: ${REF_DATES:=0451-01-01} # multiple reference dates only for RUN_TYPE=hybrid

# job settings
: ${STOP_OPTION:=nyears} # units for run length specification STOP_N 
: ${STOP_N:=10} # run continuesly for this length 
: ${RESTART:=0} # restart this many times (perform assimilation three times before forecast) 
: ${WALLTIME:='96:00:00'}
: ${PECOUNT:=X1} # T=32, S=64, M=96, L=128, X1=502
: ${ACCOUNT:=nn9039k}
: ${MAX_PARALLEL_STARCHIVE:=30}

# general settings 
: ${CASESROOT:=$SETUPROOT/../../cases}
: ${CCSMROOT:=$SETUPROOT/../../model/noresm1}
: ${ASK_BEFORE_REMOVE:=1} # 1=will ask before removing existing cases 
: ${VERBOSE:=1} # set -vx option in all scripts
: ${SKIP_CASE1:=0} # skip creating first/template case, assume it exists already 
: ${SDATE_PREFIX:=}
: ${MEMBER_PREFIX:=mem}

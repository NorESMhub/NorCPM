# EXPERIMENT DEFAULT SETTINGS 
# USE VARNAME=VALUE ARGUMENT WHEN CALLING SCRIPT TO OVERRIDE DEFAULTS 

# experiment settings
: ${EXPERIMENT:=noresm2-mm-seaclim_hindcast-test} # case prefix, not including _YYYYMMDD_memXX suffix 
: ${MEMBER1:=1} # first member  
: ${ENSSIZE:=1} # number of members 
: ${COMPSET:=NHISTfrc2}
: ${USER_MODS_DIR:=$SETUPROOT/user_mods/noresm2-mm-seaclim_hindcast_640pes}   
: ${RES:=f09_tn14}
: ${START_DATE:=1993-11-01} # YYYY-MM-DD 

# initialisation settings
: ${RUN_TYPE:=branch}  
: ${REF_CASE_LIST:='noresm2-mm_oda_20mem_19811101_mem001 noresm2-mm_oda_20mem_19811101_mem002 noresm2-mm_oda_20mem_19811101_mem003 noresm2-mm_oda_20mem_19811101_mem004 noresm2-mm_oda_20mem_19811101_mem005 noresm2-mm_oda_20mem_19811101_mem006 noresm2-mm_oda_20mem_19811101_mem007 noresm2-mm_oda_20mem_19811101_mem008 noresm2-mm_oda_20mem_19811101_mem009 noresm2-mm_oda_20mem_19811101_mem010 noresm2-mm_oda_20mem_19811101_mem011 noresm2-mm_oda_20mem_19811101_mem012 noresm2-mm_oda_20mem_19811101_mem013 noresm2-mm_oda_20mem_19811101_mem014 noresm2-mm_oda_20mem_19811101_mem015 noresm2-mm_oda_20mem_19811101_mem016 noresm2-mm_oda_20mem_19811101_mem017 noresm2-mm_oda_20mem_19811101_mem018 noresm2-mm_oda_20mem_19811101_mem019 noresm2-mm_oda_20mem_19811101_mem020'} # loop over these cases 
: ${REF_PATH_LOCAL:= /nird/datalake/NS11071K/data/noresm/output/raw/noresm2-mm_oda_20mem/noresm2-mm_oda_20mem_19811101}
: ${LINK_RESTART_FILES:=0}
: ${REF_DATE:=$START_DATE} 
: ${ADD_PERTURBATION:=0} # only for RUN_TYPE=hybrid

# job settings
: ${STOP_OPTION:=nmonths} # units for run length specification STOP_N 
: ${STOP_N:=12} # run continuesly for this length 
: ${RESTART:=0} # restart this many times  
: ${WALLTIME:='12:00:00'}
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


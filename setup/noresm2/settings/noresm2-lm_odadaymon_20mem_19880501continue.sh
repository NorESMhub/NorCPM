# EXPERIMENT DEFAULT SETTINGS 
# USE VARNAME=VALUE ARGUMENT WHEN CALLING SCRIPT TO OVERRIDE DEFAULTS 

# experiment settings
: ${EXPERIMENT:=noresm2-lm_odadaymon_20mem} # case prefix, not including _YYYYMMDD_memXX suffix 
: ${MEMBER1:=1} # first member  
: ${ENSSIZE:=20} # number of members 
: ${COMPSET:=NHISTfrc2}
: ${USER_MODS_DIR:=$SETUPROOT/user_mods/noresm2-lm_128pes}   
: ${RES:=f19_tn14}
: ${START_DATE:=1982-01-01} # YYYY-MM-DD 

# initialisation settings
: ${RUN_TYPE:=branch}  
: ${REF_CASE_LIST:='noresm2-lm_odadaymon_20mem_19820101_mem001 noresm2-lm_odadaymon_20mem_19820101_mem002 noresm2-lm_odadaymon_20mem_19820101_mem003 noresm2-lm_odadaymon_20mem_19820101_mem004 noresm2-lm_odadaymon_20mem_19820101_mem005 noresm2-lm_odadaymon_20mem_19820101_mem006 noresm2-lm_odadaymon_20mem_19820101_mem007 noresm2-lm_odadaymon_20mem_19820101_mem008 noresm2-lm_odadaymon_20mem_19820101_mem009 noresm2-lm_odadaymon_20mem_19820101_mem010 noresm2-lm_odadaymon_20mem_19820101_mem011 noresm2-lm_odadaymon_20mem_19820101_mem012 noresm2-lm_odadaymon_20mem_19820101_mem013 noresm2-lm_odadaymon_20mem_19820101_mem014 noresm2-lm_odadaymon_20mem_19820101_mem015 noresm2-lm_odadaymon_20mem_19820101_mem016 noresm2-lm_odadaymon_20mem_19820101_mem017 noresm2-lm_odadaymon_20mem_19820101_mem018 noresm2-lm_odadaymon_20mem_19820101_mem019 noresm2-lm_odadaymon_20mem_19820101_mem020'} # loop over these cases 
: ${REF_PATH_LOCAL:=/cluster/work/users/ingo/archive/noresm2-lm_odadaymon_20mem/noresm2-lm_odadaymon_20mem_19820101}
: ${LINK_RESTART_FILES:=0}
: ${REF_DATE:=1988-05-01} 
: ${ADD_PERTURBATION:=0} # only for RUN_TYPE=hybrid

# job settings
: ${STOP_OPTION:=nmonths} # units for run length specification STOP_N 
: ${STOP_N:=6} # run continuesly for this length 
: ${RESTART:=60} # restart this many times  
: ${WALLTIME:='96:00:00'}
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

# assimilation settings
: ${ASSIMROOT:=$SETUPROOT/../../assim/enkf_noresm2_oda5}
: ${MEAN_MOD_DIR:=$INPUTDATA_ASSIM/enkf/$RES/NorESM2-LM-CMIP6}
: ${NTASKS_DA:=128}
: ${NTASKS_ENKF:=108}
: ${OCNGRIDFILE:=$INPUTDATA/ocn/blom/grid/grid_tnx1v4_20170622.nc}
: ${OBSLIST:='TEM SAL SST'}
: ${PRODUCERLIST:='EN422 EN422 NOAA'}
: ${FREQUENCYLIST:='MONTH MONTH DAY'} 
: ${REF_PERIODLIST:='1991-2020 1991-2020 1991-2020'}
: ${COMBINE_ASSIM:='0 0 1'}

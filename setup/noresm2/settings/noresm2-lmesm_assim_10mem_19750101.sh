# EXPERIMENT DEFAULT SETTINGS 
# USE VARNAME=VALUE ARGUMENT WHEN CALLING SCRIPT TO OVERRIDE DEFAULTS 

# experiment settings
: ${EXPERIMENT:=noresm2-lmesm_assim_10mem} # case prefix, not including _YYYYMMDD_memXX suffix 
: ${MEMBER1:=1} # first member  
: ${ENSSIZE:=10} # number of members 
: ${COMPSET:=NHISTfrc2esm}
: ${USER_MODS_DIR:=$SETUPROOT/user_mods/noresm2-lmesm_128pes}   
: ${RES:=f19_tn14}
: ${START_DATE:=1975-01-01} # YYYY-MM-DD 

# initialisation settings
: ${RUN_TYPE:=hybrid}   
: ${REF_CASE_LIST:='NHIST_f19_tn14_20191104esm NHIST_1901_f19_tn14_20230201esm NHIST_1951_f19_tn14_20230201esm NHIST_2001_f19_tn14_20230201esm NHIST_2201_f19_tn14_20230201esm NHIST_2231_f19_tn14_20230201esm NHIST_2251_f19_tn14_20230201esm NHIST_2291_f19_tn14_20230201esm NHIST_2311_f19_tn14_20230201esm'} # full name of reference cases
: ${REF_PATH_LOCAL:=/cluster/work/users/$USER/restarts}
: ${REF_DATE:=$START_DATE}
: ${ADD_PERTURBATION:=1} # only for RUN_TYPE=hybrid

# job settings
: ${STOP_OPTION:=nmonths} # units for run length specification STOP_N 
: ${STOP_N:=1} # run continuesly for this length 
: ${RESTART:=0} # restart this many times  
: ${WALLTIME:='00:59:00'}
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
: ${PRODUCERLIST:='EN422 EN422 HADISST2'}
: ${FREQUENCYLIST:='MONTH MONTH MONTH'}
: ${REF_PERIODLIST:='1980-2010 1980-2010 1980-2010'}
: ${COMBINE_ASSIM:='0 0 1'} 

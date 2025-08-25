# EXPERIMENT DEFAULT SETTINGS 
# USE VARNAME=VALUE ARGUMENT WHEN CALLING SCRIPT TO OVERRIDE DEFAULTS 

# experiment settings
: ${EXPERIMENT:=noresm2-lm_odadaymon_40mem} # case prefix, not including _YYYYMMDD_memXX suffix 
: ${MEMBER1:=1} # first member  
: ${ENSSIZE:=40} # number of members 
: ${COMPSET:=NHISTfrc2}
: ${USER_MODS_DIR:=$SETUPROOT/user_mods/noresm2-lm_128pes}   
: ${RES:=f19_tn14}
: ${START_DATE:=1982-01-01} # YYYY-MM-DD 

# initialisation settings
: ${RUN_TYPE:=hybrid}  
: ${REF_CASE_LIST:='NHISTfrc2_f19_tn14_LESFMIPhist-all_001 NHISTfrc2_f19_tn14_LESFMIPhist-all_002 NHISTfrc2_f19_tn14_LESFMIPhist-all_003 NHISTfrc2_f19_tn14_LESFMIPhist-all_004 NHISTfrc2_f19_tn14_LESFMIPhist-all_005 NHISTfrc2_f19_tn14_LESFMIPhist-all_006 NHISTfrc2_f19_tn14_LESFMIPhist-all_007 NHISTfrc2_f19_tn14_LESFMIPhist-all_008 NHISTfrc2_f19_tn14_LESFMIPhist-all_009 NHISTfrc2_f19_tn14_LESFMIPhist-all_010 NHISTfrc2_f19_tn14_LESFMIPhist-all_011 NHISTfrc2_f19_tn14_LESFMIPhist-all_012 NHISTfrc2_f19_tn14_LESFMIPhist-all_013 NHISTfrc2_f19_tn14_LESFMIPhist-all_014 NHISTfrc2_f19_tn14_LESFMIPhist-all_015 NHISTfrc2_f19_tn14_LESFMIPhist-all_016 NHISTfrc2_f19_tn14_LESFMIPhist-all_017 NHISTfrc2_f19_tn14_LESFMIPhist-all_018 NHISTfrc2_f19_tn14_LESFMIPhist-all_019 NHISTfrc2_f19_tn14_LESFMIPhist-all_020'} # loop over these cases 
: ${REF_PATH_LOCAL:=/cluster/shared/noresm/inputdata/ccsm4_init/NHISTfrc2_f19_tn14_LESFMIPhist-all}
: ${LINK_RESTART_FILES:=0}
: ${REF_DATE:=$START_DATE} 
: ${ADD_PERTURBATION:=1} # only for RUN_TYPE=hybrid

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

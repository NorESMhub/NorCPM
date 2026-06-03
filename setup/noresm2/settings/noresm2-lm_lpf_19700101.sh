# EXPERIMENT DEFAULT SETTINGS 
# USE VARNAME=VALUE ARGUMENT WHEN CALLING SCRIPT TO OVERRIDE DEFAULTS 

## Run for NorESM2-LM low-pass filter nudging test data
## issue: https://github.com/BjerknesCPU/BCPU-support/issues/48
##  install the latest state of https://github.com/NorESMhub/norcpm
##  clone noresm2-mm_free_19500101.sh setting file;
##  change name of experiment and set enssize=2
##    (the first member will become "control" and the second member "truth")
##  modify user_nl_cam of first member to output six-hourly instantaneous U,V,PS
##  integrate the two members over 2 years (i.e. 1950-1951)

START_DATE=1971-01-01
ENSSIZE=2
RESTART=1
EXPERIMENT=n209-lm_lpf_test04_set_lpf_nday_13
REF_PATH_LOCAL='/cluster/projects/nn9039k/people/pgchiu/noresm_cam_lpf_nudge/to_norcpm/restart/NHISTfrc2_f19_tn14_LESFMIPhist-all'
REF_DATE=1982-01-01 ## for restart file

Nudge_LPF_nday=13

# experiment settings
: ${EXPERIMENT:=noresm2-lm_lpf} # case prefix, not including _YYYYMMDD_memXX suffix 
: ${MEMBER1:=1} # first member  
: ${ENSSIZE:=30} # number of members 
: ${COMPSET:=NHISTfrc2}
: ${USER_MODS_DIR:=$SETUPROOT/user_mods/noresm2-lm_lpf_640pes}
: ${RES:=f19_tn14}
: ${START_DATE:=1971-01-01} # YYYY-MM-DD 

# initialisation settings
: ${RUN_TYPE:=hybrid}  
: ${REF_CASE_LIST:='NHISTfrc2_f19_tn14_LESFMIPhist-all_001 NHISTfrc2_f19_tn14_LESFMIPhist-all_002 NHISTfrc2_f19_tn14_LESFMIPhist-all_003 NHISTfrc2_f19_tn14_LESFMIPhist-all_004 NHISTfrc2_f19_tn14_LESFMIPhist-all_005 NHISTfrc2_f19_tn14_LESFMIPhist-all_006 NHISTfrc2_f19_tn14_LESFMIPhist-all_007 NHISTfrc2_f19_tn14_LESFMIPhist-all_008 NHISTfrc2_f19_tn14_LESFMIPhist-all_009 NHISTfrc2_f19_tn14_LESFMIPhist-all_010 NHISTfrc2_f19_tn14_LESFMIPhist-all_011 NHISTfrc2_f19_tn14_LESFMIPhist-all_012 NHISTfrc2_f19_tn14_LESFMIPhist-all_013 NHISTfrc2_f19_tn14_LESFMIPhist-all_014 NHISTfrc2_f19_tn14_LESFMIPhist-all_015'} # loop over these cases 
: ${REF_PATH_LOCAL:=/cluster/shared/noresm/inputdata/ccsm4_init/NHISTfrc2_f19_tn14_LESFMIPhist-all}
: ${LINK_RESTART_FILES:=0}
: ${REF_DATE:=$START_DATE} 
: ${ADD_PERTURBATION:=1} # only for RUN_TYPE=hybrid

# job settings
: ${STOP_OPTION:=nmonths} # units for run length specification STOP_N 
: ${STOP_N:=12} # run continuesly for this length 
: ${RESTART:=9} # restart this many times  
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

# LFP nudge time strength
: ${Nudge_LPF_nday:=5.}  ## 5 day average, larger for weaker nudge
: ${Nudge_LPF_Coef:=1.} ## nudge coeffident, usually 1.0
export Nudge_LPF_nday Nudge_LPF_Coef

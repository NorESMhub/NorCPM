#!/bin/sh -e

echo Determine absolute path of script directory and source settings file
SETUPROOT=`dirname \`readlink -f $0\` `
echo SETUPROOT is $SETUPROOT
. $SETUPROOT/source_settings.sh $*

echo Prepare logging 
mkdir -p $SETUPROOT/../../logs
LOGFILE=$SETUPROOT/../../logs/create-`date +%Y%m%d%H%M`_${EXPERIMENT}.log 
echo Write log file at $LOGFILE  
npipe=/tmp/$$.tmp
trap "rm -f $npipe" EXIT
mknod $npipe p
tee <$npipe $LOGFILE &
exec 1>& -
exec 1> $npipe 2>&1
echo Executed command: $0 $*
echo Git repository hashtag: `git log -1 --pretty=format:%H 2> /dev/null || echo not available`
echo

echo Setting up experiment ${EXPERIMENT}, this can take some time  
echo + BEGIN LOOP OVER MEMBERS 
for MEMBER in `seq -w $MEMBER1 $MEMBERN`
do
 
  echo ++ PICK REFERENCE DATE
  : ${REF_DATE:=$START_DATE} # set REF_DATE to START_DATE if REF_DATE nor REF_DATE_LIST set  
  if [[ $REF_DATE_LIST ]]
  then
    NREF=`echo $REF_DATE_LIST | wc -w` 
    REF_CASE=`echo $REF_DATE_LIST | cut -d' ' -f$(( ( ( $((10#$MEMBER-10#$MEMBER1+1)) - 1 ) % $NREF ) + 1 ))`
  fi 
  echo +++ Reference date for member $MEMBER set to: $REF_DATE
  #
  CASE=${EXPERIMENT}_${SDATE_PREFIX}${SDATE}_${MEMBER_PREFIX}$MEMBER
  RELPATH=$EXPERIMENT/${EXPERIMENT}_${SDATE_PREFIX}$SDATE/$CASE
  CASEROOT=$CASESROOT/$RELPATH
  EXEROOT=$WORK/noresm/$RELPATH
  CIME_OUTPUT_ROOT=$WORK/noresm/$EXPERIMENT/${EXPERIMENT}_${SDATE_PREFIX}$SDATE 
  DOUT_S_ROOT=$WORK/archive/$RELPATH
  # 
  CASE1=${EXPERIMENT}_${SDATE_PREFIX}${SDATE}_${MEMBER_PREFIX}$MEMBER1  
  RELPATH1=$EXPERIMENT/${EXPERIMENT}_${SDATE_PREFIX}$SDATE/$CASE1
  CASEROOT1=$CASESROOT/$RELPATH1
  EXEROOT1=$WORK/noresm/$RELPATH1

  if [[ $SKIP_CASE1 && $SKIP_CASE1 -eq 1 && $CASE == $CASE1 ]]
  then
    echo ++ SKIP CASE $CASE
    continue 
  else 
    echo ++ PREPARE CASE $CASE 
  fi 
 
  echo ++ REMOVE OLD CASE IF NEEDED
  for ITEM in $CASEROOT $EXEROOT 
  do
    if [ -e $ITEM ]
    then
      if [ $ASK_BEFORE_REMOVE -eq 1 ] 
      then 
        echo "remove existing $ITEM? (y/n)"
        if [ `read line ; echo $line` == "y" ]
        then
          rm -rf $ITEM
        fi
      else
        rm -rf $ITEM
      fi
    fi
  done

  echo ++ LOCATE REFERENCE CASE 
  if [[ $REF_CASE_SUFFIX_MEMBER1 && $REF_CASE_LIST ]]
  then 
    echo either REF_PREFIX,REF_CASE_SUFFIX_MEMBER1 or REF_CASE_LIST have to be set. will quit 
    exit  
  fi 
  if [[ $REF_CASE_LIST ]]
  then
    NREF=`echo $REF_CASE_LIST | wc -w` 
    REF_CASE=`echo $REF_CASE_LIST | cut -d' ' -f$(( ( ( $((10#$MEMBER-10#$MEMBER1+1)) - 1 ) % $NREF ) + 1 ))`
  fi
  if [ $REF_CASE_SUFFIX_MEMBER1 ]
  then 
    if [[ `echo $REF_CASE_SUFFIX_MEMBER1 | wc -c` -eq 4 || `echo $REF_CASE_SUFFIX_MEMBER1 | wc -c` -eq 7 ]]
    then 
      REF_MEMBER1=`echo $REF_CASE_SUFFIX_MEMBER1 | tail -3c`
      REF_MEMBER=`printf %02d $(( 10#$MEMBER + 10#$REF_MEMBER1 - 10#$MEMBER1 ))`
    else 
      REF_MEMBER1=`echo $REF_CASE_SUFFIX_MEMBER1 | tail -4c`
      REF_MEMBER=`printf %03d $(( 10#$MEMBER + 10#$REF_MEMBER1 - 10#$MEMBER1 ))`
    fi
    REF_SUFFIX=`basename $REF_CASE_SUFFIX_MEMBER1 $REF_MEMBER1`$REF_MEMBER
    REF_CASE=$REF_CASE_PREFIX$REF_SUFFIX
  fi
  REF_PATH=$REF_PATH_LOCAL/$REF_CASE/$REF_DATE
  if [ ! -e $REF_PATH ]
  then
    echo cannot locate restart data in $REF_PATH . will keep trying   
    REF_PATH=$REF_PATH_LOCAL/$REF_CASE/rest/$REF_DATE-00000
    if [ ! -e $REF_PATH ]
    then
      echo cannot locate restart data in $REF_PATH . will quit
      exit
    fi
  fi
  echo +++ use reference case $REF_CASE in $REF_PATH

  if [ $CASE == $CASE1 ]
  then 
    echo +++ CREATE MEMBER 1 CASE
    if [[ $INPUTDATA ]] 
    then 
      $SCRIPTSROOT/create_newcase --case $CASEROOT --compset $COMPSET --res $RES --mach $MACH --project $ACCOUNT --user-mods-dir $USER_MODS_DIR --run-unsupported --input-dir $INPUTDATA 
    else 
      $SCRIPTSROOT/create_newcase --case $CASEROOT --compset $COMPSET --res $RES --mach $MACH --project $ACCOUNT --user-mods-dir $USER_MODS_DIR --run-unsupported
    fi 

    echo +++ SET INITIALISATION 
    cd $CASEROOT
    ./xmlchange --file env_build.xml --id CIME_OUTPUT_ROOT --val $CIME_OUTPUT_ROOT
    ./xmlchange --file env_build.xml --id EXEROOT --val $EXEROOT
    ./xmlchange --file env_run.xml --id RUNDIR --val $EXEROOT/run
    ./xmlchange --file env_run.xml --id DOUT_S --val FALSE
    ./xmlchange --file env_run.xml --id DOUT_S_ROOT --val $DOUT_S_ROOT
    ./xmlchange --file env_run.xml --id RUN_REFCASE --val $REF_CASE
    ./xmlchange --file env_run.xml --id GET_REFCASE --val FALSE
    ./xmlchange --file env_run.xml --id RUN_TYPE --val $RUN_TYPE
    ./xmlchange --file env_run.xml --id RUN_STARTDATE --val $START_DATE
    if [[ $RUN_TYPE == branch && ! $START_DATE == $REF_DATE ]]
    then 
      ./xmlchange --file env_run.xml --id RUN_REFDATE --val $START_DATE
    else 
      ./xmlchange --file env_run.xml --id RUN_REFDATE --val $REF_DATE
    fi 
    if [[ $ADD_PERTURBATION && $ADD_PERTURBATION -eq 1 ]]
    then
      sed -i -e '/pertlim/d' user_nl_cam
      echo "pertlim = $((10#$MEMBER))e-10" >> user_nl_cam  
    fi 

    echo +++ CONFIGURE MEMBER 1 CASE 
    [ -e $USER_MODS_DIR/env_mach_pes.xml ] && cp -f $USER_MODS_DIR/env_mach_pes.xml . 
    [ -e $USER_MODS_DIR/env_mach_specific.xml ] && cp -f $USER_MODS_DIR/env_mach_specific.xml . 
    ./case.setup
    ./preview_namelists

    echo +++ BUILD MEMBER 1 CASE 
    ./case.build

  else

    echo +++ CLONE MEMBER 1 
    $SCRIPTSROOT/create_clone --clone $CASEROOT1 --case $CASEROOT --cime-output-root $CIME_OUTPUT_ROOT --keepexe 

    echo +++ SET INITIALISATION 
    cd $CASEROOT
    ./xmlchange --file env_build.xml --id CIME_OUTPUT_ROOT --val $CIME_OUTPUT_ROOT
    ./xmlchange --file env_run.xml --id RUNDIR --val $EXEROOT/run
    ./xmlchange --file env_run.xml --id DOUT_S --val FALSE
    ./xmlchange --file env_run.xml --id DOUT_S_ROOT --val $DOUT_S_ROOT
    ./xmlchange --file env_run.xml --id RUN_REFCASE --val $REF_CASE
    ./xmlchange --file env_run.xml --id GET_REFCASE --val FALSE
    ./xmlchange --file env_run.xml --id RUN_TYPE --val $RUN_TYPE
    ./xmlchange --file env_run.xml --id RUN_STARTDATE --val $START_DATE
    if [[ $RUN_TYPE == branch && ! $START_DATE == $REF_DATE ]]
    then 
      ./xmlchange --file env_run.xml --id RUN_REFDATE --val $START_DATE
    else 
      ./xmlchange --file env_run.xml --id RUN_REFDATE --val $REF_DATE
    fi 
    if [[ $ADD_PERTURBATION && $ADD_PERTURBATION -eq 1 ]]
    then
      sed -i -e '/pertlim/d' user_nl_cam
      echo "pertlim = $((10#$MEMBER))e-10" >> user_nl_cam  
    fi 

    echo +++ CONFIGURE CASE 
    [ -e $USER_MODS_DIR/env_mach_pes.xml ] && cp -f $USER_MODS_DIR/env_mach_pes.xml . 
    [ -e $USER_MODS_DIR/env_mach_specific.xml ] && cp -f $USER_MODS_DIR/env_mach_specific.xml . 
    ./case.setup
    ./preview_namelists

    echo +++ DUMMY BUILD
    ./case.build

  fi 
  echo ++ FINISHED PREPARING CASE

  echo ++ STAGE RESTART DATA 
  cd $EXEROOT/run 
  for ITEM in `ls $REF_PATH`
  do 
    if [[ `echo $ITEM | tail -c4` == .gz ]]
    then 
      cp -f --no-preserve=mode $REF_PATH/$ITEM .  
      gunzip -f $ITEM 
    elif [[ `echo $ITEM | tail -c4` == .nc ]]
    then
      if [[ ! $LINK_RESTART_FILES || $LINK_RESTART_FILES -eq 1 ]]
      then
        ln -sf $REF_PATH/$ITEM .
      else
        if [ -f $REF_PATH/$ITEM ]
        then 
          cp -f --no-preserve=mode $REF_PATH/$ITEM .  
        fi 
      fi
    else
      cp -f --no-preserve=mode $REF_PATH/$ITEM .  
    fi
  done 

done 
echo + END LOOP OVER MEMBERS 

echo + BUILD ASSIMILATION CODE IF NEEDED
if [[ ! $ASSIMROOT ]]
then
  echo ASSIMROOT not set, will skip building of assimilation code
else 
  mkdir -p $ANALYSISROOT
  cd $ANALYSISROOT
  . $ASSIMROOT/assim_build.sh
fi

echo + SETUP COMPLETED

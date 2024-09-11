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
  REF_DATE=$START_DATE
  COUNT=0
  for ITEM in $REF_DATES
  do
    COUNT=$((COUNT+1))
    if [[ $COUNT -eq 1 || $COUNT -eq $((10#$MEMBER-10#$MEMBER1+1)) ]]
    then 
      REF_DATE=$ITEM
    fi
  done 
  #
  CASE=${EXPERIMENT}_${SDATE_PREFIX}${SDATE}_${MEMBER_PREFIX}$MEMBER
  RELPATH=$EXPERIMENT/${EXPERIMENT}_${SDATE_PREFIX}$SDATE/$CASE
  CASEROOT=$CASESROOT/$RELPATH
  EXEROOT=$WORK/noresm/$RELPATH
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
  if [ $REF_SUFFIX_MEMBER1 ]
  then 
    REF_MEMBER1=`echo $REF_SUFFIX_MEMBER1 | tail -3c`
    if [ $RUN_TYPE == branch ]
    then 
      REF_MEMBER=`printf %02d $(( 10#$MEMBER + 10#$REF_MEMBER1 - 10#$MEMBER1 ))`
    else
      REF_MEMBER=$REF_MEMBER1
    fi 
    REF_SUFFIX=`basename $REF_SUFFIX_MEMBER1 $REF_MEMBER1`$REF_MEMBER
    REF_PATH_LOCAL=`dirname $REF_PATH_LOCAL_MEMBER1`/`basename $REF_PATH_LOCAL_MEMBER1 $REF_MEMBER1`$REF_MEMBER
  else 
    REF_PATH_LOCAL=$REF_PATH_LOCAL_MEMBER1
  fi
  REF_CASE=$REF_EXPERIMENT$REF_SUFFIX
  REF_CASE1=$REF_EXPERIMENT$REF_SUFFIX_MEMBER1
  REF_PATH=$REF_PATH_LOCAL/$REF_DATE
  if [ $RUN_TYPE == hybrid ]
  then 
    if [ $((10#$MEMBER)) -ne 1 ]
    then 
      if [ $REF_MEMBER1 ] 
      then 
        REF_PATH_TRY=${REF_PATH}_${MEMBER_PREFIX}`printf %02d $(( 10#$MEMBER + 10#$REF_MEMBER1 - 10#$MEMBER1 ))`
      else 
        REF_PATH_TRY=${REF_PATH}_${MEMBER_PREFIX}`printf %02d $(( 10#$MEMBER + 1 - 10#$MEMBER1 ))`
      fi 
      if [ -e $REF_PATH_TRY ]
      then 
        REF_PATH=$REF_PATH_TRY 
      fi 
    fi
  fi
  if [ ! -e $REF_PATH ]
  then
    echo cannot locate restart data in $REF_PATH . will keep trying   
    REF_PATH=$REF_PATH_LOCAL/rest/$REF_DATE-00000
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
      $SCRIPTSROOT/create_newcase -case $CASEROOT -compset $COMPSET -res $RES -mach $MACH -pecount $PECOUNT -din_loc_root_csmdata $INPUTDATA
    else 
      $SCRIPTSROOT/create_newcase -case $CASEROOT -compset $COMPSET -res $RES -mach $MACH -pecount $PECOUNT
    fi 

    echo +++ SET INITIALISATION 
    cd $CASEROOT
    ./xmlchange -file env_build.xml -id EXEROOT -val $EXEROOT
    ./xmlchange -file env_run.xml -id DOUT_S_ROOT -val $DOUT_S_ROOT
    ./xmlchange -file env_conf.xml -id RUN_REFCASE -val $REF_CASE
    ./xmlchange -file env_conf.xml -id GET_REFCASE -val FALSE
    ./xmlchange -file env_conf.xml -id BRNCH_RETAIN_CASENAME -val TRUE
    ./xmlchange -file env_conf.xml -id RUN_TYPE -val $RUN_TYPE
    ./xmlchange -file env_conf.xml -id RUN_STARTDATE -val $START_DATE
    if [[ $RUN_TYPE == branch && ! $START_DATE == $REF_DATE ]]
    then 
      ./xmlchange -file env_conf.xml -id RUN_REFDATE -val $START_DATE
    else 
      ./xmlchange -file env_conf.xml -id RUN_REFDATE -val $REF_DATE
    fi 

    echo +++ CONFIGURE MEMBER 1 CASE 
    ./configure -case

    echo +++ DEACTIVATE MICOM RESTART COMPRESSION
    sed -i s/" RSTCMP   =".*/" RSTCMP   = 0"/ Buildconf/micom.buildnml.csh

    echo +++ BUILD MEMBER 1 CASE 
    if [[ $SOURCE_MODS ]]
    then
      CASEDIR=`pwd`
      cd $SOURCE_MODS 
      for ITEM in `find . -type f`
      do
        cp $ITEM $CASEDIR/$ITEM
      done 
      cd $CASEDIR 
    fi
    set +e 
    ./$CASE.$MACH.build
    set -e 

  else
    echo +++ CLONE MEMBER 1 
    $SCRIPTSROOT/create_clone -clone $CASEROOT1 -case $CASEROOT

    echo +++ LINK BUILD OBJECTS AND EXECUTABLE FROM MEMBER 1
    mkdir -p $EXEROOT/run/timing/checkpoints $DOUT_S_ROOT
    cd $EXEROOT
    for ITEM in atm cpl ccsm csm_share glc ice ocn pio lib
    do
      ln -s  $EXEROOT1/$ITEM .
    done
    cd run
    ln -s $EXEROOT1/run/ccsm.exe . 

    echo +++ SET INITIALISATION 
    cd $CASEROOT
    ./xmlchange -file env_build.xml -id EXEROOT -val $EXEROOT
    ./xmlchange -file env_run.xml -id DOUT_S_ROOT -val $DOUT_S_ROOT
    ./xmlchange -file env_conf.xml -id RUN_REFCASE -val $REF_CASE
    ./xmlchange -file env_conf.xml -id GET_REFCASE -val FALSE
    ./xmlchange -file env_conf.xml -id BRNCH_RETAIN_CASENAME -val TRUE
    ./xmlchange -file env_conf.xml -id RUN_TYPE -val $RUN_TYPE
    ./xmlchange -file env_conf.xml -id RUN_STARTDATE -val $START_DATE
    if [[ $RUN_TYPE == branch && ! $START_DATE == $REF_DATE ]]
    then 
      ./xmlchange -file env_conf.xml -id RUN_REFDATE -val $START_DATE
    else 
      ./xmlchange -file env_conf.xml -id RUN_REFDATE -val $REF_DATE
    fi 

    echo +++ CONFIGURE CASE 
    ./configure -case

    echo +++ MODIFY RESTART PATH IN NAMELISTS
    sed -i "s/start_ymd      =.*/start_ymd      = $SDATE/" Buildconf/cpl.buildnml.csh
    sed -i "s%$RELPATH1/run/$REF_CASE1.cam2.r.$REF_DATE1%$RELPATH/run/$REF_CASE.cam2.r.$REF_DATE%" Buildconf/cam.buildnml.csh
    sed -i "s%$REF_CASE1.cice.r.$REF_DATE1%$REF_CASE.cice.r.$REF_DATE%" Buildconf/cice.buildnml.csh
    sed -i "s%$REF_CASE1.clm2.r.$REF_DATE1%$REF_CASE.clm2.r.$REF_DATE%" Buildconf/clm.buildnml.csh

    echo +++ DUMMY BUILD
    ./xmlchange -file env_build.xml -id BUILD_COMPLETE -val TRUE 
    sed -i '/source $CASETOOLS\/ccsm_buildexe/d' $CASE.$MACH.build
    ./$CASE.$MACH.build 

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

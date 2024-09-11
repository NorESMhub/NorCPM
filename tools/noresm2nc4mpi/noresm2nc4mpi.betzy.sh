#!/bin/bash -e

source /cluster/installations/lmod/lmod/init/sh
module --quiet restore system
module load StdEnv
module load intel/2022a
module load iompi/2022a
module load netCDF/4.9.0-iompi-2022a
module load NCO/5.1.9-iomkl-2022a 

### CUSTOMIZE BEGIN ###
CASEDIR=$1
: ${ACCOUNT:=nn9039k}
: ${WALLTIME:=24:00:00} 
: ${NTASKS:=64} 
: ${NODES:=4}
: ${ZIPRES:=1} # 1=gzip restart files
: ${RMLOGS:=0} # 1=remove log files 
: ${COMPLEVEL:=5}
#NCCOPY="$EBROOTNETCDF/bin/nccopy -7 -s -d $COMPLEVEL"
: ${NCCOPY:="${EBROOTNCO}/bin/ncks -7 --cnk_dmn kk,1 --cnk_dmn kk2,1 --cnk_dmn lev,1 --cnk_dmn plev,1 --cnk_dmn k2,1 --cnk_dmn k3,1 -L ${COMPLEVEL}"}
: ${GZIP:=`which gzip`}
: ${TEMPDIR:=/cluster/work/users/$USER/`basename $0 .sh`}
### CUSTOMIZE END ###

# check input argument and print help blurb if check fails
if [[ ! $1 || $1 == "-h" || $1 == "--help" ]]
then
cat <<EOF
Usage: `basename $0` <path to case in archive directory> 

Example: `basename $0` /cluster/work/users/${USER}/archive/my-noresm-case 
  
Purpose: Converts NorESM output to compressed netcdf 4 format and gzips restarts   

Change history: 2021.04.06 ported to BETZY
                2014.04.29 first version of `basename $0`
EOF
  exit 1
fi

# check that input folder exists
if [ ! -d $CASEDIR ] 
then 
  echo $CASEDIR not a directory! aborting... 
  exit 1 
fi 

# create temporary directory (if not existing) and cd 
mkdir -p $TEMPDIR
cd $TEMPDIR

# create convert exe 
if [ ! -e convert ]
then 
cat <<EOF> convert.c
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <mpi.h>
int main(int argc, char *argv[])
{
        int rank, result, i; char s[1024]; 
        MPI_Init(&argc, &argv);
        MPI_Comm_rank(MPI_COMM_WORLD, &rank);
        strcpy(s,"${NCCOPY} ");      
        for ( i = 0; i < argc-1; i++ ) {
          if (rank == i) {
            strcat(s,argv[i+1]);
            strcat(s," ");
            strcat(s,argv[i+1]);
            strcat(s,"_tmp ; mv ");
            strcat(s,argv[i+1]);
            strcat(s,"_tmp ");
            strcat(s,argv[i+1]); 
            strcat(s," ; chmod +r ");
            strcat(s,argv[i+1]); 
            printf("cpu=%3d: %s \n", rank+1, s);
            result = system(s);  
          }
        }
        MPI_Finalize();
}
EOF
mpicc -o convert convert.c
rm convert.c
fi

# create zip exe 
if [ ! -e zip ]
then
cat <<EOF> zip.c
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <mpi.h>
int main(int argc, char *argv[])
{
        int rank, result, i; char s[1024]; 
        MPI_Init(&argc, &argv);
        MPI_Comm_rank(MPI_COMM_WORLD, &rank);
        strcpy(s,"${GZIP} ");      
        for ( i = 0; i < argc-1; i++ ) {
          if (rank == i) {
            strcat(s,argv[i+1]);
            printf("cpu=%3d: %s \n", rank+1, s);
            result = system(s);  
          }
        }
        MPI_Finalize();
}
EOF
mpicc -o zip zip.c
rm zip.c
fi

# create PBS script and submit  
LID="`date +%y%m%d-%H%M%S`"
cat <<EOF> `basename $0 .sh`_${LID}.slurm
#! /bin/sh -evx
#SBATCH --account=${ACCOUNT}
#SBATCH --job-name=convert_${CASE_PREFIX}
#SBATCH --time=${WALLTIME}
#SBATCH --ntasks=${NTASKS}
#SBATCH --nodes=${NODES}
#SBATCH --output=${TEMPDIR}/`basename $0 .sh`_${LID}.out

source /cluster/installations/lmod/lmod/init/sh
module --quiet restore system
module load StdEnv
module load intel/2022a
module load iompi/2022a
module load netCDF/4.9.0-iompi-2022a
module load NCO/5.1.9-iomkl-2022a

cd ${CASEDIR} 

# do history files 
ARGS=' ' 
for ncfile in \`find . -wholename '*/hist/*.nc' -print\`; do
  if [ \`ncdump -k \${ncfile} | grep 'netCDF-4' | wc -l\` -eq 0 ] ; then
    ARGS=\${ARGS}' '\${ncfile} 
    if [ \`echo \${ARGS} | wc -w\` -eq ${NTASKS} ] ; then 
      mpirun -n ${NTASKS} ${TEMPDIR}/convert \${ARGS}
      ARGS=' '
    fi 
  fi 
done 
if [ \`echo \${ARGS} | wc -w\` -gt 0 ] ; then 
  mpirun -n ${NTASKS} ${TEMPDIR}/convert \${ARGS}
fi

# do restart files 
if [ ${ZIPRES} == 1 ] ; then 
  CMD=${TEMPDIR}/zip
else
  CMD=${TEMPDIR}/convert
fi 
ARGS=' '
for ncfile in \`find . -wholename '*/rest/*.nc' -print\`; do
  if [[ ! \$ncfile =~ .*.clm*.r..* ]]
  then
    ARGS=\${ARGS}' '\${ncfile}
  fi 
  if [ \`echo \${ARGS} | wc -w\` -eq ${NTASKS} ] ; then 
    mpirun -n ${NTASKS} \${CMD} \${ARGS}
    ARGS=' '
  fi 
done 
if [ \`echo \${ARGS} | wc -w\` -gt 0 ] ; then 
  mpirun -n ${NTASKS} \${CMD} \${ARGS}
fi
for gzfile in \`find . -wholename '*/rest/*.gz' -print\`; do
  file \${gzfile} > /dev/null
done

# do log files 
if [ ${RMLOGS} -eq 1 ] ; then
  for logfile in \`find . -wholename '*/logs/*' -print\`; do
     rm -f \${logfile}
  done
fi

echo conversion COMPLETED 
EOF

RES=`sbatch \`basename $0 .sh\`_${LID}.slurm`
echo JOBID ${RES##* }
echo log out: ${TEMPDIR}/`basename $0 .sh`_${LID}.out 

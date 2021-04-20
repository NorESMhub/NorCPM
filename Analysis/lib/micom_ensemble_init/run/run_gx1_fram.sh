#!/bin/bash
set -ex

EXPID=micom_ensemble_init
RUNDIR=/cluster/work/users/$USER/micom_ensemble_init 
CONFDIR=/cluster/shared/noresm/inputdata/ocn/micom/gx1v6/20101119
EXEDIR=`dirname \`readlink -f $0\``/../build
RESFILE=/cluster/projects/nn9039k/people/ingo/Restart/NorCPM_ME_mem01.micom.r.1980-01-15-00000.nc

mkdir -p $RUNDIR
cd $RUNDIR
cp -u $CONFDIR/grid.nc .
cp -u $CONFDIR/inicon.nc .
cp -f $EXEDIR/$EXPID .
cp -f $RESFILE forecast002.nc
cp -f $RESFILE forecast003.nc


cat > micom_ensemble_init.run << EOF 
#!/bin/csh -f
#===============================================================================
#  This is a CCSM batch job script for fram
#===============================================================================

#SBATCH --account=nn9039k
#SBATCH --job-name=micom_ensemble_init
#SBATCH --time=00:10:00
#SBATCH --nodes=1
#SBATCH --ntasks=32
#SBATCH --qos=preproc
#SBATCH --error=micom_ensemble_init.err
#SBATCH --output=micom_ensemble_init.out
#SBATCH --exclusive 

cd $RUNDIR
# Usage:  
#     micom_ensemble_init ensemble_size 
#       or 
#     micom_ensemble_init first_member last_member 
#
# Important: 
#     Number of task has to match members times number of tiles (currently 16) 
mpirun -n 32 ./$EXPID 2 3

EOF

sbatch micom_ensemble_init.run 

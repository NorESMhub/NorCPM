### machine specific settings ### 

# determine machine
if [ -z $MACH ]
then 
  case "`hostname -d | cut -d. -f1`" in 
  *fram*) MACH=fram ;; 
  *betzy*) MACH=betzy ;; 
  head) MACH=olivia ;; ## somehow hostname of olivia is not following same rule
  *) echo "Could not identify machine."
     echo "please set environmental variable \$MACH or specify script argument MACH=" 
     exit 1 ;;  
  esac
fi 

# apply machine settings
case $MACH in
fram) 
  MIN_NODES=4
  TASKS_PER_NODE=32
  : ${WORK:=/cluster/work/users/$USER} 
  : ${INPUTDATA:=/cluster/projects/nn9039k/inputdata}
  source /cluster/software/lmod/lmod/init/csh
  module purge --force 
  module load StdEnv
  module load NCO/4.7.7-intel-2018b
  module load intel/2018b
  module load netCDF/4.6.1-intel-2018b
  module load netCDF-Fortran/4.4.4-intel-2018b    
  ulimit -s unlimited
  ;; 
betzy)
  MIN_NODES=4
  TASKS_PER_NODE=128
  : ${WORK:=/cluster/work/users/$USER} 
  : ${INPUTDATA:=/cluster/projects/nn9039k/inputdata}
  source /cluster/installations/lmod/lmod/init/sh
  module --quiet restore system
  module load StdEnv
  module load NCO/5.1.9-iomkl-2022a XML-LibXML/2.0209-GCCcore-12.3.0 CMake/3.27.6-GCCcore-13.2.0 Python/3.11.5-GCCcore-13.2.0 netCDF-Fortran/4.6.1-iompi-2023b iomkl/2023b 
  export MKL_DEBUG_CPU_TYPE=5
  ulimit -s unlimited
  ;; 
olivia)
  MIN_NODES=1
  TASKS_PER_NODE=256
  : ${WORK:=/cluster/work/projects/nn9039k/users/$USER} 
  : ${INPUTDATA:=/cluster/projects/nn9039k/inputdata}
  module -q purge
  module load NRIS/CPU
  module load git/2.45.1-GCCcore-13.3.0
  module load ESMF/8.8.0-intel-2024a-ParallelIO-2.6.5
  module load Python/3.12.3-GCCcore-13.3.0
  module load CMake/3.29.3-GCCcore-13.3.0
  module load XML-LibXML/2.0210-GCCcore-13.3.0
  module load NCO/5.2.9-intel-2024a-NorESM
  ulimit -s unlimited
  ;; 
*)
  echo "Unkown machine ${MACH}. Program will stop." 
  exit 1 ;;   
esac 
export MACH WORK INPUTDATA MIN_NODES TASKS_PER_NODE

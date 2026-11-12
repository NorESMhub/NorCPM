#! /bin/sh -e

log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S.%N') - $1"
}
test -z "$(which cdo)" && source /cluster/projects/nn9039k/people/pgchiu/conda/py3env.sh
rdate=$1
echo $rdate
today=$(date -d "$rdate" +%d)
enssize=30
echo "Land Ensemble:"
echo $enssize

infl_fac=1.01
echo "LDA inflation:"
echo $infl_fac


log_msg "Starting Python DA execution..."
python clm5_da.py ${rdate} ${enssize} ${infl_fac}
log_msg "Python DA execution finished."

log_msg "Entering wait loop for Innovation file..."
while ! test -f "./Innovation-${rdate}.nc"; do
       sleep .5
       echo "still waiting for DA to end"
done
log_msg "Innovation file detected."

echo "CLMDA OVER: NorCPM will resume now"




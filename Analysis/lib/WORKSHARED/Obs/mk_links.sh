#from: TEM_avg_1980-2000-12.nc
#to:   TEM_avg_06-1950-2009.nc
#/cluster/shared/noresm/norcpm/Obs/ANALYSIS/EN.4.1.1/Anomaly/EN.4.1.1_1971-2000-09.nc

ROOT=$(pwd)

## make link TEM/EN4
mkdir -p TEM/EN4
cd TEM/EN4
ln -s /cluster/shared/noresm/norcpm/Obs/TEM/PROFILES/????_??.nc .
ln -s /cluster/shared/noresm/norcpm/Obs/ANALYSIS/EN.4.1.1/Anomaly/EN.4.1.1_*.nc  .
fns="EN.4.1.1_*-??.nc"
for i in $fns ; do
    newf=$(echo $i|sed 's/EN.4.1.1_\(....-....\)-\(..\).nc/TEM_avg_\2-\1.nc/')
    echo "$i -> $newf"
    mv $i $newf
done
# additonal link
for i in {01..12}; do
    ln -s "TEM_avg_${i}-1971-2000.nc" "TEM_avg_${i}-1970-1983.nc"
done
cd $ROOT


## make link SAL/EN4
mkdir -p SAL/EN4
cd SAL/EN4
ln -s /cluster/shared/noresm/norcpm/Obs/SAL/PROFILES/????_??.nc .
ln -s /cluster/shared/noresm/norcpm/Obs/ANALYSIS/EN.4.1.1/Anomaly/EN.4.1.1_*.nc  .
fns="EN.4.1.1_*-??.nc"
for i in $fns ; do
    newf=$(echo $i|sed 's/EN.4.1.1_\(....-....\)-\(..\).nc/SAL_avg_\2-\1.nc/')
    echo "$i -> $newf"
    mv $i $newf
done
# additonal link
for i in {01..12}; do
    ln -s "SAL_avg_${i}-1971-2000.nc" "SAL_avg_${i}-1970-1983.nc"
done
cd $ROOT



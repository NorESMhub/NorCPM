#!/bin/bash
## file example:
##/cluster/home/pgchiu/work/noresm2/archive/norcpm2_test_19700101/norcpm2_test_19700101_mem01/ocn/hist/norcpm2_test_19700101_mem01.micom.hm.1983-12.nc

yrange='1970-1983'
fileprefix="/cluster/home/pgchiu/work/noresm2/archive/norcpm2_test_19700101/*/ocn/hist/*.hm.????-"

for i in {01..12} ; do
    files="${fileprefix}${i}.nc"
    time ncea -v depth_bnds,sigmx,sealv,fice,mld,maxmld,sst,sss,templvl,salnlvl $files  Free-average${i}-${yrange}.nc
done

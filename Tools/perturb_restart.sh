#!/bin/bash
## Add a random value to mpiom SST restart.
## Following pertub_restart.m
##    But the random number is not normal distribution.

## For NCO
##module -q purge
## Fram ## module load NCO/4.7.9-intel-2018b 
## Betzy## module load NCO/4.8.1-intel-2019a ## Betzy ##

infile=$1
outfile=$2

if [ -z "$GSL_RNG_SEED" ] ;then ## random seed if not set
  export GSL_RNG_SEED="$RANDOM"
fi
if [ -f "$infile" ] && [ ! -z "$outfile" ] ; then
    a=1
else
    echo "Uasge: $0 input_file output_file"
fi

echo RANDOM SEED: $GSL_RNG_SEED
vname=temp
FAC=10^-10

#ncap2 -c -s "${vname}=${vname}+(gsl_rng_uniform(${vname})*$FAC)"  "$infile" "$outfile"

## ncap2 remove the 'plev' dimension. Donot know why.
rm -f tmpfile.nc
ncap2 -c -s "${vname}=${vname}+(gsl_rng_uniform(${vname})*$FAC)"  "$infile" "tmpfile.nc" 
## Add plev back, need modify to read $infile
ncap2 -s'defdim("plev",70)' "tmpfile.nc" "$outfile"
rm -f tmpfile.nc


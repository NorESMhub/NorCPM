Input Data, Format and How to Generate it.
# Obs Data
## Monthly data
WORKSHARED/Obs/SST/HADISST2/1991_06.nc
                :Conventions = "CF-1.0" ;
                :history = "Wed Jan 22 15:54:19 2014: ncrcat SST_1991_06_1059.nc SST_1991_06_115.nc SST_1991_06_1169.nc SST_1991_06_1194.nc SST_1991_06_1346.nc SST_1991_06_137.nc SST_1991_06_1466.nc SST_1991_06_396.nc SST_1991_06_400.nc SST_1991_06_69.nc SST_ens_1991_06.nc\n",
                        "Wed Jan 22 15:31:34 2014: ncecat -O -u nens SST_1991_06_1059.nc SST_1991_06_1059.nc\n",
                        "Wed Jan 22 15:29:23 2014: cdo -splitsel,1 HadISST.2.1.0.0_realisation_1059.nc SST_monthly\n",
                        "5/11/2012 converted to netcdf" ;
                :source = "Met Office" ;
                :Title = "Monthly 1 degree version of HadISST.2.1.0.0 realisation 1059" ;
                :reference = "Rayner et al. in prep" ;
                :supplementary_information = "contact john.kennedy@metoffice.gov.uk" ;
                :CDO = "Climate Data Operators version 1.6.2 (http://code.zmaw.de/projects/cdo)" ;
                :nco_openmp_thread_number = 1 ;

## Climatorology files
WORKSHARED/Obs/SST/HADISST2/SST_avg_12-1980-2006.nc
                :CDI = "Climate Data Interface version 1.6.2 (http://code.zmaw.de/projects/cdi)" ;
                :Conventions = "CF-1.0" ;
                :history = "Wed Oct 23 14:12:10 2019: ncra toto.nc SST_avg_12-1980-2006.nc\n",
                        "Wed Oct 23 14:12:04 2019: ncea 1980_12.nc 1981_12.nc 1982_12.nc 1983_12.nc 1984_12.nc 1985_12.nc 1986_12.nc 1987_12.nc 1988_12.nc 1989_12.nc 1990_12.nc 1991_12.nc 1992_12.nc 1993_12.nc 1994_12.nc 1995_12.nc 1996_12.nc 1997_12.nc 1998_12.nc 1999_12.nc 2000_12.nc 2001_12.nc 2002_12.nc 2003_12.nc 2004_12.nc 2005_12.nc 2006_12.nc toto.nc\n",
                        "Wed Jan 22 15:52:57 2014: ncrcat SST_1980_12_1059.nc SST_1980_12_115.nc SST_1980_12_1169.nc SST_1980_12_1194.nc SST_1980_12_1346.nc SST_1980_12_137.nc SST_1980_12_1466.nc SST_1980_12_396.nc SST_1980_12_400.nc SST_1980_12_69.nc SST_ens_1980_12.nc\n",
                        "Wed Jan 22 15:31:28 2014: ncecat -O -u nens SST_1980_12_1059.nc SST_1980_12_1059.nc\n",
                        "Wed Jan 22 15:29:23 2014: cdo -splitsel,1 HadISST.2.1.0.0_realisation_1059.nc SST_monthly\n",
                        "5/11/2012 converted to netcdf" ;
                :source = "Met Office" ;
                :Title = "Monthly 1 degree version of HadISST.2.1.0.0 realisation 1059" ;
                :reference = "Rayner et al. in prep" ;
                :supplementary_information = "contact john.kennedy@metoffice.gov.uk" ;
                :CDO = "Climate Data Operators version 1.6.2 (http://code.zmaw.de/projects/cdo)" ;
                :nco_openmp_thread_number = 1 ;
                :NCO = "4.7.2" ;


# Model Data
## Climatorology files
WORKSHARED/Input/NorESM/f19_tn14/Free-average05-1980-2010.nc
ncea -v depth_bnds,sigmx,sealv,fice,mld,maxmld,sst,sss,templvl,salnlvl
## Representive error in model grid
WORKSHARED/Input/NorESM/f19_tn14/EN4/f19_tn14_TEM_obs_unc_ff.nc

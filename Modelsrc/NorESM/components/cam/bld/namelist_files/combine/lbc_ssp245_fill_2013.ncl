begin
src = "/cluster/shared/noresm/inputdata/atm/waccm/lb/LBC_2014-2500_CMIP6_SSP245_0p5degLat_GlobAnnAvg_c190301.nc"
    ;; yearly file

fill = "/cluster/shared/noresm/inputdata/atm/waccm/lb/LBC_17500116-20150116_CMIP6_0p5degLat_c180227.nc"
    ;; monthly file

dst = "LBC_2014-2500_fill2013_CMIP6_SSP245_0p5degLat_GlobAnnAvg_c190301.nc"

;;vars = (/"time","time_bnds","date","CO2_LBC","N2O_LBC","CH4_LBC","CFC11eq_LBC","CF2CL2_LBC"/)
;;ndim = (/    1,          2,     1,        2,        2,        2,            2,           2 /);; mostly time,lat
vars = (/"CO2_LBC","N2O_LBC","CH4_LBC","CFC11eq_LBC","CF2CL2_LBC"/)
ndim = (/        2,        2,        2,            2,           2/);; mostly time,lat
;; no time_bnds in fill file.

;; addfiles
fsrc = addfile(src,"r")
ffil = addfile(fill,"r")
system("rm -f "+dst)
fdst = addfile(dst,"c")

filB = 3156  ;; 201301
filE = 3167  ;; 201312

;; fixed coordinate variables
lat = fsrc->lat
lon = fsrc->lon

;; be expended, time
srcTime = fsrc->time
srcNt = dimsizes(srcTime)
dstNt = srcNt + 1  ;; backward 1 year
dstTime = new(dstNt,typeof(srcTime))
dstTime(1:) = srcTime
dstTime(0) = srcTime(0) - 365
dstTime&time = dstTime
;;print(""+cd_calendar(dstTime,-3) +" "+ dstTime)

;; be expended, date
srcDate = fsrc->date
dstDate = new(dstNt,typeof(srcDate))
dstDate(1:) = srcDate
dstDate(0) = srcDate(0)-10000
dstDate&time = dstTime

fdst->date = dstDate
;; otherVariables 
do i = 0, dimsizes(vars)-1
    var = fsrc->$vars(i)$
    dims = dimsizes(var)
    dims(0) = dims(0)+1
    dstvar = new(dims,typeof(var))
    dstvar(1:,:) = var

    filvar = dim_avg_n(ffil->$vars(i)$(filB:filE,:),0)
    dstvar(0,:) = (/filvar/)

    dstvar&time = dstTime

    fdst->$vars(i)$ = dstvar

    delete(dstvar)
    delete(var)
    delete(filvar)
    delete(dims)

end do
end

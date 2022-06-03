netcdf SAL_avg_08-1980-2010 {
dimensions:
	depth = 42 ;
	lat = 173 ;
	lon = 360 ;
	time = UNLIMITED ; // (1 currently)
	bnds = 2 ;
variables:
	float depth(depth) ;
		depth:long_name = "depth" ;
		depth:units = "metres" ;
		depth:positive = "down" ;
		depth:standard_name = "depth" ;
		depth:bounds = "depth_bnds" ;
	float lat(lat) ;
		lat:long_name = "latitude" ;
		lat:units = "degrees_north" ;
		lat:standard_name = "latitude" ;
	float lon(lon) ;
		lon:long_name = "longitude" ;
		lon:units = "degrees_east" ;
		lon:standard_name = "longitude" ;
	double temperature(time, depth, lat, lon) ;
		temperature:long_name = "temperature" ;
		temperature:standard_name = "sea_water_potential_temperature" ;
		temperature:units = "kelvin" ;
		temperature:_FillValue = -32768. ;
		temperature:valid_min = -5.f ;
		temperature:valid_max = 45.f ;
	double salinity(time, depth, lat, lon) ;
		salinity:long_name = "salinity" ;
		salinity:units = "psu" ;
		salinity:standard_name = "sea_water_salinity" ;
		salinity:_FillValue = -32768. ;
		salinity:valid_min = -5.f ;
		salinity:valid_max = 48.f ;
	double temperature_uncertainty(time, depth, lat, lon) ;
		temperature_uncertainty:_FillValue = -32768. ;
		temperature_uncertainty:long_name = "temperature error standard deviation" ;
		temperature_uncertainty:units = "kelvin" ;
	double salinity_uncertainty(time, depth, lat, lon) ;
		salinity_uncertainty:_FillValue = -32768. ;
		salinity_uncertainty:long_name = "salinity error standard deviation" ;
		salinity_uncertainty:units = "psu" ;
	float temperature_observation_weights(time, depth, lat, lon) ;
		temperature_observation_weights:_FillValue = -32768.f ;
		temperature_observation_weights:long_name = "temperature observation weights" ;
		temperature_observation_weights:comment = "The total weighting given to the observation increments when forming the analysis" ;
	float salinity_observation_weights(time, depth, lat, lon) ;
		salinity_observation_weights:_FillValue = -32768.f ;
		salinity_observation_weights:long_name = "salinity observation weights" ;
		salinity_observation_weights:comment = "The total weighting given to the observation increments when forming the analysis" ;
	float time(time) ;
		time:standard_name = "time" ;
		time:units = "days since 1800-01-01 00:00:00" ;
		time:bounds = "time_bnds" ;
	float time_bnds(time, bnds) ;
	float depth_bnds(depth, bnds) ;

// global attributes:
		:Conventions = "CF-1.0" ;
		:title = "Temperature and salinity analysis" ;
		:DSD_entry_id = "UKMO-L4UHFnd-GLOB-v01" ;
		:references = "None" ;
		:institution = "UK Met Office" ;
		:contact = "Simon Good - simon.good@metoffice.gov.uk" ;
		:GDS_version_id = "v1.7" ;
		:netcdf_version_id = "3.5" ;
		:creation_date = "2015-04-14 10:18:02.100 -00:00" ;
		:product_version = "1.0" ;
		:history = "Fri Dec 30 16:24:34 2016: ncea EN.4.1.1.f.analysis.g10.198008.nc EN.4.1.1.f.analysis.g10.198108.nc EN.4.1.1.f.analysis.g10.198208.nc EN.4.1.1.f.analysis.g10.198308.nc EN.4.1.1.f.analysis.g10.198408.nc EN.4.1.1.f.analysis.g10.198508.nc EN.4.1.1.f.analysis.g10.198608.nc EN.4.1.1.f.analysis.g10.198708.nc EN.4.1.1.f.analysis.g10.198808.nc EN.4.1.1.f.analysis.g10.198908.nc EN.4.1.1.f.analysis.g10.199008.nc EN.4.1.1.f.analysis.g10.199108.nc EN.4.1.1.f.analysis.g10.199208.nc EN.4.1.1.f.analysis.g10.199308.nc EN.4.1.1.f.analysis.g10.199408.nc EN.4.1.1.f.analysis.g10.199508.nc EN.4.1.1.f.analysis.g10.199608.nc EN.4.1.1.f.analysis.g10.199708.nc EN.4.1.1.f.analysis.g10.199808.nc EN.4.1.1.f.analysis.g10.199908.nc EN.4.1.1.f.analysis.g10.200008.nc EN.4.1.1.f.analysis.g10.200108.nc EN.4.1.1.f.analysis.g10.200208.nc EN.4.1.1.f.analysis.g10.200308.nc EN.4.1.1.f.analysis.g10.200408.nc EN.4.1.1.f.analysis.g10.200508.nc EN.4.1.1.f.analysis.g10.200608.nc EN.4.1.1.f.analysis.g10.200708.nc EN.4.1.1.f.analysis.g10.200808.nc EN.4.1.1.f.analysis.g10.200908.nc EN.4.1.1.f.analysis.g10.201008.nc EN.4.1.1_1980-2010-08.nc\n",
			"" ;
		:grid_resolution = "   1.00000 degree" ;
		:start_date = "2001-01-01 UTC" ;
		:start_time = "00:00:00 UTC" ;
		:stop_date = "2001-01-01 UTC" ;
		:stop_time = "00:00:00 UTC" ;
		:southernmost_latitude = -90.5f ;
		:northernmost_latitude = 89.5f ;
		:westernmost_longitude = 0.5f ;
		:easternmost_longitude = 362.5f ;
		:file_quality_index = "0" ;
		:NCO = "20161230" ;
		:nco_openmp_thread_number = 1 ;
}

 module m_read_ENVISAT_ICET

contains

  subroutine read_ENVISAT_ICET(fname,data,modlon,modlat,depths,dlon,dlat,nrobs)
  use mod_measurement
  use mod_grid
  use nfw_mod

  implicit none

  integer, intent(in) :: dlon,dlat
  integer, intent(out) :: nrobs
  type (measurement), intent(inout)  :: data(:)
  real, dimension(dlon,dlat), intent(in) :: depths,modlon,modlat
  character(len=80), intent(in) :: fname
  real(4) ,allocatable :: vsit(:,:,:), verr_ana(:,:,:),vsit2(:,:,:)
  real(4) ,allocatable :: vlongitude(:,:), vlatitude(:,:)
  integer :: vLON_ID,vLAT_ID,verr_ID
  integer :: ncid,vSIT_ID,i,j,k
  integer :: irec,nens
  integer, allocatable :: ns(:), nc(:)
  integer, allocatable :: ns2(:), nc2(:)
  logical :: ex
  real :: lon, lat,sst,sst_sq
  real(4), dimension(1) :: scalefac, addoffset
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Read  observation file
  allocate(verr_ana(dlon,dlat,1))
  allocate(vsit(dlon,dlat,1))
  allocate(vlongitude(dlon,dlat))
  allocate(vlatitude(dlon,dlat))
  allocate(ns(3))
  allocate(nc(3))
  allocate(ns2(2))
  allocate(nc2(2))

  ns(1)=1
  ns(2)=1
  ns(3)=1
  nc(1)=dlon
  nc(2)=dlat
  nc(3)=1
  ns2(1)=1
  ns2(2)=1
  nc2(1)=dlon
  nc2(2)=dlat

  inquire (file=fname, exist=ex)
  if (.not. ex) then
     print *, 'Data file ', fname, ' not found.'
     stop
  end if
  call nfw_open(fname, nf_nowrite, ncid)
  call nfw_inq_varid(fname, ncid,'sea_ice_thickness', vSIT_ID)
  call nfw_inq_varid(fname, ncid,'sea_ice_thickness_uncertainty', verr_ID)
  call nfw_inq_varid(fname, ncid,'lon', vLON_ID)
  call nfw_inq_varid(fname, ncid,'lat', vLAT_ID)
  call nfw_get_vara_real(fname, ncid, vSIT_ID, ns, nc, vsit)
  call nfw_get_vara_real(fname, ncid, verr_ID, ns, nc, verr_ana)
  call nfw_get_vara_real(fname, ncid, vLON_ID, ns2, nc2,vlongitude)
  call nfw_get_vara_real(fname, ncid, vLAT_ID, ns2, nc2,vlatitude)
  !call nfw_get_vara_real(fname, ncid, vLON_ID, 1, dlon, vlongitude)
  !call nfw_get_vara_real(fname, ncid, vLAT_ID, 1, dlat, vlatitude)
  call nfw_close(fname, ncid)
  !Convert from Kelvin to Celcius
#ifdef ANOMALY
!Read the monthly mean 
  allocate(vsit2(dlon,dlat,1))
  call nfw_open('mean_obs.nc', nf_nowrite, ncid)
  call nfw_inq_varid('mean_obs.nc', ncid,'sea_ice_thickness', vSIT_ID)
  call nfw_get_vara_real('mean_obs.nc', ncid, vSIT_ID, ns, nc, vsit2)
  vsit(:,:,1)=vsit(:,:,1)-vsit2(:,:,1)
#endif
  print *,'Nb obs mem'
  nrobs=1
  do j = 1, dlat
     do i = 1, dlon
#ifdef ANOMALY
          if (vsit2(i,j,1).gt.0.) then
#else
          if (vsit(i,j,1).gt.0.) then
#endif
           !Only fill with realistic value for the last member
           data(nrobs)%d = vsit(i,j,1)
           data(nrobs)%ipiv = i
           data(nrobs)%jpiv = j
           !regular grid [-179.5 -> 179.5] & [89.5 -> -89.5]
           data(nrobs)%lon = vlongitude(i,j) 
           data(nrobs)%lat = vlatitude(i,j)
           data(nrobs)%a1 = 1
           data(nrobs)%a2 = 0
           data(nrobs)%a3 = 0
           data(nrobs)%a4 = 0
           data(nrobs)%ns = 0
           data(nrobs)%depth = 0
           data(nrobs)%date = 0
           data(nrobs)%id ='ICET'
           data(nrobs)%orig_id =0
           data(nrobs)%i_orig_grid = -1
           data(nrobs)%j_orig_grid = -1
           data(nrobs)%h = 1
           data(nrobs)%date = 0
           data(nrobs)%var = verr_ana(i,j,1)
           data(nrobs)%status = .true.
           nrobs=nrobs+1
          endif
     enddo   ! dlat
  enddo    ! dlon
  nrobs=nrobs-1
  print *,'Max,min obs',maxval(data(:)%d),minval(data(:)%d)
  print *,'Max,min age',maxval(data(:)%date),minval(data(:)%date)
  print *,'Max,min lon',maxval(data(:)%lon),minval(data(:)%lon)
  print *,'Max,min lat',maxval(data(:)%lat),minval(data(:)%lat)
  print *,'1000 obs',data(1000)%d,data(1000)%var,data(1000)%lon,data(1000)%lat
  print *,'Nb of obs',nrobs
end subroutine read_ENVISAT_ICET
end module m_read_ENVISAT_ICET

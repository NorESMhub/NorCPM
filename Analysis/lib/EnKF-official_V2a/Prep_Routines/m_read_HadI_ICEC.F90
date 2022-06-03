 module m_read_HadI_ICEC

contains

  subroutine read_HadI_ICEC(fname,cens,data,modlon,modlat,depths,dlon,dlat,nrobs)
  use mod_measurement
  use mod_grid
  use nfw_mod

  implicit none

  integer, intent(in) :: dlon,dlat
  integer, intent(out) :: nrobs
  type (measurement), intent(inout)  :: data(:)
  real, dimension(dlon,dlat), intent(in) :: depths,modlon,modlat
  character(len=80), intent(in) :: fname
  character(len=3), intent(in) :: cens
  real(4) ,allocatable :: vsic(:,:,:,:), vsic2(:,:,:), mask_ice(:,:)
  !real(4) ,allocatable :: mask_ice(:,:,:)
  real(4) ,allocatable :: vlongitude(:), vlatitude(:)
  integer :: vLON_ID,vLAT_ID
  integer :: ncid,i,j,k,imonth
  integer :: vsic_ID,irec,nens
  integer, allocatable :: ns(:), nc(:)
  logical :: ex, ice_status
  real :: lon, lat,sst,sst_sq
  real(4), dimension(1) :: scalefac, addoffset
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Read  observation file
  read(cens,*) nens
  nens=10
  allocate(vsic(dlon,dlat,1,nens))
  allocate(mask_ice(dlon,dlat))
  allocate(vlongitude(dlon))
  allocate(vlatitude(dlat))
  allocate(ns(4))
  allocate(nc(4))

  ns(1)=1
  ns(2)=1
  ns(3)=1
  ns(4)=1
  nc(1)=dlon
  nc(2)=dlat
  nc(3)=1
  nc(4)=nens

  inquire (file=fname, exist=ex)
  if (.not. ex) then
     print *, 'Data file ', fname, ' not found.'
     stop
  end if
  print *, 'Start  reading sic'
  call nfw_open(fname, nf_nowrite, ncid)
  call nfw_inq_varid(fname, ncid,'sic', vSIC_ID)
  call nfw_get_vara_real(fname, ncid, vSIC_ID, ns, nc, vsic)

  nc(4)=1

  call nfw_inq_varid(fname, ncid,'longitude', vLON_ID)
  call nfw_inq_varid(fname, ncid,'latitude', vLAT_ID)

  !call nfw_get_vara_real(fname, ncid, vLON_ID, ns(1), nc(1), vlongitude)
  !call nfw_get_vara_real(fname, ncid, vLAT_ID, ns(1), nc(2), vlatitude)

  call nfw_get_var_real(fname, ncid, vLON_ID, vlongitude)
  call nfw_get_var_real(fname, ncid, vLAT_ID, vlatitude)

  call nfw_close(fname, ncid)

!read_ice_mask====
!  print *, 'Start  reading mask ice'
!  call nfw_open('mask_ice.nc', nf_nowrite, ncid)
!  call nfw_inq_varid('mask_ice.nc', ncid,'fice', vSIC_ID)
!  call nfw_get_vara_real('mask_ice.nc', ncid, vSIC_ID, ns(1:2), nc(1:2), mask_ice)
!  call nfw_close('mask_ice.nc', ncid)
!========

#ifdef ANOMALY
!Read the monthly mean 
  allocate(vsic2(dlon,dlat,1))
  nc(4)=1
  print *, 'Start  reading anom'
  call nfw_open('mean_obs.nc', nf_nowrite, ncid)
  print *, 'opening ID'
  call nfw_inq_varid('mean_obs.nc', ncid,'sic', vSIC_ID)
  print *, 'reading ID'
  call nfw_get_vara_real('mean_obs.nc', ncid, vSIC_ID, ns(1:3), nc(1:3), vsic2)
  print *, 'closing'
  call nfw_close('mean_obs.nc', ncid)
  print *, 'Finished  reading anom'
  !MK==determine anomaly, only for first entry, as all the same
  vsic(:,:,1,1)=vsic(:,:,1,1)-vsic2(:,:,1)
#endif

  !print *,'Nb obs mem'
  nrobs=1

  do j = 1, dlat
     !if (j<50 .or. j> 131) then  !lat>40.5 or lat < -40.5
       do i = 1, dlon
         data(nrobs)%d = vsic(i,j,1,1)
         data(nrobs)%ipiv = i
         data(nrobs)%jpiv = j
         data(nrobs)%lon = vlongitude(i) 
         data(nrobs)%lat = vlatitude(j)
         data(nrobs)%a1 = 1
         data(nrobs)%a2 = 0
         data(nrobs)%a3 = 0
         data(nrobs)%a4 = 0
         data(nrobs)%ns = 0
         data(nrobs)%depth = 0
         data(nrobs)%date = 0
         data(nrobs)%id ='ICEC'
         data(nrobs)%orig_id =0
         data(nrobs)%i_orig_grid = -1
         data(nrobs)%j_orig_grid = -1
         data(nrobs)%h = 1
         data(nrobs)%date = 0
         data(nrobs)%status = .true.
         ! std=20 %
         data(nrobs)%var = .04 
         nrobs=nrobs+1
       enddo   ! dlon
     !end if
!endif
  enddo    ! dlat

  nrobs=nrobs-1
  print *,'Max,min obs',maxval(data(:)%d),minval(data(:)%d),maxval(data(:)%lon),minval(data(:)%lat)
  print *,'Max,min age',maxval(data(:)%date),minval(data(:)%date)
  print *,'Nb of obs',nrobs
 ! print *,'Max,min lon',maxval(data(:)%lon),minval(data(:)%lon)
 ! print *,'Max,min lat',maxval(data(:)%lat),minval(data(:)%lat)
end subroutine read_HadI_ICEC
end module m_read_HadI_ICEC

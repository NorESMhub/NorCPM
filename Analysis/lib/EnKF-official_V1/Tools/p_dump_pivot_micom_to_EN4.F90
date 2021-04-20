program p_dump_pivot_micom_to_EN4
use netcdf
use nfw_mod
use m_get_micom_grid
use m_get_micom_dim
use m_pivotp_Hadi
use m_spherdist

   implicit none

   integer*4, external :: iargc
   integer, parameter :: dlon=360
   integer, parameter :: dlat=173

   character(len=80) :: filename
   logical          :: ex
   character(len=6) :: fname
   integer          :: nx,ny,nz
   real :: meandx,mindx,tlon,tlat
   real, allocatable, dimension(:,:)     :: depths,modlon,modlat,F_ipiv,F_jpiv
   real, allocatable, dimension(:)     :: lon,lat
   integer :: i,j,ipiv,jpiv
   integer :: dimids(2)
   integer :: ncid, x_ID, y_ID, z_ID 
   integer :: vJPIV_ID, vIPIV_ID
   integer :: vLON_ID, vLAT_ID
   integer, allocatable :: ns(:), nc(:)
   ! Get grid dimensions 
  call get_micom_dim(nx,ny,nz)
  allocate(depths(nx, ny))
  allocate(modlon(nx, ny))
  allocate(modlat(nx, ny))
  allocate(F_ipiv(nx,ny))
  allocate(F_jpiv(nx,ny))
  allocate(lon(dlon))
  allocate(lat(dlat))
  allocate(ns(2))
  allocate(nc(2))
  ns(1)=1
  ns(2)=1
  nc(1)=1
  nc(2)=dlon


   ! Read position and depth from model grid
   !
   call  get_micom_grid(modlon, modlat, depths, mindx, meandx, nx, ny)
    do i=1,dlon
     lon(i)=real(i)
    end do
    do j=1,dlat
       lat(j) = -83+real(j-1)
    end do


!   fname='obs.nc'
!   call nfw_open(fname, nf_nowrite, ncid)
!   call nfw_inq_varid(fname, ncid,'longitude', vLON_ID)
!   call nfw_get_vara_real(fname, ncid, vLON_ID, ns, nc, lon)
!   call nfw_inq_varid(fname, ncid,'latitude', vLAT_ID)
!   nc(2)=dlat
!   call nfw_get_vara_real(fname, ncid, vLAT_ID, ns, nc, lat)
!   call nfw_close(fname, ncid)


   !call nfw_open(fname, nf_nowrite, ncid)
   !all nfw_inq_dimid(fname, ncid, 'longitude', lon_ID)
   !all nfw_inq_dimid(fname, ncid, 'latitude', lat_ID)
   !all nfw_get_vara_double(fname, ncid,lon_ID,ns,nc, lon)
   !c(2)=dlat
   !all nfw_get_vara_double(fname, ncid,lat_ID,ns,nc, lat)
   !all nfw_close(fname, ncid)
   !here ( lon > 180.0d0)
   !   lon = lon - 360.0d0
   !nd where
         print *,'min/max lon',minval(modlon),minval(lon),maxval(modlon),maxval(lon)
         print *,'min/max lat',minval(modlat),minval(lat),maxval(modlat),maxval(lat)
   ipiv=1
   jpiv=1
   do j=1,ny
      do i=1,nx
!         i=100
!         j=100
         tlon=modlon(i,j)
         tlat=modlat(i,j)
         call pivotp_hadi(tlon, tlat, lon, lat, ipiv, jpiv,dlon,dlat)
         F_ipiv(i,j)=ipiv
         F_jpiv(i,j)=jpiv
      end do !i
   end do !j
   call nfw_create('pivots_EN4-micom.nc', nf_clobber, ncid)
   call nfw_def_dim('pivots_EN4-micom.nc', ncid, 'x', nx, dimids(1))
   call nfw_def_dim('pivots_EN4-micom.nc', ncid, 'y', ny, dimids(2))
   call nfw_def_var('pivots_EN4-micom.nc', ncid, 'ipiv',nf_double, 2, dimids, vIPIV_ID)
   call nfw_def_var('pivots_EN4-micom.nc', ncid, 'jpiv',nf_double, 2, dimids, vJPIV_ID)
  call nfw_enddef('pivots_EN4-micom.nc', ncid)
  call nfw_put_var_double('pivots_EN4-micom.nc', ncid, vIPIV_ID, F_ipiv(:,:))
  call nfw_put_var_double('pivots_EN4-micom.nc', ncid, vJPIV_ID, F_jpiv(:,:))
  call nfw_close('pivots_EN4-micom.nc', ncid)

end program

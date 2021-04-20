! File:          p_dump_pivot_sst
!
! Created:       Yiguo WANG 
!
! Last modified: 16/11/2015
!
! Purpose: find and dump in a netcdf file pivot point from EN4
!
program p_dump_pivot_2c_to_micom
use netcdf
use nfw_mod
use m_get_micom_grid
use m_get_micom_dim
use m_pivotp_micom
use m_spherdist

   implicit none

   integer*4, external :: iargc
   real, parameter :: onem=9806.
   integer, parameter :: dlon=180
   integer, parameter :: dlat=90

   character(len=80) :: filename
   logical          :: ex
   character(len=8) :: ctmp
   integer          :: nx,ny,nz
   real :: meandx,mindx,lon,lat
   real, allocatable, dimension(:,:)     :: depths,modlon,modlat, min_r, max_r, itw, jtw, its, jts, itn, jtn, ite, jte,F_ipiv,F_jpiv
   integer :: i,j,ipiv,jpiv
   integer :: dimids(2)
   integer :: ncid, x_ID, y_ID, z_ID 
   integer :: vJPIV_ID, vIPIV_ID
   integer :: ncid2, jns_ID, ins_ID, inw_ID, jnw_ID,jnn_ID, inn_ID, ine_ID, jne_ID
   ! Get grid dimensions 
  call get_micom_dim(nx,ny)
  allocate(depths(nx, ny))
  allocate(modlon(nx, ny))
  allocate(modlat(nx, ny))
  allocate(min_r(nx, ny))
  allocate(max_r(nx, ny))
  allocate(itw(nx, ny))
  allocate(jtw(nx, ny))
  allocate(its(nx, ny))
  allocate(jts(nx, ny))
  allocate(itn(nx, ny))
  allocate(jtn(nx, ny))
  allocate(ite(nx, ny))
  allocate(jte(nx, ny))
  allocate(F_ipiv(dlon,dlat))
  allocate(F_jpiv(dlon,dlat))
   ! Read position and depth from model grid
   !
   call get_micom_grid(modlon, modlat, depths, mindx, meandx, nx, ny)
   call ini_pivotp(modlon,modlat, nx, ny, min_r, max_r, itw, jtw, itn, jtn, its, jts, ite, jte)!
   ipiv=1
   jpiv=1
   do j=1,dlat
      do i=1,dlon
         if (2*i .le. 180) then
            lon = real(2*i)
         else
            lon = real(2*i - 360)
         end if
         lat = real(2*j - 90) 
         call pivotp_micom(lon, lat, modlon, modlat, ipiv, jpiv, &
                   nx, ny, min_r, max_r,itw, jtw, itn, jtn, its, jts, ite, jte)
         F_ipiv(i,j)=ipiv
         F_jpiv(i,j)=jpiv
      end do !i
   end do !j
   call nfw_create('pivots_2c.nc', nf_clobber, ncid)
   call nfw_def_dim('pivots_2c.nc', ncid, 'x', dlon, dimids(1))
   call nfw_def_dim('pivots_2c.nc', ncid, 'y', dlat, dimids(2))
   call nfw_def_var('pivots_2c.nc', ncid, 'ipiv',nf_double, 2, dimids, vIPIV_ID)
   call nfw_def_var('pivots_2c.nc', ncid, 'jpiv',nf_double, 2, dimids, vJPIV_ID)
  call nfw_enddef('pivots_2c.nc', ncid)
  call nfw_put_var_double('pivots_2c.nc', ncid, vIPIV_ID, F_ipiv(:,:))
  call nfw_put_var_double('pivots_2c.nc', ncid, vJPIV_ID, F_jpiv(:,:))
  call nfw_close('pivots_2c.nc', ncid)

end program p_dump_pivot_2c_to_micom

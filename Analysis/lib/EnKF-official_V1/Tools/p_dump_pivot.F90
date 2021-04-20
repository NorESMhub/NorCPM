! File:          p_dump_pivot_sst
!
! Created:       Francois counillon
!
! Last modified: 07/04/2014
!
! Purpose: find and dump in a netcdf file pivot point from HAdiSST
!
program p_dump_pivot_sst
use netcdf
use nfw_mod
use mod_grid
use m_get_micom_grid
use m_get_micom_dim
use m_pivotp_micom

   implicit none

   integer*4, external :: iargc
   real, parameter :: onem=9806.
   integer, parameter :: dlon=360
   integer, parameter :: dlat=180

   character(len=80) :: filename
   logical          :: ex
   character(len=8) :: ctmp
   integer          :: nx,ny
   real :: meandx,mindx
   real, allocatable, dimension(:,:)     :: depths,modlon,modlat, min_r, max_r, itw, jtw, its, jts, itn, jtn, ite, jte
   integer :: i,j,ipiv,jpiv
   integer :: ncid, x_ID, y_ID, z_ID 
   integer :: vFICEM_ID, vHICEM_ID
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
  allocate(ite(nx, ny))
  allocate(F_ipiv(dlon,dlat))
  allocate(F_jpiv(dlon,dlat))
   ! Read position and depth from model grid
   !
   call  get_micom_grid(modlon, modlat, depths, mindx, meandx, nx, ny)
   call ini_pivotp(modlon,modlat, nx, ny, min_r, max_r, itw, jtw, itn, jtn, its,
   jts, ite, jte)!
   ipiv=1
   jpiv=1
   do j=1,dlat
      do i=1,dlon
         lon=-179.5+real(i-1)
         lat = 89.5-j
         call pivotp_micom(lon, lat, modlon, modlat, ipiv, jpiv, &
                   nx, ny, min_r, max_r,itw, jtw, itn, jtn, its, jts, ite, jte)
         F_ipiv(i,j)=ipiv
         F_jpiv(i,j)=jpiv
      end do !i
   end do !j
   call nfw_create('pivots_SST.nc', nf_clobber, ncid)
   call nfw_def_dim('pivots_SST.nc', ncid, 'x', idm, dimids(1))
   call nfw_def_dim('pivots_SST.nc', ncid, 'y', jdm, dimids(2))
   call nfw_def_var('pivots_SST.nc', ncid, 'ipiv',nf_float, 2, dimids, VIPIV_ID)
   call nfw_def_var('pivots_SST.nc', ncid, 'jpiv',nf_float, 2, dimids, VJPIV_ID)
  call nfw_enddef('pivots_SST.nc', ncid)
  call nfw_put_var_double('pivots_SST.nc', ncid, VIPIV_ID, ipiv(:,:))
  call nfw_put_var_double('pivots_SST.nc', ncid, VJPIV_ID, jpiv(:,:))
  call nfw_close('pivots_SST.nc', ncid)

end program

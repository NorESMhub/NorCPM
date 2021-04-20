! File:          p_dump_pivot_sst
!
! Created:       Yiguo WANG 
!
! Last modified: 16/11/2015
!
! Purpose: find and dump in a netcdf file pivot point from EN4
!
program p_dump_pivot_ICET_to_micom
use netcdf
use nfw_mod
use m_get_micom_grid
use m_get_micom_dim
use m_pivotp_micom
use m_spherdist

   implicit none

   integer*4, external :: iargc
   real, parameter :: onem=9806.
   integer, parameter :: dlon=432
   integer, parameter :: dlat=432

   character(len=80) :: filename
   logical          :: ex
   character(len=8) :: ctmp
   integer          :: nx,ny,nz
   real :: meandx,mindx
   real, allocatable, dimension(:,:)     :: depths,modlon,modlat, min_r, max_r, F_ipiv, F_jpiv, lon, lat
   integer, allocatable, dimension(:,:) :: itw, jtw, its, jts, itn, jtn, ite, jte
   integer :: i,j,ipiv,jpiv
   integer :: dimids(2)
   integer :: ncid, x_ID, y_ID, z_ID 
   integer :: vJPIV_ID, vIPIV_ID
   integer :: ncid2, jns_ID, ins_ID, inw_ID, jnw_ID,jnn_ID, inn_ID, ine_ID, jne_ID
   ! Get grid dimensions 
  call get_micom_dim(nx,ny,nz)
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
  allocate(lon(dlon,dlat))
  allocate(lat(dlon,dlat))
   ! Reading the data grid file
   call nfw_open('data.nc', nf_nowrite, ncid)
   call nfw_inq_varid('data.nc', ncid,'lon' ,x_ID)
   call nfw_inq_varid('data.nc', ncid,'lat' ,y_ID)
   call nfw_get_var_double('data.nc', ncid, x_ID, lon)
   call nfw_get_var_double('data.nc', ncid, y_ID, lat)
   call nfw_close('data.nc', ncid)
   ! Read position and depth from model grid
   !
   call  get_micom_grid(modlon, modlat, depths, mindx, meandx, nx, ny)
   call ini_pivotp(modlon,modlat, nx, ny, min_r, max_r, itw, jtw, itn, jtn, its, jts, ite, jte)!
   ipiv=1
   jpiv=1
   do j=1,dlat
      do i=1,dlon
         call pivotp_micom(lon(i,j), lat(i,j), modlon, modlat, ipiv, jpiv, &
                   nx, ny, min_r, max_r,itw, jtw, itn, jtn, its, jts, ite, jte)
         F_ipiv(i,j)=ipiv
         F_jpiv(i,j)=jpiv
      end do !i
   end do !j
   call nfw_create('pivots_ICET.nc', nf_clobber, ncid)
   call nfw_def_dim('pivots_ICET.nc', ncid, 'x', dlon, dimids(1))
   call nfw_def_dim('pivots_ICET.nc', ncid, 'y', dlat, dimids(2))
   call nfw_def_var('pivots_ICET.nc', ncid, 'ipiv',nf_double, 2, dimids, vIPIV_ID)
   call nfw_def_var('pivots_ICET.nc', ncid, 'jpiv',nf_double, 2, dimids, vJPIV_ID)
  call nfw_enddef('pivots_ICET.nc', ncid)
  call nfw_put_var_double('pivots_ICET.nc', ncid, vIPIV_ID, F_ipiv(:,:))
  call nfw_put_var_double('pivots_ICET.nc', ncid, vJPIV_ID, F_jpiv(:,:))
  call nfw_close('pivots_ICET.nc', ncid)

end program p_dump_pivot_ICET_to_micom

! File:          p_dump_pivot_sst
!
! Created:       Francois counillon
!
! Last modified: 07/04/2014
!
! Purpose: find and dump in a netcdf file pivot point from CLS AVISO L4 data
!
program p_dump_pivot_SSH
use netcdf
use nfw_mod
use m_get_micom_grid
use m_get_micom_dim
use m_pivotp_micom
use m_spherdist

   implicit none

   integer*4, external :: iargc
   real, parameter :: onem=9806.
   integer, parameter :: dlon=360
   integer, parameter :: dlat=180

   character(len=80) :: filename
   logical          :: ex
   character(len=8) :: ctmp
   integer          :: nx,ny,nz
   real :: meandx,mindx,d_lon,d_lat
   real, allocatable, dimension(:,:)  :: depths,modlon,modlat, min_r, max_r, F_ipiv, F_jpiv
   real(4), allocatable, dimension(:) :: lon,lat
   integer, allocatable, dimension(:,:) :: itw, jtw, its, jts, itn, jtn, ite, jte
   real*8 :: min_d
   integer :: i,j,ipiv,jpiv
   integer :: dimids(2)
   integer :: ncid, x_ID, y_ID, z_ID 
   integer :: vJPIV_ID, vIPIV_ID,vLON_ID,vLAT_ID
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
  allocate(lon(dlon))
  allocate(lat(dlat))
   ! Read position and depth from model grid
   !
   call  get_micom_grid(modlon, modlat, depths, mindx, meandx, nx, ny)
   call ini_pivotp(modlon, modlat, nx, ny, min_r, max_r, itw, jtw, itn, jtn, its, jts, ite, jte)!

   call nfw_open('ssh_L4_1_deg.nc', nf_nowrite, ncid)
   call nfw_inq_varid('ssh_L4_1_deg.nc', ncid,'lon', vLON_ID)
   call nfw_inq_varid('ssh_L4_1_deg.nc', ncid,'lat', vLAT_ID)
   call nfw_get_var_real('ssh_L4_1_deg.nc', ncid, vLON_ID, lon)
   call nfw_get_var_real('ssh_L4_1_deg.nc', ncid, vLAT_ID, lat)
   call nfw_close('ssh_L4_1_deg.nc', ncid)
   print *,minval(lon), maxval(lon)
   print *,minval(lat), maxval(lat)

   
   F_ipiv(:,:)=0;
   F_jpiv(:,:)=0;
   ipiv=1
   jpiv=1
   do j=1,dlat
      do i=1,dlon
         d_lon=lon(i)
         d_lat=lat(j)
         call pivotp_micom(d_lon,d_lat, modlon, modlat, ipiv, jpiv, &
                   nx, ny, min_r, max_r,itw, jtw, itn, jtn, its, jts, ite, jte)
                   !print *,i,j,d_lon,d_lat,ipiv,jpiv
         min_d = spherdist(modlon(ipiv,jpiv), modlat(ipiv,jpiv), d_lon, d_lat)
         if (min_d <= 2*max_r(ipiv,jpiv)) then
            F_ipiv(i,j)=ipiv
            F_jpiv(i,j)=jpiv
         end if
      end do !i
   end do !j
   call nfw_create('pivots_SSH.nc', nf_clobber, ncid)
   call nfw_def_dim('pivots_SSH.nc', ncid, 'x', dlon, dimids(1))
   call nfw_def_dim('pivots_SSH.nc', ncid, 'y', dlat, dimids(2))
   call nfw_def_var('pivots_SSH.nc', ncid, 'ipiv',nf_double, 2, dimids, vIPIV_ID)
   call nfw_def_var('pivots_SSH.nc', ncid, 'jpiv',nf_double, 2, dimids, vJPIV_ID)
  call nfw_enddef('pivots_SSH.nc', ncid)
  call nfw_put_var_double('pivots_SSH.nc', ncid, vIPIV_ID, F_ipiv(:,:))
  call nfw_put_var_double('pivots_SSH.nc', ncid, vJPIV_ID, F_jpiv(:,:))
  call nfw_close('pivots_SSH.nc', ncid)

end program

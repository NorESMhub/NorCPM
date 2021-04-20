!Read the weekly observation error from NOAA OI-SST and estimate the monthly
!observation error
program p_calculate_monthly_SIT
  use nfw_mod
  implicit none

  integer*4, external :: iargc
  character(len=16) :: filename

  real(4), dimension(:,:,:), allocatable :: weekly_err,monthly_err
  real(4), dimension(:,:,:), allocatable :: weekly_ana,monthly_ana
  real(4), dimension(:,:), allocatable :: lon,lat
  real, dimension(:,:), allocatable :: tmp
  integer :: ncid
  integer, allocatable :: ns(:), nc(:)
  integer, allocatable :: ns2(:), nc2(:)
  integer :: vERR_id, vnERR_id, x_ID, y_ID, z_ID
  integer :: vANA_id, vnANA_id
  integer :: vlon_id, vnlon_id
  integer :: vlat_id, vnlat_id
  integer :: dimids(3)

  integer :: vlevel
  logical :: ex
  integer :: nx,ny,nz,i,j,k
  real :: val 
  real(4), dimension(1) :: scalefac, scaleana


   if (iargc()==1) then
      call getarg(1,filename)
   else
      print *,'Usage: calculate_monthly_SIT <filename>'
      call exit(1)
   end if
   nx=432
   ny=432
   inquire(file=trim(filename),exist=ex)

   if (ex) then
     ! Reading the grid file
      call nfw_open(trim(filename), nf_nowrite, ncid)
     ! Get dimension id in netcdf file ...
     call nfw_inq_dimid(trim(filename), ncid, 'xc', x_ID)
     call nfw_inq_dimid(trim(filename), ncid, 'yc', y_ID)
     call nfw_inq_dimid(trim(filename), ncid, 'time', z_ID)
     !Get the dimension
     call nfw_inq_dimlen(trim(filename), ncid, x_ID, nx)
     call nfw_inq_dimlen(trim(filename), ncid, y_ID, ny)
     call nfw_inq_dimlen(trim(filename), ncid, z_ID, nz)
   else
      stop 'ERROR: filename is missing'
   endif
   !print *,'Dimension read'
   allocate(ns(3))
   allocate(nc(3))
   allocate(ns2(1))
   allocate(nc2(1))
   ns(1)=1
   ns(2)=1
   ns(3)=1
   nc(1)=nx
   nc(2)=ny
   nc(3)=nz
   ns2(1)=1
   ns2(2)=1
   nc2(1)=nx
   nc2(2)=ny
   allocate(monthly_err(nx,ny,1))
   allocate(monthly_ana(nx,ny,1))
   allocate(tmp(nx,ny))
   allocate(weekly_err(nx,ny,nz))
   allocate(weekly_ana(nx,ny,nz))
   allocate(lon(nx,ny))
   allocate(lat(ny,ny))
   print *,'var allocated'
   call nfw_inq_varid(trim(filename), ncid,'analysis_sea_ice_thickness_unc', vERR_id)
   call nfw_inq_varid(trim(filename), ncid,'analysis_sea_ice_thickness', vANA_id)
   call nfw_inq_varid(trim(filename), ncid,'lon', vlon_id)
   call nfw_inq_varid(trim(filename), ncid,'lat', vlat_id)
   print *,'var id'
   call nfw_get_vara_real(trim(filename), ncid, vERR_id, ns, nc, weekly_err)
   call nfw_get_att_real(trim(filename), ncid, vERR_id, 'scale_factor', scalefac)
   call nfw_get_vara_real(trim(filename), ncid, vANA_id, ns, nc, weekly_ana)
   call nfw_get_att_real(trim(filename), ncid, vANA_id, 'scale_factor', scaleana)
   print *,'vari'
   call nfw_get_vara_real(trim(filename), ncid, vlon_id, ns2, nc2, lon)
   print *,'vari2'
   call nfw_get_vara_real(trim(filename), ncid, vlat_id, ns2, nc2, lat)
   print *,'vari3'
   call nfw_close(trim(filename), ncid)
   weekly_err=weekly_err*scalefac(1)
   weekly_ana=weekly_ana*scaleana(1)
   
   print *,'weekly var read'
   !print *,'Weekly at 155,89',weekly_err(155,89,1)
   !print *,'dimension :'
   !print *,nx,ny,nz
   monthly_ana=0.

   monthly_err=0.
   do j=1,ny
      do i=1,nx
         tmp(:,:)=0.
         do k=1,nz
            if (weekly_err(i,j,k)>0. ) then
               tmp(i,j)=tmp(i,j)+1./weekly_err(i,j,k)
               monthly_ana(i,j,1)=monthly_ana(i,j,1)+weekly_ana(i,j,k)/real(nz)
            endif
         end do
         if (tmp(i,j) .eq. 0.) then
            monthly_err(i,j,1)=-999.
         else
            monthly_err(i,j,1)=1./tmp(i,j)
         endif
      end do
   end do
   print *,'monthly calculated'
   !print *,'Monthly at  155,89',monthly_err(155,89)
   filename='monthly_file.nc'
   call nfw_create(trim(filename), nf_clobber, ncid)
   call nfw_def_dim(trim(filename), ncid, 'xc', nx, dimids(1))
   call nfw_def_dim(trim(filename), ncid, 'yc', ny, dimids(2))
   call nfw_def_dim(trim(filename), ncid, 'time', 1, dimids(3))
   call nfw_def_var(trim(filename), ncid, 'err', nf_real, 3, dimids, vnERR_id)
   call nfw_def_var(trim(filename), ncid, 'ana', nf_real, 3, dimids, vnANA_id)
   call nfw_def_var(trim(filename), ncid, 'lon', nf_real, 2, dimids, vnlon_id)
   call nfw_def_var(trim(filename), ncid, 'lat', nf_real, 2, dimids, vnlat_id)
   call nfw_enddef(trim(filename), ncid)

   call nfw_put_var_real(filename, ncid, vnERR_id, monthly_err)
   call nfw_put_var_real(filename, ncid, vnANA_id, monthly_ana)
   call nfw_put_var_real(filename, ncid, vnlon_id, lon)
   call nfw_put_var_real(filename, ncid, vnlat_id, lat)
   call nfw_close(filename, ncid)
   print *,'FINITO'
end program p_calculate_monthly_SIT

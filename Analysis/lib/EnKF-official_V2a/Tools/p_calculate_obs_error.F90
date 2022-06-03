!Read the weekly observation error from NOAA OI-SST and estimate the monthly
!observation error
program calculate_obs_error
  use nfw_mod
  implicit none

  integer*4, external :: iargc
  character(len=16) :: filename

  real(4), dimension(:,:,:), allocatable :: weekly_err,monthly_err
  real, dimension(:,:), allocatable :: tmp
  integer :: ncid
  integer, allocatable :: ns(:), nc(:)
  integer :: vERR_id, vnERR_id, x_ID, y_ID, z_ID
  integer :: dimids(3)

  integer :: vlevel
  logical :: ex
  integer :: nx,ny,nz,i,j,k
  real :: val 
  real(4), dimension(1) :: scalefac, addoffset


   if (iargc()==1) then
      call getarg(1,filename)
   else
      print *,'Usage: calculate_obs_error <filename>'
      call exit(1)
   end if
   nx=360
   ny=180
   inquire(file=trim(filename),exist=ex)

   if (ex) then
     ! Reading the grid file
      call nfw_open(trim(filename), nf_nowrite, ncid)
     ! Get dimension id in netcdf file ...
     call nfw_inq_dimid(trim(filename), ncid, 'lon', x_ID)
     call nfw_inq_dimid(trim(filename), ncid, 'lat', y_ID)
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
   ns(1)=1
   ns(2)=1
   ns(3)=1
   nc(1)=nx
   nc(2)=ny
   nc(3)=nz
   allocate(monthly_err(nx,ny,1))
   allocate(tmp(nx,ny))
   allocate(weekly_err(nx,ny,nz))
   !print *,'var allocated'
   call nfw_inq_varid(trim(filename), ncid,'err', vERR_id)
   call nfw_get_vara_real(trim(filename), ncid, vERR_id, ns, nc, weekly_err)
   call nfw_get_att_real(trim(filename), ncid, vERR_id, 'add_offset', addoffset)
   call nfw_get_att_real(trim(filename), ncid, vERR_id, 'scale_factor', scalefac)
   call nfw_close(trim(filename), ncid)
   weekly_err=weekly_err*scalefac(1)+addoffset(1)
   
   !print *,'weekly var read'
   !print *,'Weekly at 155,89',weekly_err(155,89,1)
   !print *,'dimension :'
   !print *,nx,ny,nz

   monthly_err=0.
   do j=1,ny
      do i=1,nx
         tmp(:,:)=0.
         do k=1,nz
            if (weekly_err(i,j,k)<640. .and. weekly_err(i,j,k)>0. ) then
               tmp(i,j)=tmp(i,j)+1./weekly_err(i,j,k)
            endif
         end do
         if (tmp(i,j) .eq. 0.) then
            monthly_err(i,j,1)=-999.
         else
            monthly_err(i,j,1)=1./tmp(i,j)
         endif
      end do
   end do
   !print *,'monthly calculated'
   !print *,'Monthly at  155,89',monthly_err(155,89)
   filename='monthly_error.nc'
   call nfw_create(trim(filename), nf_clobber, ncid)
   call nfw_def_dim(trim(filename), ncid, 'lon', nx, dimids(1))
   call nfw_def_dim(trim(filename), ncid, 'lat', ny, dimids(2))
   call nfw_def_dim(trim(filename), ncid, 'time', 1, dimids(3))
   call nfw_def_var(trim(filename), ncid, 'err', nf_real, 3, dimids, vnERR_id)
   call nfw_enddef(trim(filename), ncid)

   call nfw_put_var_real(filename, ncid, vnERR_id, monthly_err)
   call nfw_close(filename, ncid)
   !print *,'FINITO'
end program calculate_obs_error

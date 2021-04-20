program ensstat_point
  use m_get_micom_grid
  use m_get_micom_fld
  use m_spherdist
  use netcdf
  use nfw_mod
  use ieee_arithmetic
  implicit none 

  integer*4, external :: iargc

  integer :: kx, ky, kz

  character(len=3) :: cmem
  character(len=2) :: cmemMonthly ! Useful for Monthly mode
  integer :: idm,jdm, kdm, iarg
  real :: mindx, meandx, num
  real, allocatable, dimension(:,:) :: modlon, modlat, depths, dist
  real, allocatable, dimension(:,:,:) :: fld2, fld1, meandp,dp
  real*8, allocatable, dimension(:,:,:) :: var_temp, var_saln, &
       ave_temp,ave_saln,cov_temp,cov_saln,corr_temp
  real*8, allocatable, dimension(:,:,:) :: var_temp_month, &
       ave_temp_month
  real*4, dimension(:,:), allocatable :: iofld4
  real*8, dimension(:,:), allocatable :: corr 
  real*8 :: rscale, rscale1
  integer :: dimids(3)

  character(len=80) :: ncfile, fname, hname, argname, tmparg
  integer :: ncid,nens,i,j,k,l
  integer :: vFIELD_ID, vDIST_ID
  integer :: ns(4), nc(4)

  if (iargc()==5) then
     call getarg(1,fname)
     call getarg(2,tmparg) ; read(tmparg,*) nens
     call getarg(3,argname)
     call getarg(4,tmparg) ; read(tmparg,*) kx
     call getarg(5,tmparg) ; read(tmparg,*) ky
  else
     print *, iargc()
     print *
     print *
     print *
     print '(a)','*************** ensstat_point *******************'
     print '(a)','*This routine calculate correlation of variable *'
     print '(a)','*(<kx>, <ky>) in file <fname>'
     print '(a)','*************** ensstat_field *******************'
     print '(a)','Usage:'
     print '(a)','  ensstat_field fname enssize variable x y'
     print '(a)','Example:'
     print '(a)','  ensstat_field forecast 30 temp 200 200'
     stop '(ensstat_point)'
  end if

  call get_micom_dim(trim(fname),idm,jdm,kdm)
  allocate(modlon(idm,jdm))
  allocate(modlat(idm,jdm))
  allocate(depths(idm,jdm))
  allocate(dist(idm,jdm))
  call get_micom_grid(modlon, modlat, depths, mindx, meandx, &
       idm, jdm)
  do i=1,idm
     do j=1,jdm
        dist(i,j) = spherdist(modlon(kx,ky),modlat(kx,ky),modlon(i,j),modlat(i,j))/1000
     end do
  end do

  allocate(fld1(idm,jdm,kdm))
  allocate(fld2(idm,jdm,kdm))
  allocate(meandp(idm,jdm,kdm))
  allocate(dp(idm,jdm,kdm))
  allocate(ave_temp(idm,jdm,kdm))
  allocate(var_temp(idm,jdm,kdm))
  allocate(cov_temp(idm,jdm,kdm))
  allocate(ave_temp_month(idm,jdm,kdm))
  allocate(var_temp_month(idm,jdm,kdm))
  allocate(corr_temp(idm,jdm,kdm))
  allocate(corr(100,kdm)) 

  meandp = 0
  ave_temp=0
  var_temp=0
  cov_temp=0
  ave_temp_month = 0
  var_temp_month = 0
  rscale=1.0/(nens)
  rscale1=1.0/(nens-1.0)

  ns   =1
  nc(1)=idm
  nc(2)=jdm
  nc(3)=kdm
  nc(4)=1
  do  k=1,nens
     write(cmem,'(i3.3)') k
     !write(cmemMonthly,'(i2.2)') i !Variable for Monthly case
     ! Init & read file
     call nfw_open(trim(fname)//cmem//'.nc',nf_nowrite,ncid)
     call nfw_inq_varid(trim(fname)//cmem//'.nc',ncid,trim(argname),vFIELD_ID)
     call nfw_get_vara_double(trim(fname)//cmem//'.nc',ncid, vFIELD_ID, ns, nc, fld2)
     call nfw_inq_varid(trim(fname)//cmem//'.nc',ncid,'dp',vFIELD_ID)
     call nfw_get_vara_double(trim(fname)//cmem//'.nc',ncid, vFIELD_ID, ns, nc, dp)
     call nfw_close(trim(fname)//cmem//'.nc', ncid)

     do i=1,idm
        do j=1,jdm
           fld1(i,j,:) = fld2(kx,ky,:)
        end do
     end do
     where (dp .gt. 1.)
        meandp = meandp + 1.
     end where

     ave_temp_month=ave_temp_month+fld1
     var_temp_month=var_temp_month+fld1**2
     ave_temp = ave_temp+fld2
     var_temp = var_temp+fld2**2
     cov_temp = cov_temp+fld1*fld2
  enddo

  var_temp_month=max(0.,rscale * &
       (var_temp_month-rscale*ave_temp_month*ave_temp_month))
  ave_temp_month= rscale * ave_temp_month

  var_temp=rscale * (var_temp- &
       rscale*ave_temp*ave_temp)
  cov_temp = rscale*(cov_temp-ave_temp* &
       ave_temp_month)

!  print *, 'cov', cov_temp(kx,ky,:)
!  print *, 'var',var_temp_month(kx,ky,:)
  
  ave_temp = rscale  * ave_temp
  where (var_temp*var_temp_month &
       <= 1d-16)
     corr_temp = -2.
  elsewhere
     corr_temp = &
          cov_temp/(sqrt(var_temp*var_temp_month))
  endwhere

  do k=1,kdm
     do i=1,idm
        do j=1,jdm
           if (ieee_is_nan(corr_temp(i,j,k))) print *,cov_temp(i,j,k),var_temp(i,j,k)*var_temp_month(i,j,k)
        end do
     end do
  end do

!  print *, 'corr', corr_temp(kx,ky,:) 
  corr = 0.
  do k=1,kdm
     if (meandp(kx,ky,k) .lt. nens) cycle
     do l = 1,100
        num = 0
        do i=1,idm
           do j=1,jdm
              if (meandp(i,j,k) .eq. nens .and. corr_temp(i,j,k) .ge. -1. .and. dist(i,j) .gt. (l-2)*100 .and. dist(i,j) .le. l*100) then
                 corr(l,k) = corr(l,k) + corr_temp(i,j,k)
                 num = num + 1
              end if
           end do
        end do
        if (num .ne. 0.) corr(l,k) = corr(l,k)/num
     end do
  end do
  !print *,corr
  ! Netcdf file creation
  ncfile='./Data/ensstat_point_'//trim(argname)
  write(cmem,'(i3.3)') kx
  ncfile= trim(ncfile)//'_'//cmem
  write(cmem,'(i3.3)') ky
  ncfile= trim(ncfile)//'_'//cmem//'.nc'

!  print *,'Dumping to netcdf file ',trim(ncfile)
!!$  call nfw_create(trim(ncfile), nf_clobber, ncid)
!!$  call nfw_def_dim(trim(ncfile), ncid, 'idm', idm, dimids(1))
!!$  call nfw_def_dim(trim(ncfile), ncid, 'jdm', jdm, dimids(2))
!!$  call nfw_def_dim(trim(ncfile), ncid, 'kdm', kdm, dimids(3))
!!$
!!$  call nfw_def_var(trim(ncfile), ncid, 'corr',nf_double, 3, &
!!$       dimids, VFIELD_ID)
!!$  call nfw_def_var(trim(ncfile), ncid, 'dist',nf_double, 2, &
!!$       dimids(:2), VDIST_ID)
!!$  call nfw_enddef(trim(ncfile), ncid)
!!$
!!$  call nfw_put_var_double(trim(ncfile), ncid, VFIELD_ID, corr_temp)
!!$  call nfw_put_var_double(trim(ncfile), ncid, VDIST_ID, dist)
!!$  call nfw_close(trim(ncfile), ncid)
  call nfw_create(trim(ncfile), nf_clobber, ncid) 
  call nfw_def_dim(trim(ncfile), ncid, 'idm', 100, dimids(1))
  call nfw_def_dim(trim(ncfile), ncid, 'kdm', kdm, dimids(2))
  
  call nfw_def_var(trim(ncfile), ncid, 'corr',nf_double, 2, &                                                                                                           
       dimids(:2), VDIST_ID) 
  call nfw_enddef(trim(ncfile), ncid)

  call nfw_put_var_double(trim(ncfile), ncid, VDIST_ID, corr)
  call nfw_close(trim(ncfile), ncid)

end program ensstat_point

subroutine get_micom_dim(fname,nx,ny,nz)
   use netcdf
   use nfw_mod

   implicit none
   character(len=80), intent(inout) :: fname
   integer, intent(out) :: nx,ny,nz
   integer :: ncid, x_ID, y_ID, z_ID

   logical ex

   inquire(file='forecast001.nc',exist=ex)
   if (ex) then
     ! Reading the grid file                                                                                            
      call nfw_open('forecast001.nc', nf_nowrite, ncid)
     ! Get dimension id in netcdf file ...                                                                              
     call nfw_inq_dimid('forecast001.nc', ncid, 'x', x_ID)
     call nfw_inq_dimid('forecast001.nc', ncid, 'y', y_ID)
     call nfw_inq_dimid('forecast001.nc', ncid, 'kk', z_ID)
     !Get the dimension                                                                                                 
     call nfw_inq_dimlen('forecast001.nc', ncid, x_ID, nx)
     call nfw_inq_dimlen('forecast001.nc', ncid, y_ID, ny)
     call nfw_inq_dimlen('forecast001.nc', ncid, z_ID, nz)
  else
     print *, 'ERROR: file '//trim(fname)//'001.nc is missing'
     stop
   endif
end subroutine  get_micom_dim



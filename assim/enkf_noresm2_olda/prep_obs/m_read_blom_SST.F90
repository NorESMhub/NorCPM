 module m_read_blom_SST

contains

  subroutine read_blom_SST(fname,cmonth,data,modlon,modlat,depths,nx,ny,nrobs)
  use mod_measurement
  use mod_grid
  use nfw_mod

  implicit none

  integer, intent(in) :: nx,ny
  integer, intent(out) :: nrobs
  type (measurement), intent(inout)  :: data(:)
  real, dimension(nx,ny), intent(in) :: modlon,modlat,depths
  character(len=80), intent(in) :: fname,cmonth
  real(4) :: vsst(nx,ny),verr(nx,ny)
  real(4) :: vfice(nx,ny)
  integer :: ncid,i,j,k,imonth
  integer :: vSST_ID,vERR_ID,vFICE_ID 
  logical :: ex, found, fleeting
  real :: lon, lat
  real(4), dimension(1) :: scalefac, addoffset
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Read  observation file
  inquire (file=fname, exist=ex)
  if (.not. ex) then
     print *, 'Data file ', fname, ' not found.'
     stop
  end if
  call nfw_open(fname, nf_nowrite, ncid)
  call nfw_inq_varid(fname, ncid,'sst', vSST_ID)
  call nfw_get_var_real(fname, ncid, vSST_ID, vsst)
  call nfw_inq_varid(fname, ncid,'err', vERR_ID)
  call nfw_get_var_real(fname, ncid, vERR_ID, verr)
  call nfw_inq_varid(fname, ncid,'fice', vFICE_ID)
  call nfw_get_var_real(fname, ncid, vFICE_ID, vfice)
  call nfw_close(fname,ncid)
  k=1
  do j = 1, ny
     do i = 1, nx
       if (depths(i,j)>0 .and. vsst(i,j)>-1.81 .and. vfice(i,j)==0) then
        data(k)%d = vsst(i,j)
        data(k)%ipiv = i
        data(k)%jpiv = j
        data(k)%lon = modlon(i,j)
        data(k)%lat = modlat(i,j)
        data(k)%a1 = 1
        data(k)%a2 = 0
        data(k)%a3 = 0
        data(k)%a4 = 0
        data(k)%ns = 0
        data(k)%var = max((verr(i,j)*3)**2,0.01)
        data(k)%depth = 0
        data(k)%date = 0
        data(k)%status = .true.
        data(k)%id ='SST'
        data(k)%orig_id =0
        data(k)%i_orig_grid = -1
        data(k)%j_orig_grid = -1
        data(k)%h = 1
        k=k+1
       endif
     enddo   ! ny
  enddo    ! nx
  nrobs=k-1
  !print *,'Max,min obs',maxval(data(:)%d),minval(data(:)%d),maxval(depths(:,:)),minval(depths(:,:))
end subroutine read_blom_SST
end module m_read_blom_SST

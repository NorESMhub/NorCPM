program dump_spice
  use mod_spice
  use nfw_mod

  implicit none
  integer*4, external :: iargc
  integer imem                  ! ensemble member
  integer :: ncid, x_ID, y_ID, z_ID
  integer :: dimids(3)
  character(len=8) :: ctmp
  character(len=3) :: cmem
  logical          :: ex
  integer :: vTEM_ID, vSAL_ID,VSPI_ID,VS_ID,i,j,k
  integer :: idm,jdm,kdm
  real, allocatable, dimension(:,:,:,:)   :: temp,saln
  real, allocatable, dimension(:,:,:)   :: sp
  integer, allocatable :: ns(:), nc(:)
  character(len=80) :: oldfile
  real :: tmp

  if (iargc()==1 ) then
      call getarg(1,ctmp)
      read(ctmp,*) imem
      write(cmem,'(i3.3)') imem
   else
      print *,'"dump_spice" -- compute the spicines respect to T and S using Flament et al 2002.'
      print *
      print *,'usage: '
      print *,'   dump_spice ensemble_member'
      print *,'   "ensemble_member" is the ensemble member'
      call exit(1)
  endif
  oldfile='analysis'//cmem//'.nc'
  ! Get dimensions from blkdat
  inquire(exist=ex,file=trim(oldfile))
  if (.not.ex) then
     write(*,*) 'Can not find '//'analysis'//cmem//'.nc'
     stop '(dump_spice)'
  end if
  ! Reading the restart file
  call nfw_open(trim(oldfile), nf_write, ncid)
  ! Get dimension id in netcdf file ...
  !nb total of data
  call nfw_inq_dimid(trim(oldfile), ncid, 'x', x_ID)
  call nfw_inq_dimid(trim(oldfile), ncid, 'y', y_ID)
  call nfw_inq_dimid(trim(oldfile), ncid, 'kk', z_ID)
  !nb total of track
  call nfw_inq_dimlen(trim(oldfile), ncid, x_ID, idm)
  call nfw_inq_dimlen(trim(oldfile), ncid, y_ID, jdm)
  call nfw_inq_dimlen(trim(oldfile), ncid, z_ID, kdm)
  print *, 'The model dimension is :',idm,jdm,kdm
   !Reading dp 
   allocate(ns(4))
   allocate(nc(4))
   ns(1)=1
   ns(2)=1
   ns(3)=1
   ns(4)=1
   nc(1)=idm
   nc(2)=jdm
   nc(3)=2*kdm
   nc(4)=1
   allocate(temp(idm,jdm,2*kdm,1))
   allocate(saln(idm,jdm,2*kdm,1))
   allocate(sp(idm,jdm,kdm))
   print *,'Reading temp and saln'
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'temp',vTEM_ID)
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'saln',vSAL_ID)
   call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vTEM_ID, ns, nc, temp)
   call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vSAL_ID, ns, nc, saln)
   call nfw_close(trim(oldfile), ncid)
   print *,'compute spiciness'
   do i=1,idm
   do j=1,jdm
   do k=1,kdm
      !!print *,'compute spiciness',i,j
      if (saln(i,j,k,1)<999999.) then
       sp(i,j,k)=spice(temp(i,j,k,1),saln(i,j,k,1))
    else
       sp(i,j,k)=saln(i,j,1,1)
      end if
   end do
   end do
   end do
    call nfw_create('spicines'//cmem//'.nc', nf_clobber, ncid)
    call nfw_def_dim('spicines'//cmem//'.nc', ncid, 'x', idm, dimids(1))
    call nfw_def_dim('spicines'//cmem//'.nc', ncid, 'y', jdm, dimids(2))
    call nfw_def_dim('spicines'//cmem//'.nc', ncid, 'z', kdm, dimids(3))
    call nfw_def_var('spicines'//cmem//'.nc', ncid, 'spice', nf_float, 3, dimids, VSPI_ID)
    call nfw_enddef('spicines'//cmem//'.nc', ncid)
   call nfw_put_var_double('spicines'//cmem//'.nc', ncid, VSPI_ID, sp(:,:,:))
   call nfw_close('spicines'//cmem//'.nc', ncid)
end program dump_spice

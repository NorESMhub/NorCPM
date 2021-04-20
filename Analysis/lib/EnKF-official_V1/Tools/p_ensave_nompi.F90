! File:          p_ensmean.F90
!
! Created:       Francois counillon
!
! Last modified: 24/05/2014
!
! Purpose:       Create a light and smart average of the ensemble
!
! Description:  
!            This program recompute the kfpla from the model output
!                         ensure that the sum of dp = pb
!            Input is the mem
!
! Modifications:
!
program ensave
use netcdf
use nfw_mod
   implicit none

   integer*4, external :: iargc
   real, parameter :: onem=9806.

   integer imem                  ! ensemble member
   character(len=80) :: oldfile,cbasis, char80
   logical          :: ex
   character(len=8) :: cfld, ctmp
   character(len=3) :: cproc,cmem
   integer          :: tlevel, vlevel, nproc
   integer          :: idm,jdm,kdm
   real, allocatable, dimension(:,:)     :: pb_ave
   real, allocatable, dimension(:,:,:)     :: dp_ave,temp_ave,saln_ave,dptmp,salntmp,temptmp,nbtmp
   real, allocatable, dimension(:,:,:,:)   :: tmp3D,tmp2D
   integer :: ios,ios2,nmem
   integer :: dimids(3)
   integer :: i,j,k
   real :: dpsum
   integer, allocatable :: ns(:), nc(:)
   integer, allocatable :: ns2(:), nc2(:),ns3(:), nc3(:)
   integer :: ncid, x_ID, y_ID, z_ID
   integer :: vPBMN_ID, vPBP_ID, vPBU_ID, vPBV_ID ,vPBUP_ID,vPBVP_ID,vTMP_ID
   integer :: vFICEM_ID, vHICEM_ID
   integer :: ncid2, vTEM_ID,vSAL_ID,vDP_ID,vNB_ID
   real, allocatable :: press(:)



   if (iargc()==2 ) then
      call getarg(1,cbasis)
      call getarg(2,ctmp)
      read(ctmp,*) nmem
   else
      print *,'"ensave" -- A light and smart ensave'
      print *
      print *,'usage: '
      print *,'   ensave cbasis ensemble_size'
      print *,'ex:   ensave analysis 30'
      call exit(1)
   endif
   write(cmem,'(i3.3)') 1
   oldfile=trim(cbasis)//cmem//'.nc'
   print *, 'reading dim from file:',oldfile
   inquire(exist=ex,file=trim(oldfile))
   if (.not.ex) then
      write(*,*) 'Can not find '//trim(oldfile)
      stop '(ensave)'
   end if
   ! Reading the restart file
   call nfw_open(trim(oldfile), nf_nowrite, ncid)
   ! Get dimension id in netcdf file ...
   !nb total of data
   call nfw_inq_dimid(trim(oldfile), ncid, 'x', x_ID)
   call nfw_inq_dimid(trim(oldfile), ncid, 'y', y_ID)
   call nfw_inq_dimid(trim(oldfile), ncid, 'kk', z_ID)
   !nb total of track
   call nfw_inq_dimlen(trim(oldfile), ncid, x_ID, idm)
   call nfw_inq_dimlen(trim(oldfile), ncid, y_ID, jdm)
   call nfw_inq_dimlen(trim(oldfile), ncid, z_ID, kdm)
   call nfw_close(trim(oldfile), ncid)
   print *, 'The model dimension is :',idm,jdm,kdm
!   allocate(pb_ave (idm,jdm))
   allocate(dp_ave(idm,jdm,kdm))
   allocate(temp_ave(idm,jdm,kdm))
   allocate(saln_ave(idm,jdm,kdm))
   allocate(dptmp (idm,jdm,kdm))
   allocate(temptmp (idm,jdm,kdm))
   allocate(salntmp (idm,jdm,kdm))
   allocate(nbtmp (idm,jdm,kdm))
   allocate(tmp3D (idm,jdm,2*kdm,1))
!   allocate(tmp2D (idm,jdm,2,1))
!   pb_ave(:,:)=0
   temp_ave(:,:,:)=0
   saln_ave(:,:,:)=0
   dp_ave(:,:,:)=0
   !Reading dp 
   allocate(ns(4))
   allocate(nc(4))
   do imem=1,nmem
      write(cmem,'(i3.3)') imem
      oldfile=trim(cbasis)//cmem//'.nc'
      print *, trim(oldfile)
      inquire(exist=ex,file=trim(oldfile))
      if (.not.ex) then
         write(*,*) 'Can not find '//oldfile
         stop '(ensave)'
      end if
      call nfw_open(trim(oldfile), nf_nowrite, ncid)
      ns(1)=1
      ns(2)=1
      ns(3)=1
      ns(4)=1
      nc(1)=idm
      nc(2)=jdm
      nc(3)=2*kdm
      nc(4)=1
      !Get DP variable for masking
      call nfw_inq_varid(trim(oldfile), ncid,'dp',vDP_ID)
      call nfw_get_vara_double(trim(oldfile), ncid, vDP_ID, ns, nc, tmp3D)
      dptmp=tmp3D(:,:,1:kdm,1)
      call nfw_inq_varid(trim(oldfile), ncid,'temp',vTMP_ID)
      call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vTMP_ID, ns, nc, tmp3D)
      temptmp=tmp3D(:,:,1:kdm,1)
      call nfw_inq_varid(trim(oldfile), ncid,'saln',vTMP_ID)
      call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vTMP_ID, ns, nc, tmp3D)
      salntmp=tmp3D(:,:,1:kdm,1)
      ! DP correction
      do j=1,jdm
      do i=1,idm
        !only if not land mask
        if (dptmp(i,j,1)<100000000000.) then
         do k = 1, kdm
           if (dptmp(i,j,k)>0.) then
              temp_ave(i,j,k)=temp_ave(i,j,k)+temptmp(i,j,k)
              saln_ave(i,j,k)=saln_ave(i,j,k)+salntmp(i,j,k)
              nbtmp(i,j,k)=nbtmp(i,j,k)+1
           end if
           dp_ave(i,j,k)=dp_ave(i,j,k)+dptmp(i,j,k)
         end do
        endif
      end do
      end do
!      nc(3)=2
!      call nfw_inq_varid(trim(oldfile), ncid,'pb',vTMP_ID)
!      call nfw_get_vara_double(trim(oldfile), ncid, vTMP_ID, ns, nc, tmp2D)
!      pb_ave= pb_ave+tmp2D(:,:,1,1)
      call nfw_close(trim(oldfile), ncid)
      call sleep(5)
   enddo
   do j=1,jdm
   do i=1,idm
      do k = 1, kdm
        temp_ave(i,j,k)=temp_ave(i,j,k)/nbtmp(i,j,k)
        saln_ave(i,j,k)=saln_ave(i,j,k)/nbtmp(i,j,k)
      end do
   end do
   end do



   oldfile=trim(cbasis)//'_avg.nc'
   call nfw_create(trim(oldfile), nf_clobber, ncid)
   call nfw_def_dim(trim(oldfile), ncid, 'x', idm, dimids(1))
   call nfw_def_dim(trim(oldfile), ncid, 'y', jdm, dimids(2))
   call nfw_def_dim(trim(oldfile), ncid, 'z', kdm, dimids(3))
   call nfw_def_var(trim(oldfile), ncid, 'temp',nf_float, 3, dimids, vTEM_ID)
   call nfw_def_var(trim(oldfile), ncid, 'saln',nf_float, 3, dimids, vSAL_ID)
   call nfw_def_var(trim(oldfile), ncid, 'nbmem',nf_float, 3, dimids, vNB_ID)
   call nfw_def_var(trim(oldfile), ncid, 'dp',nf_float, 3, dimids, vDP_ID)
   call nfw_enddef(trim(oldfile), ncid)
   call nfw_put_var_double(trim(oldfile), ncid, vTEM_ID, temp_ave(:,:,:))
   call nfw_put_var_double(trim(oldfile), ncid, vSAL_ID, saln_ave(:,:,:))
   call nfw_put_var_double(trim(oldfile), ncid, vDP_ID, dp_ave(:,:,:))
   call nfw_put_var_double(trim(oldfile), ncid, vNB_ID, nbtmp(:,:,:))
   call nfw_close(trim(oldfile), ncid)
end program

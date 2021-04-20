! File:          p_fixmycom.F90
!
! Created:       Francois counillon
!
! Last modified: 24/08/2010
!
! Purpose:       Fixes EnKF output.
!
! Description:  
!            This program recompute the kfpla from the model output
!                         ensure that the sum of dp = pb
!            Input is the mem
!
! Modifications:
!
program fixmicom
use netcdf
use nfw_mod
   implicit none

   integer*4, external :: iargc
   real, parameter :: onem=9806.

   integer imem                  ! ensemble member
   character(len=80) :: oldfile,newfile, char80
   logical          :: ex
   character(len=8) :: cfld, ctmp
   character(len=3) :: cproc,cmem
   integer          :: tlevel, vlevel, nproc
   integer          :: idm,jdm,kdm
   real, allocatable:: fld(:,:)
   real, allocatable, dimension(:,:)     :: depths,modlon,modlat
   real, allocatable, dimension(:,:,:)     :: ficem,hicem
   real, allocatable, dimension(:,:,:,:)   :: dp, pb, kfpla,pbu,pbv
   integer, allocatable, dimension(:,:)   :: jns,ins,jnn,inn,inw,jnw,ine,jne
   real, parameter  :: epsil=1.e-11

   integer,parameter :: numfields=2
   integer :: ios,ios2
   integer :: i,j,k
   real :: dpsum
   integer, allocatable :: ns(:), nc(:)
   integer, allocatable :: ns2(:), nc2(:),ns3(:), nc3(:)
   integer :: ncid, x_ID, y_ID, z_ID, vDP_ID, vPBOT_ID, vKFP_ID
   integer :: vPBMN_ID, vPBP_ID, vPBU_ID, vPBV_ID ,vPBUP_ID,vPBVP_ID
   integer :: vFICEM_ID, vHICEM_ID
   integer :: ncid2, jns_ID, ins_ID, inw_ID, jnw_ID,jnn_ID, inn_ID, ine_ID, jne_ID
   real, allocatable :: press(:)



   if (iargc()==1 ) then
      call getarg(1,ctmp)
      read(ctmp,*) imem
      write(cmem,'(i3.3)') imem
   else
      print *,'"fixmycom" -- A crude routine to correct restart files obvious errors and complete diagnostic variable'
      print *
      print *,'usage: '
      print *,'   fixmicom ensemble_member'
      print *,'   "ensemble_member" is the ensemble member'
      call exit(1)
   endif
   oldfile='analysis'//cmem//'.nc'
   ! Get dimensions from blkdat
   inquire(exist=ex,file=trim(oldfile))
   if (.not.ex) then
      write(*,*) 'Can not find '//'analysis'//cmem//'.nc'
      stop '(EnKF_postprocess)'
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
   allocate(pb (idm,jdm,2,1 ))
   allocate(dp   (idm,jdm,2*kdm,1))
   allocate(kfpla(idm,jdm,2,1 ))
   allocate(press(kdm+1))
   !Reading dp 
   print *,'Reading dp and pb'
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
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'dp',vDP_ID)
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'kfpla',vKFP_ID)
   call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vDP_ID, ns, nc, dp)
   !Reading pb 
   nc(3)=2
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'pb',vPBOT_ID)
   call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vPBOT_ID, ns, nc, pb)
!   !Reading kfpla
!   nc(3)=2
!   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'kfpla',vKFP_ID)
!   call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vKFP_ID, ns, nc, kfpla)
   print *,'Correct for neg dp'

   ! DP correction
   do j=1,jdm
   do i=1,idm
   !only if not land mask
      if (dp(i,j,1)<100000000000.) then
      !!! Move negative layers to neighbouring layers.
      dpsum=dp(i,j,1,1)
      do k = 1, kdm-1
         dp(i,j,k+1,1) = dp(i,j,k+1,1) + min(0.0,dp(i,j,k,1))
         dp(i,j,k,1  ) = max(dp(i,j,k,1),0.0)
         dpsum=dpsum+ dp(i,j,k+1,1) 
      end do

      !!! Go backwards to fix lowermost layer.
      do k = kdm, 3, -1
         dp(i,j,k-1,1) = dp(i,j,k-1,1) + min(0.0,dp(i,j,k,1))
         dp(i,j,k,1)   =   max(dp(i,j,k,1),0.0)
      end do

      !!! No layers below the sea bed.
      press(  1) = 0.0         
      do k = 1, kdm-1
         press(k+1) = press(k) + dp(i,j,k,1)
         press(k+1) = min(pb(i,j,1,1),press(k+1))
      end do
      press(kdm+1) = pb(i,j,1,1)

      dpsum=0
      do k = 1, kdm
         dp(i,j,k,1) = press(k+1) - press(k)
         dpsum=dpsum+dp(i,j,k,1)
      end do
!
      if (dpsum-pb(i,j,1,1)>1 .and. pb(i,j,1,1)<100000000000 ) then
        print *,'Inconsistency at point:',i,j,dpsum,pb(i,j,1,1)
      endif
    endif
   end do
   end do
   print *,'Compute Kpfla'


!
   ! Compute the Kpfla
   do j=1,jdm
      do i=1,idm
          k=3
          dpsum=0.
          do while (dp(i,j,k,1).lt.epsil)
            dpsum=dpsum+dp(i,j,k,1)
            dp(i,j,k,1)=0.
            dp(i,j,k+kdm,1)=0.
            k=k+1
            if (k.gt.kdm) exit
          enddo
          if (k.gt.kdm) then
            dp(i,j,2,1)=dp(i,j,2,1)+dpsum
            dp(i,j,2+kdm,1)=dp(i,j,2,1)
          else
            dp(i,j,k,1)=dp(i,j,k,1)+dpsum
            dp(i,j,k+kdm,1)=dp(i,j,k,1)
          endif
          kfpla(i,j,1,1)=real(k)
          kfpla(i,j,2,1)=real(k)
      enddo
   enddo
   dp(:,:,kdm+1:2*kdm,1)=dp(:,:,1:kdm,1);
   pb(:,:,2,1)=pb(:,:,1,1);
   kfpla(:,:,2,1)=kfpla(:,:,1,1);
   print *,'dump dp, pb, Kpfla'


!
   ! Now we should be finished with dp pbot and kfpla
   nc(3)=2*kdm
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vDP_ID, ns, nc, dp)
   nc(3)=2
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vPBOT_ID, ns, nc, pb)
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vKFP_ID, ns, nc, kfpla)
   deallocate(dp,kfpla)
   !Now need to dump the 15 variables that have different name, but that almost
   !do the same stuff. Set them all equal!
   print *,'Compute the differnts pb'
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'pb_mn',vPBMN_ID)
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'pb_p',vPBP_ID)
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'pbu',vPBU_ID)
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'pbv',vPBV_ID)
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'pbu_p',vPBUP_ID)
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'pbv_p',vPBVP_ID)
   allocate(pbu (idm,jdm,2,1    ))
   allocate(pbv (idm,jdm,2,1    ))
   call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vPBU_ID, ns, nc, pbu)
   call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vPBV_ID, ns, nc, pbv)
   allocate(ins(idm,jdm))
   allocate(jns(idm,jdm))
   allocate(inn(idm,jdm))
   allocate(jnn(idm,jdm))
   allocate(inw(idm,jdm))
   allocate(jnw(idm,jdm))
   allocate(ine(idm,jdm))
   allocate(jne(idm,jdm))
  allocate(ns3(3))
  allocate(nc3(3))
  ns3(1)=1
  ns3(2)=1
  ns3(3)=1
  nc3(1)=idm
  nc3(2)=jdm
  nc3(3)=1
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vPBP_ID, ns3, nc3, pb(:,:,1,1))
   call nfw_open('grid.nc', nf_write, ncid2)
   call nfw_inq_varid('grid.nc', ncid2,'jns',jns_ID)
   call nfw_inq_varid('grid.nc', ncid2,'ins',ins_ID)
   call nfw_inq_varid('grid.nc', ncid2,'jnw',jnw_ID)
   call nfw_inq_varid('grid.nc', ncid2,'inw',inw_ID)
   allocate(ns2(2))
   allocate(nc2(2))
   ns2(1)=1
   ns2(2)=1
   nc2(1)=idm
   nc2(2)=jdm
   call nfw_get_vara_int('grid.nc', ncid2, jns_ID, ns2, nc2, jns)
   call nfw_get_vara_int('grid.nc', ncid2, ins_ID, ns2, nc2, ins)
   call nfw_get_vara_int('grid.nc', ncid2, jnw_ID, ns2, nc2, jnw)
   call nfw_get_vara_int('grid.nc', ncid2, inw_ID, ns2, nc2, inw)
   !Here we do not have acess to ifu and ilu, so we need to make some tricks to
   !make the ponts close to the land equal to 0
   do j=1,jdm
      do i=1,idm
         if ( pbu(i,j,1,1) .ne. 0) then
            pbu(i,j,1,1)=min(pb(i,j,1,1),pb(inw(i,j),jnw(i,j),1,1))
            pbu(i,j,2,1)=pbu(i,j,1,1)
         endif
         if ( pbv(i,j,1,1) .ne. 0) then
            pbv(i,j,1,1)=min(pb(i,j,1,1),pb(ins(i,j),jns(i,j),1,1))
            pbv(i,j,2,1)=pbv(i,j,1,1)
         endif
      enddo
   enddo
   nc(3)=2
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vPBU_ID, ns, nc, pbu)
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vPBV_ID, ns, nc, pbv)
   !call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vPBUP_ID, ns3, nc3, pbu(:,:,1,1))
   !call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vPBVP_ID, ns3, nc3, pbv(:,:,1,1))
   deallocate(pbu,pbv,ins,jns,inw,jnw)
   !allocate(ficem(idm,jdm,1))
   !allocate(hicem(idm,jdm,1))
   !call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'ficem',vFICEM_ID)
   !call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vFICEM_ID, ns3, nc3, ficem)
   !call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'hicem',vHICEM_ID)
   !call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vHICEM_ID, ns3, nc3, hicem)
   !print *,minval(ficem),minval(hicem)
   !do j=1,jdm
   !   do i=1,idm
   !      ficem(i,j,1)=max(ficem(i,j,1),0.)
   !      hicem(i,j,1)=max(hicem(i,j,1),0.)
   !   enddo
   !enddo
   !print *,minval(ficem),minval(hicem)
   !call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vFICEM_ID, ns3, nc3, ficem)
   !call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vHICEM_ID, ns3, nc3, hicem)
   call nfw_close(trim(oldfile)//'.nc', ncid)
   
  !ubflx_mn
  !ubflxs_p
  !vbflxs_p

!
!
!
!
!
!   ! Loop over restart file
!   rstind=1 ! Restart index
!   allok=.true.
!   do while ( allok)
!      if (trim(cfld)=='temp') then
!         ! need salinity as well
!         call get_mod_fld_new(restart(1:fnd-1),saln(:,:),imem,'saln    ',vlevel,tlevel,idm,jdm)
!         if (tlevel==-1) then
!               print *,'Could not get salinity field'
!               call exit(1)
!          end if
!
!          ! keep water warmer than freezing point
!          do j=1,jdm
!           do i=1,idm
!               fld(i,j)=max(-.057*saln(i,j),fld(i,j))
!           end do
!          end do
!      else if (trim(cfld)=='saln') then
!           do j=1,jdm
!           do i=1,idm
!              fld(i,j)=max(5.,fld(i,j)) ! LB :no water fresher than 5 psu (Baltic)
!           end do
!           end do
!      else if (trim(cfld)=='dp') then
!            fld = dp(:,:,vlevel) ! NB, one time level 
!      end if ! No correction for other fields in the hycom restart file
!
!      !   call put_mod_fld(trim(newfile),fld,imem,cfld,vlevel,tlevel,rstind,idm,jdm)
!
!      rstind=rstind+1
!   end do

end program

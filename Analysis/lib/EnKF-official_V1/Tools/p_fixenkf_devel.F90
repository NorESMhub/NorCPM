! File:          p_fixenkf.F90
!
! Created:       Francois counillon
!
! Last modified: 24/08/2010
!
! Purpose:       Fixes EnKF output.
!
! Description:  
!                         inflate the forecast  dp ; sum of dp_f = pba
!            Input is the mem
!
! Modifications:
!
program fixenkf
use netcdf
use mod_eosfun
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
   real, allocatable, dimension(:,:)     :: modlon,modlat,corioq,qlat
   real, allocatable, dimension(:,:,:)     :: ficem,hicem
   real, allocatable, dimension(:,:,:,:)   :: dp, pb, pbu,pbv,tmp,saln,temp,sigmar,sigma,pvtrop
   integer, allocatable, dimension(:,:)   :: jns,ins,jnn,inn,inw,jnw,ine,jne,insw,jnsw,pmask,umask,vmask,qmask
   real, parameter  :: epsil=1.e-11

   integer,parameter :: numfields=2
   integer :: ios,ios2
   integer :: i,j,k
   real :: dpsum,q
   integer, allocatable :: ns(:), nc(:)
   integer, allocatable :: ns2(:), nc2(:),ns3(:), nc3(:)
   integer :: ncid, x_ID, y_ID, z_ID, vDP_ID, vPBOT_ID, vKFP_ID
   integer :: vPBMN_ID, vPBP_ID, vPBU_ID, vPBV_ID ,vPBUP_ID,vPBVP_ID,vTMP_ID
   integer :: vPMASK_ID, vUMASK_ID,vVMASK_ID,vQMASK_ID,vSIGMAR_ID,vQLAT_ID
   integer :: ncid2, jns_ID, ins_ID, inw_ID, jnw_ID,jnn_ID, inn_ID, ine_ID, jne_ID, insw_ID,jnsw_ID
   real, parameter :: radian=57.295779513
   real, parameter :: pi=3.1415926536



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
   print *, 'fixenkf file:',oldfile
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
  ! print *, 'The model dimension is :',idm,jdm,kdm
   allocate(pb (idm,jdm,2,1 ))
   allocate(sigmar (idm,jdm,kdm,1 ))
   allocate(dp   (idm,jdm,2*kdm,1))
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
   !read grid file
   allocate(ins(idm,jdm))
   allocate(jns(idm,jdm))
   allocate(inn(idm,jdm))
   allocate(jnn(idm,jdm))
   allocate(inw(idm,jdm))
   allocate(jnw(idm,jdm))
   allocate(ine(idm,jdm))
   allocate(jne(idm,jdm))
   allocate(insw(idm,jdm))
   allocate(jnsw(idm,jdm))
   allocate(pmask(idm,jdm))
   allocate(umask(idm,jdm))
   allocate(vmask(idm,jdm))
   allocate(qmask(idm,jdm))
   allocate(qlat(idm,jdm))
   call nfw_open('grid.nc', nf_write, ncid2)
   call nfw_inq_varid('grid.nc', ncid2,'pmask',vPMASK_ID)
   call nfw_inq_varid('grid.nc', ncid2,'umask',vUMASK_ID)
   call nfw_inq_varid('grid.nc', ncid2,'vmask',vVMASK_ID)
   call nfw_inq_varid('grid.nc', ncid2,'qmask',vQMASK_ID)
   call nfw_inq_varid('grid.nc', ncid2,'ins',ins_ID)
   call nfw_inq_varid('grid.nc', ncid2,'jns',jns_ID)
   call nfw_inq_varid('grid.nc', ncid2,'inn',inn_ID)
   call nfw_inq_varid('grid.nc', ncid2,'jnn',jnn_ID)
   call nfw_inq_varid('grid.nc', ncid2,'inw',inw_ID)
   call nfw_inq_varid('grid.nc', ncid2,'jnw',jnw_ID)
   call nfw_inq_varid('grid.nc', ncid2,'ine',ine_ID)
   call nfw_inq_varid('grid.nc', ncid2,'jne',jne_ID)
   call nfw_inq_varid('grid.nc', ncid2,'insw',insw_ID)
   call nfw_inq_varid('grid.nc', ncid2,'jnsw',jnsw_ID)
   call nfw_inq_varid('grid.nc', ncid2,'qlat',vQLAT_ID)
   allocate(ns2(2))
   allocate(nc2(2))
   ns2(1)=1
   ns2(2)=1
   nc2(1)=idm
   nc2(2)=jdm
   call nfw_get_vara_int('grid.nc', ncid2, ins_ID, ns2, nc2, ins)
   call nfw_get_vara_int('grid.nc', ncid2, jns_ID, ns2, nc2, jns)
   call nfw_get_vara_int('grid.nc', ncid2, inn_ID, ns2, nc2, inn)
   call nfw_get_vara_int('grid.nc', ncid2, jnn_ID, ns2, nc2, jnn)
   call nfw_get_vara_int('grid.nc', ncid2, inw_ID, ns2, nc2, inw)
   call nfw_get_vara_int('grid.nc', ncid2, jnw_ID, ns2, nc2, jnw)
   call nfw_get_vara_int('grid.nc', ncid2, ine_ID, ns2, nc2, ine)
   call nfw_get_vara_int('grid.nc', ncid2, jne_ID, ns2, nc2, jne)
   call nfw_get_vara_int('grid.nc', ncid2, insw_ID, ns2, nc2, insw)
   call nfw_get_vara_int('grid.nc', ncid2, jnsw_ID, ns2, nc2, jnsw)
   call nfw_get_vara_int('grid.nc', ncid2, vPMASK_ID, ns2, nc2, pmask)
   call nfw_get_vara_int('grid.nc', ncid2, vQMASK_ID, ns2, nc2, qmask)
   call nfw_get_vara_int('grid.nc', ncid2, vUMASK_ID, ns2, nc2, umask)
   call nfw_get_vara_int('grid.nc', ncid2, vVMASK_ID, ns2, nc2, vmask)
   call nfw_get_vara_double('grid.nc', ncid2, vQLAT_ID, ns2, nc2, qlat)
   !calculate corioq needed later
   allocate(corioq(idm,jdm))
   do j=1,jdm
     do i=1,idm
       corioq(i,j)=sin(qlat(i,j)/radian)*4.*pi/86164.
     enddo
   enddo
   deallocate(qlat)

   !reading dp, pb,sigmar
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'dp',vDP_ID)
   call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vDP_ID, ns, nc, dp)
   !Reading pb 
   nc(3)=2
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'pb',vPBOT_ID)
   call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vPBOT_ID, ns, nc, pb)
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'sigmar',vSIGMAR_ID)
   call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vSIGMAR_ID, ns, nc, sigmar)

   ! Scale DP to match PB analysed
   do j=1,jdm
   do i=1,idm
   !only if not land mask
     !if (dp(i,j,1,1)<100000000000.) then
     if (pmask(i,j)==1) then
      dpsum=0.
      do k = 1, kdm
         dpsum=dpsum+ dp(i,j,k,1) 
      end do
      do k = 1, kdm
         dp(i,j,k,1)= dp(i,j,k,1)*pb(i,j,1,1)/dpsum
      end do
     endif
   end do
   end do
   dp(:,:,kdm+1:2*kdm,1)=dp(:,:,1:kdm,1)
   pb(:,:,2,1)=pb(:,:,1,1)
   ns(1)=1
   ns(2)=1
   ns(3)=1
   ns(4)=1
   nc(1)=idm
   nc(2)=jdm
   nc(3)=2*kdm
   nc(4)=1

   call eosini
!   allocate(temmin (idm,jdm,kdm,1 ))
!   call settemmin(idm,jdm,kdm,sigmar,temmin)
   ns(1)=1
   ns(2)=1
   ns(3)=1
   ns(4)=1
   nc(1)=idm
   nc(2)=jdm
   nc(3)=2*kdm
   nc(4)=1
   allocate(temp   (idm,jdm,2*kdm,1))
   allocate(saln   (idm,jdm,2*kdm,1))
   allocate(sigma   (idm,jdm,2*kdm,1))
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'temp',vTMP_ID)
   call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vTMP_ID, ns, nc, temp)
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'saln',vTMP_ID)
   call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vTMP_ID, ns, nc, saln)
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'sigma',vTMP_ID)
   call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vTMP_ID, ns, nc, sigma)
   do j=1,jdm
     do i=1,idm
       do k=1,2
        if (temp(i,j,k,1)<100000.) then
         !temp(i,j,k,1)=max(-0.0547*saln(i,j,k,1),temp(i,j,k,1))  !swtfrz shortcuted
         temp(i,j,k,1)=max(-1.8,temp(i,j,k,1))  !swtfrz shortcuted
         temp(i,j,k+kdm,1)=temp(i,j,k,1)
         saln(i,j,k+kdm,1)=saln(i,j,k,1)
         sigma(i,j,k,1)=sig(temp(i,j,k,1),saln(i,j,k,1))
         sigma(i,j,k+kdm,1)=sigma(i,j,k,1)
        endif
       enddo
       do k=3,kdm
        if (temp(i,j,k,1)<100000.) then
         temp(i,j,k,1)=max(-1.8,temp(i,j,k,1))
         saln(i,j,k,1)=sofsig(sigmar(i,j,k,1),temp(i,j,k,1))
         temp(i,j,k+kdm,1)=temp(i,j,k,1)
         saln(i,j,k+kdm,1)=saln(i,j,k,1)
         sigma(i,j,k,1)=sig(temp(i,j,k,1),saln(i,j,k,1))
         sigma(i,j,k+kdm,1)=sigma(i,j,k,1)
        endif
       enddo
     enddo
   enddo
   deallocate(sigmar)
   !Put  temperature
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'temp',vTMP_ID)
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vTMP_ID, ns, nc, temp)
   !Put  salinity
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'saln',vTMP_ID)
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vTMP_ID, ns, nc, saln)
   !Put  sigma
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'sigma',vTMP_ID)
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vTMP_ID, ns, nc, sigma)
   deallocate(temp,saln,sigma)

   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'pbu',vPBU_ID)
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'pbv',vPBV_ID)
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'pbu_p',vPBUP_ID)
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'pbv_p',vPBVP_ID)
   allocate(pbu (idm,jdm,2,1    ))
   allocate(pbv (idm,jdm,2,1    ))
   nc(3)=2
   call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vPBU_ID, ns, nc, pbu)
   call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vPBV_ID, ns, nc, pbv)
   ! Recalculate pbu pbv from pb
   do j=1,jdm
      do i=1,idm
!         if ( pbu(i,j,1,1) .ne. 0) then
         if ( umask(i,j) .eq. 1) then
            pbu(i,j,1,1)=min(pb(i,j,1,1),pb(inw(i,j),jnw(i,j),1,1))
            pbu(i,j,2,1)=pbu(i,j,1,1)
         endif
!         if ( pbv(i,j,1,1) .ne. 0) then
         if ( vmask(i,j) .eq. 1) then
            pbv(i,j,1,1)=min(pb(i,j,1,1),pb(ins(i,j),jns(i,j),1,1))
            pbv(i,j,2,1)=pbv(i,j,1,1)
         endif
      enddo
   enddo
!
   nc(3)=2
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vPBU_ID, ns, nc, pbu)
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vPBV_ID, ns, nc, pbv)
! Put first time level of pbu and pbv in pbu_p and pbv_p 
   allocate(ns3(3))
   allocate(nc3(3))
   ns3(1)=1
   ns3(2)=1
   ns3(3)=1
   nc3(1)=idm
   nc3(2)=jdm
   nc3(3)=1
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vPBUP_ID, ns3, nc3, pbu(:,:,1,1))
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vPBVP_ID, ns3, nc3, pbv(:,:,1,1))
   deallocate(pbu,pbv)
!Now filled up PBMN & PB_P
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'pb_p',vPBP_ID)
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vPBP_ID, ns3, nc3, pb(:,:,1,1))
   nc(3)=2
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'pb_mn',vPBMN_ID)
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vPBMN_ID, ns, nc, pb)
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vPBOT_ID, ns, nc, pb)
!Recalculate pvtrop
   allocate(pvtrop(idm,jdm,2,1))
   nc(3)=2
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'pvtrop',vTMP_ID)
   call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vTMP_ID, ns, nc, pvtrop)
   do j=1,jdm
     do i=1,idm
      if (umask(i,j) .eq. 1) then
       q=2./(pb(i,j,1,1)+pb(inw(i,j),jnw(i,j),1,1))
       pvtrop(i,j              ,1,1)=corioq(i       ,j       )*q
       pvtrop(inn(i,j),jnn(i,j),1,1)=corioq(inn(i,j),jnn(i,j))*q
       pvtrop(i,j              ,2,1)=pvtrop(i,j,1,1)
       pvtrop(inn(i,j),jnn(i,j),2,1)=pvtrop(inn(i,j),jnn(i,j),1,1)
      endif
     enddo
   enddo
   do j=1,jdm
     do i=1,idm
      if (vmask(i,j) .eq. 1) then
       q=2./(pb(i,j,1,1)+pb(ins(i,j),jns(i,j),1,1))
       pvtrop(i       ,j       ,1,1)=corioq(i       ,j       )*q
       pvtrop(ine(i,j),jne(i,j),1,1)=corioq(ine(i,j),jne(i,j))*q
       pvtrop(i       ,j       ,2,1)=pvtrop(i       ,j       ,1,1)
       pvtrop(ine(i,j),jne(i,j),2,1)=pvtrop(ine(i,j),jne(i,j),1,1)
      endif
     enddo
   enddo
   do j=1,jdm
     do i=1,idm
      if (qmask(i,j) .eq. 1) then
       pvtrop(i,j,1,1)=corioq(i,j)*4./(pb(i,j,1,1)+pb(inw(i,j),jnw(i,j),1,1 )+pb(ins(i,j),jns(i,j),1,1)+pb(insw(i,j),jnsw(i,j),1,1))
       pvtrop(i,j,2,1)=pvtrop(i,j,1,1)
      endif
     enddo
   enddo
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vTMP_ID, ns, nc,pvtrop)
   
   deallocate(pb,pvtrop)
   ! Now we should be finished with dp pbot 
   nc(3)=2*kdm
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vDP_ID, ns, nc, dp)
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'dpold',vDP_ID)
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vDP_ID, ns, nc, dp)
   deallocate(dp)
   !!!!! 2D variables
   nc(3)=2
   allocate(tmp (idm,jdm,2,1 ))
   !ub
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'ub',vTMP_ID)
   call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vTMP_ID, ns, nc, tmp)
   tmp(:,:,2,1)=tmp(:,:,1,1)
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vTMP_ID, ns, nc, tmp)
   !vb
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'vb',vTMP_ID)
   call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vTMP_ID, ns, nc, tmp)
   tmp(:,:,2,1)=tmp(:,:,1,1)
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vTMP_ID, ns, nc, tmp)
   call nfw_close(trim(oldfile)//'.nc', ncid)
end program

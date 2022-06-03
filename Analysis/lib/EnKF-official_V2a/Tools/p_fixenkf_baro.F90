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
   real, allocatable, dimension(:,:)     :: depths,modlon,modlat
   real, allocatable, dimension(:,:,:)     :: ficem,hicem
   real, allocatable, dimension(:,:,:,:)   :: dp, pb, pbu,pbv,tmp,saln,temp
   integer, allocatable, dimension(:,:)   :: jns,ins,jnn,inn,inw,jnw,ine,jne
   real, parameter  :: epsil=1.e-11

   integer,parameter :: numfields=2
   integer :: ios,ios2
   integer :: i,j,k
   real :: dpsum
   integer, allocatable :: ns(:), nc(:)
   integer, allocatable :: ns2(:), nc2(:),ns3(:), nc3(:)
   integer :: ncid, x_ID, y_ID, z_ID, vDP_ID, vPBOT_ID, vKFP_ID
   integer :: vPBMN_ID, vPBP_ID, vPBU_ID, vPBV_ID ,vPBUP_ID,vPBVP_ID,vTMP_ID
   integer :: vFICEM_ID, vHICEM_ID
   integer :: ncid2, jns_ID, ins_ID, inw_ID, jnw_ID,jnn_ID, inn_ID, ine_ID, jne_ID



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
     if (dp(i,j,1,1)<100000000000.) then
      dpsum=dp(i,j,1,1)
      do k = 1, kdm
         dpsum=dpsum+ dp(i,j,k,1) 
      end do
      do k = 1, kdm
         dp(i,j,k,1)=  dp(i,j,k,1)*pb(i,j,1)/dpsum
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
   allocate(ins(idm,jdm))
   allocate(jns(idm,jdm))
   allocate(inn(idm,jdm))
   allocate(jnn(idm,jdm))
   allocate(inw(idm,jdm))
   allocate(jnw(idm,jdm))
   allocate(ine(idm,jdm))
   allocate(jne(idm,jdm))
   call nfw_open('grid.nc', nf_write, ncid2)
!TODO DEPTHID not initialised depth not allocated
   call nfw_inq_varid('grid.nc', ncid2,'depths',DEPTH_ID)
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
   call nfw_get_vara_double('grid.nc', ncid2, DEPTH_ID, ns2, nc2, depths)
   !do j=0,jdm
   !  do k=1,kdm
   !    kn=k+nn
   !    do l=1,isp(j)
   !    do i=max(0,ifp(j,l)),min(ii+1,ilp(j,l))
   !      p(i,j,k+1)=p(i,j,k)+dp(i,j,kn)
   !    enddo
   !    enddo
   !  enddo
   !enddo



!TODO initialised sigma temmin

! correct temp and saln so that they respect freezing and min temp
! --- Let temmin be the freezing temperature of a given potential
! --- density. This can be achieved by using potential density given in
! --- the function sig and the salinity dependent freezing temperature
! --- given in the function swtfrz.
!
   call eosini
   gam=-.0547
   do k=2,kdm
     do j=1,jdm
       do i=1,idm
         a=((ap14-ap24*sigmar(i,j,k))*gam+ ap15-ap25*sigmar(i,j,k) )*gam+ap16-ap26*sigmar(i,j,k)
         b=(ap12-ap22*sigmar(i,j,k))*gam+ap13-ap23*sigmar(i,j,k)
         c=ap11-ap21*sigmar(i,j,k)
         salfrz=(-b+sqrt(b*b-4.*a*c))/(2.*a)
         temmin(i,j,k)=gam*salfrz
       enddo
       enddo
     enddo
   enddo
   ns(1)=1
   ns(2)=1
   ns(3)=1
   ns(4)=1
   nc(1)=idm
   nc(2)=jdm
   nc(3)=2*kdm
   nc(4)=1
   allocate(ns3(3))
   allocate(nc3(3))
   ns3(1)=1
   ns3(2)=1
   ns3(3)=1
   nc3(1)=idm
   nc3(2)=jdm
   nc3(3)=1
   deallocate(sigmar)
   allocate(temp   (idm,jdm,2*kdm,1))
   allocate(saln   (idm,jdm,2*kdm,1))
   allocate(sigma   (idm,jdm,2*kdm,1))

   do j=1,jdm
     do i=1,idm
       do k=1,2
        if (temp(i,j,k,1)<100000.) then
         temp(i,j,k)=max(-0.0547*saln(i,j,k),temp(i,j,k))  !swtfrz shortcuted
         temp(i,j,k+kdm)=temp(i,j,k)
         saln(i,j,k+kdm)=saln(i,j,k)
         sigma(i,j,k)=sig(temp(i,j,k),saln(i,j,k))
         sigma(i,j,k+kdm)=sigma(i,j,k)
        endif
       enddo
       do k=3,kk
        if (temp(i,j,k,1)<100000.) then
         temp(i,j,k)=max(temmin(i,j,k),temp(i,j,k))
         saln(i,j,k   )=sofsig(sigmar(i,j,k),temp(i,j,k))
         temp(i,j,k+kdm)=temp(i,j,k)
         saln(i,j,k+kdm)=saln(i,j,k)
         sigma(i,j,k)=sig(temp(i,j,k),saln(i,j,k))
         sigma(i,j,k+kdm)=sigma(i,j,k)
        endif
       enddo
     enddo
   enddo
   !Put  temperature
   temp(:,:,kdm+1:2*kdm,1)=temp(:,:,1:kdm,1)
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'temp',vTMP_ID)
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vTMP_ID, ns, nc, temp)
   !Put  salinity
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'saln',vTMP_ID)
   saln(:,:,kdm+1:2*kdm,1)=saln(:,:,1:kdm,1)
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
   call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vPBU_ID, ns, nc, pbu)
   call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vPBV_ID, ns, nc, pbv)
   ! Recalculate pbu pbv from pb
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
! Put first time level of pbu and pbv in pbu_p and pbv_p 
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
   
   
   call nfw_inq_varid('grid.nc', ncid2,'qlat',QLAT_ID)
   do j=1,jdm
     do i=1,idm
     enddo
   enddo

   do j=1,jdm
     do i=1,idm
          corioq=sin(qlat(i,j)/radian)*4.*pi/86164.
          pvtrop(i,j,1)=corioq*4./(pb(i,j,1,1)+pb_p(inw(i,j),inw(i,j))+pb_p(ins(i,j),ins(i,j))+pb_p(insw(i,j),insw(i,j)))
          pvtrop(i,j,2)=pvtrop(i,j,1)
     enddo
   enddo
   !pvtrop
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'pvtrop',vTMP_ID)
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vTMP_ID, ns, nc, pvtrop)
   deallocate(pb,pvtrop)
   ! Now we should be finished with dp pbot 
   nc(3)=2*kdm
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vDP_ID, ns, nc, dp)
   deallocate(dp)
   !!!!! 2D variables
   nc(3)=2
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
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   !ubflx
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'ubflx',vTMP_ID)
   call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vTMP_ID, ns, nc, tmp)
   tmp(:,:,2,1)=tmp(:,:,1,1)
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vTMP_ID, ns, nc, tmp)
   !vb
   call nfw_inq_varid(trim(oldfile)//'.nc', ncid,'vbflx',vTMP_ID)
   call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vTMP_ID, ns, nc, tmp)
   tmp(:,:,2,1)=tmp(:,:,1,1)
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vTMP_ID, ns, nc, tmp)
   call nfw_get_vara_double(trim(oldfile)//'.nc', ncid, vTMP_ID, ns, nc, tmp)
   tmp(:,:,2,1)=tmp(:,:,1,1)
   call nfw_put_vara_double(trim(oldfile)//'.nc', ncid, vTMP_ID, ns, nc, tmp)
   call nfw_close(trim(oldfile)//'.nc', ncid)
end program

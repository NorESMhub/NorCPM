! File:          p_prepare_ensemble.F90
!
! Created:       Francois counillon
!
! Last modified: 10/02/2014
!
! Purpose:       Fill the empty layer with value that are consistent with the
! ensemble and the vertical stratification of each ensemble member
!
! Description:  
!            This program compute the mean ensemble properties of the non empty layer
! if it is in agreeament with the water column, we keep it. Otherwise, we put
! the value of the mix-layerdepth.
!
! Modifications:
!
program prepare_ensemble
use netcdf
use mod_eosfun
use nfw_mod
   implicit none

   integer*4, external :: iargc
   real, parameter :: onem=9806.

   character(len=80) :: filename
   logical          :: ex
   character(len=8) :: ctmp
   integer          :: idm,jdm,kdm
   real, allocatable, dimension(:,:)     :: depths,modlon,modlat
   real, allocatable, dimension(:,:)   :: dp,saln,temp
   real, allocatable, dimension(:)   :: kfpla
   real,meanT,meanS,nbmem,dens_k,dens_m,dens
   integer :: i,j,k,nens,m
   integer :: ncid, x_ID, y_ID, z_ID 
   integer :: vPBMN_ID, vPBP_ID, vPBU_ID, vPBV_ID ,vPBUP_ID,vPBVP_ID,vTMP_ID
   integer :: vFICEM_ID, vHICEM_ID
   integer :: ncid2, jns_ID, ins_ID, inw_ID, jnw_ID,jnn_ID, inn_ID, ine_ID, jne_ID
   if (iargc()==1 ) then
      call getarg(1,ctmp)
      read(ctmp,*) nens
   else
      print *,'"prepare_ensemble" -- A Routine that fill up empty layer properties'
      print *
      print *,'usage: '
      print *,'   prepare_ensemble ensemble_size'
      call exit(1)
   endif
   call eosini

   filename='forecast001.nc'
   inquire(exist=ex,file=trim(filename))
   if (.not.ex) then
      write(*,*) 'Can not find ',filename
   end if
   ! Reading the restart file
   call nfw_open(trim(filename), nf_write, ncid)
   ! Get dimension id in netcdf file ...
   call nfw_inq_dimid(trim(filename), ncid, 'x', x_ID)
   call nfw_inq_dimid(trim(filename), ncid, 'y', y_ID)
   call nfw_inq_dimid(trim(filename), ncid, 'kk', z_ID)
   call nfw_inq_dimlen(trim(filename), ncid, x_ID, idm)
   call nfw_inq_dimlen(trim(filename), ncid, y_ID, jdm)
   call nfw_inq_dimlen(trim(filename), ncid, z_ID, kdm)
   print *, 'The model dimension is :',idm,jdm,kdm
   allocate(dp   (kdm,nens))
   allocate(temp (kdm,nens))
   allocate(saln (kdm,nens))
   allocate(dp   (kdm,nens))
   allocate(kfpla(nens))
   do j=1,jdm
      do i=1,idm
         !filling up the different matrix
         do m = 1, nens
           call read_water_column(m,i,j,idm,jdm,kdm,nens,temp,saln,dp,kfpla)
         end do
         do k = 3, kdm
            !compute the mean of the non-empty layer
            !TODO ? add U and V?
            nbmem=0.
            meanT=0.
            meanS=0.
            do m = 1, nens
               if (dp(k,m)>0) then
                  nbmem=nbmem+1.
                  meanT=meanT+temp(k,m);
                  meanS=meanS+saln(k,m);
               end if
            end do
            meanT=meanT/nbmem
            meanS=meanS/nbmem
            dens=sig(meanT,meanS)
            if (nbmem .ne. 0 .or. nbmem .ne. nens) then
            !At least 1 member is empty
               do m = 1, nens
                  if (dp(k,m)<=0) then
                     !density of the MLD
                     dens_m=sig(temp(2,m),saln(2,m))
                     !density of the first non-empty 
                     dens_k=sig(temp(kfpla(m),m),saln(kfpla(m),m))
                     if (k<kfpla(m) .and. (dens<dens_m .or. dens>dens_k)) then
                        temp(k,m)=temp(2,m)
                        saln(k,m)=saln(2,m)
                     else
                        temp(k,m)=meanT
                        saln(k,m)=meanS
                     endif
                  endif
               end do
            end if
         end do !k
         !TODO We should dump the water column
      end do !i
   end do !j
contains
  subroutine read_water_column(imem,ii,jj,nx,ny,nz,nens,t,s,dp,kfpla)
   implicit none
   !use netcdf
   integer, intent(in) ::  imem,ii,jj,nx,ny,nz,nens
   real, intent(inout), dimension(nens,kdm)   :: t,s,dp
   real, intent(inout), dimension(nens)   :: kfpla
   character(len=3) :: cmem
   integer, allocatable :: ns(:), nc(:)
   integer :: vDP_ID, vTEM_ID, vSAL_ID, vKFPL_ID 
   integer :: ncid
   allocate(ns(4))
   allocate(nc(4))

   ns(1)=ii
   ns(2)=jj
   ns(3)=1
   ns(4)=1
   nc(1)=ii
   nc(2)=jj
   nc(3)=kdm
   nc(4)=1
   write(cmem,'(i3.3)') imem
   call nfw_open (trim('forecast'//cmem//'.nc'), nf_write, ncid)
   !reading DP
   call nfw_inq_varid(trim('forecast'//cmem//'.nc'), ncid,'dp',vDP_ID)
   call nfw_get_vara_double(trim('forecast'//cmem//'.nc'), ncid, vDP_ID, ns, nc, dp)
   !reading TEMP
   call nfw_inq_varid(trim('forecast'//cmem//'.nc'), ncid,'temp',vTEM_ID)
   call nfw_get_vara_double(trim('forecast'//cmem//'.nc'), ncid, vTEM_ID, ns, nc, t)
   !reading SALN
   call nfw_inq_varid(trim('forecast'//cmem//'.nc'), ncid,'temp',vSAL_ID)
   call nfw_get_vara_double(trim('forecast'//cmem//'.nc'), ncid, vSAL_ID, ns, nc, s)
   ns(1)=ii
   ns(2)=jj
   ns(3)=1
   ns(4)=1
   nc(1)=ii
   nc(2)=jj
   nc(3)=1
   nc(4)=1
   !reading KFPLA
   call nfw_inq_varid(trim('forecast'//cmem//'.nc'), ncid,'kfpla',vKFPL_ID)
   call nfw_get_vara_double(trim('forecast'//cmem//'.nc'), ncid, vKFPL_ID, ns, nc,kfpla)
   call nfw_close(trim('forecast'//cmem//'.nc'), ncid)
   deallocate(ns,nc)
  end subroutine read_water_column




end program

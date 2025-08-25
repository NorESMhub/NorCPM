      module mod_oda
c
      use dimensions
      use mod_xc
      use mod_nctools
      use mod_dia 
      use mod_time
      use mod_state
c
      implicit none

      contains

      subroutine oda()
c
      implicit none
c
      logical :: ldooda,ldooda_daily,ldooda_monthly,lpause
      if (mod(nstep+nint(0.5*nstep_in_day),nstep_in_day).ne.0) return 
      inquire(file='../../ANALYSIS/BLOM_DA_DAILY',exist=ldooda_daily)
      inquire(file='../../ANALYSIS/BLOM_DA_MONTHLY',
     .  exist=ldooda_monthly)
      if (ldooda_daily) then
        ldooda = .true.
      else if (ldooda_monthly .and. date%day .eq. 15) then 
        ldooda = .true.
      else  
        ldooda = .false.
      end if
      if (ldooda) then 
        if (mnproc.eq.1) then
          write (lp,*) 'Perform ODA ', date%year, date%month, date%day
        endif
c
        call restart_wt_oda
c
        if (mnproc.eq.1) then
          write(lp,*)'ODA pause at ',rdate()
          open(unit=999,file='../../ANALYSIS/BLOM_PAUSE_'//member_tag()
     .      //'_'//rdate(),status='replace',action='write')
          write(999,'(A)') rdate() 
          close(999)
          lpause = .true.
          do while ( lpause )
            call sleepqq(100) !! for sleep 0.1 sec
            inquire(file='../../ANALYSIS/BLOM_PAUSE_'//member_tag()//'_'
     .        //rdate(),exist=lpause)
          end do
          write(lp,*)'ODA pause finished, continue run'
        end if         
        call restart_rd_oda
      else
          write (lp,*) 'Skip ODA ', date%year, date%month, date%day
      endif 
c
      end subroutine oda


      character(len=3) function member_tag()
c
      implicit none
c
      character(len=3), save :: member_tag_saved='UNS'
      character(len=512) :: rundir
c
      if (member_tag_saved.eq.'UNS') then 
        call getcwd(rundir)
        member_tag_saved=rundir(LEN_TRIM(rundir)-6:LEN_TRIM(rundir)-4) 
      end if 
      member_tag = member_tag_saved
c
      end function member_tag


      character(len=10) function rdate()
c
      implicit none
c
      write(rdate,'(i4.4,"-",i2.2,"-",i2.2)') 
     .  date%year,date%month,date%day
c
      end function rdate


      character(len=512) function rstfnm_oda() 
c
      implicit none
c
      rstfnm_oda = 
     .  "../../ANALYSIS/blom.rda."//member_tag()//"."//rdate()//".nc"
c
      end function rstfnm_oda


      subroutine restart_rd_oda 
c
c --- ------------------------------------------------------------------
c --- Read initial conditions from restart file
c --- ------------------------------------------------------------------
c
c
      implicit none
c
      character(len=512) :: rstfnm
      integer, dimension(1-nbdy:idm+nbdy,1-nbdy:jdm+nbdy) :: iuu,ivv
      integer i,j 
      logical first
      data first /.true./
      save first,iuu,ivv
c
c --- Compute extended uv masks 
      if (first) then
        first=.false.
c$OMP PARALLEL DO PRIVATE(i)
        do j=1,jj
          do i=1,ii
            if ((ip(i,j)+ip(i-1,j)).ge.1) then
              iuu(i,j)=1
            else
              iuu(i,j)=0
            endif
            if ((ip(i,j)+ip(i,j-1)).ge.1) then
              ivv(i,j)=1
            else
              ivv(i,j)=0
            endif
          enddo
        enddo
c$OMP END PARALLEL DO
      endif
c
c --- - open restart file
      rstfnm = rstfnm_oda()
      call ncfopn(rstfnm,'r',' ',1,iotype)
c
      if (mnproc.eq.1) then
        write (lp,'(2a)') ' restart_rd_oda: reading ODA restart file ',
     .                    trim(rstfnm)
      endif
c
      call ncread('u',u,iuu,1,0.)
      call ncread('v',v,ivv,1,0.)
      call ncread('dp',dp,ip,1,0.)
      call ncread('temp',temp,ip,1,0.)
      call ncread('saln',saln,ip,1,0.)
c
      call ncfcls
c
c --- delete file
      if (mnproc.eq.1) then 
        open(unit=999, file=rstfnm, status='old')
        close(999, status='delete')
      end if 
c
c --- copy data from time level 1 to level 2 
      u(:,:,kk+1:) = u(:,:,:kk)      
      v(:,:,kk+1:) = v(:,:,:kk)      
      dp(:,:,kk+1:) = dp(:,:,:kk)      
      temp(:,:,kk+1:) = temp(:,:,:kk)      
      saln(:,:,kk+1:) = saln(:,:,:kk)      
c
      return
      end subroutine restart_rd_oda 


      subroutine restart_wt_oda
c
c --- ------------------------------------------------------------------
c --- Write model state to restart files
c --- ------------------------------------------------------------------
c
      implicit none
c
      character(len=512) :: rstfnm
      integer, dimension(1-nbdy:idm+nbdy,1-nbdy:jdm+nbdy) :: iuu,ivv
      integer i,j 
      logical first
      data first /.true./
      save first,iuu,ivv
c
c --- Compute extended uv masks 
      if (first) then
        first=.false.
c$OMP PARALLEL DO PRIVATE(i)
        do j=1,jj
          do i=1,ii
            if ((ip(i,j)+ip(i-1,j)).ge.1) then
              iuu(i,j)=1
            else
              iuu(i,j)=0
            endif
            if ((ip(i,j)+ip(i,j-1)).ge.1) then
              ivv(i,j)=1
            else
              ivv(i,j)=0
            endif
          enddo
        enddo
c$OMP END PARALLEL DO
      endif
c
c --- average two time levels 
c
      u(:,:,:kk) = 0.5 * (u(:,:,1:kk)+u(:,:,kk+1:))     
      v(:,:,:kk) = 0.5 * (v(:,:,1:kk)+v(:,:,kk+1:))     
      dp(:,:,:kk) = 0.5 * (dp(:,:,1:kk)+dp(:,:,kk+1:))     
      temp(:,:,:kk) = 0.5 * (temp(:,:,1:kk)+temp(:,:,kk+1:))   
      saln(:,:,:kk) = 0.5 * (saln(:,:,1:kk)+saln(:,:,kk+1:))   
c
c --- open DA restart file
c
      rstfnm = rstfnm_oda()
c
      call ncfopn(rstfnm,'w','6',1,iotype)
      call ncputi('nday0',date0%day)
      call ncputi('nmonth0',date0%month)
      call ncputi('nyear0',date0%year)
      call ncputr('time0',time0)
      call ncputr('time',time)
c
c --- define spatial and time dimensions
      call ncdims('x',itdm)
      call ncdims('y',jtdm)
      call ncdims('kk',kk)
      call ncdims('time',1)
c
c --- output model fields to restart file
c
      call defvarrst('u','x y kk time')
      call defvarrst('v','x y kk time')
      call defvarrst('dp','x y kk time')
      call defvarrst('temp','x y kk time')
      call defvarrst('saln','x y kk time')
c
      call ncedef
c
      call wrtrst('u','x y kk time',u(:,:,:kk),iuu)
      call wrtrst('v','x y kk time',v(:,:,:kk),ivv)
      call wrtrst('dp','x y kk time',dp(:,:,:kk),ip)
      call wrtrst('temp','x y kk time',temp(:,:,:kk),ip)
      call wrtrst('saln','x y kk time',saln(:,:,:kk),ip)
c
      call ncfcls
c
      return
      end


      subroutine wrtrst(vnm,dims,fld,msk)
c
c --- ------------------------------------------------------------------
      use mod_xc
      use mod_nctools
c
      implicit none
c 
      character(len=*) :: vnm,dims
      real, dimension(*) :: fld
      integer, dimension(*) :: msk
c
c --- Write data in compressed or uncompressed format
      if (dims(2:5).eq.'comp') then 
        call nccomp(vnm,dims,fld,msk,1.,0.,8)
      else
        call ncwrtr(vnm,dims,fld,msk,1,1.,0.,8)
      endif
c
      end


      subroutine defvarrst(vnm,dims)
c
c --- ------------------------------------------------------------------
      use mod_nctools
c
      implicit none
c 
      character(len=*) :: vnm,dims

      call ncdefvar(vnm,dims,ndouble,8)
c
      end subroutine defvarrst

      end module mod_oda

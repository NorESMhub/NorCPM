#define DCPP_TAU
#define DCPP_MODE 'sam'
#define DCPP_PRODUCT 'step_function_DJFM_20yrs'
#define DCPP_YEAR1 1950
#define DCPP_YEARN 1969
#define DCPP_MULTIFILE 
      module mod_dcpp
c
      use dimensions
      use mod_xc
      use mod_dia
      use mod_nctools
      use mod_time
      use mod_state
      use mod_grid, only: cosang, sinang
      use mod_utility, only: util1, util2      
      use mod_types, only: r8
      use mod_seaice, only: ficem
      use mod_forcing, only : nsf, ztx, mty
#ifdef DCPP_HFX
     .  , dcpphfx, dcpphfx1, dcpphfx2, dcpphfx_weighted
#endif 
#ifdef DCPP_TAU
     .  , dcpptaux, dcpptaux1, dcpptaux2, dcpptaux_weighted 
     .  , dcpptauy, dcpptauy1, dcpptauy2, dcpptauy_weighted 
#endif 
c
      implicit none

      contains

      subroutine dcpp()
c
      implicit none
c
      character(len=512) :: fnm
      character(len=4) :: yyyy 
      integer, dimension(1-nbdy:idm+nbdy,1-nbdy:jdm+nbdy) :: iuu,ivv
      integer :: i,j,l
      real(r8) :: utmp, vtmp, dcpp_weight, w1, w2, dist 
      real(r8), parameter ::
     .   mval = -1.e12_r8,
     .   fval = -1.e13_r8
      real(r8), parameter :: w(12) = (/1,1,1,0,0,0,0,0,0,0,0,1/)
      integer, parameter :: daysInMonth(12) = 
     .                        (/31,28,31,30,31,30,31,31,30,31,30,31/)
      integer :: year1, year2, month1, month2
      real(r8) :: daysInMonthHalf1, daysInMonthHalf2, daysInMonthHalf12
      logical first
      data first /.true./
      save first,iuu,ivv
#ifdef MULTIFILE
      logical :: interp_30day=.false.
#else
      logical :: interp_30day=.false.
#endif
      integer, save :: year1_old=0, month1_old=0,
     .                 year2_old=0, month2_old=0  
c
c --- compute dcpp_weight
c
      if (interp_30day) then ! use 30-day approximation in temporal interpolation 
         if (date%year.lt.DCPP_YEAR1.or.date%year.ge.DCPP_YEARN) then
            if (date%year.eq.DCPP_YEAR1.and.date%month.eq.1.and.
     .          date%day.le.15) then
               dcpp_weight = 1. - (15.+date%day)/30.
            else
               dcpp_weight = 0.0_r8
            endif
         else
            if (date%year.eq.DCPP_YEAR1.and.date%month.eq.1.and.
     .          date%day.le.15) then
               dcpp_weight = (15.+date%day)/30.
            else
               if (date%day.le.15) then
                  dcpp_weight = w(mod(date%month+11,12))
     .                          *(1-(15.+date%day)/30.)
     .                         +w(date%month)*(15.+date%day)/30.
               else
                  dcpp_weight = w(date%month)
     .                          *(1-min(15.,date%day-15.)/30.)
     .                         +w(mod(date%month,12)+1)
     .                          *min(15.,date%day-15.)/30.
               endif
            end if
         endif
         if (mnproc.eq.1) then
            if (mod(nstep+nint(0.5*nstep_in_day),nstep_in_day).eq.0)
     .      write (lp,*) 'DCPP:', date%year,date%month,date%day,
     .         dcpp_weight
         endif
      else ! use actual length of month in temporal interpolation 
         if (date%day.le.daysInMonth(date%month)/2) then 
            month1 = mod(date%month+10,12)+1 
            month2 = date%month 
         else
            month1 = date%month 
            month2 = mod(date%month,12)+1 
         endif
         if (month2.eq.1.and.month2.ne.date%month) then
            year1 = date%year 
            year2 = year1 + 1 
         else if (month1.eq.12.and.month1.ne.date%month) then
            year2 = date%year 
            year1 = year2 - 1 
         else 
            year1 = date%year 
            year2 = year1
         endif 
         daysInMonthHalf1 = daysInMonth(month1)/2
         daysInMonthHalf2 = daysInMonth(month2)/2
         daysInMonthHalf12 = daysInMonthHalf1 + daysInMonthHalf2
         if (date%day.le.0.5+daysInMonth(date%month)/2) then 
            dist = 0.5 + daysInMonthHalf2 - date%day 
            w1 = dist / daysInMonthHalf12 
            w2 = 1 - w1  
         else
            dist = date%day - 0.5 - daysInMonthHalf1 
            w2 = dist / daysInMonthHalf12 
            w1 = 1 - w2
         endif 
#ifdef DCPP_MULTIFILE 
         dcpp_weight = 1. 
#else
         dcpp_weight = w1*w(month1) + w2*w(month2) 
#endif
         if (mnproc.eq.1.and.
     .       mod(nstep+nint(0.5*nstep_in_day),nstep_in_day).eq.0) then 
            write (lp,*) 'DCPP:', date%year,date%month,date%day
            write (lp,*) 'DCPP:', month1,month2,w1,w2,dcpp_weight,dist
         endif
      endif
c
c --- read DCPP weights 
c
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
#ifdef DCPP_MULTIFILE 
      if (year1.ne.year1_old.or.month1.ne.month1_old.or.
     .    year2.ne.year2_old.or.month2.ne.month2_old) then 
         year1_old = year1
         month1_old = month1 
         year2_old = year2
         month2_old = month2 
#ifdef DCPP_HFX
         write(yyyy,'(i4)') min(max(year1,DCPP_YEAR1),DCPP_YEARN)  
         fnm='/cluster/projects/nn9039k/people/'
     .     //'ingo/DCPP/DCPP-C_forcings/' 
     .     // DCPP_MODE // '/' // DCPP_PRODUCT // '/'  
     .     // DCPP_MODE //'_forcing_hfds_' // yyyy // '_tnx1v4.nc' 
         if (mnproc.eq.1) write (lp,*) 
     .      ' dcpp: reading DCPP hfx weights from ', trim(fnm)
     .     ,' for month ', month1
         call ncfopn(fnm,'r',' ',month1,iotype)
         call ncread('weights',dcpphfx1,ip,1,0.)
         call ncfcls
         call fill_global(mval, fval, halo_pv, dcpphfx1)
         call xctilr(dcpphfx1, 1,1, 1,1, halo_ps)                 

         write(yyyy,'(i4)') min(max(year2,DCPP_YEAR1),DCPP_YEARN) 
         fnm='/cluster/projects/nn9039k/people/'
     .     //'ingo/DCPP/DCPP-C_forcings/'
     .     // DCPP_MODE // '/' // DCPP_PRODUCT // '/'
     .     // DCPP_MODE //'_forcing_hfds_' // yyyy // '_tnx1v4.nc'
         if (mnproc.eq.1) write (lp,*) 
     .      ' dcpp: reading DCPP hfx weights from ', trim(fnm)
     .     ,' for month ', month2
         call ncfopn(fnm,'r',' ',month2,iotype)
         call ncread('weights',dcpphfx2,ip,1,0.)
         call ncfcls
         call fill_global(mval, fval, halo_pv, dcpphfx2)
         call xctilr(dcpphfx2, 1,1, 1,1, halo_ps)                 

#endif 
#ifdef DCPP_TAU
         write(yyyy,'(i4)')  min(max(year1,DCPP_YEAR1),DCPP_YEARN)
         fnm='/cluster/projects/nn9039k/people/'
     .     //'ingo/DCPP/DCPP-C_forcings/'
     .     // DCPP_MODE // '/' // DCPP_PRODUCT // '/'
     .     // DCPP_MODE //'_forcing_tauuo_' // yyyy // '_tnx1v4.nc'
         if (mnproc.eq.1) write (lp,*)
     .      ' dcpp: reading DCPP taux weights from ', trim(fnm)
     .     ,' for month ', month1
         call ncfopn(fnm,'r',' ',month1,iotype)
         call ncread('weights',util1,ip,1,0.)
         call ncfcls
         fnm='/cluster/projects/nn9039k/people/'
     .     //'ingo/DCPP/DCPP-C_forcings/'
     .     // DCPP_MODE // '/' // DCPP_PRODUCT // '/'
     .     // DCPP_MODE //'_forcing_tauvo_' // yyyy // '_tnx1v4.nc'
         if (mnproc.eq.1) write (lp,*)
     .      ' dcpp: reading DCPP tauy weights from ', trim(fnm)
     .     ,' for month ', month1
         call ncfopn(fnm,'r',' ',month1,iotype)
         call ncread('weights',util2,ip,1,0.)
         call ncfcls

        do j = 1, jj - 1 ! hardcoded for tripolar grid !!!
            do i = 1, ii
               if     (ip(i,j) == 0) then
                  util1(i,j) = mval
                  util2(i,j) = mval
               elseif (cplmsk(i,j) == 0) then
                  util1(i,j) = fval
                  util2(i,j) = fval
               else
                  utmp = util1(i,j)
                  vtmp = util2(i,j)
                  util1(i,j) =   utmp*cosang(i,j) + vtmp*sinang(i,j)
                  util2(i,j) = - utmp*sinang(i,j) + vtmp*cosang(i,j)
             endif
            enddo
         enddo
         call fill_global(mval, fval, halo_pv, util1)
         call fill_global(mval, fval, halo_pv, util2)
         call xctilr(util1, 1,1, 1,1, halo_pv)
         call xctilr(util2, 1,1, 1,1, halo_pv)
         do j=1,jj
            do l=1,isu(j)
            do i=max(1,ifu(j,l)),min(ii,ilu(j,l))
               ! x-component of momentum flux [kg/m/s^2]
               dcpptaux1(i,j) = .5_r8*(util1(i-1,j) + util1(i,j))
            enddo
            enddo
            do l=1,isv(j)
            do i=max(1,ifv(j,l)),min(ii,ilv(j,l))
               ! y-component of momentum flux [kg/m/s^2]
               dcpptauy1(i,j) = .5_r8*(util2(i,j-1) + util2(i,j))
            enddo
            enddo
         enddo

         write(yyyy,'(i4)') min(max(year2,DCPP_YEAR1),DCPP_YEARN)
         fnm='/cluster/projects/nn9039k/people/'
     .     //'ingo/DCPP/DCPP-C_forcings/'
     .     // DCPP_MODE // '/' // DCPP_PRODUCT // '/'
     .     // DCPP_MODE //'_forcing_tauuo_' // yyyy // '_tnx1v4.nc'
         if (mnproc.eq.1) write (lp,*)
     .      ' dcpp: reading DCPP taux weights from ', trim(fnm)
     .     ,' for month ', month2
         call ncfopn(fnm,'r',' ',month2,iotype)
         call ncread('weights',util1,ip,1,0.)
         call ncfcls
         fnm='/cluster/projects/nn9039k/people/'
     .     //'ingo/DCPP/DCPP-C_forcings/'
     .     // DCPP_MODE // '/' // DCPP_PRODUCT // '/'
     .     // DCPP_MODE //'_forcing_tauvo_' // yyyy // '_tnx1v4.nc'
         if (mnproc.eq.1) write (lp,*)
     .      ' dcpp: reading DCPP tauy weights from ', trim(fnm)
     .     ,' for month ', month2
         call ncfopn(fnm,'r',' ',month2,iotype)
         call ncread('weights',util2,ip,1,0.)
         call ncfcls
     
         do j = 1, jj - 1 ! hardcoded for tripolar grid !!!
            do i = 1, ii
               if     (ip(i,j) == 0) then
                  util1(i,j) = mval
                  util2(i,j) = mval
               elseif (cplmsk(i,j) == 0) then
                  util1(i,j) = fval
                  util2(i,j) = fval
               else
                  utmp = util1(i,j)
                  vtmp = util2(i,j)
                  util1(i,j) =   utmp*cosang(i,j) + vtmp*sinang(i,j)
                  util2(i,j) = - utmp*sinang(i,j) + vtmp*cosang(i,j)
             endif
            enddo
         enddo
         call fill_global(mval, fval, halo_pv, util1)
         call fill_global(mval, fval, halo_pv, util2)
         call xctilr(util1, 1,1, 1,1, halo_pv)
         call xctilr(util2, 1,1, 1,1, halo_pv)
         do j=1,jj
            do l=1,isu(j)
            do i=max(1,ifu(j,l)),min(ii,ilu(j,l))
               ! x-component of momentum flux [kg/m/s^2]
               dcpptaux2(i,j) = .5_r8*(util1(i-1,j) + util1(i,j))
            enddo
            enddo
            do l=1,isv(j)
            do i=max(1,ifv(j,l)),min(ii,ilv(j,l))
               ! y-component of momentum flux [kg/m/s^2]
               dcpptauy2(i,j) = .5_r8*(util2(i,j-1) + util2(i,j))
            enddo
            enddo
         enddo
#endif 
      end if 
#else      
      if (first) then
#ifdef DCPP_HFX
         fnm='/cluster/projects/nn9039k/people/'
     .     //'ingo/DCPP/DCPP-C_forcings/' 
     .     // DCPP_MODE //'_forcing_hfds_tnx1v4.nc' 
         if (mnproc.eq.1) write (lp,'(2a)') 
     .      ' dcpp: reading DCPP hfx weights from ', trim(fnm)
         call ncfopn(fnm,'r',' ',1,iotype)
         call ncread('weights',dcpphfx,ip,1,0.)
         call ncfcls
         call fill_global(mval, fval, halo_pv, dcpphfx)
         call xctilr(dcpphfx, 1,1, 1,1, halo_ps)
#endif 
#ifdef DCPP_TAU
         fnm='/cluster/projects/nn9039k/people/'
     .     //'ingo/DCPP/DCPP-C_forcings/'
     .     //DCPP_MODE//'_forcing_tauuo_tnx1v4.nc' 
         if (mnproc.eq.1) write (lp,'(2a)') 
     .      ' dcpp: reading DCPP taux weights from ', trim(fnm)
         call ncfopn(fnm,'r',' ',1,iotype)
         call ncread('weights',util1,ip,1,0.)
         call ncfcls
         fnm='/cluster/projects/nn9039k/people/'
     .     //'ingo/DCPP/DCPP-C_forcings/'
     .     //DCPP_MODE//'_forcing_tauvo_tnx1v4.nc'
         if (mnproc.eq.1) write (lp,'(2a)') 
     .      ' dcpp: reading DCPP tauy weights from ', trim(fnm)
         endif
         call ncfopn(fnm,'r',' ',1,iotype)
         call ncread('weights',util2,ip,1,0.)
         call ncfcls
         do j = 1, jj - 1 ! hardcoded for tripolar grid !!!
            do i = 1, ii
               if     (ip(i,j) == 0) then
                  util1(i,j) = mval
                  util2(i,j) = mval
               elseif (cplmsk(i,j) == 0) then
                  util1(i,j) = fval
                  util2(i,j) = fval
               else
                  utmp = util1(i,j)
                  vtmp = util2(i,j)
                  util1(i,j) =   utmp*cosang(i,j) + vtmp*sinang(i,j)
                  util2(i,j) = - utmp*sinang(i,j) + vtmp*cosang(i,j)
               endif
            enddo
         enddo
         call fill_global(mval, fval, halo_pv, util1)
         call fill_global(mval, fval, halo_pv, util2)      
         call xctilr(util1, 1,1, 1,1, halo_pv)
         call xctilr(util2, 1,1, 1,1, halo_pv)
         do j=1,jj
            do l=1,isu(j)
            do i=max(1,ifu(j,l)),min(ii,ilu(j,l))
               ! x-component of momentum flux [kg/m/s^2]
               dcpptaux(i,j) = .5_r8*(util1(i-1,j) + util1(i,j))
            enddo
            enddo
            do l=1,isv(j)
            do i=max(1,ifv(j,l)),min(ii,ilv(j,l))
               ! y-component of momentum flux [kg/m/s^2]
               dcpptauy(i,j) = .5_r8*(util2(i,j-1) + util2(i,j))
            enddo
            enddo
         enddo
#endif 
      endif 
#endif 
c
c --- apply DCPP weights     
c
#ifdef DCPP_HFX
#ifdef DCPP_MULTIFILE
      dcpphfx = w1*dcpphfx1 + w2*dcpphfx2 
#endif 
      dcpphfx_weighted = (1.-ficem)*dcpphfx*dcpp_weight 
      nsf = nsf + dcpphfx_weighted
#endif 
#ifdef DCPP_TAU
#ifdef DCPP_MULTIFILE
      dcpptaux = w1*dcpptaux1 + w2*dcpptaux2 
      dcpptauy = w1*dcpptauy1 + w2*dcpptauy2 
#endif 
      util1 = ficem
      call xctilr(util1, 1,1, 1,1, halo_pv)
      do j=1,jj
         do l=1,isu(j)
         do i=max(1,ifu(j,l)),min(ii,ilu(j,l))
            dcpptaux_weighted(i,j) = dcpptaux(i,j) * dcpp_weight 
     .        * (1 - .5_r8*(util1(i-1,j) + util1(i,j))) 
         enddo
         enddo
         do l=1,isv(j)
         do i=max(1,ifv(j,l)),min(ii,ilv(j,l))
            dcpptauy_weighted(i,j) = dcpptauy(i,j) * dcpp_weight 
     .        * (1 - .5_r8*(util1(i,j-1) + util1(i,j)))
         enddo
         enddo
      enddo
      ztx = ztx + dcpptaux_weighted
      mty = mty + dcpptauy_weighted
#endif 
c
      end subroutine dcpp

      end module mod_dcpp

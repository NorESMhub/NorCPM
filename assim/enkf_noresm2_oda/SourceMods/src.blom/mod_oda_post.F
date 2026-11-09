      module mod_oda_post
c
c --- ------------------------------------------------------------------
c --- Post-processing the blom model state after data assimilation 
c --- ------------------------------------------------------------------
c
c      use mod_config, only: expcnf
c      use mod_time, only: date, nday1, nday2, nstep1, nstep2, nstep,
c     .                    delt1
c      use mod_timing, only: init_timing, get_time
      use mod_xc
c      use mod_pointtest, only: init_ptest
c      use mod_inicon, only: icfile
      use mod_constants, only: epsilp
      use mod_grid, only: corioq
      use mod_state, only: temp, saln, sigma, dp, dpu, dpv, uflx, vflx, p, pu, pv, phi, 
     .                     pb, pb_p, pbu, pbv, pbu_p, pbv_p, kfpla
      use mod_barotp, only: pvtrop, pb_mn
      use mod_pgforc, only: pgfx, pgfy, pgfxm, pgfym, xixp, xixm, xiyp, xiym, pgforc
c      use mod_niw, only: uml, vml, umlres, vmlres
      use mod_eos, only: sig
c      use mod_swabs, only: iniswa
c      use mod_ndiff, only: ndiff_init
      use mod_tmsmt, only: dpold
c      use mod_dia
c      use mod_inicon, only: inicon
c      use mod_budget, only: budget_init
c      use mod_cmnfld_routines, only: cmnfld1
c      use netcdf
#if defined(TRC) && defined(TKE)
      use mod_tke, only: initke
#endif
c
      implicit none
c
      contains
c
      subroutine blom_init_oda
c
      implicit none
c
      integer istat,ncid,varid,i,j,k,l,m,n,mm,nn,k1m,k1n,mt,mmt,kn,km
      real q,dpsum,dps
      logical icrest,fexist


      if (mnproc.eq.1) then
        write (lp,*) ' blom_init_oda Initializing BLOM after ODA'
      endif
c
c
c --- ------------------------------------------------------------------
c --- Initialize layer thicknesses 
c --- ------------------------------------------------------------------
c
      call xctilr(dp, 1,kk, 1,1, halo_ps)
c      call xctilr(pb, 1,2, nbdy,nbdy, halo_ps)
      do j=1,jj
        do l=1,isp(j)
        do i=max(1,ifp(j,l)),min(ii,ilp(j,l))
            dpsum=0.
c           When not updating the full water colum, sum(DP)!=PB
            do k=1,kk
              dpsum=dpsum+dp(i,j,k) 
            enddo
            pb(i,j,1)=dpsum
c            do k=1,kk
c              dp(i,j,k)=dp(i,j,k)*pb(i,j,1)/dpsum
c            enddo
c           if less that 20 m we split half-half
c           Otherwise 1st=10m second the rest
c           Cannot have MLD < 5m take from ater below
            dpsum=dp(i,j,1)+dp(i,j,2)
            if (dpsum .le. 20.*98060.) then
              if (dpsum.le.(5.*98060.)) then
                dp(i,j,1)=2.5*98060.
                dp(i,j,2)=2.5*98060.
                dp(i,j,3) = dp(i,j,3) + (dpsum-(5.*98060.))
                dpsum=5.*98060.
              else
                dp(i,j,1)=dpsum/2.
                dp(i,j,2)=dpsum/2.
              endif
            else
              dp(i,j,1)=10.*98060.
              dp(i,j,2)=dpsum-10.*98060.
            end if
            do k=3,kk-1
              dp(i,j,k+1)=dp(i,j,k+1)+min(0.0,dp(i,j,k))
              dp(i,j,k)=max(dp(i,j,k),0.0)
            end do
c           !!! Go backwards to fix lowermost layer.
            do k=kk,2,-1
              dp(i,j,k-1)=dp(i,j,k-1)+min(0.0,dp(i,j,k))
              dp(i,j,k)= max(dp(i,j,k),0.0)
            end do
            do k=1,kk
              dp(i,j,k+kk)= dp(i,j,k)
            enddo
            pb(i,j,2)=pb(i,j,1)
        enddo
        enddo
      enddo
c
c     call xctilr(temp, 1,kk, 1,1, halo_ps)
c     call xctilr(saln, 1,kk, 1,1, halo_ps)
c     call xctilr(sigma, 1,kk, 1,1, halo_ps)
      do j=1,jj
        do l=1,isp(j)
        do i=max(1,ifp(j,l)),min(ii,ilp(j,l))
          do k=1,2
            sigma(i,j,k)=sig(temp(i,j,k),saln(i,j,k))
            sigma(i,j,k+kk)=sigma(i,j,k)
          enddo
          do k=3,kk
            sigma(i,j,k)=sig(temp(i,j,k),saln(i,j,k))
            sigma(i,j,k+kk)=sigma(i,j,k)
          enddo
c          ustar(i,j)=0.
c          buoyfl(i,j)=0.
        enddo
        enddo
      enddo
c
c$OMP PARALLEL DO PRIVATE(k,l,i)
      do j=0,jj+1
        do k=1,kk
          do l=1,isp(j)
          do i=max(0,ifp(j,l)),min(ii+1,ilp(j,l))
            p(i,j,k+1)=p(i,j,k)+dp(i,j,k)
          enddo
          enddo
        enddo
      enddo

c      do j=1,jj
c        do l=1,isp(j)
c        do i=max(1,ifp(j,l)),min(ii,ilp(j,l))
c          phi(i,j,kk+1)=-g*depths(i,j)*1.e2
c        enddo
c        enddo
c      enddo
c$OMP END PARALLEL DO

c      call xctilr(dp, 1,kk, 1,1, halo_ps)
      call xctilr(p, 1,kk+1, 2,2, halo_ps)
c      call xctilr(phi(1-nbdy,1-nbdy,kk+1), 1,1, 1,1, halo_ps)
      call xctilr(pb, 1,2, nbdy,nbdy, halo_ps)
c
c --- ------------------------------------------------------------------
c --- set layer thickness and bottom pressure
c --- ------------------------------------------------------------------
c
c$OMP PARALLEL DO PRIVATE(l,i)
      do j=0,jj+1
        do l=1,isp(j)
        do i=max(0,ifp(j,l)),min(ii+1,ilp(j,l))
          pb_mn(i,j,1)=pb(i,j,1)
          pb_mn(i,j,2)=pb(i,j,1)
          pb_p(i,j)=pb(i,j,1)
        enddo
        enddo
      enddo
c$OMP END PARALLEL DO
c
c$OMP PARALLEL DO PRIVATE(l,i)
      do  j=1,jj
        do l=1,isu(j)
        do i=max(1,ifu(j,l)),min(ii,ilu(j,l))
          pbu(i,j,1)=min(pb(i,j,1),pb(i-1,j,1))
          pbu(i,j,2)=pbu(i,j,1)
          pbu_p(i,j)=pbu(i,j,1)
        enddo
        enddo
        do l=1,isv(j)
        do i=max(1,ifv(j,l)),min(ii,ilv(j,l))
          pbv(i,j,1)=min(pb(i,j,1),pb(i,j-1,1))
          pbv(i,j,2)=pbv(i,j,1)
          pbv_p(i,j)=pbv(i,j,1)
        enddo
        enddo
      enddo
c$OMP END PARALLEL DO
c
c$OMP PARALLEL DO PRIVATE(k,l,i,q)
      do j=-1,jj+2
        do k=1,kk
          do l=1,isu(j)
          do i=max(-1,ifu(j,l)),min(ii+2,ilu(j,l))
            q=min(p(i,j,kk+1),p(i-1,j,kk+1))
            dpu(i,j,k)=
     .        max(0.,min(q,.5*(p(i,j,k+1)+p(i-1,j,k+1))) 
     .              -min(q,.5*(p(i,j,k  )+p(i-1,j,k  ))))
          enddo
          enddo
          do l=1,isv(j)
          do i=max(-1,ifv(j,l)),min(ii+2,ilv(j,l))
            q=min(p(i,j,kk+1),p(i,j-1,kk+1))
            dpv(i,j,k)=
     .        max(0.,min(q,.5*(p(i,j,k+1)+p(i,j-1,k+1)))
     .              -min(q,.5*(p(i,j,k  )+p(i,j-1,k  ))))
          enddo
          enddo
        enddo
      enddo
c$OMP END PARALLEL DO
c
c$OMP PARALLEL DO PRIVATE(k,l,i)
      do j=1,jj
        do k=1,kk
          do l=1,isu(j)
          do i=max(1,ifu(j,l)),min(ii,ilu(j,l))
            dpu(i,j,k+kk)=dpu(i,j,k)
            pu(i,j,k+1)=pu(i,j,k)+dpu(i,j,k)
          enddo
          enddo
          do l=1,isv(j)
          do i=max(1,ifv(j,l)),min(ii,ilv(j,l))
            dpv(i,j,k+kk)=dpv(i,j,k)
            pv(i,j,k+1)=pv(i,j,k)+dpv(i,j,k)
          enddo
          enddo
        enddo
      enddo
c$OMP END PARALLEL DO
c
c --- ------------------------------------------------------------------
c --- initialize potential vorticity of barotropic flow
c --- ------------------------------------------------------------------
c
      call xctilr(pvtrop, 1,2, 1,3, halo_qs)
      call xctilr(corioq, 1,1, nbdy,nbdy, halo_qs)
c$OMP PARALLEL DO PRIVATE(l,i,q)
      do j=0,jj
        do l=1,isu(j)
        do i=max(1,ifu(j,l)),min(ii,ilu(j,l))
          q=2./(pb_p(i,j)+pb_p(i-1,j))
          pvtrop(i,j  ,1)=corioq(i,j  )*q
          pvtrop(i,j+1,1)=corioq(i,j+1)*q
          pvtrop(i,j  ,2)=pvtrop(i,j  ,1)
          pvtrop(i,j+1,2)=pvtrop(i,j+1,1)
        enddo
        enddo
      enddo
c$OMP END PARALLEL DO
c$OMP PARALLEL DO PRIVATE(l,i,q)
      do j=1,jj
        do l=1,isv(j)
        do i=max(0,ifv(j,l)),min(ii,ilv(j,l))
          q=2./(pb_p(i,j)+pb_p(i,j-1))
          pvtrop(i  ,j,1)=corioq(i  ,j)*q
          pvtrop(i+1,j,1)=corioq(i+1,j)*q
          pvtrop(i  ,j,2)=pvtrop(i  ,j,1)
          pvtrop(i+1,j,2)=pvtrop(i+1,j,1)
        enddo
        enddo
      enddo
c$OMP END PARALLEL DO
c
c$OMP PARALLEL DO
      do j=1,jj
        do l=1,isq(j)
        do i=max(1,ifq(j,l)),min(ii,ilq(j,l))
          pvtrop(i,j,1)=corioq(i,j)*4./(pb_p(i,j  )+pb_p(i-1,j  )
     .                                 +pb_p(i,j-1)+pb_p(i-1,j-1))
          pvtrop(i,j,2)=pvtrop(i,j,1)
        enddo
        enddo
      enddo
c$OMP END PARALLEL DO
c
c --- ------------------------------------------------------------------
c --- Initialize fields related to the pressure gradient force
c --- ------------------------------------------------------------------
c
      call pgforc(2,1,kk,0,kk+1,1)
c
c$OMP PARALLEL DO PRIVATE(k,l,i)
      do j=1,jj
        do k=1,kk
          do l=1,isu(j)
          do i=max(1,ifu(j,l)),min(ii,ilu(j,l))
            pgfx(i,j,k+kk)=pgfx(i,j,k)
          enddo
          enddo
          do l=1,isv(j)
          do i=max(1,ifv(j,l)),min(ii,ilv(j,l))
            pgfy(i,j,k+kk)=pgfy(i,j,k)
          enddo
          enddo
        enddo
        do l=1,isu(j)
        do i=max(1,ifu(j,l)),min(ii,ilu(j,l))
          pgfxm(i,j,2)=pgfxm(i,j,1)
          xixp(i,j,2)=xixp(i,j,1)
          xixm(i,j,2)=xixm(i,j,1)
        enddo
        enddo
        do l=1,isv(j)
        do i=max(1,ifv(j,l)),min(ii,ilv(j,l))
          pgfym(i,j,2)=pgfym(i,j,1)
          xiyp(i,j,2)=xiyp(i,j,1)
          xiym(i,j,2)=xiym(i,j,1)
        enddo
        enddo
      enddo
c$OMP END PARALLEL DO
c
c --- ------------------------------------------------------------------
c --- Define first physical interior layer
c --- ------------------------------------------------------------------
c
c$OMP PARALLEL DO PRIVATE(l,i,k,dps)
      do j=1,jj
        do l=1,isp(j)
        do i=max(1,ifp(j,l)),min(ii,ilp(j,l))
          k=3
          dps=0.
          do while (dp(i,j,k).lt.epsilp)
            dps=dps+dp(i,j,k)
            dp(i,j,k)=0.
            dp(i,j,k+kk)=0.
            k=k+1
            if (k.gt.kk) exit
          enddo
          if (k.gt.kk) then
            dp(i,j,2)=dp(i,j,2)+dps
            dp(i,j,2+kk)=dp(i,j,2)
          else
            dp(i,j,k)=dp(i,j,k)+dps
            dp(i,j,k+kk)=dp(i,j,k)
          endif
          kfpla(i,j,1)=k
          kfpla(i,j,2)=k
        enddo
        enddo
      enddo
c$OMP END PARALLEL DO
c
c --- ------------------------------------------------------------------
c --- Set other time level layer thicknesses
c --- ------------------------------------------------------------------
c
c$OMP PARALLEL DO PRIVATE(k,l,i)
      do j=1,jj
        do k=1,kk
          do l=1,isp(j)
          do i=max(1,ifp(j,l)),min(ii,ilp(j,l))
            dp(i,j,k+kk)=dp(i,j,k)
            dpold(i,j,k)=dp(i,j,k)
            dpold(i,j,k+kk)=dp(i,j,k)
          enddo
          enddo
        enddo
      enddo
c$OMP END PARALLEL DO
c
      if (mnproc.eq.1) then
        write (lp,*) ' blom_init_oda: Ending initialisation after ODA'
      endif
      end subroutine blom_init_oda
c
      end module mod_oda_post

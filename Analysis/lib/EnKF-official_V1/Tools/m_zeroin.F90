module m_zeroin
use mod_spice
contains
subroutine zeroin(zeropkt,expect,delta,tol,temp,sp)

! A zero of the function  $sp-spice(t,s)$
! We know t and spicenes, we want to find s
! The solution will be accepted within $[ax,bx]$.

! This function subprogram is a slightly  modified  translation  of
! the algol 60 procedure  zero  given in  richard brent, algorithms for
! minimization without derivatives, prentice - hall, inc. (1973).


   real zeropkt,temp,sp
   real expect   ! left endpoint of initial interval
   real delta   ! right endpoint of initial interval
   real ax,bx   ! right endpoint of initial interval
   real tol  !  desired length of the interval of uncertainty of the
   real  a,b,c,d,e,eps,fa,fb,fc,tol1,xm,p,q,r,s
   real  abs,sign,fval

!  compute eps, the relative machine precision

   icorr=0

   eps = 1.0
 10 eps = eps/2.0
   tol1 = 1.0 + eps
   if (tol1 .gt. 1.0) go to 10


! initialization
 77 a = expect-delta
   b = expect+delta
   fa = sp-spice(temp,a)
!   write(*,*)'a,b',a,b
   fb = sp-spice(temp,b)
!   write(*,*)'a,b',a,b
  !write(*,*)'a,b',a,b,temp,sp,fa,fb


   if (fa*fb.gt.0.0) then
#ifdef DEBUG
      write(*,*)'fa=',fa
      write(*,*)'fb=',fb
      write(*,*)'fa*fb =',fa*fb,'is greater than zero'
#endif
      delta=delta/2.
      icorr=icorr+1
      if (icorr < 20) then
         goto 77
      else
         write(*,'(2(a,g13.5))')'zeroin: No convergence, expect=',expect,' delta=',delta
         stop
      endif
   endif

! begin step

 20 c = a
   fc = fa
   d = b - a
   e = d
!   write(*,*)'a,b,c, fa fb fc',a,b,c,fa,fb,fc
!   write(*,*)'test',abs(fc), abs(fb)
!   stop
 30 if (abs(fc) .ge. abs(fb)) go to 40
   a = b
   b = c
   c = a
   fa = fb
   fb = fc
   fc = fa

! convergence test

 40 tol1 = 2.0*eps*abs(b) + 0.5*tol
   xm = .5*(c - b)
!   write(*,*)'xm',xm
   if (abs(xm) .le. tol1) go to 90
   if (fb .eq. 0.0) go to 90

! is bisection necessary

   if (abs(e) .lt. tol1) go to 70
   if (abs(fa) .le. abs(fb)) go to 70

! is quadratic interpolation possible

   if (a .ne. c) go to 50

! linear interpolation

   s = fb/fa
   p = 2.0*xm*s
   q = 1.0 - s
   go to 60

! inverse quadratic interpolation

 50 q = fa/fc
   r = fb/fc
   s = fb/fa
   p = s*(2.0*xm*q*(q - r) - (b - a)*(r - 1.0))
   q = (q - 1.0)*(r - 1.0)*(s - 1.0)

! adjust signs

 60 if (p .gt. 0.0) q = -q
   p = abs(p)

! is interpolation acceptable

   if ((2.0*p) .ge. (3.0*xm*q - abs(tol1*q))) go to 70
   if (p .ge. abs(0.5*e*q)) go to 70
   e = d
   d = p/q
!   write(*,*)'e,d',e,d
   go to 80

! bisection

 70 d = xm
   e = d

! complete step

 80 a = b
   fa = fb
   if (abs(d) .gt. tol1) b = b + d
   if (abs(d) .le. tol1) b = b + sign(tol1, xm)
   fb = sp-spice(temp,b)
!   write(*,*)'e,d,fb',b,d,fb
   if ((fb*(fc/abs(fc))) .gt. 0.0) go to 20
   go to 30

! done

 90 zeropkt = b
   fval=sp-spice(temp,b)
end subroutine zeroin
end module m_zeroin

      module dimensions
c
c --- itdm  = total grid dimension in i direction
c --- jtdm  = total grid dimension in j direction
c --- kdm   =       grid dimension in k direction
      integer    itdm,jtdm,kdm
      parameter (itdm=360,jtdm=385,kdm=53)
c
c --- ijqr  = total number of active tiles
c --- iqr   = maximum number of tiles in i direction
c --- jqr   = maximum number of tiles in j direction
c --- idm   = maximum single tile grid dimension in i direction
c --- jdm   = maximum single tile grid dimension in j direction
      integer    ijqr,iqr,jqr,idm,jdm
      parameter (ijqr=63,iqr=8,jqr=8,idm=45,jdm=49)
c
c --- region type (nreg=-1: unknown,
c ---              nreg= 0:   closed/closed,
c ---              nreg= 1: periodic/closed,
c ---              nreg= 2: periodic/arctic,
c ---              nreg= 3: periodic/periodic
c ---              nreg= 4:   closed/periodic)
      integer    nreg
      data nreg /2/
c
c --- i0_pe = 1st dimension tile offsets
c --- ii_pe = 1st dimension tile extents
c --- j0_pe = 2nd dimension tile offsets
c --- jj_pe = 2nd dimension tile extents
      integer, dimension(iqr,jqr) :: i0_pe,ii_pe,j0_pe,jj_pe
      data i0_pe/
     .  0,45,90,135,180,225,270,315,0,45,90,135,180,225,270,315,0,45,90,
     .  135,180,225,270,315,0,59,90,148,180,225,270,315,0,45,90,149,180,
     .  225,270,315,0,45,90,135,180,225,270,315,15,45,90,135,-1,246,270,
     .  315,0,45,90,135,180,225,270,315/
      data ii_pe/
     .  45,45,45,45,45,45,45,45,45,45,45,45,45,45,45,45,45,45,45,45,45,
     .  45,45,45,34,31,35,32,45,45,45,45,45,45,31,31,45,45,45,45,45,45,
     .  45,45,45,45,45,45,30,45,45,14,0,24,45,32,45,45,45,45,45,45,45,
     .  45/
      data j0_pe/
     .  0,0,0,0,0,0,0,0,48,48,48,48,48,48,48,48,96,96,96,96,96,96,96,96,
     .  144,144,144,144,144,144,144,144,193,193,193,193,193,193,193,193,
     .  241,241,241,241,241,241,241,241,289,289,289,289,289,289,289,289,
     .  337,337,337,337,337,337,337,337/
      data jj_pe/
     .  48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,
     .  48,48,48,49,49,49,49,49,49,49,49,48,48,48,48,48,48,48,48,48,48,
     .  48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,
     .  48/
c
      end module dimensions

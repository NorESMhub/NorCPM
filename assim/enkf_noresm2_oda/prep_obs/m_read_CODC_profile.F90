! File:          m_read_CODC_profile.F90
!
! Created:       28 January 2026
!
! Author:        Yiguo WANG (YW)
!                NERSC
!
! Purpose:       Read profile data from NetCDF files from CODC into NorCPM
!                system.
!
! Description:   Data file(s) are defined by the string in the 4th line of
!                "infile.data". It should have the following format:
!                <BEGIN>
!                CODC
!                SAL | TEM 
!                <obs. error variance>
!                <File name(s) or a wildcard>
!                <END>
!                After that:
!                1. all profiles are read into two arrays,
!                   deph(1 : nlev, 1 : nprof) and v(1 : nlev, 1 : nprof), where
!                   nprof is the total number of profiles in all files, and
!                   nlev is the maximum number of horizontal levels for all
!                   profiles;
!                2. bad data with qc flags other than '1' is discarded;
!                3. dry or outside locations are discarded
!                4. if there close profiles (in the same grid cell), the best
!                   one (with most data or the most recent) is retained
!
!

module m_read_CODC_profile
  implicit none

  integer, parameter, private :: STRLEN = 512
  integer, parameter, private :: kdm = 119
  integer, parameter, private :: kdm1 = 42

#ifdef ANOMALY
  ! anomaly
  real, parameter, private :: TEM_MIN = -6.0
  real, parameter, private :: TEM_MAX = 6.0
  real, parameter, private :: SAL_MIN = -3.0
  real, parameter, private :: SAL_MAX = 3.0
#else
  ! full field
  real, parameter, private :: TEM_MIN = -2.5
  real, parameter, private :: TEM_MAX = 35.0
  real, parameter, private :: SAL_MIN = 1.0
  real, parameter, private :: SAL_MAX = 50.0
#endif

  public read_CODC_profile

  private data_inquire
  private data_readfile
  private potential_density
  private get_pivot
  private data_variance
  private data_obsunc

  contains

  subroutine read_CODC_profile(fnames, obstype, variance, nx, ny, data, nrobs)
    use mod_measurement
    use m_oldtonew
    use m_confmap
    use m_bilincoeff
    use m_pivotp
    use nfw_mod
    use ieee_arithmetic
    use m_get_micom_fld

    character(*), intent(in) :: fnames
    character(*), intent(in) :: obstype
    real(8), intent(in) :: variance
    integer, intent(in) :: nx, ny
    integer, intent(out) :: nrobs
    type(measurement), allocatable, intent(out) :: data(:)

    character(STRLEN) :: fname
    integer :: nfile, nprof, nlev

    real(8), allocatable :: juld(:)
    real(8), allocatable :: lat(:), lon(:)
    real(8), allocatable :: depth_temp(:, :), depth_saln(:, :)
    real(8), allocatable :: temp(:,:), saln(:, :)
    real(8), allocatable :: obs(:,:), depth_obs(:, :) 

    integer, allocatable :: ipiv(:), jpiv(:)

    real(8), dimension(nx, ny) :: modlat, modlon
    real(8), dimension(nx, ny) :: depths, mxd1, mxd2, fice

    real(8), dimension(nx, ny, kdm1) :: obs_unc
    real(8), dimension(2, kdm1) :: d3z 

    real(8), dimension(360, 180, kdm) :: obs_mean
    real(8), dimension(360) :: dlon
    real(8), dimension(180) :: dlat
    real(8), dimension(kdm) :: ddepth
    real(8), allocatable, dimension(:) :: splinex, spliney, splined
    real(8), allocatable, dimension(:) :: splinexe, splineye
    integer :: lon_int, lat_int 

    integer :: f, l, p, np, k, ll
    integer :: ipp1,ipm1,jpp1,jpm1
    integer, allocatable :: mask(:)
    integer, allocatable :: mask2(:, :)
    integer, allocatable :: fid(:);
    integer, allocatable :: profid(:)
    integer, allocatable :: done(:)
    real(8) :: zmax, Q, Qbest, rho, rho_prev, rho_inc
    integer :: best
    integer :: p1
    
    integer ngood, ndata
    real(8) :: latnew, lonnew
    
    print *, 'BEGIN read_CODC_profile()'

    call data_inquire(fnames, nfile, nprof, nlev)
    print *, '  overall: nprof =', nprof, ', nlev =', nlev

    allocate(juld(nprof))
    allocate(lat(nprof))
    allocate(lon(nprof))
    allocate(temp(nprof,nlev))
    allocate(saln(nprof, nlev))
    allocate(depth_temp(nprof, nlev))
    allocate(depth_saln(nprof, nlev))
    allocate(obs(nprof, nlev))
    allocate(depth_obs(nprof, nlev))

    allocate(fid(nprof))
    allocate(profid(nprof))

    ! read pre-estimated obs uncertainties
    !
    fname = './obs_unc_'//trim(obstype)//'.nc'
    call data_obsunc(trim(fname), trim(obstype), d3z, obs_unc)
    
    ! read data
    !
    p = 1
    do f = 1, nfile
       call data_readfile(f, np, juld(p : nprof),&
            lat(p : nprof), lon(p : nprof), temp(p : nprof, 1 : nlev), &
            depth_temp(p : nprof, 1 : nlev), saln(p : nprof, 1 : nlev), &
            depth_saln(p : nprof, 1 : nlev))
       fid(p : p + np - 1) = f
       do l = 1, np
          profid(p + l - 1) = l
       end do
       p = p + np
    end do
   if (trim(obstype) == 'TEM') then
      obs = temp
      depth_obs = depth_temp
   else if (trim(obstype) == 'SAL') then
      obs = saln
      depth_obs = depth_saln
   else
      print *, 'ERROR: read_CODC_profile(): <obstype> should be <TEM> or <SAL>...'
      stop
   end if

   ! initialize masks
   allocate(mask(nprof))
   mask(:) = 1
   allocate(mask2(nprof, nlev))
   mask2(:, :) = 1

   ! check nan
   do p = 1, nprof
      do l = 1, nlev
         if (ieee_is_nan(obs(p, l))) then
            mask2(p, l) = 0
         end if
         if (ieee_is_nan(depth_obs(p, l)) .or. (depth_obs(p, l) .ge. 5500.)) then
            mask2(p, l) = 0
         end if
      end do
      if (count(mask2(p, :) == 1) == 0) then
         mask(p) = 0
      end if
   end do

#ifdef ANOMALY
   ! read climatology
   fname = 'mean_obs.nc'
   call data_obsmean(trim(fname), trim(obstype), ddepth, dlon, dlat, obs_mean)

   do p = 1, nprof
      if ((lat(p) .lt. minval(dlat)) .or. (lat(p) .gt. maxval(dlat))) then
         mask(p) = 0
         mask2(p, :) = 0
         cycle
      end if
      if ((lon(p) .lt. minval(dlon)) .or. (lon(p) .gt. maxval(dlon))) then
         mask(p) = 0
         mask2(p, :) = 0
         cycle
      end if
       
      ! identify coordinate in obs_mean
      lon_int = ceiling(lon(p)) + 180
      lat_int = ceiling(lat(p)) + 90
       
      ! find available depth for obs_mean
      f = count(.not. ieee_is_nan(obs_mean(lon_int, lat_int, :)))
      if (f .lt. 2) then
         mask(p) = 0
         mask2(p, :) = 0
         cycle
      end if
       
      allocate(splinex(f), spliney(f), splined(f))
      l = 0
      do k = 1, kdm
         if (.not. ieee_is_nan(obs_mean(lon_int, lat_int, k))) then 
            l = l + 1
            splinex(l) = ddepth(k)
            spliney(l) = obs_mean(lon_int, lat_int, k)
         end if
      end do
      if (l .ne. f) print *, 'Error in spline: l /= f'
      call spline_pchip_set(f, splinex, spliney, splined)

      ! find available depths in obs
      f = count(depth_obs(p, :) .lt. 5500.)
      if (f .lt. 1) then
          mask(p) = 0
          mask2(p, :) = 0
          deallocate(splinex, spliney, splined)
          cycle
      end if

      allocate(splinexe(f), splineye(f))       
      ll = 0
      do k = 1, nlev
          if (depth_obs(p, k) .lt. 5500.) then
             ll = ll + 1
             splinexe(ll) = depth_obs(p, k)
          end if
      end do
      if (ll .ne. f) print *, 'Error in spline: ll /= f'
      call spline_pchip_val(l, splinex, spliney, splined, &
            ll, splinexe, splineye)

      ! calcule anomaly
      ll = 0
      do k = 1, nlev
         if (depth_obs(p, k) .lt. maxval(splinex)) then
            ll = ll + 1
            obs(p, k) = obs(p, k) - splineye(ll)
         else if (depth_obs(p, k) .lt. 5500.) then
            ll = ll + 1
            mask2(p, k) = 0
         else
            mask2(p, k) = 0
         end if
      end do
      deallocate(splinex, spliney, splined, splinexe, splineye)
   end do
#endif

   ! ipiv, jpiv
   !
   allocate(ipiv(nprof), jpiv(nprof))
   ipiv(:) = -999
   jpiv(:) = -999
   call get_pivot(nx, ny, nprof, lon, lat, ipiv, jpiv, depths, modlon, modlat)
   where (ipiv < 1 .or. jpiv < 1 .or. ipiv > nx - 1 .or. jpiv > ny - 1) mask = 0
   do p = 1, nprof
      if (mask(p) == 0) then
         mask2(p, :) = 0
      end if
   end do
   print *, '  after calculating pivot points:'
   print *, '    ', count(mask == 1), ' good profiles'
   print *, '    ', count(mask2 == 1), ' good obs'

   ! Check land grid    
   !
   do p = 1, nprof
#ifdef MASK_LANDNEIGHBOUR
      ipm1=max(ipiv(p)-1,1)
      ipp1=min(ipiv(p)+1,nx)
      jpm1=max(jpiv(p)-1,1)
      jpp1=min(jpiv(p)+1,ny)
      if (any(depths(ipm1:ipp1, jpm1:jpp1) < 60) ) mask(p) = 0
#endif
      if (depths(ipiv(p), jpiv(p)) < 60) mask(p) = 0
   end do
   do p = 1, nprof
      if (mask(p) == 0) then
         mask2(p, :) = 0
      end if
   end do
   print *, '  after examinating model land points:'
   print *, '    ', count(mask == 1), ' good profiles'
   print *, '    ', count(mask2 == 1), ' good obs'

   ! Check for the observation being wet                                                             
   !                                           
   do p = 1, nprof
      if (mask(p) == 0) then
         cycle
      end if
      do l = 1, nlev
         if (mask2(p, l) == 0) then
            cycle
         end if
         if (depth_obs(p, l) > depths(ipiv(p), jpiv(p)) .or.&
               depth_obs(p, l) > depths(ipiv(p) + 1, jpiv(p)) .or.&
               depth_obs(p, l) > depths(ipiv(p), jpiv(p) + 1) .or.&
               depth_obs(p, l) > depths(ipiv(p) + 1, jpiv(p) + 1)) then
            mask2(p, l) = 0
         end if
      end do
      if (count(mask2(p, :) == 1) == 0) then
         mask(p) = 0
      end if
   end do
   print *, '  after examining for wet cells:'
   print *, '    ', count(mask == 1), ' good profiles'
   print *, '    ', count(mask2 == 1), ' good obs'

   ! Check for the observation above mixed layer
   !
   fname = 'forecast001'
   call get_micom_fld_new(trim(fname), mxd1, 'dp', 1, 1, nx, ny)
   call get_micom_fld_new(trim(fname), mxd2, 'dp', 2, 1, nx, ny)
   mxd1 = (mxd1 + mxd2) / 98060. ! Unit: meter
   do p = 1, nprof
      if (mask(p) == 0) then
         cycle
      end if
      do l = 1, nlev
         if (mask2(p, l) == 0) then
            cycle
         end if
         if (depth_obs(p, l) < mxd1(ipiv(p), jpiv(p))) then
            mask2(p, l) = 0
         end if
      end do
      if (count(mask2(p, :) == 1) == 0) then
         mask(p) = 0
      end if
   end do
   print *, '  after examining for obs above the mixed layer:'
   print *, '    ', count(mask == 1), ' good profiles'
   print *, '    ', count(mask2 == 1), ' good obs'
   
   ! check for reasonable values
   !
   do p = 1, nprof
      if (mask(p) == 0) then
         cycle
      end if
      do l = 1, nlev
         if (mask2(p, l) == 0) then
            cycle
         end if
         if (trim(obstype) == 'TEM') then
            if ((obs(p, l) .lt. TEM_MIN) .or. (obs(p, l) .gt. TEM_MAX)) then
               mask2(p, l) = 0
            end if
         else if (trim(obstype) == 'SAL') then
            if ((obs(p, l) .lt. SAL_MIN) .or. (obs(p, l) .gt. SAL_MAX)) then
               mask2(p, l) = 0
            end if
         end if
      end do
      if (count(mask2(p, :) == 1) == 0) then
         mask(p) = 0
      end if
   end do
   print *, '  after examining for reasonable values:'
   print *, '    ', count(mask == 1), ' good profiles'
   print *, '    ', count(mask2 == 1), ' good obs'

   ! Read sea ice clim from model 
   fname = 'mean_mod'
   call get_micom_fld_new(trim(fname), fice, 'fice', 0, 1, nx, ny)

   ngood = count(mask2 == 1)
   nrobs = ngood
   allocate(data(ngood))
   ndata = 0
   do p = 1, nprof
      if (mask(p) == 0) then
         cycle
      end if
      do l = 1, nlev
         if (mask2(p, l) == 0) then
            cycle
         end if

         ndata = ndata + 1
         if (ndata > ngood) then
            print *, 'ERROR: read_CODC_profile(): programming error'
            print *, '  p =', p, ', l =', l
            print *, '  # data =', ndata, ', ngood =', ngood
            stop
         end if
       
         ! PS: I guess we should not bother about the cost of the
         ! comparisons below.
         !
         data(ndata) % d = obs(p, l)
         data(ndata) % id = obstype
         data(ndata) % lon = lon(p)
         data(ndata) % lat = lat(p)
         data(ndata) % depth = max(0.0, depth_obs(p, l))
         if (variance > 0) then
            data(ndata) % var = variance
         else
            call data_variance(trim(obstype), data(ndata) % depth, data(ndata) % var)
         end if
         do k = 1,kdm1
            if (data(ndata) % depth >= d3z(1,k) .and. data(ndata) % depth < d3z(2,k)) then
               data(ndata) % var = max(data(ndata) % var, obs_unc(ipiv(p), jpiv(p), k))
               exit
            end if
         end do
         if (fice(ipiv(p), jpiv(p)) > 15.0) data(ndata) % var = 10.0 * data(ndata) % var 
         data(ndata) % ipiv = ipiv(p)
         data(ndata) % jpiv = jpiv(p)
         data(ndata) % ns = 0 ! for a point (not gridded) measurement
         data(ndata) % date = 0 ! assimilate synchronously

         data(ndata) % a1 = 1
         data(ndata) % a2 = 0
         data(ndata) % a3 = 0
         data(ndata) % a4 = 0

         data(ndata) % status = .true. ! (active)
         data(ndata) % i_orig_grid = p
         data(ndata) % j_orig_grid = l
         data(ndata) % orig_id = 0
         data(ndata) % h = 0
       end do
    end do

    if (ndata /= ngood) then
       print *, 'ERROR: read_CODC_profile(): programming error'
       print *, '  ndata =', ndata, ', ngood =', ngood
       stop
    end if

   deallocate(juld, lat, lon)
   deallocate(temp, saln, depth_temp, depth_saln)
   deallocate(obs, depth_obs, fid, profid)
   deallocate(mask, mask2, ipiv, jpiv)

   print *, 'END read_CODC_profile()'

  end subroutine read_CODC_profile


  subroutine data_inquire(fnames, nfile, nprof, nlev)
    use nfw_mod

    character(*), intent(in) :: fnames
    integer, intent(inout) :: nfile, nprof, nlev

    character(STRLEN) :: command ! (there may be a limit of 80 on some systems)
    character(STRLEN) :: fname
    integer :: ios
    integer :: ncid
    integer :: id

    integer :: nprof_this, nlev_this

    nfile = 0
    nprof = 0
    nlev = 0

    command = 'ls '//trim(fnames)//' > infiles.txt'
    call system(command);

    nfile = 0
    open(10, file = 'infiles.txt')
    do while (.true.)
       read(10, fmt = '(a)', iostat = ios) fname
       if (ios /= 0) then
          exit
       end if

       nfile = nfile + 1
       print *, '  file #', nfile, ' = "', trim(fname), '"'

       call nfw_open(fname, nf_nowrite, ncid)

       ! nprof
       !
       call nfw_inq_dimid(fname, ncid, 'N_PROF', id)
       call nfw_inq_dimlen(fname, ncid, id, nprof_this)
       print *, '    nprof = ', nprof_this

       ! nlev
       !
       call nfw_inq_dimid(fname, ncid, 'N_LEVELS', id)
       call nfw_inq_dimlen(fname, ncid, id, nlev_this)
       print *, '    nlev = ', nlev_this
       
       nprof = nprof + nprof_this
       if (nlev_this > nlev) then
          nlev = nlev_this
       end if

       call nfw_close(fname, ncid)
    end do
    close(10)
  end subroutine data_inquire


  subroutine data_readfile(fid, nprof, juld_all, lat_all, lon_all, &
    temp_all, depth_temp_all, saln_all, depth_saln_all)
    use nfw_mod

    integer, intent(in) :: fid
    integer, intent(inout) :: nprof
    real(8), intent(inout), dimension(:) :: juld_all
    real(8), intent(inout), dimension(:) :: lat_all, lon_all
    real(8), intent(inout), dimension(:,:) :: temp_all
    real(8), intent(inout), dimension(:,:) :: saln_all
    real(8), intent(inout), dimension(:,:) :: depth_saln_all
    real(8), intent(inout), dimension(:,:) :: depth_temp_all

    character(STRLEN) :: fname
    integer :: f, ncid, id, nlev, str_recorder
    real(8), allocatable :: profile_info(:,:)
    
    open(10, file = 'infiles.txt')
    do f = 1, fid
       read(10, fmt = '(a)') fname
    end do
    close(10)

    print *, '  reading "', trim(fname), '"'
    
    call nfw_open(fname, nf_nowrite, ncid)

    ! nprof
    !
    call nfw_inq_dimid(fname, ncid, 'N_PROF', id)
    call nfw_inq_dimlen(fname, ncid, id, nprof)

    ! nlev
    !
    call nfw_inq_dimid(fname, ncid, 'N_LEVELS', id)
    call nfw_inq_dimlen(fname, ncid, id, nlev)

    ! str_recorder
    !
    call nfw_inq_dimid(fname, ncid, 'STRINGS_recorder', id)
    call nfw_inq_dimlen(fname, ncid, id, str_recorder)

    ! Profile_info_record_all
    !
    allocate(profile_info(nprof, str_recorder))
    call nfw_inq_varid(fname, ncid, 'Profile_info_record_all', id)
    call nfw_get_var_double(fname, ncid, id, profile_info(1 : nprof, 1 : str_recorder))

    ! temp
    !
    call nfw_inq_varid(fname, ncid, 'Temperature', id)
    call nfw_get_var_double(fname, ncid, id, temp_all(1 : nprof, 1 : nlev))

    ! depth_temp
    !
    call nfw_inq_varid(fname, ncid, 'Depth_Temperature', id)
    call nfw_get_var_double(fname, ncid, id, depth_temp_all(1 : nprof, 1 : nlev))

    ! saln
    !
    call nfw_inq_varid(fname, ncid, 'Salinity', id)
    call nfw_get_var_double(fname, ncid, id, saln_all(1 : nprof, 1 : nlev))

    ! depth_saln
    !
    call nfw_inq_varid(fname, ncid, 'Depth_Salinity', id)
    call nfw_get_var_double(fname, ncid, id, depth_saln_all(1 : nprof, 1 : nlev))
    call nfw_close(fname, ncid)

    ! extract juld, lat, lon
    juld_all(1 : nprof) = profile_info(1 : nprof, 13)
    lat_all(1 : nprof) = profile_info(1 : nprof, 5)
    lon_all(1 : nprof) = profile_info(1 : nprof, 6)
    deallocate(profile_info)

  end subroutine data_readfile

  real(8) function potential_density(T, S)
    real(8), intent(in) :: T, S

    if (T < -2.0d0 .or. T > 40.0d0 .or. S < 0.0d0 .or. S > 42.0d0) then
       potential_density = -999.0d0
       return
    end if

    potential_density =&
         -9.20601d-2&
         + T * (5.10768d-2 + S * (- 3.01036d-3)&
         + T * (- 7.40849d-3 + T * 3.32367d-5 + S * 3.21931d-5))&
         + 8.05999d-1 * S
  end function potential_density

  ! Purpose: find pivot points from profile data 
  !
  subroutine get_pivot(nx, ny, nprof, lon, lat, ipiv, jpiv, depths, modlon, modlat)
    use m_get_micom_grid
    use m_get_micom_dim
    use m_pivotp_micom
    
    implicit none

    ! Grid dimensions
    integer, intent(in) :: nx, ny
    integer, intent(in) :: nprof 

    real   , intent(in)    :: lon(nprof), lat(nprof)
    integer, intent(inout) :: ipiv(nprof), jpiv(nprof)

    real, intent(inout), dimension(nx,ny) :: depths, modlon, modlat

    real, parameter :: onem=98060.
    
    character(len=80) :: filename
    logical          :: ex
    character(len=8) :: ctmp

    real :: meandx,mindx
    real, allocatable, dimension(:,:) :: min_r, max_r
    integer, allocatable, dimension(:,:) :: itw, &
         jtw, its, jts, itn, jtn, ite, jte
    integer :: p
    integer :: dimids(2)
    integer :: ncid, x_ID, y_ID, z_ID 
    integer :: vJPIV_ID, vIPIV_ID
    integer :: ncid2, jns_ID, ins_ID, inw_ID, jnw_ID,jnn_ID, inn_ID, ine_ID, jne_ID
    
    allocate(min_r(nx, ny))
    allocate(max_r(nx, ny))
    allocate(itw(nx, ny))
    allocate(jtw(nx, ny))
    allocate(its(nx, ny))
    allocate(jts(nx, ny))
    allocate(itn(nx, ny))
    allocate(jtn(nx, ny))
    allocate(ite(nx, ny))
    allocate(jte(nx, ny))

    ! Read position and depth from model grid
    !
    call get_micom_grid(modlon, modlat, depths, mindx, meandx, nx, ny)
    call ini_pivotp(modlon,modlat, nx, ny, min_r, max_r, itw, jtw, itn, jtn, &
         its, jts, ite, jte)
    do p=1,nprof
       ipiv(p) = 1
       jpiv(p) = 1
       if (lat(p) .ge. -90 .and. lat(p) .le. 89 .and. lon(p) .ge. -180 .and. lon(p) .le. 180) then
#ifdef PIVOTP_MICOM_NEW
          call pivotp_micom_new(lon(p), lat(p), modlon, modlat, ipiv(p), jpiv(p), &
               nx, ny, min_r, max_r,itw, jtw, its, jts, itn, jtn, ite, jte)
#else
          call pivotp_micom(lon(p), lat(p), modlon, modlat, ipiv(p), jpiv(p), &
               nx, ny, min_r, max_r,itw, jtw, itn, jtn, its, jts, ite, jte)
#endif
       end if
    end do
  end subroutine get_pivot

  ! Define the observation error variance as in Xie and Zhu, 2010
  ! 
  subroutine data_variance(obstype, depth, var)

    implicit none
    
    character(*), intent(in) :: obstype
    real        , intent(in) :: depth

    real, intent(inout) :: var

    if (trim(obstype) == 'TEM') then
       var = 0.05 + 0.45 * exp(-0.002 * depth)
       var = var ** 2.0
    elseif(trim(obstype) == 'SAL') then
       var = 0.02 + 0.10 * exp(-0.008 * depth)
       var = var ** 2.0
    else
       print *, 'ERROR: data_variance(): the definition of variance is only available for <TEM> and <SAL>'
       print *, 'The inital variance in the file <infile.data> should be non-negative...'
       stop
    end if
  end subroutine data_variance

  ! Purpose: read obervation uncertainties (instrumental and 
  !          representativeness error) from the pre-estimation.
  ! Refer to Karspeck, A. (2016).
  !
  subroutine data_obsunc(fname, obstype, depth_bnd, field)
    use nfw_mod

    character(*), intent(in)            :: fname
    character(*), intent(in)                 :: obstype
    real(8), intent(inout), dimension(:,:)   :: depth_bnd
    real(8), intent(inout), dimension(:,:,:) :: field
    
    integer :: ncid
    integer :: id
    
    !print *, '  reading "', trim(fname), '"'
    call nfw_open(trim(fname), nf_nowrite, ncid)

    ! depth_bnd
    call nfw_inq_varid(trim(fname), ncid, 'depth_bnds', id)
    call nfw_get_var_double(trim(fname), ncid, id, depth_bnd)
    
    ! Obs_Unc
    call nfw_inq_varid(trim(fname), ncid, 'var_o', id)
    call nfw_get_var_double(trim(fname), ncid, id, field)

    call nfw_close(trim(fname), ncid)
  end subroutine data_obsunc

  ! Purpose: read obervation climatology
  !                                     
  subroutine data_obsmean(fname, obstype, depth, lon, lat, field)
    use nfw_mod

    character(*), intent(in)            :: fname
    character(*), intent(in)                 :: obstype
    real(8), intent(inout), dimension(:)     :: depth, lon, lat
    real(8), intent(inout), dimension(:,:,:) :: field

    integer :: ncid
    integer :: id
    !integer, dimension(4) :: ns, nc

!    print *, '  reading "', trim(fname), '"'
    call nfw_open(trim(fname), nf_nowrite, ncid)

    ! depth
    call nfw_inq_varid(trim(fname), ncid, 'depth_0_2000', id)
    call nfw_get_var_double(trim(fname), ncid, id, depth(1:79))
    call nfw_inq_varid(trim(fname), ncid, 'depth_2000_6000', id)
    call nfw_get_var_double(trim(fname), ncid, id, depth(80:)) 

    ! lon
    call nfw_inq_varid(trim(fname), ncid, 'lon', id)
    call nfw_get_var_double(trim(fname), ncid, id, lon)

    ! lat
    call nfw_inq_varid(trim(fname), ncid, 'lat', id)
    call nfw_get_var_double(trim(fname), ncid, id, lat)

    ! Obs_mean
    if (trim(obstype) == 'SAL') then
       call nfw_inq_varid(trim(fname), ncid, 'S_mean_0_2000', id)
       call nfw_get_var_double(trim(fname), ncid, id, field(:,:,1:79))
       call nfw_inq_varid(trim(fname), ncid, 'S_mean_2000_6000', id)
       call nfw_get_var_double(trim(fname), ncid, id, field(:,:,80:))
    elseif (trim(obstype) == 'TEM') then
       call nfw_inq_varid(trim(fname), ncid, 'T_mean_0_2000', id)
       call nfw_get_var_double(trim(fname), ncid, id, field(:,:,1:79))
       call nfw_inq_varid(trim(fname), ncid, 'T_mean_2000_6000', id)
       call nfw_get_var_double(trim(fname), ncid, id, field(:,:,80:))
    end if

    call nfw_close(trim(fname), ncid)
  end subroutine data_obsmean
    
end module  m_read_CODC_profile

! =============================================================================
!  sm_da_s2s_mpi.f90
!  Fortran 90 + MPI port of the original sm_da_s2s.py (CLM5 soil-moisture / SWE
!  ensemble DA, EAKF increments + regression onto the state).
!
!  Parallel design
!    * restart files (the I/O) are split by ENSEMBLE MEMBER:
!        rank r reads / writes members r+1, r+1+nproc, ...
!    * the analysis itself (a few seconds of arithmetic) runs on rank 0 only,
!      so the numerics are a direct translation of the serial Python.
!
!  Array conventions
!    NetCDF-Fortran reverses dimension order w.r.t. Python:
!      Python H2OSOI_LIQ[column, levtot]   <->  Fortran (levtot, column)
!    Inside the analysis, ensemble member is the FASTEST index:
!      liq(k, l, c)  = member k, soil layer l, column c   (Python [c, l, k])
!    gidx is kept 0-based exactly as in Python; use gidx+1 to index Fortran arrays.
!
!  Run:   mpirun -n 30 ./sm_da_s2s_mpi 20240101 30 1.05
! =============================================================================
module sm_da_mod
  use mpi
  use netcdf
  use, intrinsic :: ieee_arithmetic
  implicit none

  integer, parameter :: dp = kind(1.0d0)

  ! ============================== configuration ===============================
  character(len=256) :: DIR     = './'
  character(len=256) :: OBS_DIR = './INPUT_SM'

  ! CLM5 vertical grid (layer thickness in m). 
  integer, parameter :: NSOI_CLM5    = 20      ! hydrologically active soil layers (nlevsoi)
  integer, parameter :: NSNO_DEFAULT = 12      ! CLM5 default nlevsno (used if 'levsno' dim is missing)
  real(dp), parameter :: DZ_CLM5(NSOI_CLM5) = (/ &
       0.02_dp, 0.04_dp, 0.06_dp, 0.08_dp, 0.12_dp, 0.16_dp, 0.20_dp, 0.24_dp, 0.28_dp, 0.32_dp, &
       0.36_dp, 0.40_dp, 0.44_dp, 0.54_dp, 0.64_dp, 0.74_dp, 0.84_dp, 0.94_dp, 1.04_dp, 1.14_dp /)

  real(dp), parameter :: RHO_W = 1000.0_dp, RHO_I = 917.0_dp
  real(dp), parameter :: FILL  = 1.0e30_dp

  integer, parameter :: LUN_SOIL = 1, LUN_CROP = 2   ! vegetated/bare soil + crop only 
  real(dp) :: OBS_DEPTH = 0.05_dp          ! m ; 0.05 = depth-weighted 0-5 cm operator
  logical  :: OBS_DEPTH_NONE = .false.     ! .true. = top layer only (Python OBS_DEPTH = None)
  real(dp) :: SM_ERR  = 0.05_dp            ! m3/m3
  real(dp) :: SWE_ERR = 0.02_dp            ! MUST be in the same units as H2OSNO (mm)
  real(dp) :: OUTLIER = 3.0_dp
  real(dp) :: MIN_ELIG_WEIGHT = 0.05_dp
  real(dp) :: VAR_MIN = 1.0e-12_dp

  real(dp) :: SM_SNOWFREE_MM = 1.0_dp
  real(dp) :: FROZEN_T = 273.15_dp

  logical  :: UPDATE_TEMP = .false.
  real(dp) :: VERT_LOC = 3.0_dp
  logical  :: VERT_LOC_NONE = .false.      ! .true. = no vertical localisation (Python VERT_LOC = None)
  real(dp) :: TEMP_LOC = 0.5_dp
  real(dp) :: TEMP_CLAMP = 2.0_dp

  real(dp) :: THETA_MIN = 0.01_dp
  real(dp) :: THETA_SAT = 0.45_dp
  real(dp) :: SWE_MIN = 1.0_dp
  real(dp) :: LOC_SWE = 1.0_dp

  
  ! Set to .false. for soil moisture only.
  logical  :: ASSIM_SWE = .true.

  ! set at run time by configure_layout()
  integer, parameter :: NSOIL = NSOI_CLM5
  integer  :: NSNO = NSNO_DEFAULT
  integer  :: NCOL = 0
  real(dp) :: DZ(NSOIL), ZI(0:NSOIL)

  ! column metadata (rank 0 only)
  integer,  allocatable :: m_gidx(:)
  real(dp), allocatable :: m_wt(:), m_watsat(:,:)
  logical,  allocatable :: m_elig(:)
  logical :: m_has_watsat = .false.

  integer :: myrank = 0, nproc = 1

contains

  ! ============================ small utilities ==============================
  subroutine check(status, msg)
    integer, intent(in) :: status
    character(len=*), intent(in) :: msg
    integer :: ierr
    if (status /= nf90_noerr) then
      write(*,'(a,i0,a,a,a,a)') '[rank ', myrank, '] NetCDF error in ', trim(msg), ': ', trim(nf90_strerror(status))
      call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
    end if
  end subroutine check

  subroutine fatal(msg)
    character(len=*), intent(in) :: msg
    integer :: ierr
    write(*,'(a,i0,a,a)') '[rank ', myrank, '] ERROR: ', trim(msg)
    call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
  end subroutine fatal

  function qnan() result(x)
    real(dp) :: x
    x = ieee_value(1.0_dp, ieee_quiet_nan)
  end function qnan

  function pinf() result(x)
    real(dp) :: x
    x = ieee_value(1.0_dp, ieee_positive_inf)
  end function pinf

  ! np.nan_to_num(x, nan=0.0): NaN -> 0, +-inf -> +-largest finite
  elemental function nan_to_num(x) result(y)
    real(dp), intent(in) :: x
    real(dp) :: y
    if (ieee_is_nan(x)) then
      y = 0.0_dp
    else if (x > huge(x)) then
      y = huge(x)
    else if (x < -huge(x)) then
      y = -huge(x)
    else
      y = x
    end if
  end function nan_to_num

  ! isbad(a) = ~isfinite(a) | (abs(a) > FILL)
  elemental function isbad(x) result(b)
    real(dp), intent(in) :: x
    logical :: b
    b = (.not. ieee_is_finite(x)) .or. (abs(x) > FILL)
  end function isbad

  function path_join(d, name) result(p)
    character(len=*), intent(in) :: d, name
    character(len=600) :: p
    integer :: n
    n = len_trim(d)
    if (n == 0) then
      p = trim(name)
    else if (d(n:n) == '/') then
      p = trim(d)//trim(name)
    else
      p = trim(d)//'/'//trim(name)
    end if
  end function path_join

  function member_file(rdate, i) result(f)
    character(len=*), intent(in) :: rdate
    integer, intent(in) :: i
    character(len=600) :: f
    character(len=128) :: nm
    write(nm,'(a,i3.3,a,a,a)') 'clm.rda.', i, '.', trim(rdate), '.nc'
    f = path_join(DIR, nm)
  end function member_file

  function var_exists(ncid, name) result(ex)
    integer, intent(in) :: ncid
    character(len=*), intent(in) :: name
    logical :: ex
    integer :: vid
    ex = (nf90_inq_varid(ncid, name, vid) == nf90_noerr)
  end function var_exists

  ! ============================ layout / metadata =============================
  subroutine configure_layout(ncid)
    integer, intent(in) :: ncid
    integer :: dimid, stat, l
    stat = nf90_inq_dimid(ncid, 'levsno', dimid)
    if (stat == nf90_noerr) then
      call check(nf90_inquire_dimension(ncid, dimid, len=NSNO), 'levsno')
    else
      NSNO = NSNO_DEFAULT
    end if
    DZ = DZ_CLM5
    ZI(0) = 0.0_dp
    do l = 1, NSOIL
      ZI(l) = ZI(l-1) + DZ(l)
    end do
  end subroutine configure_layout

  subroutine get_ncol(ncid)
    integer, intent(in) :: ncid
    integer :: vid, nd, dimids(NF90_MAX_VAR_DIMS)
    call check(nf90_inq_varid(ncid, 'cols1d_ityplun', vid), 'cols1d_ityplun')
    call check(nf90_inquire_variable(ncid, vid, ndims=nd, dimids=dimids), 'inq cols1d_ityplun')
    call check(nf90_inquire_dimension(ncid, dimids(1), len=NCOL), 'column dimension')
  end subroutine get_ncol

  subroutine obs_layer_weights(w)
    real(dp), intent(out) :: w(NSOIL)
    real(dp) :: ov(NSOIL)
    integer :: l
    if (OBS_DEPTH_NONE) then
      w = 0.0_dp
      w(1) = 1.0_dp
      return
    end if
    do l = 1, NSOIL
      ov(l) = max(min(ZI(l), OBS_DEPTH) - ZI(l-1), 0.0_dp)
    end do
    w = ov / sum(ov)
  end subroutine obs_layer_weights

  subroutine read_int1(ncid, name, arr)
    integer, intent(in) :: ncid
    character(len=*), intent(in) :: name
    integer, allocatable, intent(out) :: arr(:)
    integer :: vid, nd, dimids(NF90_MAX_VAR_DIMS), n
    call check(nf90_inq_varid(ncid, name, vid), name)
    call check(nf90_inquire_variable(ncid, vid, ndims=nd, dimids=dimids), name)
    call check(nf90_inquire_dimension(ncid, dimids(1), len=n), name)
    allocate(arr(n))
    call check(nf90_get_var(ncid, vid, arr), name)
  end subroutine read_int1

  subroutine read_real1(ncid, name, arr)
    integer, intent(in) :: ncid
    character(len=*), intent(in) :: name
    real(dp), allocatable, intent(out) :: arr(:)
    integer :: vid, nd, dimids(NF90_MAX_VAR_DIMS), n
    call check(nf90_inq_varid(ncid, name, vid), name)
    call check(nf90_inquire_variable(ncid, vid, ndims=nd, dimids=dimids), name)
    call check(nf90_inquire_dimension(ncid, dimids(1), len=n), name)
    allocate(arr(n))
    call check(nf90_get_var(ncid, vid, arr), name)
  end subroutine read_real1

  ! Column -> obs-grid mapping, area weights, eligibility (DART landunit localisation)
  subroutine read_column_meta(ncid, nlon, ng)
    integer, intent(in) :: ncid, nlon, ng
    integer, allocatable :: ityp(:), ixy(:), jxy(:), gci(:), gxy(:), gyy(:), act(:)
    real(dp), allocatable :: wt(:)
    integer :: c, vid
    logical :: active

    call read_int1(ncid, 'cols1d_ityplun', ityp)
    if (var_exists(ncid, 'cols1d_wtgcell')) then
      call read_real1(ncid, 'cols1d_wtgcell', wt)
    else if (var_exists(ncid, 'cols1d_wtxy')) then
      call read_real1(ncid, 'cols1d_wtxy', wt)
    else
      call fatal('None of cols1d_wtgcell, cols1d_wtxy in restart')
    end if
    NCOL = size(ityp)
    allocate(m_gidx(NCOL), m_elig(NCOL))

    if (var_exists(ncid, 'cols1d_ixy') .and. var_exists(ncid, 'cols1d_jxy')) then
      call read_int1(ncid, 'cols1d_ixy', ixy)
      call read_int1(ncid, 'cols1d_jxy', jxy)
      m_gidx = (jxy - 1) * nlon + (ixy - 1)
    else if (var_exists(ncid, 'cols1d_gridcell_index') .and. var_exists(ncid, 'grid1d_ixy')) then
      call read_int1(ncid, 'cols1d_gridcell_index', gci)
      call read_int1(ncid, 'grid1d_ixy', gxy)
      call read_int1(ncid, 'grid1d_jxy', gyy)
      do c = 1, NCOL
        if (gci(c) >= 1 .and. gci(c) <= size(gxy)) then
          m_gidx(c) = (gyy(gci(c)) - 1) * nlon + (gxy(gci(c)) - 1)
        else
          m_gidx(c) = -1
        end if
      end do
    else
      ! assumes obs are stored in CLM land-gridcell order
      call read_int1(ncid, 'cols1d_gridcell_index', gci)
      m_gidx = gci - 1
    end if

    if (var_exists(ncid, 'cols1d_active')) then
      call read_int1(ncid, 'cols1d_active', act)
    end if

    allocate(m_wt(NCOL))
    m_wt = wt
    do c = 1, NCOL
      active = .true.
      if (allocated(act)) active = (act(c) /= 0)
      m_elig(c) = (ityp(c) == LUN_SOIL .or. ityp(c) == LUN_CROP) .and. (wt(c) > 0.0_dp) &
                  .and. active .and. (m_gidx(c) >= 0) .and. (m_gidx(c) < ng)
    end do

    m_has_watsat = .false.
    if (nf90_inq_varid(ncid, 'WATSAT', vid) == nf90_noerr) then
      allocate(m_watsat(NSOIL, NCOL))
      call check(nf90_get_var(ncid, vid, m_watsat, start=(/1,1/), count=(/NSOIL,NCOL/)), 'WATSAT')
      m_has_watsat = .true.
    end if
  end subroutine read_column_meta

  ! ============================ observations =================================
  ! mimic netCDF4-python auto-masking (_FillValue, missing_value, valid_min/max/range)
  subroutine apply_mask(ncid, vid, a)
    integer, intent(in) :: ncid, vid
    real(dp), intent(inout) :: a(:)
    real(dp) :: fv, mv, vmin, vmax, vr(2)
    logical :: has_fv, has_mv, has_vmin, has_vmax, has_vr, masked
    integer :: i
    has_fv   = (nf90_get_att(ncid, vid, '_FillValue',    fv)   == nf90_noerr)
    has_mv   = (nf90_get_att(ncid, vid, 'missing_value', mv)   == nf90_noerr)
    has_vmin = (nf90_get_att(ncid, vid, 'valid_min',     vmin) == nf90_noerr)
    has_vmax = (nf90_get_att(ncid, vid, 'valid_max',     vmax) == nf90_noerr)
    has_vr   = (nf90_get_att(ncid, vid, 'valid_range',   vr)   == nf90_noerr)
    do i = 1, size(a)
      masked = .false.
      if (has_fv)   masked = masked .or. (a(i) == fv)
      if (has_mv)   masked = masked .or. (a(i) == mv)
      if (has_vr)   masked = masked .or. (a(i) < vr(1)) .or. (a(i) > vr(2))
      if (has_vmin) masked = masked .or. (a(i) < vmin)
      if (has_vmax) masked = masked .or. (a(i) > vmax)
      if (.not. has_fv) masked = masked .or. (a(i) >= 9.9e36_dp)   ! default netCDF fill
      if (masked) a(i) = qnan()
    end do
  end subroutine apply_mask

  subroutine read_obs_var(ncid, name, found, flat, nd, nlon_v)
    integer, intent(in) :: ncid
    character(len=*), intent(in) :: name
    logical, intent(out) :: found
    real(dp), allocatable, intent(out) :: flat(:)
    integer, intent(out) :: nd, nlon_v
    integer :: vid, stat, dimids(NF90_MAX_VAR_DIMS), n1, n2
    real(dp), allocatable :: b2(:,:)
    found = .false.; nd = 0; nlon_v = 0
    stat = nf90_inq_varid(ncid, name, vid)
    if (stat /= nf90_noerr) return
    call check(nf90_inquire_variable(ncid, vid, ndims=nd, dimids=dimids), 'inq obs '//name)
    if (nd == 1) then
      call check(nf90_inquire_dimension(ncid, dimids(1), len=n1), 'obs dim')
      allocate(flat(n1))
      call check(nf90_get_var(ncid, vid, flat), 'get obs '//name)
      nlon_v = n1
    else if (nd == 2) then
      call check(nf90_inquire_dimension(ncid, dimids(1), len=n1), 'obs dim1')
      call check(nf90_inquire_dimension(ncid, dimids(2), len=n2), 'obs dim2')
      allocate(b2(n1, n2))
      call check(nf90_get_var(ncid, vid, b2), 'get obs '//name)
      allocate(flat(n1*n2))
      flat = reshape(b2, (/ n1*n2 /))       ! Fortran (lon,lat) memory order == numpy ravel of [lat,lon]
      nlon_v = n1
    else
      call fatal('obs variable '//name//' must be 1-D or 2-D')
    end if
    call apply_mask(ncid, vid, flat)
    found = .true.
  end subroutine read_obs_var

  subroutine read_obs(rdate, have_sm, have_swe, sm, swe, ng, nd_ref, nlon_ref)
    character(len=*), intent(in) :: rdate
    logical, intent(out) :: have_sm, have_swe
    real(dp), allocatable, intent(out) :: sm(:), swe(:)
    integer, intent(out) :: ng, nd_ref, nlon_ref
    character(len=600) :: path
    character(len=128) :: nm
    logical :: ex
    integer :: ncid, nd, nlon_t
    have_sm = .false.; have_swe = .false.; ng = 0; nd_ref = 0; nlon_ref = 0
    nm = 'CCI_sm_obs_'//trim(rdate)//'.nc'
    path = path_join(OBS_DIR, nm)
    inquire(file=trim(path), exist=ex)
    if (ex) then
      call check(nf90_open(trim(path), nf90_nowrite, ncid), 'open '//trim(path))
      call read_obs_var(ncid, 'sm', have_sm, sm, nd, nlon_t)
      if (have_sm) then
        ng = size(sm); nd_ref = nd; nlon_ref = nlon_t
      end if
      if (ASSIM_SWE) then
        call read_obs_var(ncid, 'swe_assimilable', have_swe, swe, nd, nlon_t)
        if (have_swe .and. .not. have_sm) then
          ng = size(swe); nd_ref = nd; nlon_ref = nlon_t
        end if
      end if
      call check(nf90_close(ncid), 'close obs')
    end if
    if (.not. allocated(sm))  allocate(sm(0))
    if (.not. allocated(swe)) allocate(swe(0))
  end subroutine read_obs

  ! ============================ numerics =====================================
  subroutine grid_mean(ens, nrow, vals, g, w, ng, out, wsum)
    integer, intent(in) :: ens, nrow, ng, g(nrow)
    real(dp), intent(in) :: vals(ens, nrow), w(nrow)
    real(dp), intent(out) :: out(ens, ng), wsum(ng)
    integer :: n, ig, k
    wsum = 0.0_dp
    out  = 0.0_dp
    do n = 1, nrow
      ig = g(n) + 1
      wsum(ig) = wsum(ig) + w(n)
      do k = 1, ens
        out(k, ig) = out(k, ig) + w(n) * vals(k, n)
      end do
    end do
    do ig = 1, ng
      if (wsum(ig) <= 0.0_dp) then
        out(:, ig) = qnan()
      else
        out(:, ig) = out(:, ig) / wsum(ig)
      end if
    end do
  end subroutine grid_mean

  ! EAKF increments for all gridcells; only rows with valid=.true. can be assimilated
  subroutine eakf_increments(ens, ng, hx, y, r, valid, dy, var_out, innov, ok)
    integer, intent(in) :: ens, ng
    real(dp), intent(in) :: hx(ens, ng), y(ng), r
    logical, intent(in) :: valid(ng)
    real(dp), intent(out) :: dy(ens, ng), var_out(ng), innov(ng)
    logical, intent(out) :: ok(ng)
    integer :: ig, k
    real(dp) :: mu, var, var_a, mu_a, sc, rn
    rn = real(ens, dp)
    do ig = 1, ng
      dy(:, ig) = 0.0_dp
      var_out(ig) = pinf()
      innov(ig) = qnan()
      ok(ig) = .false.
      if (.not. valid(ig)) cycle
      mu = sum(hx(:, ig)) / rn
      var = 0.0_dp
      do k = 1, ens
        var = var + (hx(k, ig) - mu)**2
      end do
      var = var / (rn - 1.0_dp)
      innov(ig) = y(ig) - mu
      ok(ig) = ieee_is_finite(mu) .and. (var > VAR_MIN) .and. (abs(innov(ig)) <= OUTLIER * sqrt(var + r))
      if (ok(ig)) then
        var_a = 1.0_dp / (1.0_dp / var + 1.0_dp / r)
        mu_a  = var_a * (mu / var + y(ig) / r)
        sc    = sqrt(var_a / var)
        do k = 1, ens
          dy(k, ig) = (mu_a + sc * (hx(k, ig) - mu)) - hx(k, ig)
        end do
        var_out(ig) = var
      end if
    end do
  end subroutine eakf_increments

  ! ============================ analysis (rank 0) ============================
  subroutine analysis_root(rdate, ens, infl, ng, liq, ice, tsoi, swe, has_swe, have_sm, y_sm, have_swe_obs, y_swe, &
                           sm_do, ne, ec, liq_new, t_new, nsw, sw_cols, s_post, innov_sm, innov_swe)
    character(len=*), intent(in) :: rdate
    integer, intent(in) :: ens, ng
    real(dp), intent(in) :: infl
    real(dp), intent(in) :: liq(:,:,:), ice(:,:,:), tsoi(:,:,:), swe(:,:)
    logical, intent(in) :: has_swe, have_sm, have_swe_obs
    real(dp), intent(in) :: y_sm(:), y_swe(:)
    logical, intent(out) :: sm_do
    integer, intent(out) :: ne, nsw
    integer, allocatable, intent(out) :: ec(:), sw_cols(:)
    real(dp), allocatable, intent(out) :: liq_new(:,:,:), t_new(:,:,:), s_post(:,:), innov_sm(:), innov_swe(:)

    integer :: c, n, k, l, s, ig, nS, n_ok, nes, nchg, nn
    logical :: bad
    real(dp) :: rn, mm, swm, tm, cov, reg, th_sat_l, hi, th_ana, t_ana, sm_, sw_
    integer,  allocatable :: ec_f(:), g_e(:), es_f(:), g_s(:)
    real(dp), allocatable :: w_e(:), w_s(:), hx_col(:,:), tt(:,:), swin(:,:), hx(:,:), wsum(:), wtmp(:)
    real(dp), allocatable :: t_top(:,:), swe_g(:,:), dy(:,:), var_s(:), innov(:), hm(:), loc(:), wobs(:)
    real(dp), allocatable :: s_x(:,:), hx_s(:,:), wsum_s(:), hm_s(:)
    logical,  allocatable :: valid(:), ok(:), allow(:), chg(:)
    real(dp) :: thc(ens, NSOIL), thi(ens, NSOIL), Tc(ens, NSOIL), thx(ens, NSOIL)
    real(dp) :: X(ens, 2*NSOIL), Xp(ens, 2*NSOIL), Xa(ens, 2*NSOIL), hxp(ens), sc_(ens)

    rn = real(ens, dp)

    ! ---- eligible, non-bad soil columns ----
    allocate(ec_f(NCOL))
    ne = 0
    do c = 1, NCOL
      if (.not. m_elig(c)) cycle
      bad = .false.
      do l = 1, NSOIL
        do k = 1, ens
          if (isbad(liq(k,l,c)) .or. isbad(ice(k,l,c)) .or. isbad(tsoi(k,l,c))) bad = .true.
        end do
      end do
      if (bad) cycle
      ne = ne + 1
      ec_f(ne) = c
    end do
    allocate(g_e(ne), w_e(ne))
    do n = 1, ne
      g_e(n) = m_gidx(ec_f(n))
      w_e(n) = m_wt(ec_f(n))
    end do

    ! ===================== SOIL MOISTURE =====================
    sm_do = .false.
    allocate(innov_sm(ng))
    innov_sm = qnan()
    allocate(t_new(0,0,0))
    if (have_sm .and. ne > 0) then
      sm_do = .true.
      allocate(wobs(NSOIL))
      call obs_layer_weights(wobs)

      allocate(hx_col(ens, ne), tt(ens, ne), swin(ens, ne))
      do n = 1, ne
        c = ec_f(n)
        do l = 1, NSOIL
          do k = 1, ens
            thc(k, l) = liq(k, l, c) / (RHO_W * DZ(l))
          end do
          mm = sum(thc(:, l)) / rn
          do k = 1, ens
            thx(k, l) = mm + infl * (thc(k, l) - mm)           ! inflate(th)
          end do
        end do
        do k = 1, ens
          hx_col(k, n) = 0.0_dp
          do l = 1, NSOIL
            hx_col(k, n) = hx_col(k, n) + wobs(l) * thx(k, l)  ! einsum('l,nlk->nk')
          end do
          tt(k, n) = tsoi(k, 1, c)                             ! T[:,0,:]
          if (has_swe) swin(k, n) = nan_to_num(swe(k, c))
        end do
      end do

      allocate(hx(ens, ng), wsum(ng), t_top(ens, ng), wtmp(ng))
      call grid_mean(ens, ne, hx_col, g_e, w_e, ng, hx, wsum)
      call grid_mean(ens, ne, tt, g_e, w_e, ng, t_top, wtmp)
      if (has_swe) then
        allocate(swe_g(ens, ng))
        call grid_mean(ens, ne, swin, g_e, w_e, ng, swe_g, wtmp)
      end if

      allocate(valid(ng), ok(ng), dy(ens, ng), var_s(ng), innov(ng))
      do ig = 1, ng
        if (has_swe) then
          swm = sum(swe_g(:, ig)) / rn
          bad = (nan_to_num(swm) < SM_SNOWFREE_MM)             ! 'snowfree'
        else
          bad = .true.
        end if
        tm = sum(t_top(:, ig)) / rn
        valid(ig) = ieee_is_finite(y_sm(ig)) .and. (y_sm(ig) >= 0.0_dp) .and. (y_sm(ig) <= 1.0_dp) &
                    .and. (wsum(ig) >= MIN_ELIG_WEIGHT) .and. bad .and. (nan_to_num(tm) >= FROZEN_T)
      end do
      call eakf_increments(ens, ng, hx, y_sm, SM_ERR**2, valid, dy, var_s, innov, ok)
      innov_sm = innov
      n_ok = count(ok)
      write(*,'(a,a,a,i0,a)') '[', trim(rdate), '] SM obs assimilated in ', n_ok, ' gridcells'

      ! vertical localisation
      nS = NSOIL
      if (UPDATE_TEMP) nS = 2 * NSOIL
      allocate(loc(nS), hm(ng))
      do l = 1, NSOIL
        if (VERT_LOC_NONE) then
          loc(l) = 1.0_dp
        else
          loc(l) = exp(-real(l-1, dp) / VERT_LOC)
        end if
        if (UPDATE_TEMP) loc(NSOIL + l) = exp(-real(l-1, dp) / 4.0_dp) * TEMP_LOC
      end do
      do ig = 1, ng
        hm(ig) = sum(hx(:, ig)) / rn
      end do

      allocate(liq_new(NSOIL, ne, ens))
      deallocate(t_new)
      if (UPDATE_TEMP) then
        allocate(t_new(NSOIL, ne, ens))
      else
        allocate(t_new(0,0,0))
      end if

      do n = 1, ne
        c  = ec_f(n)
        ig = g_e(n) + 1
        do l = 1, NSOIL
          do k = 1, ens
            thc(k, l) = liq(k, l, c) / (RHO_W * DZ(l))
            thi(k, l) = ice(k, l, c) / (RHO_I * DZ(l))
            Tc(k, l)  = tsoi(k, l, c)
          end do
        end do

        if (ok(ig)) then
          ! X = [th_x (, T_x)]
          do l = 1, NSOIL
            mm = sum(thc(:, l)) / rn
            do k = 1, ens
              X(k, l) = mm + infl * (thc(k, l) - mm)
            end do
            if (UPDATE_TEMP) then
              mm = sum(Tc(:, l)) / rn
              do k = 1, ens
                X(k, NSOIL + l) = mm + infl * (Tc(k, l) - mm)
              end do
            end if
          end do
          do s = 1, nS
            mm = sum(X(:, s)) / rn
            Xp(:, s) = X(:, s) - mm
          end do
          do k = 1, ens
            hxp(k) = nan_to_num(hx(k, ig) - hm(ig))
          end do
          ! regress_increment
          do s = 1, nS
            cov = sum(Xp(:, s) * hxp) / (rn - 1.0_dp)
            reg = cov / var_s(ig)
            do k = 1, ens
              Xa(k, s) = X(k, s) + (loc(s) * reg) * dy(k, ig)
            end do
          end do
          do l = 1, NSOIL
            if (m_has_watsat) then
              th_sat_l = m_watsat(l, c)
            else
              th_sat_l = THETA_SAT
            end if
            do k = 1, ens
              hi = max(th_sat_l - thi(k, l), THETA_MIN)
              th_ana = min(max(Xa(k, l), THETA_MIN), hi)
              liq_new(l, n, k) = (th_ana * RHO_W) * DZ(l)
              if (UPDATE_TEMP) then
                t_ana = Tc(k, l) + min(max(Xa(k, NSOIL + l) - Tc(k, l), -TEMP_CLAMP), TEMP_CLAMP)
                t_new(l, n, k) = t_ana
              end if
            end do
          end do
        else
          do l = 1, NSOIL
            do k = 1, ens
              liq_new(l, n, k) = (thc(k, l) * RHO_W) * DZ(l)   ! where(upd, th_ana, th)*RHO_W*dz
              if (UPDATE_TEMP) t_new(l, n, k) = Tc(k, l)
            end do
          end do
        end if
      end do
      deallocate(hx_col, tt, swin, hx, wsum, t_top, wtmp, valid, ok, dy, var_s, innov, loc, hm, wobs)
      if (allocated(swe_g)) deallocate(swe_g)
    end if

    ! ======================== SNOW (SWE) ========================
    nsw = 0
    allocate(innov_swe(ng))
    innov_swe = qnan()
    allocate(sw_cols(0), s_post(0, ens))
    if (has_swe .and. have_swe_obs) then
      allocate(es_f(NCOL))
      nes = 0
      do c = 1, NCOL
        if (.not. m_elig(c)) cycle
        if (any(isbad(swe(:, c)))) cycle                         ! any FillValue member -> skip
        nes = nes + 1
        es_f(nes) = c
      end do
      if (nes > 0) then
        allocate(g_s(nes), w_s(nes), s_x(ens, nes), allow(nes))
        do n = 1, nes
          g_s(n) = m_gidx(es_f(n))
          w_s(n) = m_wt(es_f(n))
          sc_ = swe(:, es_f(n))
          allow(n) = any(sc_ > 0.0_dp)                           ! DART snow safety rule
          sw_ = sum(sc_) / rn
          do k = 1, ens
            s_x(k, n) = max(0.0_dp, sw_ + infl * (sc_(k) - sw_))
          end do
        end do
        allocate(hx_s(ens, ng), wsum_s(ng))
        call grid_mean(ens, nes, s_x, g_s, w_s, ng, hx_s, wsum_s)

        allocate(valid(ng), ok(ng), dy(ens, ng), var_s(ng), innov(ng), hm_s(ng))
        do ig = 1, ng
          valid(ig) = ieee_is_finite(y_swe(ig)) .and. (y_swe(ig) >= 0.0_dp) .and. (wsum_s(ig) >= MIN_ELIG_WEIGHT)
        end do
        call eakf_increments(ens, ng, hx_s, y_swe, SWE_ERR**2, valid, dy, var_s, innov, ok)
        innov_swe = innov
        write(*,'(a,a,a,i0,a)') '[', trim(rdate), '] SWE obs assimilated in ', count(ok), ' gridcells'

        do ig = 1, ng
          hm_s(ig) = sum(hx_s(:, ig)) / rn
        end do
        allocate(chg(nes))
        nchg = 0
        do n = 1, nes
          chg(n) = ok(g_s(n) + 1) .and. allow(n)
          if (chg(n)) nchg = nchg + 1
        end do
        deallocate(sw_cols, s_post)
        allocate(sw_cols(nchg), s_post(nchg, ens))
        nn = 0
        do n = 1, nes
          if (.not. chg(n)) cycle
          nn = nn + 1
          ig = g_s(n) + 1
          sw_ = sum(s_x(:, n)) / rn
          do k = 1, ens
            hxp(k) = nan_to_num(hx_s(k, ig) - hm_s(ig))
          end do
          cov = sum((s_x(:, n) - sw_) * hxp) / (rn - 1.0_dp)
          reg = cov / var_s(ig)
          do k = 1, ens
            s_post(nn, k) = max(0.0_dp, s_x(k, n) + (LOC_SWE * reg) * dy(k, ig))
          end do
          sw_cols(nn) = es_f(n)
        end do
        nsw = nchg
        deallocate(g_s, w_s, s_x, allow, hx_s, wsum_s, valid, ok, dy, var_s, innov, hm_s, chg)
      end if
    end if

    if (.not. sm_do) then
      ne = 0
      if (.not. allocated(liq_new)) allocate(liq_new(NSOIL, 0, ens))
    end if
    allocate(ec(ne))
    if (ne > 0) ec = ec_f(1:ne)
  end subroutine analysis_root

  ! ============================ restart output ===============================
  ! a[cols] = where(|a[cols]| < FILL, a[cols]*ratio, a[cols])   (rows = columns, 1-based here)
  subroutine scale_var(ncid, name, cols, ratio, nsel)
    integer, intent(in) :: ncid, nsel, cols(nsel)
    character(len=*), intent(in) :: name
    real(dp), intent(in) :: ratio(nsel)
    integer :: vid, nd, dimids(NF90_MAX_VAR_DIMS), n1, i, l, c
    real(dp), allocatable :: a1(:), a2(:,:)
    if (nsel == 0) return
    if (nf90_inq_varid(ncid, name, vid) /= nf90_noerr) return
    call check(nf90_inquire_variable(ncid, vid, ndims=nd, dimids=dimids), 'inq '//name)
    if (nd == 1) then
      allocate(a1(NCOL))
      call check(nf90_get_var(ncid, vid, a1), 'get '//name)
      do i = 1, nsel
        c = cols(i)
        if (abs(a1(c)) < FILL) a1(c) = a1(c) * ratio(i)
      end do
      call check(nf90_put_var(ncid, vid, a1), 'put '//name)
    else if (nd == 2) then
      call check(nf90_inquire_dimension(ncid, dimids(1), len=n1), 'dim '//name)
      allocate(a2(n1, NCOL))
      call check(nf90_get_var(ncid, vid, a2), 'get '//name)
      do i = 1, nsel
        c = cols(i)
        do l = 1, n1
          if (abs(a2(l, c)) < FILL) a2(l, c) = a2(l, c) * ratio(i)
        end do
      end do
      call check(nf90_put_var(ncid, vid, a2), 'put '//name)
    end if
  end subroutine scale_var

  !  Simplified snow repartitioning:
  !   - columns with snow layers: rescale layer liquid/ice mass, DZSNO, ZSNO, ZISNO
  !     and SNOW_DEPTH so layer-summed SWE equals the posterior;
  !   - CLM5 columns with snow but no layers: update H2OSNO_NO_LAYERS and SNOW_DEPTH;
  !   - columns with no snow at all are left alone (no snow creation).
  subroutine repartition_member(ncid, cols, nc, post)
    integer, intent(in) :: ncid, nc, cols(nc)
    real(dp), intent(in) :: post(nc)
    integer :: vl, vi, vn, vh, i, l, c, nact, ia, ncnl, in_
    real(dp), allocatable :: liq_s(:,:), ice_s(:,:), lc(:,:), ic(:,:), lsum(:), tgt(:), prior_nl(:)
    real(dp), allocatable :: an(:), a(:), ratio(:), rn_(:)
    integer, allocatable :: c_act(:), c_nl(:)
    logical, allocatable :: lv(:,:), iv(:,:), act(:), nl(:)

    allocate(liq_s(NSNO, NCOL), ice_s(NSNO, NCOL))
    call check(nf90_inq_varid(ncid, 'H2OSOI_LIQ', vl), 'H2OSOI_LIQ')
    call check(nf90_inq_varid(ncid, 'H2OSOI_ICE', vi), 'H2OSOI_ICE')
    call check(nf90_get_var(ncid, vl, liq_s, start=(/1,1/), count=(/NSNO,NCOL/)), 'get snow liq')
    call check(nf90_get_var(ncid, vi, ice_s, start=(/1,1/), count=(/NSNO,NCOL/)), 'get snow ice')

    allocate(lc(NSNO, nc), ic(NSNO, nc), lv(NSNO, nc), iv(NSNO, nc), lsum(nc), tgt(nc), act(nc), nl(nc))
    do i = 1, nc
      c = cols(i)
      lc(:, i) = liq_s(:, c)
      ic(:, i) = ice_s(:, c)
      lv(:, i) = abs(lc(:, i)) < FILL
      iv(:, i) = abs(ic(:, i)) < FILL
      lsum(i) = sum(merge(lc(:, i), 0.0_dp, lv(:, i))) + sum(merge(ic(:, i), 0.0_dp, iv(:, i)))
      act(i) = lsum(i) > 0.0_dp
      tgt(i) = max(post(i), SWE_MIN)
    end do

    nl = .false.
    if (nf90_inq_varid(ncid, 'H2OSNO_NO_LAYERS', vn) == nf90_noerr) then
      allocate(an(NCOL), prior_nl(nc))
      call check(nf90_get_var(ncid, vn, an), 'get H2OSNO_NO_LAYERS')
      do i = 1, nc
        prior_nl(i) = an(cols(i))
        nl(i) = (.not. act(i)) .and. (prior_nl(i) > 0.0_dp) .and. (abs(prior_nl(i)) < FILL)
      end do
      if (any(nl)) then
        ncnl = count(nl)
        allocate(c_nl(ncnl), rn_(ncnl))
        in_ = 0
        do i = 1, nc
          if (.not. nl(i)) cycle
          in_ = in_ + 1
          an(cols(i)) = tgt(i)
          c_nl(in_) = cols(i)
          rn_(in_) = tgt(i) / prior_nl(i)
        end do
        call check(nf90_put_var(ncid, vn, an), 'put H2OSNO_NO_LAYERS')
        call scale_var(ncid, 'SNOW_DEPTH', c_nl, rn_, ncnl)
      end if
    end if

    if (any(act)) then
      nact = count(act)
      allocate(c_act(nact), ratio(nact))
      ia = 0
      do i = 1, nc
        if (.not. act(i)) cycle
        ia = ia + 1
        c_act(ia) = cols(i)
        ratio(ia) = tgt(i) / lsum(i)
        do l = 1, NSNO
          if (lv(l, i)) then
            liq_s(l, cols(i)) = lc(l, i) * ratio(ia)
          else
            liq_s(l, cols(i)) = lc(l, i)
          end if
          if (iv(l, i)) then
            ice_s(l, cols(i)) = ic(l, i) * ratio(ia)
          else
            ice_s(l, cols(i)) = ic(l, i)
          end if
        end do
      end do
      call check(nf90_put_var(ncid, vl, liq_s, start=(/1,1/), count=(/NSNO,NCOL/)), 'put snow liq')
      call check(nf90_put_var(ncid, vi, ice_s, start=(/1,1/), count=(/NSNO,NCOL/)), 'put snow ice')
      call scale_var(ncid, 'DZSNO',      c_act, ratio, nact)
      call scale_var(ncid, 'ZSNO',       c_act, ratio, nact)
      call scale_var(ncid, 'ZISNO',      c_act, ratio, nact)
      call scale_var(ncid, 'SNOW_DEPTH', c_act, ratio, nact)
    end if

    if (any(act .or. nl)) then
      allocate(a(NCOL))
      call check(nf90_inq_varid(ncid, 'H2OSNO', vh), 'H2OSNO')
      call check(nf90_get_var(ncid, vh, a), 'get H2OSNO')
      do i = 1, nc
        if (act(i) .or. nl(i)) a(cols(i)) = tgt(i)
      end do
      call check(nf90_put_var(ncid, vh, a), 'put H2OSNO')
    end if
  end subroutine repartition_member

  ! write one member's analysis into its restart file
  subroutine apply_member(fname, liq_slab, tsoi_slab, sm_do, ne, ec, lnew, tnew, nsw, sw_cols, spm)
    character(len=*), intent(in) :: fname
    real(dp), intent(inout) :: liq_slab(:,:), tsoi_slab(:,:)      ! (NSOIL, NCOL) as read
    logical, intent(in) :: sm_do
    integer, intent(in) :: ne, nsw, ec(:), sw_cols(:)
    real(dp), intent(in) :: lnew(:,:), tnew(:,:), spm(:)
    integer :: ncid, vid, n
    if (.not. (sm_do .or. nsw > 0)) return                        ! nothing changed: leave file alone
    call check(nf90_open(trim(fname), nf90_write, ncid), 'open (r+) '//trim(fname))
    if (sm_do) then
      do n = 1, ne
        liq_slab(:, ec(n)) = lnew(:, n)
      end do
      call check(nf90_inq_varid(ncid, 'H2OSOI_LIQ', vid), 'H2OSOI_LIQ')
      call check(nf90_put_var(ncid, vid, liq_slab, start=(/NSNO+1,1/), count=(/NSOIL,NCOL/)), 'put H2OSOI_LIQ')
      if (UPDATE_TEMP) then
        do n = 1, ne
          tsoi_slab(:, ec(n)) = tnew(:, n)
        end do
        call check(nf90_inq_varid(ncid, 'T_SOISNO', vid), 'T_SOISNO')
        call check(nf90_put_var(ncid, vid, tsoi_slab, start=(/NSNO+1,1/), count=(/NSOIL,NCOL/)), 'put T_SOISNO')
      end if
    end if
    if (nsw > 0) call repartition_member(ncid, sw_cols, nsw, spm)
    call check(nf90_close(ncid), 'close '//trim(fname))
  end subroutine apply_member

  subroutine write_innovation(rdate, ng, innov_sm, innov_swe)
    character(len=*), intent(in) :: rdate
    integer, intent(in) :: ng
    real(dp), intent(in) :: innov_sm(ng), innov_swe(ng)
    character(len=128) :: nm
    character(len=600) :: path
    integer :: ncid, d_row, d_col, v1, v2
    nm = 'Innovation-'//trim(rdate)//'.nc'
    path = path_join(DIR, nm)
    call check(nf90_create(trim(path), ior(nf90_clobber, nf90_netcdf4), ncid), 'create '//trim(path))
    call check(nf90_def_dim(ncid, 'row', ng, d_row), 'def row')
    call check(nf90_def_dim(ncid, 'col', 1, d_col), 'def col')
    ! Python dims ('row','col')  ==  Fortran dimids (col,row)
    call check(nf90_def_var(ncid, 'innovation',     nf90_double, (/d_col, d_row/), v1), 'def innovation')
    call check(nf90_def_var(ncid, 'innovation_swe', nf90_double, (/d_col, d_row/), v2), 'def innovation_swe')
    call check(nf90_enddef(ncid), 'enddef')
    call check(nf90_put_var(ncid, v1, reshape(innov_sm,  (/1, ng/))), 'put innovation')
    call check(nf90_put_var(ncid, v2, reshape(innov_swe, (/1, ng/))), 'put innovation_swe')
    call check(nf90_close(ncid), 'close innovation')
  end subroutine write_innovation

  ! ================================ driver ====================================
  subroutine sm_da_s2s(rdate, ens, infl)
    character(len=*), intent(in) :: rdate
    integer, intent(in) :: ens
    real(dp), intent(in) :: infl

    character(len=600) :: fname
    integer :: ierr, ncid, ng, nlon, nlon_rst, m, j, nmy, owner, stat, nd_ref, nlon_ref, dimid, ne, nsw
    logical :: have_obs, have_sm, have_swe_obs, has_swe, sm_do
    real(dp), allocatable :: y_sm(:), y_swe(:)
    real(dp), allocatable :: liq_loc(:,:,:), ice_loc(:,:,:), tsoi_loc(:,:,:), swe_loc(:,:)
    real(dp), allocatable :: liq(:,:,:), ice(:,:,:), tsoi(:,:,:), swe(:,:)
    real(dp), allocatable :: t1(:,:), t2(:,:), t3(:,:), t4(:)
    real(dp), allocatable :: liq_new(:,:,:), t_new(:,:,:), s_post(:,:), innov_sm(:), innov_swe(:)
    real(dp), allocatable :: lnew(:,:), tnew(:,:), spm(:)
    integer, allocatable :: ec(:), sw_cols(:)

    if (myrank == 0) then
      do m = 1, ens
        print '(a)', trim(member_file(rdate, m))
      end do
    end if

    ! ---- layout / sizes from member 1 (cheap, read-only; every rank does it) ----
    fname = member_file(rdate, 1)
    call check(nf90_open(trim(fname), nf90_nowrite, ncid), 'open '//trim(fname))
    call configure_layout(ncid)
    call get_ncol(ncid)
    has_swe = var_exists(ncid, 'H2OSNO')
    nlon_rst = -1
    stat = nf90_inq_dimid(ncid, 'lon', dimid)
    if (stat == nf90_noerr) call check(nf90_inquire_dimension(ncid, dimid, len=nlon_rst), 'lon dimension')
    call check(nf90_close(ncid), 'close')

    ! ---- observations: read on rank 0 ----
    have_obs = .false.; have_sm = .false.; have_swe_obs = .false.; ng = 0
    if (myrank == 0) then
      call read_obs(rdate, have_sm, have_swe_obs, y_sm, y_swe, ng, nd_ref, nlon_ref)
      have_obs = have_sm .or. have_swe_obs
    end if
    call MPI_Bcast(have_obs, 1, MPI_LOGICAL, 0, MPI_COMM_WORLD, ierr)
    if (.not. have_obs) then
      if (myrank == 0) print '(a,a,a)', 'No observations for ', trim(rdate), '; restarts left unchanged.'
      return
    end if

    ! ---- column metadata (rank 0) ----
    if (myrank == 0) then
      if (nd_ref == 2) then
        nlon = nlon_ref
      else
        nlon = nlon_rst
      end if
      fname = member_file(rdate, 1)
      call check(nf90_open(trim(fname), nf90_nowrite, ncid), 'open '//trim(fname))
      call read_column_meta(ncid, nlon, ng)
      call check(nf90_close(ncid), 'close')
    end if

    ! ---- parallel read of my members ----
    nmy = 0
    do m = myrank + 1, ens, nproc
      nmy = nmy + 1
    end do
    allocate(liq_loc(NSOIL, NCOL, nmy), ice_loc(NSOIL, NCOL, nmy), tsoi_loc(NSOIL, NCOL, nmy), swe_loc(NCOL, nmy))
    j = 0
    do m = myrank + 1, ens, nproc
      j = j + 1
      call read_member(member_file(rdate, m), liq_loc(:,:,j), ice_loc(:,:,j), tsoi_loc(:,:,j), swe_loc(:,j))
    end do

    ! ---- gather all members on rank 0: liq(k, l, c) = member k, layer l, column c ----
    if (myrank == 0) then
      allocate(liq(ens, NSOIL, NCOL), ice(ens, NSOIL, NCOL), tsoi(ens, NSOIL, NCOL))
      if (has_swe) then
        allocate(swe(ens, NCOL))
      else
        allocate(swe(ens, 0))
      end if
      allocate(t1(NSOIL, NCOL), t2(NSOIL, NCOL), t3(NSOIL, NCOL), t4(NCOL))
      do m = 1, ens
        owner = mod(m - 1, nproc)
        if (owner == 0) then
          j = (m - 1) / nproc + 1
          liq(m, :, :)  = liq_loc(:, :, j)
          ice(m, :, :)  = ice_loc(:, :, j)
          tsoi(m, :, :) = tsoi_loc(:, :, j)
          if (has_swe) swe(m, :) = swe_loc(:, j)
        else
          call MPI_Recv(t1, NSOIL*NCOL, MPI_DOUBLE_PRECISION, owner, 10*m+1, MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
          call MPI_Recv(t2, NSOIL*NCOL, MPI_DOUBLE_PRECISION, owner, 10*m+2, MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
          call MPI_Recv(t3, NSOIL*NCOL, MPI_DOUBLE_PRECISION, owner, 10*m+3, MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
          liq(m, :, :)  = t1
          ice(m, :, :)  = t2
          tsoi(m, :, :) = t3
          if (has_swe) then
            call MPI_Recv(t4, NCOL, MPI_DOUBLE_PRECISION, owner, 10*m+4, MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
            swe(m, :) = t4
          end if
        end if
      end do
      deallocate(t1, t2, t3, t4)
    else
      j = 0
      do m = myrank + 1, ens, nproc
        j = j + 1
        call MPI_Send(liq_loc(:,:,j),  NSOIL*NCOL, MPI_DOUBLE_PRECISION, 0, 10*m+1, MPI_COMM_WORLD, ierr)
        call MPI_Send(ice_loc(:,:,j),  NSOIL*NCOL, MPI_DOUBLE_PRECISION, 0, 10*m+2, MPI_COMM_WORLD, ierr)
        call MPI_Send(tsoi_loc(:,:,j), NSOIL*NCOL, MPI_DOUBLE_PRECISION, 0, 10*m+3, MPI_COMM_WORLD, ierr)
        if (has_swe) call MPI_Send(swe_loc(:,j), NCOL, MPI_DOUBLE_PRECISION, 0, 10*m+4, MPI_COMM_WORLD, ierr)
      end do
    end if
    deallocate(ice_loc)

    ! ---- analysis on rank 0 ----
    ne = 0; nsw = 0; sm_do = .false.
    if (myrank == 0) then
      call analysis_root(rdate, ens, infl, ng, liq, ice, tsoi, swe, has_swe, have_sm, y_sm, have_swe_obs, y_swe, &
                         sm_do, ne, ec, liq_new, t_new, nsw, sw_cols, s_post, innov_sm, innov_swe)
      deallocate(liq, ice, tsoi, swe)
    end if

    ! ---- what is to be written (all ranks need to know) ----
    call MPI_Bcast(sm_do, 1, MPI_LOGICAL, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(ne,    1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(nsw,   1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
    if (myrank /= 0) allocate(ec(ne), sw_cols(nsw))
    if (ne  > 0) call MPI_Bcast(ec,      ne,  MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
    if (nsw > 0) call MPI_Bcast(sw_cols, nsw, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)

    ! ---- parallel write of my members ----
    if (myrank == 0) then
      do m = 1, ens
        owner = mod(m - 1, nproc)
        if (owner == 0) cycle
        if (sm_do) call MPI_Send(liq_new(:,:,m), NSOIL*ne, MPI_DOUBLE_PRECISION, owner, 10*m+5, MPI_COMM_WORLD, ierr)
        if (sm_do .and. UPDATE_TEMP) &
          call MPI_Send(t_new(:,:,m), NSOIL*ne, MPI_DOUBLE_PRECISION, owner, 10*m+6, MPI_COMM_WORLD, ierr)
        if (nsw > 0) call MPI_Send(s_post(:,m), nsw, MPI_DOUBLE_PRECISION, owner, 10*m+7, MPI_COMM_WORLD, ierr)
      end do
      j = 0
      do m = 1, ens, nproc
        j = j + 1
        if (sm_do) then
          if (UPDATE_TEMP) then
            call apply_member(member_file(rdate, m), liq_loc(:,:,j), tsoi_loc(:,:,j), sm_do, ne, ec, &
                              liq_new(:,:,m), t_new(:,:,m), nsw, sw_cols, s_post(:,m))
          else
            call apply_member(member_file(rdate, m), liq_loc(:,:,j), tsoi_loc(:,:,j), sm_do, ne, ec, &
                              liq_new(:,:,m), liq_new(:,:,m), nsw, sw_cols, s_post(:,m))
          end if
        else
          allocate(lnew(NSOIL, 0), tnew(NSOIL, 0))
          call apply_member(member_file(rdate, m), liq_loc(:,:,j), tsoi_loc(:,:,j), sm_do, ne, ec, &
                            lnew, tnew, nsw, sw_cols, s_post(:,m))
          deallocate(lnew, tnew)
        end if
      end do
    else
      allocate(lnew(NSOIL, ne), tnew(NSOIL, ne), spm(nsw))
      j = 0
      do m = myrank + 1, ens, nproc
        j = j + 1
        if (sm_do) call MPI_Recv(lnew, NSOIL*ne, MPI_DOUBLE_PRECISION, 0, 10*m+5, MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
        if (sm_do .and. UPDATE_TEMP) &
          call MPI_Recv(tnew, NSOIL*ne, MPI_DOUBLE_PRECISION, 0, 10*m+6, MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
        if (nsw > 0) call MPI_Recv(spm, nsw, MPI_DOUBLE_PRECISION, 0, 10*m+7, MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
        call apply_member(member_file(rdate, m), liq_loc(:,:,j), tsoi_loc(:,:,j), sm_do, ne, ec, &
                          lnew, tnew, nsw, sw_cols, spm)
      end do
    end if

    if (myrank == 0) call write_innovation(rdate, ng, innov_sm, innov_swe)
    call MPI_Barrier(MPI_COMM_WORLD, ierr)
  end subroutine sm_da_s2s

  subroutine read_member(fname, liq_m, ice_m, tsoi_m, swe_m)
    character(len=*), intent(in) :: fname
    real(dp), intent(out) :: liq_m(:,:), ice_m(:,:), tsoi_m(:,:), swe_m(:)
    integer :: ncid, vid
    call check(nf90_open(trim(fname), nf90_nowrite, ncid), 'open '//trim(fname))
    call check(nf90_inq_varid(ncid, 'H2OSOI_LIQ', vid), 'H2OSOI_LIQ')
    call check(nf90_get_var(ncid, vid, liq_m, start=(/NSNO+1,1/), count=(/NSOIL,NCOL/)), 'get H2OSOI_LIQ')
    call check(nf90_inq_varid(ncid, 'H2OSOI_ICE', vid), 'H2OSOI_ICE')
    call check(nf90_get_var(ncid, vid, ice_m, start=(/NSNO+1,1/), count=(/NSOIL,NCOL/)), 'get H2OSOI_ICE')
    call check(nf90_inq_varid(ncid, 'T_SOISNO', vid), 'T_SOISNO')
    call check(nf90_get_var(ncid, vid, tsoi_m, start=(/NSNO+1,1/), count=(/NSOIL,NCOL/)), 'get T_SOISNO')
    if (nf90_inq_varid(ncid, 'H2OSNO', vid) == nf90_noerr) then
      call check(nf90_get_var(ncid, vid, swe_m), 'get H2OSNO')
    end if
    call check(nf90_close(ncid), 'close '//trim(fname))
  end subroutine read_member

end module sm_da_mod


program sm_da_s2s_main
  use mpi
  use sm_da_mod
  implicit none
  integer :: ierr, ens
  real(dp) :: infl
  character(len=64) :: a1, a2, a3

  call MPI_Init(ierr)
  call MPI_Comm_rank(MPI_COMM_WORLD, myrank, ierr)
  call MPI_Comm_size(MPI_COMM_WORLD, nproc, ierr)

  if (command_argument_count() >= 3) then
    call get_command_argument(1, a1)
    call get_command_argument(2, a2)
    call get_command_argument(3, a3)
    read(a2, *) ens
    read(a3, *) infl
    call sm_da_s2s(trim(a1), ens, infl)
  end if

  call MPI_Finalize(ierr)
end program sm_da_s2s_main

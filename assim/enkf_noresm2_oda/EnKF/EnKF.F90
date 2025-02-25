! File:          EnKF.F90
!
! Created:       ???
!
! Last modified: 20/04/2010
!
! Purpose:       Main program for EnKF analysis
!
! Description:   The workflow is as follows:
!                -- read model parameters
!                -- read obs
!                -- conduct necessary pre-processing of obs (superobing)
!                -- calculate ensemble observations
!                -- calculate X5
!                -- update the ensemble
!
! Modifications:
!                15/09/2014 YW: Coupling automatically layer thicknesses to preserve 
!                  the non-negativity of DP. The list of modified files is as follows:
!                  -- distribute.F90
!                  -- m_local_analysis.F90                              
!                28/10/2011 FC: The code is adapted to work with micom
!                20/9/2011 PS:
!                  Modified code to allow individual inflations for each of
!                  `NFIELD' fields updated in a batch - thanks to Ehouarn Simon
!                  for spotting this inconsistency
!                6/8/2010 PS:
!                  Small changes in calls to calc_X5() and update_fields() to
!                  reflect changes in interfaces.
!                6/7/2010 PS:
!                  Moved point output to a separate module m_point2nc.F90
!                25/5/2010 PS:
!                  Added inflation as a 4th command line argument
!                20/5/2010 PS:
!                  Set NFIELD = 4. This requires 4 GB per node in TOPAZ and
!                  "medium" memory model on Hexagon (a single allocation for a
!                   variable over 2GB)
!                20/4/2010 PS:
!                  Set NFIELD = 4. This will require 2 GB per node in TOPAZ.
!                  Thanks to Alok Gupta for hinting this possibility.
!                10/4/2010 PS:
!                  Moved variable `field' from real(8) to real(4);
!                  set NFIELD = 2.
!                Prior history:
!                  Not documented.

program EnKF
#if defined(QMPI)
  use qmpi
#else
  use qmpi_fake
#endif
  use m_parameters
  use distribute
  use mod_measurement
  use m_get_micom_nrens
  use m_get_micom_grid
  use m_get_micom_dim
  use m_obs
  use m_local_analysis
  use m_prep_4_EnKF
  use m_set_random_seed2
  use m_get_micom_fld
  use m_put_micom_fld
  use mod_analysisfields
  use m_parse_blkdat
  use m_random
  use m_point2nc
  use netcdf
  use nfw_mod
  implicit none

  character(*), parameter :: ENKF_VERSION = "2.11"

  integer, external :: iargc

  ! NFIELD is the number of fields (x N) passed for the update during a call to
  ! update_fields(). In TOPAZ4 NFIELD = 2 if there is 1 GB of RAM per node, and
  ! NFIELD = 4 if there are 2 GB of RAM. Higher value of NFIELD reduces the
  ! number of times X5tmp.uf is read from disk, which is the main bottleneck
  ! for the analysis time right now.
  !
  integer, parameter :: NFIELD = 53

  character(512) :: options

  integer :: nrens
  real, allocatable, dimension(:,:) :: modlon, modlat, depths, readfld, readfld2
  real, allocatable, dimension(:,:) :: S ! ensemble observations HE
  real, allocatable, dimension(:)   :: d ! d - Hx

  integer k, m
#ifdef FAST
  integer k2 
#endif

  ! "New" variables used in the parallelization 
  integer, dimension(:,:), allocatable :: nlobs_array
  real(4), allocatable :: fld(:,:),dpfld(:,:),fld_ave(:),nb_ave(:)
  real(8) rtc, time0, time1, time2

  ! Additional fields
  character(len=3) :: cmem
  character(len=80) :: memfile
  integer :: fieldcounter

  character(100) :: text_string

  real :: rdummy
  integer :: idm, jdm, kdm
  integer :: i

  real :: mindx
  real :: meandx
  integer :: m1, m2, nfields
  real :: infls(NFIELD)
  logical :: isdp(NFIELD)

#if defined(QMPI)
  call start_mpi()
#endif

  ! Read the characteristics of the assimilation to be carried out.

  if (iargc() /= 1) then
     print *, 'Usage: EnKF <parameter file>'
     print *, '       EnKF -h'
     print *, 'Options:'
     print *, '  -h -- describe parameter fie format'
     call stop_mpi()
  else
     call getarg(1, options)
     if (trim(options) == "-h") then
        call prm_describe()
        call stop_mpi()
     end if
  end if

  if (master) then
     print *
     print '(a, a)', ' EnKF version ', ENKF_VERSION
     print *
  end if

  call prm_read()
  call prm_print()

  ! get model dimensions
  !29/05/2015 Add reading of kdm
  call get_micom_dim(idm,jdm,kdm)
  if (master) then
     print *, 'read dimension idm,jdm,kdm :',idm,jdm,kdm
  end if
  allocate(modlon(idm,jdm))
  allocate(readfld(idm,jdm))
  allocate(readfld2(idm,jdm))
  allocate(modlat(idm,jdm))
  allocate(depths(idm,jdm))
  allocate(nlobs_array(idm, jdm))
  ! get model grid
  !
  call get_micom_grid(modlon, modlat, depths, mindx, meandx, idm, jdm)
  if (master) then
     print *,'MEAN grid size and min from scpx/scpy :',meandx,mindx
  end if

  ! set a variable random seed
  !
  !call set_random_seed3

  ! initialise point output
  !
  call p2nc_init

  time0 = rtc()

  ! read measurements
  !
  if (master) then
     print *, 'EnKF: reading observations'
  end if
  call obs_readobs
  if (master) then
     print '(a, i6)', '   # of obs = ', nobs
     print '(a, a, a, e10.3, a, e10.3)', '   first obs = "', trim(obs(1) % id),&
          '", v = ', obs(1) % d, ', var = ', obs(1) % var
     print '(a, a, a, e10.3, a, e10.3)', '   last obs = "', trim(obs(nobs) % id),&
          '", v = ', obs(nobs) % d, ', var = ', obs(nobs) % var
  end if
  if (master) then
     print *
  end if

  ! read ensemble size and store in A
  !
  nrens = get_micom_nrens(idm, jdm)
  if (master) then
     print '(a, i5, a)', ' EnKF: ', nrens, ' ensemble members found'
  end if
  if (ENSSIZE > 0) then
     ENSSIZE = min(nrens, ENSSIZE)
  else
     ENSSIZE = nrens
  end if
  if (master) then
     print '(a, i4, a)', ' EnKF: ', ENSSIZE, ' ensemble members used'
  end if
  if (master) then
     print *
  end if

  ! PS - preprocess the obs using the information about the ensemble fields
  ! here (if necessary), before running prep_4_EnKF(). This is necessary e.g.
  ! for assimilating in-situ data because of the dynamic vertical geometry in
  ! HYCOM
  !
  call obs_prepareobs

  allocate(S(nobs, ENSSIZE), d(nobs))
  call prep_4_EnKF(ENSSIZE, d, S, depths, meandx / 1000.0, idm, jdm, kdm)
  if (master) then
     print *, 'EnKF: finished initialisation, time = ',  rtc() - time0
  end if

  ! (no parallelization was required before this point)

  time1 = rtc()

  allocate(X5(ENSSIZE, ENSSIZE, idm))
  allocate(X5check(ENSSIZE, ENSSIZE, idm))
  call calc_X5(ENSSIZE, modlon, modlat, depths, mindx, meandx, d, S,&
       LOCRAD, RFACTOR2, nlobs_array, idm, jdm)
  deallocate(d, S, X5check)
  if (master) then
     print *, 'EnKF: finished calculation of X5, time = ', rtc() - time0
  end if

  allocate(fld(idm * jdm, ENSSIZE * NFIELD))

#if defined(QMPI)
  call barrier()
#endif

  ! get fieldnames and fieldlevels
  !
  call get_analysisfields()

  call distribute_iterations_field(numfields,fieldnames,fieldlevel)
#if defined(QMPI)
  call barrier() !KAL - just for "niceness" of output
#endif
  time2 = rtc()
  do m1 = my_first_iteration, my_last_iteration, NFIELD
     m2 = min(my_last_iteration, m1 + NFIELD - 1)
     nfields = m2 - m1 + 1

     do m = m1, m2
!29/05/2015 fanf add 3 digit to qmpi
         print '(a, i3, a, i3, a, a6, a, i3, a, f11.0)',&
              "I am ", qmpi_proc_num, ', m = ', m, ", field = ",&
              fieldnames(m), ", k = ", fieldlevel(m), ", time = ",&
              rtc() - time2
        if ( trim(fieldnames(m)) /= 'dp' ) then
           if (fieldlevel(m)>=3) then    
              allocate(dpfld(idm * jdm, ENSSIZE))
              allocate(fld_ave(idm * jdm))
              allocate(nb_ave(idm * jdm))
              fld_ave(:)=0
              nb_ave(:)=0
              dpfld(:,:)=0
           end if !field level not in the mixed layer
        endif ! not dp
#ifdef FAST
       do k2 = 1, ENSSIZE
           k = mod(k2 + fieldlevel(m) -1,ENSSIZE) + 1
#else
       do k = 1, ENSSIZE
#endif
           write(cmem, '(i3.3)') k
           memfile = 'forecast' // cmem
           ! reshaping and conversion to real(4)
           call get_micom_fld_new(trim(memfile), readfld, fieldnames(m),&
                fieldlevel(m), 1, idm, jdm)
           fld(:, ENSSIZE * (m - m1) + k) = reshape(readfld, (/idm * jdm/))
           if ( trim(fieldnames(m)) /= 'dp' ) then
              !Do not apply fix in the ML dp=1..2
              if (fieldlevel(m)>=3) then    
                 call get_micom_fld_new(trim(memfile), readfld2, 'dp',&
                      fieldlevel(m), 1, idm, jdm)
                 ! reshaping and conversion to real(4)
                 dpfld(:, k) = reshape(readfld2, (/idm * jdm/))
                 !10 cm
                 where(dpfld(:, k)>9806.)
                    fld_ave=fld_ave+reshape(readfld, (/idm * jdm/))
                    nb_ave=nb_ave+1
                 endwhere
              endif !field level not in the mixed layer
           end if ! not dp
        end do !ens size
        !filled up empty layer with ensemble average value
        if ( trim(fieldnames(m)) /= 'dp' ) then
           if (fieldlevel(m)>=3) then    
#ifdef FAST
              do k2 = 1, ENSSIZE
                 k = mod(k2 + fieldlevel(m) -1,ENSSIZE) + 1
#else
              do k = 1, ENSSIZE
#endif
                 do i = 1, idm*jdm
                    !10 cm
                    if( dpfld(i, k)<9806. .and. nb_ave(i)>0 ) then
                       !print *,'Fanf',i,k,nb_ave(i),fld_ave(i),fld(i, ENSSIZE * (m - m1) + k),fld_ave(i)/nb_ave(i),fieldlevel(m)
                       fld(i, ENSSIZE * (m - m1) + k)= fld_ave(i)/nb_ave(i);
                    endif
                 enddo
              enddo
              deallocate(dpfld,fld_ave,nb_ave)
           end if !field level not in the mixed layer
        endif ! not dp
        call p2nc_storeforecast(idm, jdm, ENSSIZE, numfields, m, fld(:, ENSSIZE * (m - m1) + 1 : ENSSIZE * (m + 1 - m1)))
        infls(m - m1 + 1) = prm_getinfl(trim(fieldnames(m)));
        isdp(m - m1 + 1) = (trim(fieldnames(m)) == 'dp' )
     end do

     call update_fields(idm, jdm, ENSSIZE, nfields, nlobs_array, depths,&
          fld(1,1), infls, isdp)

     do m = m1, m2
        fieldcounter = (m - my_first_iteration) + 1
#ifdef FAST
        do k2 = 1, ENSSIZE
           k = mod(k2 + fieldlevel(m) -1,ENSSIZE) + 1
#else
        do k = 1, ENSSIZE
#endif
           write(cmem,'(i3.3)') k
           memfile = 'forecast' // cmem
!           memfile = 'analysis' // cmem
           ! reshaping and conversion to real(8)
           readfld = reshape(fld(:, ENSSIZE * (m - m1) + k), (/idm, jdm/))
           call put_micom_fld(trim(memfile), readfld, k,&
                fieldnames(m), fieldlevel(m), 1, idm, jdm)
        end do
     end do
  end do
  deallocate(X5)
  deallocate(fld)

  call p2nc_writeforecast

  ! Barrier only necessary for timings
#if defined(QMPI)
  call barrier()
#endif
  if (master) then
     print *, 'EnKF: time for initialization = ', time1 - time0
     print *, 'EnKF: time for X5 calculation = ', time2 - time1
     print *, 'EnKF: time for ensemble update = ', rtc() - time2
     print *, 'EnKF: total time = ', rtc() - time0
  end if
#if defined(QMPI)
  call barrier()
#endif
  print *, 'EnKF: Finished'
  call stop_mpi()
end program EnKF

#if defined(_G95_)
! not tested! - PS
!
real function rtc()
  integer :: c

  call system_clock(count=c)
  rtc = dfloat(c)
end function rtc
#endif

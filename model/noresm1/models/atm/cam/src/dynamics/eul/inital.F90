module inital
!----------------------------------------------------------------------- 
! 
! Purpose:  CAM startup initial conditions module
!
!----------------------------------------------------------------------- 

   implicit none

   private   ! By default everything private to this module
!
! Public methods
!
   public cam_initial   ! Cam initialization (formally inital)

contains

!
!----------------------------------------------------------------------- 
!

subroutine cam_initial( dyn_in, dyn_out, nlfilename )

!----------------------------------------------------------------------- 
! 
! Purpose: 
! Define initial conditions for first run of case
! 
! Method: 
! 
! Author: 
! Original version:  CCM1
! Standardized:      L. Bath, June 1992
!                    T. Acker, March 1996
! Reviewed:          B. Boville, April 1996
!
!-----------------------------------------------------------------------
   use dyn_comp,             only: dyn_import_t, dyn_export_t, dyn_init
   use prognostics,          only: initialize_prognostics
   use phys_grid,            only: phys_grid_init
   use chem_surfvals,        only: chem_surfvals_init
   use camsrfexch_types,     only: atm2hub_alloc
   use scanslt,              only: scanslt_alloc
   use startup_initialconds, only: setup_initial, initial_conds, initial_file_get_id
   use ref_pres,             only: ref_pres_init


#if (defined SPMD)
   use spmd_dyn,             only: spmdbuf
#endif
!-----------------------------------------------------------------------
!
! Arguments
!
!  Arguments are not used in this dycore, included for compatibility
   type(dyn_import_t) :: dyn_in
   type(dyn_export_t) :: dyn_out
   character(len=*), intent(in) :: nlfilename

!---------------------------Local variables-----------------------------
!
!-----------------------------------------------------------------------
   call setup_initial()
   !
   ! Initialize ghg surface values before default initial distributions
   ! are set in inidat.
   call chem_surfvals_init()
   !
   call dyn_init(initial_file_get_id(), nlfilename)
   !
   !
   ! Initialize prognostics variables
   !
   call initialize_prognostics
   call scanslt_alloc()
   !
   ! Set commons
   !
   call initcom
   !
   ! Define physics data structures
   !
   call phys_grid_init
#if (defined SPMD)
   ! Allocate communication buffers for
   ! collective communications in realloc
   ! routines and in dp_coupling
   call spmdbuf ()
#endif

   ! Initialize physics grid reference pressures (needed by initialize_radbuffer)
   call ref_pres_init()

   call initial_conds( dyn_in )

end subroutine cam_initial

!
!----------------------------------------------------------------------- 
!

end module inital

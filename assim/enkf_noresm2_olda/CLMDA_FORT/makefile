MPI = YES
VPATH = .:TMP:../shared

include make.inc.betzy

SHELL = /bin/bash

PROGS = sm_da_s2s_mpi

# where the executable is put (same convention as the EnKF makefile: relative to ./TMP)
BINDIR = ../../..

all: $(PROGS)

SM_SRC_F90 = \
sm_da_s2s_mpi.f90

SM_OBJ = $(SM_SRC_F90:.f90=.o)

sm_da_s2s_mpi: $(SM_OBJ)
	@echo "->sm_da_s2s_mpi"
	@echo $(LD) $(LINKFLAGS) -o $(BINDIR)/sm_da_s2s_mpi $(SM_OBJ) $(LIBS)
	@cd ./TMP ; $(LD) $(LINKFLAGS) -o $(BINDIR)/sm_da_s2s_mpi $(SM_OBJ) $(LIBS)

$(SM_OBJ): makefile

clean:
	@rm -f TMP/*.*  $(BINDIR)/sm_da_s2s_mpi

# The source is plain free-form Fortran (no #ifdefs) and uses '//' for string concatenation,
# so it is NOT passed through $(CPP) (cpp would treat '//' as a comment).
%.o: %.f90
	@echo "  $*".f90
	@mkdir -p TMP
	@cd ./TMP ; $(CF90) -c $(FFLAGS) $(F90FLG) -o $*.o ../$<

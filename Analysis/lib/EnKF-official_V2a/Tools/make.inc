LIB_NETCDF= -L/local/netcdf/lib/ -lnetcdf -lnetcdff
LIB_LAPACK =

INCS = $(INC_NETCDF) $(INC_FFTW)
LIBS = -mkl=sequential $(LIB_LAPACK) $(LIB_NETCDF) $(LIB_FFTW)

ifeq ($(MPI),YES)
	CF90 = mpiifort
	CC = mpiicc
	PARO =
	CPPFLAGS = -DQMPI 
else
	CF90 = ifort
	CC = icc
	PAR0 = 
endif
CF77 = $(CF90)
LD = $(CF90) 
CPP = cpp -P -traditional-cpp

CPPARCH = -DIA32 -DFFTW -DNOMPIR8
CPPFLAGS += $(CPPARCH) -DF90_NOFLUSH

SIZEO = -r8
OPTO = #-fast -fastsse
ARCHO= -mcmodel=medium
INLO = -ip
DIVO = 
DEBUG_FLAGS = -g -traceback -fp-stack-check -w

# uncomment below for debugging and set MPI = NO in makefile
#CF90 = pgfortran
#	DEBUG_FLAGS = -g -Minform=inform
#	PAR0 =
#	OPTO = 
#	INC_NETCDF = -I/local/netcdf-3.6.2-pgi/include
#	LIB_NETCDF = /local/netcdf-3.6.2-pgi/lib/libnetcdf.a
#	INC_FFTW = -I/opt/fftw/3.2.2/include
#	LIB_FFTW = /opt/fftw/3.2.2/lib/libfftw3.a

FFLAGS = $(SIZEO) $(OPTO) $(ARCHO) $(PARO) $(INLO) $(DIVO) $(DEBUG_FLAGS) $(INCS)
CFLAGS = $(FFLAGS)
LINKFLAGS = $(SIZEO) $(OPTO) $(ARCHO) $(PARO) $(INLO) $(DIVO) $(DEBUG_FLAGS) 

# language-specific flags
#
F77FLG = -fixed
F90FLG = -free

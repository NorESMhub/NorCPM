MPI = NO
include ../make.inc

VPATH = ../:./:TMP

PROGS = fixenkf\
calculate_obs_error\
dump_spice\
prep_ens\
recompute_saln\
dump_pivot_SSH\
dump_pivot_SST\
ensave\
ensave_ice\
dump_pivot_EN4_to_micom\
dump_pivot_2c_to_micom

all: $(PROGS)

ENSAVE_OBJ = qmpi.o\
nfw.o\
p_ensave.o

ENSAVE_ICE_OBJ = qmpi.o\
nfw.o\
p_ensave_ice.o

CONSISTENCY_OBJ = qmpi.o\
mod_raw_io.o\
m_parse_blkdat.o\
m_put_mod_fld.o\
m_get_mod_grid.o\
m_get_mod_fld.o\
nfw.o\
p_consistency.o

DUMP_SPICE_OBJ = qmpi.o\
mod_spice.o\
nfw.o\
p_dump_spice.o

CALC_ERR_OBJ = qmpi.o\
nfw.o\
p_calculate_obs_error.o

DUMP_PIVOT_SSH_OBJ = qmpi.o\
nfw.o\
m_spherdist.o\
m_pivotp_micom.o\
m_get_micom_dim.o\
m_get_micom_grid.o\
p_dump_pivot_SSH.o

DUMP_PIVOT_SST_OBJ = qmpi.o\
nfw.o\
m_spherdist.o\
m_pivotp_micom.o\
m_get_micom_dim.o\
m_get_micom_grid.o\
p_dump_pivot_SST.o

DUMP_EN4_MICOM_OBJ = qmpi.o\
nfw.o\
m_spherdist.o\
m_pivotp_micom.o\
m_get_micom_dim.o\
m_get_micom_grid.o\
p_dump_pivot_EN4_to_micom.o

DUMP_2C_MICOM_OBJ = qmpi.o\
nfw.o\
m_spherdist.o\
m_pivotp_micom.o\
m_get_micom_dim.o\
m_get_micom_grid.o\
p_dump_pivot_2c_to_micom.o

RECOMPUTE_SALN_OBJ = qmpi.o\
mod_spice.o\
m_zeroin.o\
nfw.o\
p_recompute_saln.o

FIXMICOM_OBJ = qmpi.o\
nfw.o\
eosdat.o\
mod_eosfun.o\
p_fixenkf.o

FIXCICE_OBJ = qmpi.o\
nfw.o\
eosdat.o\
mod_eosfun.o\
distribute.o\
p_fixenkf_cice_mpi.o

PREP_ENS_OBJ = qmpi.o\
nfw.o\
eosdat.o\
mod_eosfun.o\
p_prepare_ensemble.o



TESTX4_SRC_F90 = qmpi.F90\
m_parse_blkdat.F90\
m_get_mod_nrens.F90\
testX4.F90


TESTX4_OBJ = $(TESTX4_SRC_F90:.F90=.o)

m_Generate_element_Si.o: m_parse_blkdat.o mod_measurement.o m_get_mod_fld.o m_insitu.o m_obs.o
m_insitu.o: nfw.o
m_get_mod_nrens.o: qmpi.o
m_obs.o : m_parameters.o m_uobs.o


$(CONSISTENCY_OBJ) $(FIXMICOM_OBJ) : MODEL.CPP makefile



calculate_obs_error: $(CALC_ERR_OBJ)
	   @echo "->calculate_obs_error"
		   @cd ./TMP ; $(LD) $(LINKFLAGS) -o ../calculate_obs_error $(CALC_ERR_OBJ)

ensave: $(ENSAVE_OBJ)
	@echo "->ensave"
	@cd ./TMP ; $(LD) $(LINKFLAGS) -o ../ensave $(ENSAVE_OBJ) 

ensave_ice: $(ENSAVE_ICE_OBJ)
	@echo "->ensave_ice"
	@cd ./TMP ; $(LD) $(LINKFLAGS) -o ../ensave_ice $(ENSAVE_ICE_OBJ) $(LIBS)

consistency: $(CONSISTENCY_OBJ)
	@echo "->consistency"
	@cd ./TMP ; $(LD) $(LINKFLAGS) -o ../consistency $(CONSISTENCY_OBJ) $(LIBS)

prep_ens: $(PREP_ENS_OBJ)
	@echo "->prep_ens"
	@cd ./TMP ; $(LD) $(LINKFLAGS) -o ../prep_ens $(PREP_ENS_OBJ)

dump_spice: $(DUMP_SPICE_OBJ)
	   @echo "->dump_spice"
	   @cd ./TMP ; $(LD) $(LINKFLAGS) -o ../dump_spice $(DUMP_SPICE_OBJ) $(LIBS)

dump_pivot_SST: $(DUMP_PIVOT_SST_OBJ)
	   @echo "->dump_pivot_SST"
	   @cd ./TMP ; $(LD) $(LINKFLAGS) -o ../dump_pivot_SST $(DUMP_PIVOT_SST_OBJ) $(LIBS)

dump_pivot_SSH: $(DUMP_PIVOT_SSH_OBJ)
	   @echo "->dump_pivot_SSH"
	   @cd ./TMP ; $(LD) $(LINKFLAGS) -o ../dump_pivot_SSH $(DUMP_PIVOT_SSH_OBJ) $(LIBS)

dump_pivot_EN4_to_micom: $(DUMP_EN4_MICOM_OBJ)
	@echo "->dump_pivot_EN4_to_micom"
	@cd ./TMP ; $(LD) $(LINKFLAGS) -o ../dump_pivot_EN4_to_micom $(DUMP_EN4_MICOM_OBJ) $(LIBS)

dump_pivot_2c_to_micom: $(DUMP_2C_MICOM_OBJ)
	@echo "->dump_pivot_2c_to_micom"
	@cd ./TMP ; $(LD) $(LINKFLAGS) -o ../dump_pivot_2c_to_micom $(DUMP_2C_MICOM_OBJ) $(LIBS)

recompute_saln: $(RECOMPUTE_SALN_OBJ)
	      @echo "->recompute_saln"
	      @cd ./TMP ; $(LD) $(LINKFLAGS) -o ../recompute_saln $(RECOMPUTE_SALN_OBJ) $(LIBS)

fixenkf: $(FIXMICOM_OBJ)
	@echo "->fixenkf"
	@cd ./TMP ; $(LD) $(LINKFLAGS) -o ../fixenkf $(FIXMICOM_OBJ)


fixenkf_cice: $(FIXCICE_OBJ)
	@echo "->fixenkf_cice"
	@cd ./TMP ; $(LD) $(LINKFLAGS) -o ../fixenkf_cice $(FIXCICE_OBJ) $(LIBS)

clean:
	@rm -f *.o *.mod TMP/*.* $(PROGS)

%.o: %.F90
	@echo "  $*".F90
	@rm -f ./TMP/$*.f90
	@cat MODEL.CPP $< | $(CPP) $(CPPFLAGS) > ./TMP/$*.f90
	@cd ./TMP; $(CF90) -c $(FFLAGS) $(F90FLG) -o $*.o $*.f90

%.o: %.F
	@echo "  $*".F
	@rm -f ./TMP/$*.f
	@cat MODEL.CPP $< | $(CPP) $(CPPFLAGS) > ./TMP/$*.f
	@cd ./TMP; $(CF77) -c $(FFLAGS) $(F77FLG) -o $*.o $*.f 

%.o: %.c
	@echo "  $*".c
	@cd ./TMP ; $(CC) -c $(CFLAGS) -o $*.o -I.. -I../.. ../../$*.c

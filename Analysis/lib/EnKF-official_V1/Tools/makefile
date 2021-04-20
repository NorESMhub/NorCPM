MPI = YES
include ../make.inc

SHELL = /bin/bash
VPATH = ..:.:TMP

PROGS = ensave calculate_obs_error calculate_monthly_SIT

all: $(PROGS)

ENSAVE_OBJ = qmpi.o\
distribute.o\
nfw.o\
p_ensave.o

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


CALC_SIT_OBJ = qmpi.o\
nfw.o\
p_calculate_monthly_SIT.o


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

DUMP_ICET_MICOM_OBJ =nfw.o\
m_spherdist.o\
m_pivotp_micom.o\
m_get_micom_dim.o\
m_get_micom_grid.o\
p_dump_pivot_ICET_to_micom.o

DUMP_2C_MICOM_OBJ = qmpi.o\
nfw.o\
m_spherdist.o\
m_pivotp_micom.o\
m_get_micom_dim.o\
m_get_micom_grid.o\
p_dump_pivot_2c_to_micom.o

DUMP_MICOM_EN4_OBJ = nfw.o\
m_spherdist.o\
m_pivotp_micom.o\
m_get_micom_dim.o\
m_get_micom_grid.o\
p_dump_pivot_micom_to_EN4.o

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

PREP_ENS_OBJ = qmpi.o\
nfw.o\
eosdat.o\
mod_eosfun.o\
p_prepare_ensemble.o

ENSSTAT_OBJ = qmpi.o\
nfw.o\
m_spherdist.o\
m_get_micom_grid.o\
m_get_micom_fld.o\
p_ensstat_point.o

TESTX4_SRC_F90 = qmpi.F90\
m_parse_blkdat.F90\
m_get_mod_nrens.F90\
testX4.F90


TESTX4_OBJ = $(TESTX4_SRC_F90:.F90=.o)

m_Generate_element_Si.o: m_parse_blkdat.o mod_measurement.o m_get_mod_fld.o m_insitu.o m_obs.o
m_insitu.o: nfw.o
m_get_mod_nrens.o: qmpi.o
m_obs.o : m_parameters.o m_uobs.o


$(CONSISTENCY_OBJ) $(FIXMICOM_OBJ) $(ENSAVE_OBJ) : MODEL.CPP makefile



calculate_obs_error: $(CALC_ERR_OBJ)
	   @echo "->calculate_obs_error"
		   @cd ./TMP ; $(LD) $(LINKFLAGS) -o ../calculate_obs_error $(CALC_ERR_OBJ) $(LIBS)

calculate_monthly_SIT: $(CALC_SIT_OBJ)
	   @echo "->calculate_monthly_SIT"
		   @cd ./TMP ; $(LD) $(LINKFLAGS) -o ../calculate_monthly_SIT $(CALC_SIT_OBJ) $(LIBS)

prep_obs: $(PREP_OBS_OBJ)
	@echo "->prep_obs"
	@echo $(LD) $(LINKFLAGS) -o ../prep_obs $(PREP_OBS_OBJ) $(LIBS)
	@cd ./TMP; $(LD) $(LINKFLAGS) -o ../prep_obs $(PREP_OBS_OBJ) $(LIBS)

$(PREP_OBS_OBJ): makefile MODEL.CPP



ensave: $(ENSAVE_OBJ)
	@echo "->ensave"
	@cd ./TMP ; $(LD) $(LINKFLAGS) -o ../ensave $(ENSAVE_OBJ) $(LIBS)

ensstat_point: $(ENSSTAT_OBJ)
	@echo "->ensstat_point"
	@cd ./TMP ; $(LD) $(LINKFLAGS) -o ../ensstat_point $(ENSSTAT_OBJ) $(LIBS)

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

dump_pivot_ICET_to_micom: $(DUMP_ICET_MICOM_OBJ)
	@echo "->dump_pivot_ICET_to_micom"
	@cd ./TMP ; $(LD) $(LINKFLAGS) -o ../dump_pivot_ICET_to_micom $(DUMP_ICET_MICOM_OBJ) $(LIBS)

dump_pivot_2c_to_micom: $(DUMP_2C_MICOM_OBJ)
	@echo "->dump_pivot_2c_to_micom"
	@cd ./TMP ; $(LD) $(LINKFLAGS) -o ../dump_pivot_2c_to_micom $(DUMP_2C_MICOM_OBJ) $(LIBS)

dump_pivot_micom_to_EN4: $(DUMP_MICOM_EN4_OBJ)
	@echo "->dump_pivot_micom_to_EN4"
	@cd ./TMP ; $(LD) $(LINKFLAGS) -o ../dump_pivot_micom_to_EN4 $(DUMP_MICOM_EN4_OBJ) $(LIBS)

recompute_saln: $(RECOMPUTE_SALN_OBJ)
	      @echo "->recompute_saln"
	      @cd ./TMP ; $(LD) $(LINKFLAGS) -o ../recompute_saln $(RECOMPUTE_SALN_OBJ) $(LIBS)

fixenkf: $(FIXMICOM_OBJ)
	@echo "->fixenkf"
	@cd ./TMP ; $(LD) $(LINKFLAGS) -o ../fixenkf $(FIXMICOM_OBJ)


clean:
	@rm -f TMP/*.f  TMP/*.o TMP/*.f90 TMP/*.h TMP/*.mod $(PROGS)



%.o: %.F90
	@echo "  $*".F90
	@rm -f ./TMP/$*.f90
	@cat MODEL.CPP $< | $(CPP) $(CPPFLAGS) > ./TMP/$*.f90
	@cd ./TMP; $(CF90) -c $(FFLAGS) $(F90FLG) -o $*.o $*.f90

%.o: %.F
	@echo "  $*".F
	@rm -f ./TMP/$*.f
	@cat MODEL.CPP $< | $(CPP) $(CPPFLAGS) > ./TMP/$*.f
	@cd ./TMP; $(CF77) -c $(FFLAGS) $(F77FLG) -o $*.o $*.f 2> /dev/null


%.o: %.c
	@echo "  $*".c
	@cd ./TMP ; $(CC) -c $(CFLAGS) -o $*.o -I.. -I../.. ../../$*.c

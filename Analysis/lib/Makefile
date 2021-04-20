

## This make file compile EnKF and prep_obs with anomaly and full field versions.
## And also ensave.
## Copy execuble binaries to ./WORKSHARED/bin after compile.

BINDIR=WORKSHARED/bin
ENKF_SRCDIR=EnKF-official_V1
PREPOBS_SRCDIR=EnKF-official_V1/Prep_Routines
ENSAVE_SRCDIR=EnKF-official_V1/Tools
MICOMINIT_SRCDIR=micom_ensemble_init/build
MODELCPP=MODEL.CPP
SET_ANO=sed -i 's/^.*ANOMALY/\#define ANOMALY/'
SET_FF=sed -i 's/^.*ANOMALY/\#undef ANOMALY/'
GRID_TYPE=
ENKF_VERSION=1
GRID_TYPE=tp
defult: EnKF_ff EnKF_ano prep_obs_ff prep_obs_ano ensave micom_ensemble_bp micom_ensemble_tp

ensave:
	make -C $(ENSAVE_SRCDIR) clean
	make -C $(ENSAVE_SRCDIR)
	cp $(ENSAVE_SRCDIR)/ensave $(BINDIR)/ensave

prep_obs_ano:
	$(SET_ANO)  $(PREPOBS_SRCDIR)/$(MODELCPP)
	make -C $(PREPOBS_SRCDIR)
	cp $(PREPOBS_SRCDIR)/prep_obs $(BINDIR)/prep_obs_anom_V${ENKF_VERSION}
prep_obs_ff:
	$(SET_FF)  $(PREPOBS_SRCDIR)/$(MODELCPP)
	make -C $(PREPOBS_SRCDIR)
	cp $(PREPOBS_SRCDIR)/prep_obs $(BINDIR)/prep_obs_ff_V${ENKF_VERSION}

EnKF_ano:
	$(SET_ANO)  $(ENKF_SRCDIR)/$(MODELCPP)
	make -C $(ENKF_SRCDIR)
	cp $(ENKF_SRCDIR)/EnKF $(BINDIR)/EnKF_$(GRID_TYPE)_anom_V${ENKF_VERSION}
EnKF_ff:
	$(SET_FF)  $(ENKF_SRCDIR)/$(MODELCPP)
	make -C $(ENKF_SRCDIR)
	cp $(ENKF_SRCDIR)/EnKF $(BINDIR)/EnKF_$(GRID_TYPE)_ff_V${ENKF_VERSION}

micom_ensemble_bp:
	## bipolar grid
	## -DSKIPVAR skips regc, rrm0 and rbdmc2 reading and writing.
	make -C $(MICOMINIT_SRCDIR) clean
	sed -i -e's/^CPPDEFS.*/CPPDEFS = -DMPI -DSKIPVAR/' $(MICOMINIT_SRCDIR)/Makefile
	sed -i -e's:data nreg.*:data nreg /1/:' $(MICOMINIT_SRCDIR)/../src/dimensions.F
	make -C $(MICOMINIT_SRCDIR) 
	cp $(MICOMINIT_SRCDIR)/micom_ensemble_init $(BINDIR)/micom_ensemble_init_f19_g16
micom_ensemble_tp:
	## tripolar grid
	make -C $(MICOMINIT_SRCDIR) clean
	sed -i -e's/^CPPDEFS.*/CPPDEFS = -DMPI -DARCTIC -DSKIPVAR/' $(MICOMINIT_SRCDIR)/Makefile
	sed -i -e's:data nreg.*:data nreg /2/:' $(MICOMINIT_SRCDIR)/../src/dimensions.F
	make -C $(MICOMINIT_SRCDIR) 
	cp $(MICOMINIT_SRCDIR)/micom_ensemble_init $(BINDIR)/micom_ensemble_init_f19_tn14

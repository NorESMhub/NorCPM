# Makefile created by mkmf $Id: mkmf,v 14.0 2007/03/20 22:13:27 fms Exp $ 

include Makefile.config
#For bipolar grid -DMPI 
#CPPDEFS = -DMPI 
#for tripolar grid -DMPI -DARCTIC
#CPPDEFS = -DMPI -DDOSA 
CPPDEFS = -DMPI -DARCTIC -DSKIPVAR

.DEFAULT:
	-touch $@
all: micom_ensemble_init
bigrid.o: ../src/bigrid.F mod_xc.o
	$(FC) $(CPPDEFS) $(CPPFLAGS) $(FFLAGS) $(SFFLAGS) $(OTHERFLAGS) -c	../src/bigrid.F
blkdat.o: ../src/blkdat.F ../src/common_blocks.h mod_xc.o
	$(FC) $(CPPDEFS) $(CPPFLAGS) $(FFLAGS) $(SFFLAGS) $(OTHERFLAGS) -c -I../src	../src/blkdat.F
chksum.o: ../src/chksum.F mod_xc.o
	$(FC) $(CPPDEFS) $(CPPFLAGS) $(FFLAGS) $(SFFLAGS) $(OTHERFLAGS) -c	../src/chksum.F
chksummsk.o: ../src/chksummsk.F mod_xc.o
	$(FC) $(CPPDEFS) $(CPPFLAGS) $(FFLAGS) $(SFFLAGS) $(OTHERFLAGS) -c	../src/chksummsk.F
crc.o: ../src/crc.c ../src/crc.h
	$(CC) $(CPPDEFS) $(CPPFLAGS) $(CFLAGS) $(OTHERFLAGS) -c -I../src	../src/crc.c
dimensions.o: ../src/dimensions.F
	$(FC) $(CPPDEFS) $(CPPFLAGS) $(FFLAGS) $(SFFLAGS) $(OTHERFLAGS) -c	../src/dimensions.F
eosdat.o: ../src/eosdat.F ../src/common_eos.h
	$(FC) $(CPPDEFS) $(CPPFLAGS) $(FFLAGS) $(SFFLAGS) $(OTHERFLAGS) -c -I../src	../src/eosdat.F
eosfun.o: ../src/eosfun.F ../src/common_eos.h
	$(FC) $(CPPDEFS) $(CPPFLAGS) $(FFLAGS) $(SFFLAGS) $(OTHERFLAGS) -c -I../src	../src/eosfun.F
fill_global.o: ../src/fill_global.F mod_xc.o
	$(FC) $(CPPDEFS) $(CPPFLAGS) $(FFLAGS) $(SFFLAGS) $(OTHERFLAGS) -c	../src/fill_global.F
geoenv_file.o: ../src/geoenv_file.F ../src/common_blocks.h ../src/common_geo.h mod_xc.o
	$(FC) $(CPPDEFS) $(CPPFLAGS) $(FFLAGS) $(SFFLAGS) $(OTHERFLAGS) -c -I../src ../src/geoenv_file.F
getlpi.o: ../src/getlpi.F
	$(FC) $(CPPDEFS) $(CPPFLAGS) $(FFLAGS) $(SFFLAGS) $(OTHERFLAGS) -c	../src/getlpi.F
inigeo.o: ../src/inigeo.F ../src/common_blocks.h ../src/common_geo.h mod_xc.o mod_nctools.o
	$(FC) $(CPPDEFS) $(CPPFLAGS) $(FFLAGS) $(SFFLAGS) $(OTHERFLAGS) -c -I../src	../src/inigeo.F
inivar.o: ../src/inivar.F ../src/common_blocks.h mod_xc.o
	$(FC) $(CPPDEFS) $(CPPFLAGS) $(FFLAGS) $(SFFLAGS) $(OTHERFLAGS) -c -I../src	../src/inivar.F
micom_ensemble_init.o: ../src/micom_ensemble_init.F ../src/common_blocks.h mod_xc.o mod_nctools.o
	$(FC) $(CPPDEFS) $(CPPFLAGS) $(FFLAGS) $(SFFLAGS) $(OTHERFLAGS) -c -I../src ../src/micom_ensemble_init.F
mod_nctools.o: ../src/mod_nctools.F mod_xc.o
	$(FC) $(CPPDEFS) $(CPPFLAGS) $(FFLAGS) $(SFFLAGS) $(OTHERFLAGS) -c	../src/mod_nctools.F
mod_xc.o: ../src/mod_xc.F ../src/mod_xc_mp.inc ../src/mod_xc_sm.inc dimensions.o
	$(FC) $(CPPDEFS) $(CPPFLAGS) $(FFLAGS) $(SFFLAGS) $(OTHERFLAGS) -c -I../src	../src/mod_xc.F
pgforc.o: ../src/pgforc.F ../src/common_blocks.h mod_xc.o
	$(FC) $(CPPDEFS) $(CPPFLAGS) $(FFLAGS) $(SFFLAGS) $(OTHERFLAGS) -c -I../src	../src/pgforc.F
swtfrz.o: ../src/swtfrz.F
	$(FC) $(CPPDEFS) $(CPPFLAGS) $(FFLAGS) $(SFFLAGS) $(OTHERFLAGS) -c	../src/swtfrz.F
wtime.o: ../src/wtime.F
	$(FC) $(CPPDEFS) $(CPPFLAGS) $(FFLAGS) $(SFFLAGS) $(OTHERFLAGS) -c	../src/wtime.F
./common_geo.h: ../src/common_geo.h
	cp ../src/common_geo.h .
./bigrid.F: ../src/bigrid.F
	cp ../src/bigrid.F .
./geoenv_file.F: ../src/geoenv_file.F
	cp ../src/geoenv_file.F .
./swtfrz.F: ../src/swtfrz.F
	cp ../src/swtfrz.F .
./micom_ensemble_init.F: ../src/micom_ensemble_init.F
	cp ../src/micom_ensemble_init.F .
./eosfun.F: ../src/eosfun.F
	cp ../src/eosfun.F .
./blkdat.F: ../src/blkdat.F
	cp ../src/blkdat.F .
./common_blocks.h: ../src/common_blocks.h
	cp ../src/common_blocks.h .
./fill_global.F: ../src/fill_global.F
	cp ../src/fill_global.F .
./crc.h: ../src/crc.h
	cp ../src/crc.h .
./mod_xc_sm.inc: ../src/mod_xc_sm.inc
	cp ../src/mod_xc_sm.inc .
./mod_xc.F: ../src/mod_xc.F
	cp ../src/mod_xc.F .
./eosdat.F: ../src/eosdat.F
	cp ../src/eosdat.F .
./dimensions.F: ../src/dimensions.F
	cp ../src/dimensions.F .
./getlpi.F: ../src/getlpi.F
	cp ../src/getlpi.F .
./common_eos.h: ../src/common_eos.h
	cp ../src/common_eos.h .
./mod_xc_mp.inc: ../src/mod_xc_mp.inc
	cp ../src/mod_xc_mp.inc .
./inigeo.F: ../src/inigeo.F
	cp ../src/inigeo.F .
./crc.c: ../src/crc.c
	cp ../src/crc.c .
./chksummsk.F: ../src/chksummsk.F
	cp ../src/chksummsk.F .
./wtime.F: ../src/wtime.F
	cp ../src/wtime.F .
./inivar.F: ../src/inivar.F
	cp ../src/inivar.F .
./chksum.F: ../src/chksum.F
	cp ../src/chksum.F .
./mod_nctools.F: ../src/mod_nctools.F
	cp ../src/mod_nctools.F .
./pgforc.F: ../src/pgforc.F
	cp ../src/pgforc.F .
SRC = ../src/mod_nctools.F ../src/crc.c ../src/fill_global.F ../src/dimensions.F ../src/chksummsk.F ../src/inigeo.F ../src/eosfun.F ../src/inivar.F ../src/mod_xc.F ../src/blkdat.F ../src/geoenv_file.F ../src/pgforc.F ../src/wtime.F ../src/eosdat.F        \
../src/swtfrz.F ../src/micom_ensemble_init.F ../src/bigrid.F ../src/getlpi.F ../src/chksum.F ../src/mod_xc_mp.inc ../src/crc.h ../src/mod_xc_sm.inc ../src/common_geo.h ../src/common_blocks.h                 \
../src/common_eos.h
OBJ = mod_nctools.o crc.o fill_global.o dimensions.o chksummsk.o inigeo.o eosfun.o inivar.o mod_xc.o blkdat.o geoenv_file.o pgforc.o wtime.o eosdat.o swtfrz.o micom_ensemble_init.o bigrid.o getlpi.o chksum.o
OFF = ../src/common_geo.h ../src/bigrid.F ../src/geoenv_file.F ../src/swtfrz.F ../src/micom_ensemble_init.F ../src/eosfun.F ../src/blkdat.F ../src/common_blocks.h ../src/fill_global.F ../src/crc.h          \
../src/mod_xc_sm.inc ../src/mod_xc.F ../src/eosdat.F ../src/dimensions.F ../src/getlpi.F ../src/common_eos.h ../src/mod_xc_mp.inc ../src/inigeo.F ../src/crc.c ../src/chksummsk.F ../src/wtime.F ../src/inivar.F ../src/chksum.F ../src/mod_nctools.F          \
../src/pgforc.F
clean: neat
	-rm -f .cppdefs *.mod $(OBJ) micom_ensemble_init
neat:
	-rm -f $(TMPFILES)
localize: $(OFF)
	cp $(OFF) .
TAGS: $(SRC)
	etags $(SRC)
tags: $(SRC)
	ctags $(SRC)
micom_ensemble_init: $(OBJ) 
	$(LD) $(OBJ) -o micom_ensemble_init  $(LDFLAGS)

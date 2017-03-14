#
# Copyright (C) 2003, Northwestern University and Argonne National Laboratory
# See COPYRIGHT notice in top-level directory.
#
# $Id$
#
# @configure_input@

SUFFIXES = .o .c

AM_DEFAULT_SOURCE_EXT = .c

AM_CPPFLAGS = -I$(srcdir)/../common
LDADD = $(top_builddir)/src/libs/libpnetcdf.la ../common/libtestutils.la

AM_CFLAGS =
if IS_BIGENDIAN
   AM_CFLAGS += -DWORDS_BIGENDIAN
endif

if DECL_MPI_OFFSET
   # Do not add to AM_CPPFLAGS, as it will also be used by Fortran programs
   # AM_CPPFLAGS += -DHAVE_DECL_MPI_OFFSET
   AM_CFLAGS += -DHAVE_DECL_MPI_OFFSET
   # AM_FFLAGS  += $(FC_DEFINE)HAVE_DECL_MPI_OFFSET
   # AM_FCFLAGS += $(FC_DEFINE)HAVE_DECL_MPI_OFFSET
endif

TESTPROGRAMS = large_files large_var

check_PROGRAMS = $(TESTPROGRAMS)

# autimake 1.11.3 has not yet implemented AM_TESTS_ENVIRONMENT
# For newer versions, we can use AM_TESTS_ENVIRONMENT instead
# AM_TESTS_ENVIRONMENT  = TESTPROGRAMS="$(TESTPROGRAMS)" ; export TESTPROGRAMS;
# AM_TESTS_ENVIRONMENT += TESTSEQRUN="$(TESTSEQRUN)" ; export TESTSEQRUN;
# AM_TESTS_ENVIRONMENT += TESTOUTDIR="$(TESTOUTDIR)" ; export TESTOUTDIR;
TESTS_ENVIRONMENT  = TESTPROGRAMS="$(TESTPROGRAMS)" ; export TESTPROGRAMS;
TESTS_ENVIRONMENT += TESTSEQRUN="$(TESTSEQRUN)" ; export TESTSEQRUN;
TESTS_ENVIRONMENT += TESTOUTDIR="$(TESTOUTDIR)" ; export TESTOUTDIR;

TESTS = seq_runs.sh

EXTRA_DIST = seq_runs.sh

CLEANFILES = *.nc core core.*

../common/libtestutils.la:
	set -e; cd ../common && $(MAKE) $(MFLAGS) tests

# Some of these tests are designed to run on one processes,
# Run them on 4 processes to see if they can handle well

ptest ptest4: $(TESTPROGRAMS)
	$(RM) -f $(TESTOUTDIR)/testfile.nc $(TESTOUTDIR)/testfile.nc
	set -e ; for i in $(TESTPROGRAMS) ; do ( \
	$(TESTMPIRUN4) ./$$i $(TESTOUTDIR)/testfile.nc ; \
	) ; done

ptest2: $(TESTPROGRAMS)
	$(RM) -f $(TESTOUTDIR)/testfile.nc $(TESTOUTDIR)/testfile.nc
	set -e ; for i in $(TESTPROGRAMS); do ( \
	$(TESTMPIRUN2) ./$$i $(TESTOUTDIR)/testfile.nc ; \
	) ; done

ptest6: $(TESTPROGRAMS)
	$(RM) -f $(TESTOUTDIR)/testfile.nc $(TESTOUTDIR)/testfile.nc
	set -e ; for i in $(TESTPROGRAMS); do ( \
	$(TESTMPIRUN6) ./$$i $(TESTOUTDIR)/testfile.nc ; \
	) ; done

ptests: ptest2 ptest4 ptest6
ptest8 ptest10:

# build check targets but not invoke
tests: $(check_PROGRAMS)
.PHONY: tests ptest ptests ptest2 ptest4 ptest6 ptest8 ptest10 $(LDADD)

dist-hook:
	-rm -rf `find $(distdir) -name .svn`

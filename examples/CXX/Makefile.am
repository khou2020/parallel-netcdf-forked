#
# Copyright (C) 2014, Northwestern University and Argonne National Laboratory
# See COPYRIGHT notice in top-level directory.
#
# $Id$
#
# @configure_input@

SUFFIXES = .cpp .o

AM_DEFAULT_SOURCE_EXT = .cpp

AM_CPPFLAGS = -I$(top_builddir)/src/libcxx
LDADD = ${top_builddir}/src/lib/libpnetcdf.la

TESTPROGRAMS = collective_write \
               nonblocking_write \
               column_wise \
               block_cyclic \
               flexible_api \
               get_info \
               hints \
               put_varn_float \
               put_varn_int \
               put_vara \
               get_vara \
               transpose \
               vard_int \
               fill_mode

check_PROGRAMS = $(TESTPROGRAMS)

# parallel runs only
# TESTS = $(TESTPROGRAMS)

CLEANFILES = *.nc core core.*

ptest ptest4: $(TESTPROGRAMS)
	@for i in $(TESTPROGRAMS); do { \
        $(TESTMPIRUN4) ./$$i -q $(TESTOUTDIR)/testfile.nc ; \
        if [ $$? = 0 ] ; then \
           echo "PASS: C++ parallel run on 4 processes --------------- $$i"; \
        else \
           echo "FAILED: C++ parallel run on 4 processes ------------- $$i"; \
           exit 1; \
        fi ; } ; done

ptest8: $(TESTPROGRAMS)
	@for i in $(TESTPROGRAMS) ; do { \
        $(TESTMPIRUN8) ./$$i -q $(TESTOUTDIR)/testfile.nc ; \
        if [ $$? = 0 ] ; then \
           echo "PASS: C++ parallel run on 8 processes --------------- $$i"; \
        else \
           echo "FAILED: C++ parallel run on 8 processes ------------- $$i"; \
           exit 1; \
        fi ; } ; done

ptest3: $(TESTPROGRAMS)
	@for i in $(TESTPROGRAMS) ; do { \
        $(TESTMPIRUN3) ./$$i -q $(TESTOUTDIR)/testfile.nc ; \
        if [ $$? = 0 ] ; then \
           echo "PASS: C++ parallel run on 3 processes --------------- $$i"; \
        else \
           echo "FAILED: C++ parallel run on 3 processes ------------- $$i"; \
           exit 1; \
        fi ; } ; done

ptests: ptest3 ptest4 ptest8 
ptest2 ptest6 ptest10:

# build check targets but not invoke
tests: $(check_PROGRAMS)
.PHONY: tests ptest ptests ptest2 ptest3 ptest4 ptest6 ptest8 ptest10

dist-hook:
	-rm -rf `find $(distdir) -name .svn`

#
# Copyright (C) 2012, Northwestern University and Argonne National Laboratory
# See COPYRIGHT notice in top-level directory.
#
# $Id: Makefile.am 2815 2017-01-01 23:06:33Z wkliao $
#
# @configure_input@

lib_LTLIBRARIES = libpnetcdf.la

# Using libpnetcdf_la_LDFLAGS = $(ABIVERSIONFLAGS) does NOT seem to work,
# because libpnetcdf_la_LINK is explicitly set below to deal with cross
# language link.
AM_LDFLAGS = $(ABIVERSIONFLAGS)

libpnetcdf_la_SOURCES =
libpnetcdf_la_LIBADD  = ../dispatchers/libdispatchers.la
libpnetcdf_la_LIBADD += ../drivers/common/libcommon.la
libpnetcdf_la_LIBADD += ../drivers/ncmpio/libncmpio.la
if BUILD_DRIVER_FOO
libpnetcdf_la_LIBADD += ../drivers/ncfoo/libncfoo.la
endif

nodist_EXTRA_libpnetcdf_la_SOURCES = dummyc.c

if HAS_MPICXX
libpnetcdf_la_LIBADD += ../binding/cxx/libcxx.la
# According Automake Manual, Section 8.3.5 Libtool Convenience Libraries,
# using nodist_EXTRA to trick automake to use C++ compiler
nodist_EXTRA_libpnetcdf_la_SOURCES += dummycxx.cxx
libpnetcdf_la_LINK = $(CXXLINK)
else
# From automake manual Section 8.14.3.1, "... if Fortran 77, C and C++ source
# code is compiled into a program, then the C++ linker will be used." and "A
# per-target _LINK variable will override the above selection"
libpnetcdf_la_LINK = $(LINK)
endif

if HAS_FORTRAN
libpnetcdf_la_LIBADD += ../binding/f77/libf77.la
libpnetcdf_la_LIBADD += ../binding/f90/libf90.la
# According to Automake Manual, Section 8.14.3 Mixing Fortran 77 With C and
# C++, adding $(FLIBS) is necessary
# libpnetcdf_la_LIBADD += $(FLIBS) $(FCLIBS)
# nodist_EXTRA_libpnetcdf_la_SOURCES += dummyf90.f90
endif

../dispatchers/libdispatchers.la:
	set -e; cd ../dispatchers && $(MAKE) $(MFLAGS)

../drivers/common/libcommon.la:
	set -e; cd ../drivers/common && $(MAKE) $(MFLAGS)

../drivers/ncmpio/libncmpio.la:
	set -e; cd ../drivers/ncmpio && $(MAKE) $(MFLAGS)

../drivers/ncfoo/libncfoo.la:
	set -e; cd ../drivers/ncfoo && $(MAKE) $(MFLAGS)

../binding/cxx/libcxx.la:
	set -e; cd ../binding/cxx && $(MAKE) $(MFLAGS)

../binding/f77/libf77.la:
	set -e; cd ../binding/f77 && $(MAKE) $(MFLAGS)

../binding/f90/libf90.la:
	set -e; cd ../binding/f90 && $(MAKE) $(MFLAGS)

tests-local: all


dnl Process this m4 file to produce 'C' language file.
dnl
dnl If you see this line, you can ignore the next one.
! Do not edit this file. It is produced from the corresponding .m4 source
dnl
!
!  Copyright (C) 2013, Northwestern University and Argonne National Laboratory
!  See COPYRIGHT notice in top-level directory.
!
! $Id$
!

dnl
dnl VAR_SCALAR
dnl
define(`VAR_SCALAR',dnl
`dnl
   function nf90mpi_$1_var_$3$2(ncid, varid, values, start, bufcount, buftype)
     integer,                                                intent( in) :: ncid, varid
     $4 (kind=$3),                                           intent($6)  :: values
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent( in) :: start
     integer (kind=MPI_OFFSET_KIND),               optional, intent( in) :: bufcount
     integer,                                      optional, intent( in) :: buftype

     integer                                     :: nf90mpi_$1_var_$3$2
     integer (kind=MPI_OFFSET_KIND), allocatable :: localIndex(:)
     integer                                     :: numDims

     ! inquire variable dimensionality
     nf90mpi_$1_var_$3$2 = nfmpi_inq_varndims(ncid, varid, numDims)
     if (nf90mpi_$1_var_$3$2 .NE. NF_NOERR) return

     if (numDims .GT. 0) then
         ! allocate local arrays
         allocate(localIndex(numDims))
         if (present(start)) then
             localIndex(:numDims) = start(:numDims)
         else
             ! Set local arguments to default values
             localIndex(:) = 1
         endif
     endif

     if (present(buftype)) then
         nf90mpi_$1_var_$3$2 = nfmpi_$1_var1$2(ncid, varid, localIndex, values, bufcount, buftype)
     else
         nf90mpi_$1_var_$3$2 = nfmpi_$1_var1_$5$2(ncid, varid, localIndex, values)
     endif
     if (numDims .GT. 0) deallocate(localIndex)
   end function nf90mpi_$1_var_$3$2
')dnl

VAR_SCALAR(put,     , OneByteInt,    integer, int1,   in)
VAR_SCALAR(put,     , TwoByteInt,    integer, int2,   INTENTV)
VAR_SCALAR(put,     , FourByteInt,   integer, int,    INTENTV)
VAR_SCALAR(put,     , FourByteReal,  real,    real,   INTENTV)
VAR_SCALAR(put,     , EightByteReal, real,    double, INTENTV)
VAR_SCALAR(put,     , EightByteInt,  integer, int8,   INTENTV)

VAR_SCALAR(put, _all, OneByteInt,    integer, int1,   in)
VAR_SCALAR(put, _all, TwoByteInt,    integer, int2,   INTENTV)
VAR_SCALAR(put, _all, FourByteInt,   integer, int,    INTENTV)
VAR_SCALAR(put, _all, FourByteReal,  real,    real,   INTENTV)
VAR_SCALAR(put, _all, EightByteReal, real,    double, INTENTV)
VAR_SCALAR(put, _all, EightByteInt,  integer, int8,   INTENTV)

VAR_SCALAR(get,     , OneByteInt,    integer, int1,   out)
VAR_SCALAR(get,     , TwoByteInt,    integer, int2,   out)
VAR_SCALAR(get,     , FourByteInt,   integer, int,    out)
VAR_SCALAR(get,     , FourByteReal,  real,    real,   out)
VAR_SCALAR(get,     , EightByteReal, real,    double, out)
VAR_SCALAR(get,     , EightByteInt,  integer, int8,   out)

VAR_SCALAR(get, _all, OneByteInt,    integer, int1,   out)
VAR_SCALAR(get, _all, TwoByteInt,    integer, int2,   out)
VAR_SCALAR(get, _all, FourByteInt,   integer, int,    out)
VAR_SCALAR(get, _all, FourByteReal,  real,    real,   out)
VAR_SCALAR(get, _all, EightByteReal, real,    double, out)
VAR_SCALAR(get, _all, EightByteInt,  integer, int8,   out)

dnl
dnl NBVAR1(ncid, varid, values, start, count, req)
dnl
define(`NBVAR1',dnl
`dnl
   function nf90mpi_$1_var_$2(ncid, varid, values, req, start, bufcount, buftype)
     integer,                                                intent( in) :: ncid, varid
     $3 (kind=$2),                                           intent($5)  :: values
     integer,                                                intent(out) :: req
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent( in) :: start
     integer (kind=MPI_OFFSET_KIND),               optional, intent( in) :: bufcount
     integer,                                      optional, intent( in) :: buftype

     integer                                     :: nf90mpi_$1_var_$2
     integer (kind=MPI_OFFSET_KIND), allocatable :: localIndex(:)
     integer                                     :: numDims

     ! inquire variable dimensionality
     nf90mpi_$1_var_$2 = nfmpi_inq_varndims(ncid, varid, numDims)
     if (nf90mpi_$1_var_$2 .NE. NF_NOERR) return

     if (numDims .GT. 0) then
         ! allocate local arrays
         allocate(localIndex(numDims))
         if (present(start)) then
             localIndex(:numDims) = start(:numDims)
         else
             ! Set local arguments to default values
             localIndex(:) = 1
         endif
     endif

     if (present(buftype)) then
         nf90mpi_$1_var_$2 = nfmpi_$1_var1(ncid, varid, localIndex, values, bufcount, buftype, req)
     else
         nf90mpi_$1_var_$2 = nfmpi_$1_var1_$4(ncid, varid, localIndex, values, req)
     endif
     if (numDims .GT. 0) deallocate(localIndex)
   end function nf90mpi_$1_var_$2
')dnl

!
! Nonblocking iput APIs
!

NBVAR1(iput, OneByteInt,    integer, int1,   in)
NBVAR1(iput, TwoByteInt,    integer, int2,   INTENTV)
NBVAR1(iput, FourByteInt,   integer, int,    INTENTV)
NBVAR1(iput, FourByteReal,  real,    real,   INTENTV)
NBVAR1(iput, EightByteReal, real,    double, INTENTV)
NBVAR1(iput, EightByteInt,  integer, int8,   INTENTV)

!
! Nonblocking iget APIs
!

NBVAR1(iget, OneByteInt,    integer, int1,   out)
NBVAR1(iget, TwoByteInt,    integer, int2,   out)
NBVAR1(iget, FourByteInt,   integer, int,    out)
NBVAR1(iget, FourByteReal,  real,    real,   out)
NBVAR1(iget, EightByteReal, real,    double, out)
NBVAR1(iget, EightByteInt,  integer, int8,   out)

!
! Nonblocking bput APIs
!

NBVAR1(bput, OneByteInt,    integer, int1,   in)
NBVAR1(bput, TwoByteInt,    integer, int2,   INTENTV)
NBVAR1(bput, FourByteInt,   integer, int,    INTENTV)
NBVAR1(bput, FourByteReal,  real,    real,   INTENTV)
NBVAR1(bput, EightByteReal, real,    double, INTENTV)
NBVAR1(bput, EightByteInt,  integer, int8,   INTENTV)

dnl
dnl VAR(ncid, varid, values, start, count, stride, map)
dnl
define(`VAR',dnl
`dnl
   function nf90mpi_$1_var_$2D_$3$8(ncid, varid, values, start, count, stride, map, bufcount, buftype)
     integer,                                                intent( in) :: ncid, varid
     $4 (kind=$3), dimension($6),                            intent( $7) :: values
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent( in) :: start
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent( in) :: count
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent( in) :: stride
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent( in) :: map
     integer (kind=MPI_OFFSET_KIND),               optional, intent( in) :: bufcount
     integer,                                      optional, intent( in) :: buftype

     integer                                     :: nf90mpi_$1_var_$2D_$3$8
     integer (kind=MPI_OFFSET_KIND), allocatable :: localStart(:)
     integer (kind=MPI_OFFSET_KIND), allocatable :: localCount(:)
     integer (kind=MPI_OFFSET_KIND), allocatable :: localStride(:)
     integer (kind=MPI_OFFSET_KIND), allocatable :: localMap(:)
     integer                                     :: numDims
     ifelse(`$2', `1', ,`integer :: counter')

     ! inquire variable dimensionality
     nf90mpi_$1_var_$2D_$3$8 = nfmpi_inq_varndims(ncid, varid, numDims)
     if (nf90mpi_$1_var_$2D_$3$8 .NE. NF_NOERR) return

     if (numDims .GT. 0) then
         ! allocate local arrays
         allocate(localStart(numDims))
         allocate(localCount(numDims))
         allocate(localStride(numDims))
         allocate(localMap(numDims))
         if (present(start)) then
             localStart(:numDims) = start(:numDims)
         else
             ! Set local arguments to default values
             localStart(:) = 1
         endif
         if (present(count)) then
             localCount(:numDims) = count(:numDims)
         else
             ! Set local arguments to default values
             localCount(:$2) = shape(values)
             if (numDims .GT. $2) localCount($2+1:) = 1
         endif
         if (present(stride)) then
             localStride(:numDims) = stride(:numDims)
         else
             ! Set local arguments to default values
             localStride(:) = 1
         endif
         if (present(map)) then
             localMap(:numDims) = map(:numDims)
         else
             ! Set local arguments to default values
             ! localMap(:$2) = (/ 1, (product(localCount(:counter)), counter = 1, $2 - 1) /)
             localMap(1) = 1
             ifelse(`$2', `1', ,`
             do counter = 1, $2 - 1
                localMap(counter+1) = localMap(counter) * localCount(counter)
             enddo')
         endif
     endif

     if (present(map)) then
         if (present(buftype)) then
             nf90mpi_$1_var_$2D_$3$8 = &
                nfmpi_$1_varm$8(ncid, varid, localStart, localCount, localStride, localMap, values, bufcount, buftype)
         else
             nf90mpi_$1_var_$2D_$3$8 = &
                nfmpi_$1_varm_$5$8(ncid, varid, localStart, localCount, localStride, localMap, values)
         endif
     else if (present(stride)) then
         if (present(buftype)) then
             nf90mpi_$1_var_$2D_$3$8 = &
                nfmpi_$1_vars$8(ncid, varid, localStart, localCount, localStride, values, bufcount, buftype)
         else
             nf90mpi_$1_var_$2D_$3$8 = &
                nfmpi_$1_vars_$5$8(ncid, varid, localStart, localCount, localStride, values)
         endif
     else
         if (present(buftype)) then
             nf90mpi_$1_var_$2D_$3$8 = &
                nfmpi_$1_vara$8(ncid, varid, localStart, localCount, values, bufcount, buftype)
         else
             nf90mpi_$1_var_$2D_$3$8 = &
                nfmpi_$1_vara_$5$8(ncid, varid, localStart, localCount, values)
         endif
     endif
     if (numDims .GT. 0) then
         deallocate(localMap)
         deallocate(localStride)
         deallocate(localCount)
         deallocate(localStart)
     endif
   end function nf90mpi_$1_var_$2D_$3$8
')dnl

!
! Independent put APIs
!

VAR(put, 1, OneByteInt, integer, int1,  :,              in)
VAR(put, 2, OneByteInt, integer, int1, `:,:',           in)
VAR(put, 3, OneByteInt, integer, int1, `:,:,:',         in)
VAR(put, 4, OneByteInt, integer, int1, `:,:,:,:',       in)
VAR(put, 5, OneByteInt, integer, int1, `:,:,:,:,:',     in)
VAR(put, 6, OneByteInt, integer, int1, `:,:,:,:,:,:',   in)
VAR(put, 7, OneByteInt, integer, int1, `:,:,:,:,:,:,:', in)

VAR(put, 1, TwoByteInt, integer, int2,  :,              INTENTV)
VAR(put, 2, TwoByteInt, integer, int2, `:,:',           INTENTV)
VAR(put, 3, TwoByteInt, integer, int2, `:,:,:',         INTENTV)
VAR(put, 4, TwoByteInt, integer, int2, `:,:,:,:',       INTENTV)
VAR(put, 5, TwoByteInt, integer, int2, `:,:,:,:,:',     INTENTV)
VAR(put, 6, TwoByteInt, integer, int2, `:,:,:,:,:,:',   INTENTV)
VAR(put, 7, TwoByteInt, integer, int2, `:,:,:,:,:,:,:', INTENTV)

VAR(put, 1, FourByteInt, integer, int,  :,              INTENTV)
VAR(put, 2, FourByteInt, integer, int, `:,:',           INTENTV)
VAR(put, 3, FourByteInt, integer, int, `:,:,:',         INTENTV)
VAR(put, 4, FourByteInt, integer, int, `:,:,:,:',       INTENTV)
VAR(put, 5, FourByteInt, integer, int, `:,:,:,:,:',     INTENTV)
VAR(put, 6, FourByteInt, integer, int, `:,:,:,:,:,:',   INTENTV)
VAR(put, 7, FourByteInt, integer, int, `:,:,:,:,:,:,:', INTENTV)

VAR(put, 1, FourByteReal, real,   real,  :,              INTENTV)
VAR(put, 2, FourByteReal, real,   real, `:,:',           INTENTV)
VAR(put, 3, FourByteReal, real,   real, `:,:,:',         INTENTV)
VAR(put, 4, FourByteReal, real,   real, `:,:,:,:',       INTENTV)
VAR(put, 5, FourByteReal, real,   real, `:,:,:,:,:',     INTENTV)
VAR(put, 6, FourByteReal, real,   real, `:,:,:,:,:,:',   INTENTV)
VAR(put, 7, FourByteReal, real,   real, `:,:,:,:,:,:,:', INTENTV)

VAR(put, 1, EightByteReal, real, double,  :,              INTENTV)
VAR(put, 2, EightByteReal, real, double, `:,:',           INTENTV)
VAR(put, 3, EightByteReal, real, double, `:,:,:',         INTENTV)
VAR(put, 4, EightByteReal, real, double, `:,:,:,:',       INTENTV)
VAR(put, 5, EightByteReal, real, double, `:,:,:,:,:',     INTENTV)
VAR(put, 6, EightByteReal, real, double, `:,:,:,:,:,:',   INTENTV)
VAR(put, 7, EightByteReal, real, double, `:,:,:,:,:,:,:', INTENTV)

VAR(put, 1, EightByteInt, integer, int8,  :,              INTENTV)
VAR(put, 2, EightByteInt, integer, int8, `:,:',           INTENTV)
VAR(put, 3, EightByteInt, integer, int8, `:,:,:',         INTENTV)
VAR(put, 4, EightByteInt, integer, int8, `:,:,:,:',       INTENTV)
VAR(put, 5, EightByteInt, integer, int8, `:,:,:,:,:',     INTENTV)
VAR(put, 6, EightByteInt, integer, int8, `:,:,:,:,:,:',   INTENTV)
VAR(put, 7, EightByteInt, integer, int8, `:,:,:,:,:,:,:', INTENTV)

!
! Independent get APIs
!

VAR(get, 1, OneByteInt, integer, int1,  :,              out)
VAR(get, 2, OneByteInt, integer, int1, `:,:',           out)
VAR(get, 3, OneByteInt, integer, int1, `:,:,:',         out)
VAR(get, 4, OneByteInt, integer, int1, `:,:,:,:',       out)
VAR(get, 5, OneByteInt, integer, int1, `:,:,:,:,:',     out)
VAR(get, 6, OneByteInt, integer, int1, `:,:,:,:,:,:',   out)
VAR(get, 7, OneByteInt, integer, int1, `:,:,:,:,:,:,:', out)

VAR(get, 1, TwoByteInt, integer, int2,  :,              out)
VAR(get, 2, TwoByteInt, integer, int2, `:,:',           out)
VAR(get, 3, TwoByteInt, integer, int2, `:,:,:',         out)
VAR(get, 4, TwoByteInt, integer, int2, `:,:,:,:',       out)
VAR(get, 5, TwoByteInt, integer, int2, `:,:,:,:,:',     out)
VAR(get, 6, TwoByteInt, integer, int2, `:,:,:,:,:,:',   out)
VAR(get, 7, TwoByteInt, integer, int2, `:,:,:,:,:,:,:', out)

VAR(get, 1, FourByteInt, integer, int,  :,              out)
VAR(get, 2, FourByteInt, integer, int, `:,:',           out)
VAR(get, 3, FourByteInt, integer, int, `:,:,:',         out)
VAR(get, 4, FourByteInt, integer, int, `:,:,:,:',       out)
VAR(get, 5, FourByteInt, integer, int, `:,:,:,:,:',     out)
VAR(get, 6, FourByteInt, integer, int, `:,:,:,:,:,:',   out)
VAR(get, 7, FourByteInt, integer, int, `:,:,:,:,:,:,:', out)

VAR(get, 1, FourByteReal, real,   real,  :,              out)
VAR(get, 2, FourByteReal, real,   real, `:,:',           out)
VAR(get, 3, FourByteReal, real,   real, `:,:,:',         out)
VAR(get, 4, FourByteReal, real,   real, `:,:,:,:',       out)
VAR(get, 5, FourByteReal, real,   real, `:,:,:,:,:',     out)
VAR(get, 6, FourByteReal, real,   real, `:,:,:,:,:,:',   out)
VAR(get, 7, FourByteReal, real,   real, `:,:,:,:,:,:,:', out)

VAR(get, 1, EightByteReal, real, double,  :,              out)
VAR(get, 2, EightByteReal, real, double, `:,:',           out)
VAR(get, 3, EightByteReal, real, double, `:,:,:',         out)
VAR(get, 4, EightByteReal, real, double, `:,:,:,:',       out)
VAR(get, 5, EightByteReal, real, double, `:,:,:,:,:',     out)
VAR(get, 6, EightByteReal, real, double, `:,:,:,:,:,:',   out)
VAR(get, 7, EightByteReal, real, double, `:,:,:,:,:,:,:', out)

VAR(get, 1, EightByteInt, integer, int8,  :,              out)
VAR(get, 2, EightByteInt, integer, int8, `:,:',           out)
VAR(get, 3, EightByteInt, integer, int8, `:,:,:',         out)
VAR(get, 4, EightByteInt, integer, int8, `:,:,:,:',       out)
VAR(get, 5, EightByteInt, integer, int8, `:,:,:,:,:',     out)
VAR(get, 6, EightByteInt, integer, int8, `:,:,:,:,:,:',   out)
VAR(get, 7, EightByteInt, integer, int8, `:,:,:,:,:,:,:', out)

!
! collective put APIs
!

VAR(put, 1, OneByteInt, integer, int1,  :,              in, _all)
VAR(put, 2, OneByteInt, integer, int1, `:,:',           in, _all)
VAR(put, 3, OneByteInt, integer, int1, `:,:,:',         in, _all)
VAR(put, 4, OneByteInt, integer, int1, `:,:,:,:',       in, _all)
VAR(put, 5, OneByteInt, integer, int1, `:,:,:,:,:',     in, _all)
VAR(put, 6, OneByteInt, integer, int1, `:,:,:,:,:,:',   in, _all)
VAR(put, 7, OneByteInt, integer, int1, `:,:,:,:,:,:,:', in, _all)

VAR(put, 1, TwoByteInt, integer, int2,  :,              INTENTV, _all)
VAR(put, 2, TwoByteInt, integer, int2, `:,:',           INTENTV, _all)
VAR(put, 3, TwoByteInt, integer, int2, `:,:,:',         INTENTV, _all)
VAR(put, 4, TwoByteInt, integer, int2, `:,:,:,:',       INTENTV, _all)
VAR(put, 5, TwoByteInt, integer, int2, `:,:,:,:,:',     INTENTV, _all)
VAR(put, 6, TwoByteInt, integer, int2, `:,:,:,:,:,:',   INTENTV, _all)
VAR(put, 7, TwoByteInt, integer, int2, `:,:,:,:,:,:,:', INTENTV, _all)

VAR(put, 1, FourByteInt, integer, int,  :,              INTENTV, _all)
VAR(put, 2, FourByteInt, integer, int, `:,:',           INTENTV, _all)
VAR(put, 3, FourByteInt, integer, int, `:,:,:',         INTENTV, _all)
VAR(put, 4, FourByteInt, integer, int, `:,:,:,:',       INTENTV, _all)
VAR(put, 5, FourByteInt, integer, int, `:,:,:,:,:',     INTENTV, _all)
VAR(put, 6, FourByteInt, integer, int, `:,:,:,:,:,:',   INTENTV, _all)
VAR(put, 7, FourByteInt, integer, int, `:,:,:,:,:,:,:', INTENTV, _all)

VAR(put, 1, FourByteReal, real,   real,  :,              INTENTV, _all)
VAR(put, 2, FourByteReal, real,   real, `:,:',           INTENTV, _all)
VAR(put, 3, FourByteReal, real,   real, `:,:,:',         INTENTV, _all)
VAR(put, 4, FourByteReal, real,   real, `:,:,:,:',       INTENTV, _all)
VAR(put, 5, FourByteReal, real,   real, `:,:,:,:,:',     INTENTV, _all)
VAR(put, 6, FourByteReal, real,   real, `:,:,:,:,:,:',   INTENTV, _all)
VAR(put, 7, FourByteReal, real,   real, `:,:,:,:,:,:,:', INTENTV, _all)

VAR(put, 1, EightByteReal, real, double,  :,              INTENTV, _all)
VAR(put, 2, EightByteReal, real, double, `:,:',           INTENTV, _all)
VAR(put, 3, EightByteReal, real, double, `:,:,:',         INTENTV, _all)
VAR(put, 4, EightByteReal, real, double, `:,:,:,:',       INTENTV, _all)
VAR(put, 5, EightByteReal, real, double, `:,:,:,:,:',     INTENTV, _all)
VAR(put, 6, EightByteReal, real, double, `:,:,:,:,:,:',   INTENTV, _all)
VAR(put, 7, EightByteReal, real, double, `:,:,:,:,:,:,:', INTENTV, _all)

VAR(put, 1, EightByteInt, integer, int8,  :,              INTENTV, _all)
VAR(put, 2, EightByteInt, integer, int8, `:,:',           INTENTV, _all)
VAR(put, 3, EightByteInt, integer, int8, `:,:,:',         INTENTV, _all)
VAR(put, 4, EightByteInt, integer, int8, `:,:,:,:',       INTENTV, _all)
VAR(put, 5, EightByteInt, integer, int8, `:,:,:,:,:',     INTENTV, _all)
VAR(put, 6, EightByteInt, integer, int8, `:,:,:,:,:,:',   INTENTV, _all)
VAR(put, 7, EightByteInt, integer, int8, `:,:,:,:,:,:,:', INTENTV, _all)
!
! collective get APIs
!

VAR(get, 1, OneByteInt, integer, int1,  :,              out, _all)
VAR(get, 2, OneByteInt, integer, int1, `:,:',           out, _all)
VAR(get, 3, OneByteInt, integer, int1, `:,:,:',         out, _all)
VAR(get, 4, OneByteInt, integer, int1, `:,:,:,:',       out, _all)
VAR(get, 5, OneByteInt, integer, int1, `:,:,:,:,:',     out, _all)
VAR(get, 6, OneByteInt, integer, int1, `:,:,:,:,:,:',   out, _all)
VAR(get, 7, OneByteInt, integer, int1, `:,:,:,:,:,:,:', out, _all)

VAR(get, 1, TwoByteInt, integer, int2,  :,              out, _all)
VAR(get, 2, TwoByteInt, integer, int2, `:,:',           out, _all)
VAR(get, 3, TwoByteInt, integer, int2, `:,:,:',         out, _all)
VAR(get, 4, TwoByteInt, integer, int2, `:,:,:,:',       out, _all)
VAR(get, 5, TwoByteInt, integer, int2, `:,:,:,:,:',     out, _all)
VAR(get, 6, TwoByteInt, integer, int2, `:,:,:,:,:,:',   out, _all)
VAR(get, 7, TwoByteInt, integer, int2, `:,:,:,:,:,:,:', out, _all)

VAR(get, 1, FourByteInt, integer, int,  :,              out, _all)
VAR(get, 2, FourByteInt, integer, int, `:,:',           out, _all)
VAR(get, 3, FourByteInt, integer, int, `:,:,:',         out, _all)
VAR(get, 4, FourByteInt, integer, int, `:,:,:,:',       out, _all)
VAR(get, 5, FourByteInt, integer, int, `:,:,:,:,:',     out, _all)
VAR(get, 6, FourByteInt, integer, int, `:,:,:,:,:,:',   out, _all)
VAR(get, 7, FourByteInt, integer, int, `:,:,:,:,:,:,:', out, _all)

VAR(get, 1, FourByteReal, real,   real,  :,              out, _all)
VAR(get, 2, FourByteReal, real,   real, `:,:',           out, _all)
VAR(get, 3, FourByteReal, real,   real, `:,:,:',         out, _all)
VAR(get, 4, FourByteReal, real,   real, `:,:,:,:',       out, _all)
VAR(get, 5, FourByteReal, real,   real, `:,:,:,:,:',     out, _all)
VAR(get, 6, FourByteReal, real,   real, `:,:,:,:,:,:',   out, _all)
VAR(get, 7, FourByteReal, real,   real, `:,:,:,:,:,:,:', out, _all)

VAR(get, 1, EightByteReal, real, double,  :,              out, _all)
VAR(get, 2, EightByteReal, real, double, `:,:',           out, _all)
VAR(get, 3, EightByteReal, real, double, `:,:,:',         out, _all)
VAR(get, 4, EightByteReal, real, double, `:,:,:,:',       out, _all)
VAR(get, 5, EightByteReal, real, double, `:,:,:,:,:',     out, _all)
VAR(get, 6, EightByteReal, real, double, `:,:,:,:,:,:',   out, _all)
VAR(get, 7, EightByteReal, real, double, `:,:,:,:,:,:,:', out, _all)

VAR(get, 1, EightByteInt, integer, int8,  :,              out, _all)
VAR(get, 2, EightByteInt, integer, int8, `:,:',           out, _all)
VAR(get, 3, EightByteInt, integer, int8, `:,:,:',         out, _all)
VAR(get, 4, EightByteInt, integer, int8, `:,:,:,:',       out, _all)
VAR(get, 5, EightByteInt, integer, int8, `:,:,:,:,:',     out, _all)
VAR(get, 6, EightByteInt, integer, int8, `:,:,:,:,:,:',   out, _all)
VAR(get, 7, EightByteInt, integer, int8, `:,:,:,:,:,:,:', out, _all)

!
! Nonblocking APIs
!

dnl
dnl NBVAR(ncid, varid, values, start, count, stride, map, req)
dnl
define(`NBVAR',dnl
`dnl
   function nf90mpi_$1_var_$2D_$3(ncid, varid, values, req, start, count, stride, map, bufcount, buftype)
     integer,                                                intent( in) :: ncid, varid
     $4 (kind=$3), dimension($6),                            intent( $7) :: values
     integer,                                                intent(out) :: req
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent( in) :: start
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent( in) :: count
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent( in) :: stride
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent( in) :: map
     integer (kind=MPI_OFFSET_KIND),               optional, intent( in) :: bufcount
     integer,                                      optional, intent( in) :: buftype

     integer                                     :: nf90mpi_$1_var_$2D_$3
     integer (kind=MPI_OFFSET_KIND), allocatable :: localStart(:)
     integer (kind=MPI_OFFSET_KIND), allocatable :: localCount(:)
     integer (kind=MPI_OFFSET_KIND), allocatable :: localStride(:)
     integer (kind=MPI_OFFSET_KIND), allocatable :: localMap(:)
     integer                                     :: numDims
     ifelse(`$2', `1', ,`integer :: counter')

     ! inquire variable dimensionality
     nf90mpi_$1_var_$2D_$3 = nfmpi_inq_varndims(ncid, varid, numDims)
     if (nf90mpi_$1_var_$2D_$3 .NE. NF_NOERR) return

     if (numDims .GT. 0) then
         ! allocate local arrays
         allocate(localStart(numDims))
         allocate(localCount(numDims))
         allocate(localStride(numDims))
         allocate(localMap(numDims))
         if (present(start)) then
             localStart(:numDims) = start(:numDims)
         else
             ! Set local arguments to default values
             localStart(:) = 1
         endif
         if (present(count)) then
             localCount(:numDims) = count(:numDims)
         else
             ! Set local arguments to default values
             localCount(:$2) = shape(values)
             if (numDims .GT. $2) localCount($2+1:) = 1
         endif
         if (present(stride)) then
             localStride(:numDims) = stride(:numDims)
         else
             ! Set local arguments to default values
             localStride(:) = 1
         endif
         if (present(map)) then
             localMap(:numDims) = map(:numDims)
         else
             ! Set local arguments to default values
             ! localMap(:$2) = (/ 1, (product(localCount(:counter)), counter = 1, $2 - 1) /)
             localMap(1) = 1
             ifelse(`$2', `1', ,`
             do counter = 1, $2 - 1
                localMap(counter+1) = localMap(counter) * localCount(counter)
             enddo')
         endif
     endif

     if (present(map)) then
         if (present(buftype)) then
             nf90mpi_$1_var_$2D_$3 = &
                 nfmpi_$1_varm(ncid, varid, localStart, localCount, localStride, localMap, values, bufcount, buftype, req)
         else
             nf90mpi_$1_var_$2D_$3 = &
                 nfmpi_$1_varm_$5(ncid, varid, localStart, localCount, localStride, localMap, values, req)
         endif
     else if (present(stride)) then
         if (present(buftype)) then
             nf90mpi_$1_var_$2D_$3 = &
                 nfmpi_$1_vars(ncid, varid, localStart, localCount, localStride, values, bufcount, buftype, req)
         else
             nf90mpi_$1_var_$2D_$3 = &
                 nfmpi_$1_vars_$5(ncid, varid, localStart, localCount, localStride, values, req)
         endif
     else
         if (present(buftype)) then
             nf90mpi_$1_var_$2D_$3 = &
                 nfmpi_$1_vara(ncid, varid, localStart, localCount, values, bufcount, buftype, req)
         else
             nf90mpi_$1_var_$2D_$3 = &
                 nfmpi_$1_vara_$5(ncid, varid, localStart, localCount, values, req)
         endif
     endif
     if (numDims .GT. 0) then
         deallocate(localMap)
         deallocate(localStride)
         deallocate(localCount)
         deallocate(localStart)
     endif
   end function nf90mpi_$1_var_$2D_$3
')dnl

!
! iput APIs
!

NBVAR(iput, 1, OneByteInt, integer, int1,  :,              in)
NBVAR(iput, 2, OneByteInt, integer, int1, `:,:',           in)
NBVAR(iput, 3, OneByteInt, integer, int1, `:,:,:',         in)
NBVAR(iput, 4, OneByteInt, integer, int1, `:,:,:,:',       in)
NBVAR(iput, 5, OneByteInt, integer, int1, `:,:,:,:,:',     in)
NBVAR(iput, 6, OneByteInt, integer, int1, `:,:,:,:,:,:',   in)
NBVAR(iput, 7, OneByteInt, integer, int1, `:,:,:,:,:,:,:', in)

NBVAR(iput, 1, TwoByteInt, integer, int2,  :,              INTENTV)
NBVAR(iput, 2, TwoByteInt, integer, int2, `:,:',           INTENTV)
NBVAR(iput, 3, TwoByteInt, integer, int2, `:,:,:',         INTENTV)
NBVAR(iput, 4, TwoByteInt, integer, int2, `:,:,:,:',       INTENTV)
NBVAR(iput, 5, TwoByteInt, integer, int2, `:,:,:,:,:',     INTENTV)
NBVAR(iput, 6, TwoByteInt, integer, int2, `:,:,:,:,:,:',   INTENTV)
NBVAR(iput, 7, TwoByteInt, integer, int2, `:,:,:,:,:,:,:', INTENTV)

NBVAR(iput, 1, FourByteInt, integer, int,  :,              INTENTV)
NBVAR(iput, 2, FourByteInt, integer, int, `:,:',           INTENTV)
NBVAR(iput, 3, FourByteInt, integer, int, `:,:,:',         INTENTV)
NBVAR(iput, 4, FourByteInt, integer, int, `:,:,:,:',       INTENTV)
NBVAR(iput, 5, FourByteInt, integer, int, `:,:,:,:,:',     INTENTV)
NBVAR(iput, 6, FourByteInt, integer, int, `:,:,:,:,:,:',   INTENTV)
NBVAR(iput, 7, FourByteInt, integer, int, `:,:,:,:,:,:,:', INTENTV)

NBVAR(iput, 1, FourByteReal, real,   real,  :,              INTENTV)
NBVAR(iput, 2, FourByteReal, real,   real, `:,:',           INTENTV)
NBVAR(iput, 3, FourByteReal, real,   real, `:,:,:',         INTENTV)
NBVAR(iput, 4, FourByteReal, real,   real, `:,:,:,:',       INTENTV)
NBVAR(iput, 5, FourByteReal, real,   real, `:,:,:,:,:',     INTENTV)
NBVAR(iput, 6, FourByteReal, real,   real, `:,:,:,:,:,:',   INTENTV)
NBVAR(iput, 7, FourByteReal, real,   real, `:,:,:,:,:,:,:', INTENTV)

NBVAR(iput, 1, EightByteReal, real, double,  :,              INTENTV)
NBVAR(iput, 2, EightByteReal, real, double, `:,:',           INTENTV)
NBVAR(iput, 3, EightByteReal, real, double, `:,:,:',         INTENTV)
NBVAR(iput, 4, EightByteReal, real, double, `:,:,:,:',       INTENTV)
NBVAR(iput, 5, EightByteReal, real, double, `:,:,:,:,:',     INTENTV)
NBVAR(iput, 6, EightByteReal, real, double, `:,:,:,:,:,:',   INTENTV)
NBVAR(iput, 7, EightByteReal, real, double, `:,:,:,:,:,:,:', INTENTV)

NBVAR(iput, 1, EightByteInt, integer, int8,  :,              INTENTV)
NBVAR(iput, 2, EightByteInt, integer, int8, `:,:',           INTENTV)
NBVAR(iput, 3, EightByteInt, integer, int8, `:,:,:',         INTENTV)
NBVAR(iput, 4, EightByteInt, integer, int8, `:,:,:,:',       INTENTV)
NBVAR(iput, 5, EightByteInt, integer, int8, `:,:,:,:,:',     INTENTV)
NBVAR(iput, 6, EightByteInt, integer, int8, `:,:,:,:,:,:',   INTENTV)
NBVAR(iput, 7, EightByteInt, integer, int8, `:,:,:,:,:,:,:', INTENTV)

!
! iget APIs
!

NBVAR(iget, 1, OneByteInt, integer, int1,  :,              out)
NBVAR(iget, 2, OneByteInt, integer, int1, `:,:',           out)
NBVAR(iget, 3, OneByteInt, integer, int1, `:,:,:',         out)
NBVAR(iget, 4, OneByteInt, integer, int1, `:,:,:,:',       out)
NBVAR(iget, 5, OneByteInt, integer, int1, `:,:,:,:,:',     out)
NBVAR(iget, 6, OneByteInt, integer, int1, `:,:,:,:,:,:',   out)
NBVAR(iget, 7, OneByteInt, integer, int1, `:,:,:,:,:,:,:', out)

NBVAR(iget, 1, TwoByteInt, integer, int2,  :,              out)
NBVAR(iget, 2, TwoByteInt, integer, int2, `:,:',           out)
NBVAR(iget, 3, TwoByteInt, integer, int2, `:,:,:',         out)
NBVAR(iget, 4, TwoByteInt, integer, int2, `:,:,:,:',       out)
NBVAR(iget, 5, TwoByteInt, integer, int2, `:,:,:,:,:',     out)
NBVAR(iget, 6, TwoByteInt, integer, int2, `:,:,:,:,:,:',   out)
NBVAR(iget, 7, TwoByteInt, integer, int2, `:,:,:,:,:,:,:', out)

NBVAR(iget, 1, FourByteInt, integer, int,  :,              out)
NBVAR(iget, 2, FourByteInt, integer, int, `:,:',           out)
NBVAR(iget, 3, FourByteInt, integer, int, `:,:,:',         out)
NBVAR(iget, 4, FourByteInt, integer, int, `:,:,:,:',       out)
NBVAR(iget, 5, FourByteInt, integer, int, `:,:,:,:,:',     out)
NBVAR(iget, 6, FourByteInt, integer, int, `:,:,:,:,:,:',   out)
NBVAR(iget, 7, FourByteInt, integer, int, `:,:,:,:,:,:,:', out)

NBVAR(iget, 1, FourByteReal, real,   real,  :,              out)
NBVAR(iget, 2, FourByteReal, real,   real, `:,:',           out)
NBVAR(iget, 3, FourByteReal, real,   real, `:,:,:',         out)
NBVAR(iget, 4, FourByteReal, real,   real, `:,:,:,:',       out)
NBVAR(iget, 5, FourByteReal, real,   real, `:,:,:,:,:',     out)
NBVAR(iget, 6, FourByteReal, real,   real, `:,:,:,:,:,:',   out)
NBVAR(iget, 7, FourByteReal, real,   real, `:,:,:,:,:,:,:', out)

NBVAR(iget, 1, EightByteReal, real, double,  :,              out)
NBVAR(iget, 2, EightByteReal, real, double, `:,:',           out)
NBVAR(iget, 3, EightByteReal, real, double, `:,:,:',         out)
NBVAR(iget, 4, EightByteReal, real, double, `:,:,:,:',       out)
NBVAR(iget, 5, EightByteReal, real, double, `:,:,:,:,:',     out)
NBVAR(iget, 6, EightByteReal, real, double, `:,:,:,:,:,:',   out)
NBVAR(iget, 7, EightByteReal, real, double, `:,:,:,:,:,:,:', out)

NBVAR(iget, 1, EightByteInt, integer, int8,  :,              out)
NBVAR(iget, 2, EightByteInt, integer, int8, `:,:',           out)
NBVAR(iget, 3, EightByteInt, integer, int8, `:,:,:',         out)
NBVAR(iget, 4, EightByteInt, integer, int8, `:,:,:,:',       out)
NBVAR(iget, 5, EightByteInt, integer, int8, `:,:,:,:,:',     out)
NBVAR(iget, 6, EightByteInt, integer, int8, `:,:,:,:,:,:',   out)
NBVAR(iget, 7, EightByteInt, integer, int8, `:,:,:,:,:,:,:', out)

!
! bput APIs
!

NBVAR(bput, 1, OneByteInt, integer, int1,  :,              in)
NBVAR(bput, 2, OneByteInt, integer, int1, `:,:',           in)
NBVAR(bput, 3, OneByteInt, integer, int1, `:,:,:',         in)
NBVAR(bput, 4, OneByteInt, integer, int1, `:,:,:,:',       in)
NBVAR(bput, 5, OneByteInt, integer, int1, `:,:,:,:,:',     in)
NBVAR(bput, 6, OneByteInt, integer, int1, `:,:,:,:,:,:',   in)
NBVAR(bput, 7, OneByteInt, integer, int1, `:,:,:,:,:,:,:', in)

NBVAR(bput, 1, TwoByteInt, integer, int2,  :,              INTENTV)
NBVAR(bput, 2, TwoByteInt, integer, int2, `:,:',           INTENTV)
NBVAR(bput, 3, TwoByteInt, integer, int2, `:,:,:',         INTENTV)
NBVAR(bput, 4, TwoByteInt, integer, int2, `:,:,:,:',       INTENTV)
NBVAR(bput, 5, TwoByteInt, integer, int2, `:,:,:,:,:',     INTENTV)
NBVAR(bput, 6, TwoByteInt, integer, int2, `:,:,:,:,:,:',   INTENTV)
NBVAR(bput, 7, TwoByteInt, integer, int2, `:,:,:,:,:,:,:', INTENTV)

NBVAR(bput, 1, FourByteInt, integer, int,  :,              INTENTV)
NBVAR(bput, 2, FourByteInt, integer, int, `:,:',           INTENTV)
NBVAR(bput, 3, FourByteInt, integer, int, `:,:,:',         INTENTV)
NBVAR(bput, 4, FourByteInt, integer, int, `:,:,:,:',       INTENTV)
NBVAR(bput, 5, FourByteInt, integer, int, `:,:,:,:,:',     INTENTV)
NBVAR(bput, 6, FourByteInt, integer, int, `:,:,:,:,:,:',   INTENTV)
NBVAR(bput, 7, FourByteInt, integer, int, `:,:,:,:,:,:,:', INTENTV)

NBVAR(bput, 1, FourByteReal, real,   real,  :,              INTENTV)
NBVAR(bput, 2, FourByteReal, real,   real, `:,:',           INTENTV)
NBVAR(bput, 3, FourByteReal, real,   real, `:,:,:',         INTENTV)
NBVAR(bput, 4, FourByteReal, real,   real, `:,:,:,:',       INTENTV)
NBVAR(bput, 5, FourByteReal, real,   real, `:,:,:,:,:',     INTENTV)
NBVAR(bput, 6, FourByteReal, real,   real, `:,:,:,:,:,:',   INTENTV)
NBVAR(bput, 7, FourByteReal, real,   real, `:,:,:,:,:,:,:', INTENTV)

NBVAR(bput, 1, EightByteReal, real, double,  :,              INTENTV)
NBVAR(bput, 2, EightByteReal, real, double, `:,:',           INTENTV)
NBVAR(bput, 3, EightByteReal, real, double, `:,:,:',         INTENTV)
NBVAR(bput, 4, EightByteReal, real, double, `:,:,:,:',       INTENTV)
NBVAR(bput, 5, EightByteReal, real, double, `:,:,:,:,:',     INTENTV)
NBVAR(bput, 6, EightByteReal, real, double, `:,:,:,:,:,:',   INTENTV)
NBVAR(bput, 7, EightByteReal, real, double, `:,:,:,:,:,:,:', INTENTV)

NBVAR(bput, 1, EightByteInt, integer, int8,  :,              INTENTV)
NBVAR(bput, 2, EightByteInt, integer, int8, `:,:',           INTENTV)
NBVAR(bput, 3, EightByteInt, integer, int8, `:,:,:',         INTENTV)
NBVAR(bput, 4, EightByteInt, integer, int8, `:,:,:,:',       INTENTV)
NBVAR(bput, 5, EightByteInt, integer, int8, `:,:,:,:,:',     INTENTV)
NBVAR(bput, 6, EightByteInt, integer, int8, `:,:,:,:,:,:',   INTENTV)
NBVAR(bput, 7, EightByteInt, integer, int8, `:,:,:,:,:,:,:', INTENTV)

!
! Other nonblocking control APIs
!

   function nf90mpi_wait(ncid, num, req, st)
     integer,               intent(in)    :: ncid, num
     integer, dimension(:), intent(inout) :: req
     integer, dimension(:), intent(out)   :: st
     integer                              :: nf90mpi_wait

     nf90mpi_wait = nfmpi_wait(ncid, num, req, st)
   end function nf90mpi_wait

   function nf90mpi_wait_all(ncid, num, req, st)
     integer,               intent(in)    :: ncid, num
     integer, dimension(:), intent(inout) :: req
     integer, dimension(:), intent(out)   :: st
     integer                              :: nf90mpi_wait_all

     nf90mpi_wait_all = nfmpi_wait_all(ncid, num, req, st)
   end function nf90mpi_wait_all

   function nf90mpi_cancel(ncid, num, req, st)
     integer,               intent(in)    :: ncid, num
     integer, dimension(:), intent(inout) :: req
     integer, dimension(:), intent(out)   :: st
     integer                              :: nf90mpi_cancel

     nf90mpi_cancel = nfmpi_cancel(ncid, num, req, st)
   end function nf90mpi_cancel

   function nf90mpi_buffer_attach(ncid, bufsize)
     integer,                        intent( in) :: ncid
     integer (kind=MPI_OFFSET_KIND), intent( in) :: bufsize
     integer                                     :: nf90mpi_buffer_attach

     nf90mpi_buffer_attach = nfmpi_buffer_attach(ncid, bufsize)
   end function nf90mpi_buffer_attach

   function nf90mpi_inq_buffer_usage(ncid, usage)
     integer,                        intent( in) :: ncid
     integer (kind=MPI_OFFSET_KIND), intent(out) :: usage
     integer                                     :: nf90mpi_inq_buffer_usage

     nf90mpi_inq_buffer_usage = nfmpi_inq_buffer_usage(ncid, usage)
   end function nf90mpi_inq_buffer_usage

   function nf90mpi_inq_buffer_size(ncid, buf_size)
     integer,                        intent( in) :: ncid
     integer (kind=MPI_OFFSET_KIND), intent(out) :: buf_size
     integer                                     :: nf90mpi_inq_buffer_size

     nf90mpi_inq_buffer_size = nfmpi_inq_buffer_usage(ncid, buf_size)
   end function nf90mpi_inq_buffer_size

   function nf90mpi_buffer_detach(ncid)
     integer,                       intent( in) :: ncid
     integer                                    :: nf90mpi_buffer_detach

     nf90mpi_buffer_detach = nfmpi_buffer_detach(ncid)
   end function nf90mpi_buffer_detach


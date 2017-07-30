dnl Process this m4 file to produce 'C' language file.
dnl
dnl If you see this line, you can ignore the next one.
/* Do not edit this file. It is produced from the corresponding .m4 source */
dnl
/*
 *  Copyright (C) 2017, Northwestern University and Argonne National Laboratory
 *  See COPYRIGHT notice in top-level directory.
 */
/* $Id$ */

#ifdef HAVE_CONFIG_H
# include <config.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h> /* memcpy() */

#include <unistd.h>
#ifdef HAVE_INTTYPES_H
#include <inttypes.h> /* uint16_t, uint32_t, uint64_t */
#elif defined(HAVE_STDINT_H)
#include <stdint.h>   /* uint16_t, uint32_t, uint64_t */
#endif
#include <assert.h>

#include <mpi.h>

#include <pnetcdf.h>
#include <pnc_debug.h>
#include <common.h>
#include <ncx.h>

/*
 * The NetCDF CDF formats define external NC data types and describe their
 * intents of use, also shown below.
 *
 *   external type   No. Bits   Intent of use
 *   -------------   --------   ---------------------------------
 *   NC_CHAR          8         text data (only non-numerical type in NetCDF)
 *   NC_BYTE          8         1-byte integer
 *   NC_SHORT        16         2-byte signed integer
 *   NC_INT          32         4-byte signed integer
 *   NC_FLOAT        32         4-byte floating point number
 *   NC_DOUBLE       64         8-byte real number in double precision
 *   NC_UBYTE         8         unsigned 1-byte integer
 *   NC_USHORT       16         unsigned 2-byte integer
 *   NC_UINT         32         unsigned 4-byte integer
 *   NC_INT64        64         signed 8-byte integer
 *   NC_UINT64       64         unsigned 8-byte integer
 *
 *
 * Datatype Mapping between in-memory types and MPI datatypes:
 *
 *   internal type of
 *   I/O buffer argument   example API              MPI datatype
 *   -------------------   ----------------------   -----------------
 *   char*                 ncmpi_put_var_text       MPI_CHAR
 *   signed char*          ncmpi_put_var_schar      MPI_SIGNED_CHAR
 *   unsigned char*        ncmpi_put_var_uchar      MPI_UNSIGNED_CHAR
 *   short*                ncmpi_put_var_short      MPI_SHORT
 *   unsigned short*       ncmpi_put_var_ushort     MPI_UNSIGNED_SHORT
 *   int*                  ncmpi_put_var_int        MPI_INT
 *   unsigned int*         ncmpi_put_var_uint       MPI_UNSIGNED
 *   long*                 ncmpi_put_var_long       MPI_LONG
 *   float*                ncmpi_put_var_float      MPI_FLOAT
 *   double*               ncmpi_put_var_double     MPI_DOUBLE
 *   long long*            ncmpi_put_var_longlong   MPI_LONG_LONG_INT
 *   unsigned long long*   ncmpi_put_var_ulonglong  MPI_UNSIGNED_LONG_LONG
 *
 *
 * Note NC_CHAR is the only non-numerical data type available in NetCDF realm.
 * All other external types are considered numerical, which are illegal to be
 * converted (type-casted) to and from a variable defined in NC_CHAR type. The
 * only legal APIs to read/write a variable of type NC_CHAR are "_text" APIs.
 *
 */

/*----< check_cast() >-------------------------------------------------------*/
/* netCDF specification makes a special case for type conversion between
 * uchar and NC_BYTE: do not check for range error. See
 * http://www.unidata.ucar.edu/software/netcdf/docs/data_type.html#type_conversion
 */
static int
check_cast(int          format, /* 1, 2, or 5 (CDF format number) */
           nc_type      xtype,  /* external NC type */
           MPI_Datatype itype)  /* internal MPI type */
{
    if (xtype == NC_CHAR) { /* NC_ECHAR is already checked before here */
        assert(itype == MPI_CHAR);
        return 0;
    }

    if (format < NC_FORMAT_CDF5 &&
        xtype == NC_BYTE && itype == MPI_UNSIGNED_CHAR) return 0;

    if (itype == MPI_LONG && SIZEOF_LONG == SIZEOF_INT) itype = MPI_INT;

    return !( (xtype == NC_BYTE   && itype == MPI_SIGNED_CHAR)    ||
              (xtype == NC_SHORT  && itype == MPI_SHORT)          ||
              (xtype == NC_INT    && itype == MPI_INT)            ||
              (xtype == NC_FLOAT  && itype == MPI_FLOAT)          ||
              (xtype == NC_DOUBLE && itype == MPI_DOUBLE)         ||
              (xtype == NC_UBYTE  && itype == MPI_UNSIGNED_CHAR)  ||
              (xtype == NC_USHORT && itype == MPI_UNSIGNED_SHORT) ||
              (xtype == NC_UINT   && itype == MPI_UNSIGNED)       ||
              (xtype == NC_INT64  && itype == MPI_LONG_LONG_INT)  ||
              (xtype == NC_UINT64 && itype == MPI_UNSIGNED_LONG_LONG)
            );
}

/*----< check_swap() >-------------------------------------------------------*/
static int
check_swap(nc_type      xtype,  /* external NC type */
           MPI_Datatype itype)  /* internal MPI type */
{
#ifdef WORDS_BIGENDIAN
    return 0;
#else
    if ((xtype == NC_CHAR  && itype == MPI_CHAR)           ||
        (xtype == NC_BYTE  && itype == MPI_SIGNED_CHAR)    ||
        (xtype == NC_UBYTE && itype == MPI_UNSIGNED_CHAR))
        return 0;

    return 1;
#endif
}

int
ncmpio_need_convert(int format, nc_type xtype, MPI_Datatype itype)
{
    return check_cast(format, xtype, itype);
}

/*----< ncmpio_need_swap() >-------------------------------------------------*/
int
ncmpio_need_swap(nc_type xtype, MPI_Datatype itype)
{
    return check_swap(xtype, itype);
}


/* Other options to in-place byte-swap
htonl() is for 4-byte swap
htons() is for 2-byte swap

#include <arpa/inet.h>
    dest[i] = htonl(dest[i]);
    dest[i] = htons(dest[i]);

Or

#include <byteswap.h>

        for (i=0; i<nelems; i++)
            dest[i] = __bswap_32(dest[i]);

*/

/*----< ncmpii_in_swapn() >--------------------------------------------------*/
/* in-place byte swap */
void
ncmpii_in_swapn(void       *buf,
                MPI_Offset  nelems,  /* number of elements in buf[] */
                int         esize)   /* byte size of each element */
{
#ifdef WORDS_BIGENDIAN
    return;
#else
    size_t i;

    if (esize <= 1 || nelems <= 0) return;  /* no need */

    if (esize == 4) { /* this is the most common case */
        uint32_t *dest = (uint32_t*) buf;
        for (i=0; i<nelems; i++)
            dest[i] =  ((dest[i]) << 24)
                    | (((dest[i]) & 0x0000ff00) << 8)
                    | (((dest[i]) & 0x00ff0000) >> 8)
                    | (((dest[i]) >> 24));
    }
    else if (esize == 8) {
        uint64_t *dest = (uint64_t*) buf;
        for (i=0; i<nelems; i++)
            dest[i] = ((dest[i] & 0x00000000000000FFULL) << 56) | 
                      ((dest[i] & 0x000000000000FF00ULL) << 40) | 
                      ((dest[i] & 0x0000000000FF0000ULL) << 24) | 
                      ((dest[i] & 0x00000000FF000000ULL) <<  8) | 
                      ((dest[i] & 0x000000FF00000000ULL) >>  8) | 
                      ((dest[i] & 0x0000FF0000000000ULL) >> 24) | 
                      ((dest[i] & 0x00FF000000000000ULL) >> 40) | 
                      ((dest[i] & 0xFF00000000000000ULL) >> 56);
    }
    else if (esize == 2) {
        uint16_t *dest = (uint16_t*) buf;
        for (i=0; i<nelems; i++)
            dest[i] = (uint16_t)(((dest[i] & 0xff) << 8) |
                                 ((dest[i] >> 8) & 0xff));
    }
    else {
        uchar tmp, *op = (uchar*)buf;
        /* for esize is not 1, 2, or 4 */
        while (nelems-- > 0) {
            for (i=0; i<esize/2; i++) {
                tmp           = op[i];
                op[i]         = op[esize-1-i];
                op[esize-1-i] = tmp;
            }
            op += esize;
        }
    }
#endif
}

dnl
dnl PUTN_XTYPE(xtype)
dnl
define(`PUTN_XTYPE',dnl
`dnl
/*----< putn_$1() >----------------------------------------------------------*/
/* Only xtype and itype do not match and type casting is required will call
 * this subroutine.
 */
static int
putn_$1(ifelse(`$1',`NC_BYTE',`int cdf_ver,/* 1,2,or 5 CDF format */')
        void         *xp,     /* buffer of external type $1 */
        const void   *buf,    /* user buffer of internal type, itype */
        MPI_Offset    nelems,
        MPI_Datatype  itype,  /* internal data type (MPI_Datatype) */
        void         *fillp)  /* in internal representation */
{
    assert(itype != MPI_CHAR); /* ECHAR should have been checked already */

    if (itype == MPI_UNSIGNED_CHAR) {
        ifelse(`$1',`NC_BYTE',
       `if (cdf_ver < 5)
            return ncmpix_putn_NC_UBYTE_uchar(&xp, nelems,(const uchar*)buf, fillp);
        else')
            return ncmpix_putn_$1_uchar(&xp, nelems, (const uchar*)     buf, fillp);
    }
    else if (itype == MPI_SIGNED_CHAR) /* This is for 1-byte integer */
        return ncmpix_putn_$1_schar    (&xp, nelems, (const schar*)     buf, fillp);
    else if (itype == MPI_SHORT)
        return ncmpix_putn_$1_short    (&xp, nelems, (const short*)     buf, fillp);
    else if (itype == MPI_UNSIGNED_SHORT)
        return ncmpix_putn_$1_ushort   (&xp, nelems, (const ushort*)    buf, fillp);
    else if (itype == MPI_INT)
        return ncmpix_putn_$1_int      (&xp, nelems, (const int*)       buf, fillp);
    else if (itype == MPI_UNSIGNED)
        return ncmpix_putn_$1_uint     (&xp, nelems, (const uint*)      buf, fillp);
    else if (itype == MPI_LONG)
        return ncmpix_putn_$1_long     (&xp, nelems, (const long*)      buf, fillp);
    else if (itype == MPI_FLOAT)
        return ncmpix_putn_$1_float    (&xp, nelems, (const float*)     buf, fillp);
    else if (itype == MPI_DOUBLE)
        return ncmpix_putn_$1_double   (&xp, nelems, (const double*)    buf, fillp);
    else if (itype == MPI_LONG_LONG_INT)
        return ncmpix_putn_$1_longlong (&xp, nelems, (const longlong*)  buf, fillp);
    else if (itype == MPI_UNSIGNED_LONG_LONG)
        return ncmpix_putn_$1_ulonglong(&xp, nelems, (const ulonglong*) buf, fillp);
    DEBUG_RETURN_ERROR(NC_EBADTYPE)
}
')dnl

PUTN_XTYPE(NC_UBYTE)
PUTN_XTYPE(NC_SHORT)
PUTN_XTYPE(NC_USHORT)
PUTN_XTYPE(NC_INT)
PUTN_XTYPE(NC_UINT)
PUTN_XTYPE(NC_FLOAT)
PUTN_XTYPE(NC_DOUBLE)
PUTN_XTYPE(NC_INT64)
PUTN_XTYPE(NC_UINT64)

/* In CDF-2, NC_BYTE is considered a signed 1-byte integer in signed APIs, and
 * unsigned 1-byte integer in unsigned APIs. In CDF-5, NC_BYTE is always a
 * signed 1-byte integer. See
 * http://www.unidata.ucar.edu/software/netcdf/docs/data_type.html#type_conversion
 */
PUTN_XTYPE(NC_BYTE)


int ncmpio_x_putn_NC_BYTE(int cdf_ver, void *xp, const void *buf, MPI_Offset nelems, MPI_Datatype itype, void *fillp) { return putn_NC_BYTE(cdf_ver, xp, buf, nelems, itype, fillp); }
int ncmpio_x_putn_NC_UBYTE(void *xp, const void *buf, MPI_Offset nelems, MPI_Datatype itype, void *fillp) { return putn_NC_UBYTE(xp, buf, nelems, itype, fillp); }
int ncmpio_x_putn_NC_SHORT(void *xp, const void *buf, MPI_Offset nelems, MPI_Datatype itype, void *fillp) { return putn_NC_SHORT(xp, buf, nelems, itype, fillp); }
int ncmpio_x_putn_NC_USHORT(void *xp, const void *buf, MPI_Offset nelems, MPI_Datatype itype, void *fillp) { return putn_NC_USHORT(xp, buf, nelems, itype, fillp); }
int ncmpio_x_putn_NC_INT(void *xp, const void *buf, MPI_Offset nelems, MPI_Datatype itype, void *fillp) { return putn_NC_INT(xp, buf, nelems, itype, fillp); }
int ncmpio_x_putn_NC_UINT(void *xp, const void *buf, MPI_Offset nelems, MPI_Datatype itype, void *fillp) { return putn_NC_UINT(xp, buf, nelems, itype, fillp); }
int ncmpio_x_putn_NC_FLOAT(void *xp, const void *buf, MPI_Offset nelems, MPI_Datatype itype, void *fillp) { return putn_NC_FLOAT(xp, buf, nelems, itype, fillp); }
int ncmpio_x_putn_NC_DOUBLE(void *xp, const void *buf, MPI_Offset nelems, MPI_Datatype itype, void *fillp) { return putn_NC_DOUBLE(xp, buf, nelems, itype, fillp); }
int ncmpio_x_putn_NC_INT64(void *xp, const void *buf, MPI_Offset nelems, MPI_Datatype itype, void *fillp) { return putn_NC_INT64(xp, buf, nelems, itype, fillp); }
int ncmpio_x_putn_NC_UINT64(void *xp, const void *buf, MPI_Offset nelems, MPI_Datatype itype, void *fillp) { return putn_NC_UINT64(xp, buf, nelems, itype, fillp); }


dnl
dnl GETN_XTYPE(xtype)
dnl
define(`GETN_XTYPE',dnl
`dnl
/*----< getn_$1() >----------------------------------------------------------*/
/* Only xtype and itype do not match and type casting is required will call
 * this subroutine.
 */
static int
getn_$1(ifelse(`$1',`NC_BYTE',`int cdf_ver,/* 1,2,or 5 CDF format */')
        const void   *xp,     /* buffer of external type $1 */
        void         *ip,     /* user buffer of internal type, itype */
        MPI_Offset    nelems,
        MPI_Datatype  itype)  /* internal data type (MPI_Datatype) */
{
    assert(itype != MPI_CHAR); /* ECHAR should have been checked already */

    if (itype == MPI_UNSIGNED_CHAR) {
        ifelse(`$1',`NC_BYTE',`if (cdf_ver < 5)
            return ncmpix_getn_NC_UBYTE_uchar(&xp, nelems,(uchar*)ip);
        else')
            return ncmpix_getn_$1_uchar(&xp, nelems,      (uchar*)ip);
    }
    else if (itype == MPI_SIGNED_CHAR)
        return ncmpix_getn_$1_schar    (&xp, nelems,      (schar*)ip);
    else if (itype == MPI_SHORT)
        return ncmpix_getn_$1_short    (&xp, nelems,      (short*)ip);
    else if (itype == MPI_UNSIGNED_SHORT)
        return ncmpix_getn_$1_ushort   (&xp, nelems,     (ushort*)ip);
    else if (itype == MPI_INT)
        return ncmpix_getn_$1_int      (&xp, nelems,        (int*)ip);
    else if (itype == MPI_UNSIGNED)
        return ncmpix_getn_$1_uint     (&xp, nelems,       (uint*)ip);
    else if (itype == MPI_LONG)
        return ncmpix_getn_$1_long     (&xp, nelems,       (long*)ip);
    else if (itype == MPI_FLOAT)
        return ncmpix_getn_$1_float    (&xp, nelems,      (float*)ip);
    else if (itype == MPI_DOUBLE)
        return ncmpix_getn_$1_double   (&xp, nelems,     (double*)ip);
    else if (itype == MPI_LONG_LONG_INT)
        return ncmpix_getn_$1_longlong (&xp, nelems,   (longlong*)ip);
    else if (itype == MPI_UNSIGNED_LONG_LONG)
        return ncmpix_getn_$1_ulonglong(&xp, nelems,  (ulonglong*)ip);
    DEBUG_RETURN_ERROR(NC_EBADTYPE)
}
')dnl

GETN_XTYPE(NC_UBYTE)
GETN_XTYPE(NC_SHORT)
GETN_XTYPE(NC_USHORT)
GETN_XTYPE(NC_INT)
GETN_XTYPE(NC_UINT)
GETN_XTYPE(NC_FLOAT)
GETN_XTYPE(NC_DOUBLE)
GETN_XTYPE(NC_INT64)
GETN_XTYPE(NC_UINT64)

/* In CDF-2, NC_BYTE is considered a signed 1-byte integer in signed APIs, and
 * unsigned 1-byte integer in unsigned APIs. In CDF-5, NC_BYTE is always a
 * signed 1-byte integer. See
 * http://www.unidata.ucar.edu/software/netcdf/docs/data_type.html#type_conversion
 */
GETN_XTYPE(NC_BYTE)

int ncmpio_x_getn_NC_BYTE(int cdf_ver, const void *xp, void *ip, MPI_Offset nelems, MPI_Datatype itype) { return getn_NC_BYTE(cdf_ver, xp, ip, nelems, itype); }
int ncmpio_x_getn_NC_UBYTE(const void *xp, void *ip, MPI_Offset nelems, MPI_Datatype itype) { return getn_NC_UBYTE(xp, ip, nelems, itype); }
int ncmpio_x_getn_NC_SHORT(const void *xp, void *ip, MPI_Offset nelems, MPI_Datatype itype) { return getn_NC_SHORT(xp, ip, nelems, itype); }
int ncmpio_x_getn_NC_USHORT(const void *xp, void *ip, MPI_Offset nelems, MPI_Datatype itype) { return getn_NC_USHORT(xp, ip, nelems, itype); }
int ncmpio_x_getn_NC_INT(const void *xp, void *ip, MPI_Offset nelems, MPI_Datatype itype) { return getn_NC_INT(xp, ip, nelems, itype); }
int ncmpio_x_getn_NC_UINT(const void *xp, void *ip, MPI_Offset nelems, MPI_Datatype itype) { return getn_NC_UINT(xp, ip, nelems, itype); }
int ncmpio_x_getn_NC_FLOAT(const void *xp, void *ip, MPI_Offset nelems, MPI_Datatype itype) { return getn_NC_FLOAT(xp, ip, nelems, itype); }
int ncmpio_x_getn_NC_DOUBLE(const void *xp, void *ip, MPI_Offset nelems, MPI_Datatype itype) { return getn_NC_DOUBLE(xp, ip, nelems, itype); }
int ncmpio_x_getn_NC_INT64(const void *xp, void *ip, MPI_Offset nelems, MPI_Datatype itype) { return getn_NC_INT64(xp, ip, nelems, itype); }
int ncmpio_x_getn_NC_UINT64(const void *xp, void *ip, MPI_Offset nelems, MPI_Datatype itype) { return getn_NC_UINT64(xp, ip, nelems, itype); }


/*----< ncmpii_put_cast_swap() >---------------------------------------------*/
/* type casting and Endianness byte swap if needed */
int
ncmpii_put_cast_swap(int            format, /* NC_FORMAT_CDF2/NC_FORMAT_CDF5 */
                     MPI_Offset     nelems,   /* number of data elements */
                     nc_type        xtype,    /* external data type */
                     MPI_Datatype   itype,    /* internal data type */
                     void          *fillp,    /* pointer to fill value */
                     void          *ibuf,     /* buffer in internal type */
                     int            isNewBuf, /* whether ibuf != user buf */
                     void         **xbuf)     /* OUT: buffer in external type */
{
    int err=NC_NOERR, xsz=0;
    size_t nbytes;

    *xbuf = ibuf;

    ncmpii_xlen_nc_type(xtype, &xsz);
    nbytes = (size_t)(nelems * xsz);

    /* pack ibuf to xbuf. The contents of xbuf will be in the external
     * representation, ready to be written to file.
     */
    if (check_cast(format, xtype, itype)) {
        /* user buf type mismatches NC var type */

        *xbuf = NCI_Malloc(nbytes);
        if (*xbuf == NULL) DEBUG_RETURN_ERROR(NC_ENOMEM)

        /* datatype conversion + byte-swap from ibuf to xbuf */
        switch(xtype) {
            case NC_BYTE:
                err = putn_NC_BYTE(format,*xbuf,ibuf,nelems,itype,fillp);
                break;
            case NC_UBYTE:
                err = putn_NC_UBYTE(*xbuf,ibuf,nelems,itype,fillp);
                break;
            case NC_SHORT:
                err = putn_NC_SHORT(*xbuf,ibuf,nelems,itype,fillp);
                break;
            case NC_USHORT:
                err = putn_NC_USHORT(*xbuf,ibuf,nelems,itype,fillp);
                break;
            case NC_INT:
                err = putn_NC_INT(*xbuf,ibuf,nelems,itype,fillp);
                break;
            case NC_UINT:
                err = putn_NC_UINT(*xbuf,ibuf,nelems,itype,fillp);
                break;
            case NC_FLOAT:
                err = putn_NC_FLOAT(*xbuf,ibuf,nelems,itype,fillp);
                break;
            case NC_DOUBLE:
                err = putn_NC_DOUBLE(*xbuf,ibuf,nelems,itype,fillp);
                break;
            case NC_INT64:
                err = putn_NC_INT64(*xbuf,ibuf,nelems,itype,fillp);
                break;
            case NC_UINT64:
                err = putn_NC_UINT64(*xbuf,ibuf,nelems,itype,fillp);
                break;
            default:
                err = NC_EBADTYPE;
                break;
        }

        /* NC_ERANGE can be caused by some elements in ibuf that is out of
         * range of the external data type, it is not considered a fatal error
         * and the request must continue to finish.
         */
        if (err != NC_NOERR && err != NC_ERANGE) {
            NCI_Free(*xbuf);
            *xbuf = NULL;
            return err;
        }
    }
    else if (check_swap(xtype, itype)) { /* no casting, just byte swap */
#ifdef DISABLE_IN_PLACE_SWAP
        if (!isNewBuf)
#else
        if (!isNewBuf && nbytes <= NC_BYTE_SWAP_BUFFER_SIZE)
#endif
        {
            /* allocate ibuf and copy buf to xbuf, before byte-swap */
            *xbuf = NCI_Malloc(nbytes);
            if (*xbuf == NULL) DEBUG_RETURN_ERROR(NC_ENOMEM)

            memcpy(*xbuf, ibuf, nbytes);
        }

        /* perform array in-place byte-swap on xbuf */
        ncmpii_in_swapn(*xbuf, nelems, xsz);
    }
    return err;
}

/*----< ncmpii_get_cast_swap() >---------------------------------------------*/
/* type casting and Endianness byte swap if needed */
int
ncmpii_get_cast_swap(int            format, /* NC_FORMAT_CDF2/NC_FORMAT_CDF5 */
                     MPI_Offset     nelems, /* number of data elements */
                     nc_type        xtype,  /* external data type */
                     MPI_Datatype   itype,  /* internal data type */
                     void          *buf,    /* user buffer */
                     void          *xbuf,   /* buffer in external type */
                     void         **ibuf)   /* OUT: buffer in internal type */
{
    /* xbuf contains the data read from file and in external data type */
    int err=NC_NOERR, xsz=0;
    size_t nbytes;

    MPI_Type_size(itype, &xsz);
    nbytes = (size_t)(nelems * xsz);

    if (check_cast(format, xtype, itype)) {
        /* user buf type mismatches NC var type */

        /* xbuf cannot be buf, but ibuf can */
        if (buf == NULL) { /* meaning ibuf cannot be buf */
            *ibuf = NCI_Malloc(nbytes);
            if (*ibuf == NULL) DEBUG_RETURN_ERROR(NC_ENOMEM)
        }
        else
            *ibuf = buf; /* both imap buftype are contiguous */

        /* type conversion + byte-swap from xbuf to ibuf */
        switch(xtype) {
            case NC_BYTE:
                err = getn_NC_BYTE(format,xbuf,*ibuf,nelems,itype);
                break;
            case NC_UBYTE:
                err = getn_NC_UBYTE(xbuf,*ibuf,nelems,itype);
                break;
            case NC_SHORT:
                err = getn_NC_SHORT(xbuf,*ibuf,nelems,itype);
                break;
            case NC_USHORT:
                err = getn_NC_USHORT(xbuf,*ibuf,nelems,itype);
                break;
            case NC_INT:
                err = getn_NC_INT(xbuf,*ibuf,nelems,itype);
                break;
            case NC_UINT:
                err = getn_NC_UINT(xbuf,*ibuf,nelems,itype);
                break;
            case NC_FLOAT:
                err = getn_NC_FLOAT(xbuf,*ibuf,nelems,itype);
                break;
            case NC_DOUBLE:
                err = getn_NC_DOUBLE(xbuf,*ibuf,nelems,itype);
                break;
            case NC_INT64:
                err = getn_NC_INT64(xbuf,*ibuf,nelems,itype);
                break;
            case NC_UINT64:
                err = getn_NC_UINT64(xbuf,*ibuf,nelems,itype);
                break;
            default:
                err = NC_EBADTYPE;
                break;
        }
        /* NC_ERANGE can be caused by some elements in xbuf that is out of
         * range of the internal data type, it is not considered a fatal error
         * and the request must continue to finish.
         */
        if (err != NC_NOERR && err != NC_ERANGE) {
            if (*ibuf != buf) NCI_Free(*ibuf);
            *ibuf = NULL;
            return err;
        }
    }
    else {
        if (check_swap(xtype, itype)) /* no need to convert, just byte swap */
            ncmpii_in_swapn(xbuf, nelems, xsz);
        *ibuf = xbuf;
    }

    return err;
}

/*
 *  Copyright (C) 2003, Northwestern University and Argonne National Laboratory
 *  See COPYRIGHT notice in top-level directory.
 */
/* $Id$ */

#ifndef _NC_H
#define _NC_H

/*
 * netcdf library 'private' data structures, objects and interfaces
 */

#include <stddef.h>     /* size_t */
#include <sys/types.h>  /* off_t */

#include <dispatch.h>
#include "ncmpio_driver.h"

#define FILE_ALIGNMENT_DEFAULT 512
#define HEADER_ALIGNMENT_LB    4

/* define MPI_OFFSET if not defined */
#ifndef HAVE_DECL_MPI_OFFSET
    #ifdef HAVE_DECL_MPI_LONG_LONG_INT
        #define MPI_OFFSET MPI_LONG_LONG_INT
    #else
        #define MPI_OFFSET MPI_INT
    #endif
#endif

/* XXX: this seems really low.  do we end up spending a ton of time mallocing?
 * could we reduce that by increasing this to something 21st century? */
#ifndef NC_ARRAY_GROWBY
#define NC_ARRAY_GROWBY 64
#endif

/* ncmpi_create/ncmpi_open set up header to be 'chunksize' big and to grow
 * by 'chunksize' as new items added. This used to be 4k. 256k lets us read
 * in an entire climate header in one go */
#define NC_DEFAULT_CHUNKSIZE 262144

/* when variable's nctype is NC_CHAR, I/O buffer's MPI type must be MPI_CHAR
 * and vice versa */
#define NCMPII_ECHAR(nctype, mpitype) ((((nctype) == NC_CHAR) == ((mpitype) != MPI_CHAR)) ? NC_ECHAR : NC_NOERR)

/*
 * The extern size of an empty
 * netcdf version 1 file.
 * The initial value of ncp->xsz.
 */
#define MIN_NC_XSZ 32

typedef enum {
    NC_UNSPECIFIED =  0,
    NC_DIMENSION   = 10,  /* \x00 \x00 \x00 \x0A */
    NC_VARIABLE    = 11,  /* \x00 \x00 \x00 \x0B */
    NC_ATTRIBUTE   = 12   /* \x00 \x00 \x00 \x0C */
} NC_tag;

/* netcdf file format:
     netcdf_file  = header  data
     header       = magic  numrecs  dim_list  gatt_list  var_list
     magic        = 'C'  'D'  'F'  VERSION
     VERSION      = \x01 | \x02 | \x05
     numrecs      = NON_NEG | STREAMING
     dim_list     = ABSENT | NC_DIMENSION  nelems  [dim ...]
     gatt_list    = att_list
     att_list     = ABSENT | NC_ATTRIBUTE  nelems  [attr ...]
     var_list     = ABSENT | NC_VARIABLE   nelems  [var ...]
     ABSENT       = ZERO  ZERO                  // Means list is not present
     ZERO         = \x00 \x00 \x00 \x00         // 32-bit zero

  Minimum happens when nothing is defined, i.e.
     magic              -- 4 bytes
     numrecs            -- 4 bytes for CDF-1 and CDF-2, 8 bytes for CDF-5
     dim_list = ABSENT  -- 8 bytes
     gatt_list = ABSENT -- 8 bytes
     var_list = ABSENT  -- 8 bytes
*/

typedef struct NC NC; /* forward reference */

#define NC_NAME_TABLE_CHUNK 16
#define HASH_TABLE_SIZE 256
/*
#define HASH_FUNC(x) ncmpio_jenkins_one_at_a_time_hash(x)
#define HASH_FUNC(x) ncmpio_additive_hash(x)
#define HASH_FUNC(x) ncmpio_rotating_hash(x)
#define HASH_FUNC(x) ncmpio_Pearson_hash(x)
*/
#define HASH_FUNC(x) ncmpio_Bernstein_hash(x)
/* Look like Bernstein's hashing function performs the best */

/* For the initial naive implementation of hashing:
 * #define HASH_FUNC(x) (unsigned char)x[0]
 * if used this simple hash function, HASH_TABLE_SIZE must be 256 which is the
 * number of possible keys can be stored in an unsigned char
 */

typedef struct NC_nametable {
    int  num;  /* number of elements added in the list array. Its value starts
                  with zero and incremented with new name is created. When its
                  value becomes a multiple of NC_NAME_TABLE_CHUNK, list will be
                  reallocated to a space of size (num + NC_NAME_TABLE_CHUNK) */
    int *list; /* dimension or variable IDs */
} NC_nametable;

/*
 * NC dimension structure
 */
typedef struct {
    MPI_Offset  size;
    size_t      name_len; /* strlen(name), for faster string compare */
    char       *name;
} NC_dim;

/* the dimension ID returned from ncmpi_def_dim() is an integer pointer
 * which means the total number of defined dimension allowed in a file
 * is up to 2^31-1. Thus, the member ndefined below should be of type int.
 */
typedef struct NC_dimarray {
    size_t         ndefined;      /* number of defined dimensions */
    int            unlimited_id;  /* -1 for not defined, otherwise >= 0 */
    NC_dim       **value;
    NC_nametable   nameT[HASH_TABLE_SIZE]; /* table for quick name lookup.
                    * indices 0, 1, ... HASH_TABLE_SIZE-1 are the hash keys.
                    * nameT[i].num is the number of hash collisions. The IDs of
                    * dimensions with names producing the same hash key i are
                    * stored in nameT[i].list[*]
                    */
} NC_dimarray;

/* Begin defined in dim.c ---------------------------------------------------*/
extern void
ncmpio_free_NC_dimarray(NC_dimarray *ncap);

extern int
ncmpio_dup_NC_dimarray(NC_dimarray *ncap, const NC_dimarray *ref);

/*
 * NC attribute
 *
 * Number of attributes is limited by 2^31-1 because the argument attnump in
 *  int nc_inq_attid(int ncid, int varid, const char *name, int *attnump);
 * is a signed 4-byte integer.
 */
typedef struct {
    MPI_Offset nelems;   /* number of attribute elements */
    MPI_Offset xsz;      /* amount of space at xvalue (4-byte aligned) */
    nc_type    xtype;    /* external NC data type of the attribute */
    size_t     name_len; /* strlen(name) for faster string compare */
    char      *name;     /* name of the attributes */
    void      *xvalue;   /* the actual data, in external representation */
} NC_attr;

typedef struct NC_attrarray {
    size_t         ndefined;  /* number of defined attributes */
    NC_attr      **value;
    NC_nametable   nameT[HASH_TABLE_SIZE]; /* table for quick name lookup.
                    * indices 0, 1, ... HASH_TABLE_SIZE-1 are the hash keys.
                    * nameT[i].num is the number of hash collisions. The IDs of
                    * variables with names producing the same hash key i are
                    * stored in nameT[i].list[*]
                    */
} NC_attrarray;

/* Begin defined in attr.c --------------------------------------------------*/
extern int
ncmpio_new_NC_attr(char *name, nc_type xtype, MPI_Offset nelems, NC_attr **attrp);

extern int
ncmpio_NC_findattr(const NC_attrarray *ncap, const char *uname);

extern void
ncmpio_free_NC_attrarray(NC_attrarray *ncap);

extern int
ncmpio_dup_NC_attrarray(NC_attrarray *ncap, const NC_attrarray *ref);

/*
 * NC variable: description and data
 */
typedef struct {
    int           varid;   /* variable ID */
    int           xsz;     /* byte size of 1 array element */
    nc_type       xtype;   /* variable's external NC data type */
    int           no_fill; /* whether fill mode is disabled */
    size_t        name_len;/* strlen(name) for faster string compare */
    char         *name;    /* name of the variable */
    int           ndims;   /* number of dimensions */
    int          *dimids;  /* [ndims] array of dimension IDs */
    MPI_Offset   *shape;   /* [ndims] dim->size of each dim
                              shape[0] == NC_UNLIMITED if record variable */
    MPI_Offset   *dsizes;  /* [ndims] the right to left product of shape */
    MPI_Offset    begin;   /* starting file offset of this variable */
    MPI_Offset    len;     /* this is the "vsize" defined in header format, the
                              total size in bytes of the array variable.
                              For record variable, this is the record size */
    NC_attrarray  attrs;   /* attribute array */
#ifdef ENABLE_SUBFILING
    int           num_subfiles;
    int           ndims_org;  /* ndims before subfiling */
    int          *dimids_org; /* dimids before subfiling */
#endif
} NC_var;

/* note: we only allow less than 2^31-1 variables defined in a file */
typedef struct NC_vararray {
    size_t         ndefined;    /* number of defined variables */
    int            num_rec_vars;/* number of defined record variables */
    NC_var       **value;
    NC_nametable   nameT[HASH_TABLE_SIZE]; /* table for quick name lookup.
                    * indices 0, 1, ... HASH_TABLE_SIZE-1 are the hash keys.
                    * nameT[i].num is the number of hash collisions. The IDs of
                    * variables with names producing the same hash key i are
                    * stored in nameT[i].list[*]
                    */
} NC_vararray;

/* Begin defined in var.c ---------------------------------------------------*/
extern void
ncmpio_free_NC_var(NC_var *varp);

extern NC_var *
ncmpio_new_NC_var(char *name, int ndims);

extern void
ncmpio_free_NC_vararray(NC_vararray *ncap);

extern int
ncmpio_dup_NC_vararray(NC_vararray *ncap, const NC_vararray *ref);

extern int
ncmpio_NC_var_shape64(NC_var *varp, const NC_dimarray *dims);

extern int
ncmpio_NC_lookupvar(NC *ncp, int varid, NC_var **varp);

#define IS_RECVAR(vp) \
        ((vp)->shape != NULL ? (*(vp)->shape == NC_UNLIMITED) : 0 )

/*
 *  The PnetCDF non-blocking I/O request type
 */
typedef struct NC_req {
    int            id;          /* even number for write, odd for read */
    int            buftype_is_contig;
    int            need_swap_back_buf;
    int            abuf_index;  /* index in the abuf occupy_table
                                   -1 means not using attached buffer */
    MPI_Offset     num_recs;    /* number of records requested (1 for
                                   fixed-size variable) */
    void          *buf;         /* the original user buffer */
    void          *xbuf;        /* the buffer used to read/write, may point to
                                   the same address as buf */
    void          *tmpBuf;      /* tmp buffer to be freed, used only by
                                   nonblocking varn when buftype is noncontig */
    void          *userBuf;     /* user buffer to be unpacked from tmpBuf. used
                                   only by by nonblocking varn when buftype is
                                   noncontig */
    NC_var        *varp;
    MPI_Offset    *start;        /* [varp->ndims] */
    MPI_Offset    *count;        /* [varp->ndims] */
    MPI_Offset    *stride;       /* [varp->ndims] */
    MPI_Offset     bnelems;      /* number of elements in user buffer */
    MPI_Offset     offset_start; /* starting of aggregate access region */
    MPI_Offset     offset_end;   /*   ending of aggregate access region */
    MPI_Offset     bufcount;     /* the number of buftype in this request */
    MPI_Datatype   buftype;      /* user defined derived data type */
    MPI_Datatype   ptype;        /* element data type in buftype */
    MPI_Datatype   imaptype;     /* derived data type constructed from imap */
    int           *status;       /* pointer to user's status */
} NC_req;

#define NC_ABUF_DEFAULT_TABLE_SIZE 128

typedef struct NC_buf_status {
    MPI_Aint   buf_addr;
    MPI_Offset req_size;
    int        is_used;
} NC_buf_status;

typedef struct NC_buf {
    MPI_Offset     size_allocated;
    MPI_Offset     size_used;
    int            table_size;
    int            tail;         /* index of last free entry */
    NC_buf_status *occupy_table; /* [table_size] */
    void          *buf;
} NC_buf;

/* chunk size for allocating read/write nonblocking request lists */
#define NC_REQUEST_CHUNK 1024

/* various file modes stored in flags */
#define NC_NSYNC  0x100000  /* synchronise numrecs on change */
#define NC_HSYNC  0x200000  /* synchronise whole header on change */
#define NC_NDIRTY 0x400000  /* numrecs has changed */
#define NC_HDIRTY 0x800000  /* header info has changed */
struct NC {
    int           ncid;         /* file ID */
    int           flags;        /* various modes, i.e. define/data, fill,
                                   indep/coll, header dirty, etc */
    int           iomode;       /* cmode or omode used in ncmpi_create/open */
    int           mpiomode;     /* mode used in MPI_File_open, passed from
                                 * collective open to independent open */
    int           format;       /* 1, 2, or 5 corresponding to CDF-1, 2, or 5 */
    int           safe_mode;    /* 0 or 1, for parameter consistency check */
    int           numGetReqs;   /* number of pending nonblocking get requests */
    int           numPutReqs;   /* number of pending nonblocking put requests */
#ifdef ENABLE_SUBFILING
    int           subfile_mode; /* 0 or 1, for disable/enable subfiling */
    int           num_subfiles; /* number of subfiles */
    struct NC    *ncp_sf;       /* ncp of subfile */
#endif
    int           striping_unit; /* file stripe size of the file */
    MPI_Offset    chunk;       /* chunk size for reading header */
    MPI_Offset    h_align;     /* file alignment for header */
    MPI_Offset    v_align;     /* file alignment for each fixed variable */
    MPI_Offset    r_align;     /* file alignment for record variable section */
    MPI_Offset    h_minfree;   /* pad at the end of the header section */
    MPI_Offset    v_minfree;   /* pad at the end of the data section for fixed-size variables */
    MPI_Offset    xsz;       /* external size of this header, <= var[0].begin */
    MPI_Offset    begin_var; /* file offset of the first (non-record) var */
    MPI_Offset    begin_rec; /* file offset of the first 'record' */

    MPI_Offset    recsize;   /* length of 'record': sum of single record sizes
                                of all the record variables */
    MPI_Offset    numrecs;   /* number of 'records' allocated */
    MPI_Offset    put_size;  /* amount of writes committed so far in bytes */
    MPI_Offset    get_size;  /* amount of reads  committed so far in bytes */

    MPI_Comm      comm;           /* MPI communicator */
    MPI_Info      mpiinfo;        /* used MPI info object */
    MPI_File      collective_fh;  /* file handle for collective mode */
    MPI_File      independent_fh; /* file handle for independent mode */

    NC_dimarray   dims;     /* dimensions defined */
    NC_attrarray  attrs;    /* global attributes defined */
    NC_vararray   vars;     /* variables defined */

    NC_req       *get_list; /* list of nonblocking read requests */
    NC_req       *put_list; /* list of nonblocking write requests */
    NC_buf       *abuf;     /* attached buffer, used by bput APIs */

    char         *path;     /* file name */
    struct NC    *old;      /* contains the previous NC during redef. */
};

#define NC_readonly(ncp)   fIsSet((ncp)->flags, NC_MODE_RDONLY)
#define NC_IsNew(ncp)      fIsSet((ncp)->flags, NC_MODE_CREATE)
#define NC_indef(ncp)      fIsSet((ncp)->flags, NC_MODE_DEF)
#define NC_indep(ncp)      fIsSet((ncp)->flags, NC_MODE_INDEP)
#define NC_dofill(ncp)     fIsSet((ncp)->flags, NC_MODE_FILL)

#define set_NC_ndirty(ncp)   fSet((ncp)->flags, NC_NDIRTY)
#define NC_ndirty(ncp)     fIsSet((ncp)->flags, NC_NDIRTY)
#define set_NC_hdirty(ncp)   fSet((ncp)->flags, NC_HDIRTY)
#define NC_hdirty(ncp)     fIsSet((ncp)->flags, NC_HDIRTY)
#define NC_doFsync(ncp)    fIsSet((ncp)->iomode, NC_SHARE)
#define NC_doHsync(ncp)    fIsSet((ncp)->flags, NC_HSYNC)
#define NC_doNsync(ncp)    fIsSet((ncp)->flags, NC_NSYNC)

#define ErrIsHeaderDiff(err) \
        (NC_EMULTIDEFINE_FIRST >= (err) && (err) >= NC_EMULTIDEFINE_LAST)

/* Begin defined in nc.c ----------------------------------------------------*/
extern void
ncmpio_free_NC(NC *ncp);

extern int
ncmpio_NC_check_vlens(NC *ncp);

/* Begin defined in ncmpio_header_get.c -------------------------------------*/
typedef struct bufferinfo {
    MPI_Comm    comm;
    MPI_File    collective_fh;
    MPI_Offset  get_size; /* amount of reads  committed so far in bytes */
    MPI_Offset  offset;   /* current read/write offset in the file */
    MPI_Offset  size;     /* size of the buffer */
    int         version;  /* 1, 2, and 5 for CDF-1, 2, and 5 respectively */
    int         safe_mode;/* 0: disabled, 1: enabled */
    void       *base;     /* beginning of read/write buffer */
    void       *pos;      /* current position in buffer */
} bufferinfo;

extern MPI_Offset
ncmpio_hdr_len_NC(const NC *ncp);

extern int
ncmpio_hdr_get_NC(NC *ncp);

/* Begin defined in ncmpio_header_put.c -------------------------------------*/
extern int
ncmpio_hdr_put_NC(NC *ncp, void *buf);

extern int
ncmpio_write_header(NC *ncp);

/* Begin defined in ncmpio_sync.c -------------------------------------------*/
extern int
ncmpio_file_sync(NC *ncp);

extern int
ncmpio_write_numrecs(NC *ncp, MPI_Offset new_numrecs);

/* Begin defined in ncmpio_filetype.c ---------------------------------------*/
extern int
ncmpio_filetype_create_vars(const NC* ncp, const NC_var* varp,
                const MPI_Offset start[], const MPI_Offset count[],
                const MPI_Offset stride[], int rw_flag, int *blocklen,
                MPI_Offset *offset, MPI_Datatype *filetype,
                int *is_filetype_contig);

extern int                
ncmpio_file_set_view(const NC *ncp, MPI_File fh, MPI_Offset *offset,
                MPI_Datatype filetype);

/* Begin defined in ncmpio_igetput.m4 ---------------------------------------*/
extern int
ncmpio_igetput_varm(NC *ncp, NC_var *varp, const MPI_Offset *start,
                const MPI_Offset *stride, const MPI_Offset *imap,
                const MPI_Offset *count, void *buf, MPI_Offset bufcount,
                MPI_Datatype datatype, int *reqid, int reqMode,
                int isSameGroup);

/* Begin defined in ncmpio_hash_func.c --------------------------------------*/
extern int
ncmpio_jenkins_one_at_a_time_hash(const char *str_name);

extern int
ncmpio_additive_hash(const char *str_name);

extern int
ncmpio_rotating_hash(const char *str_name);

extern int
ncmpio_Bernstein_hash(const char *str_name);

extern int
ncmpio_Pearson_hash(const char *str_name);

extern int
ncmpio_update_name_lookup_table(NC_nametable *nameT, const int id,
                                const char *oldname, const char *newname);

extern void
ncmpio_hash_insert(NC_nametable *nameT, const char *name, int id);

extern int
ncmpio_hash_delete(NC_nametable *nameT, const char *name, int id);

extern int
ncmpio_hash_replace(NC_nametable *nameT, const char *old_name, const char *new_name,
                    int id);

extern void
ncmpio_hash_table_copy(NC_nametable *dest, const NC_nametable *src);

extern void
ncmpio_hash_table_free(NC_nametable *nameT);

extern void
ncmpio_hash_table_populate_NC_var(NC_vararray *varsp);

extern void
ncmpio_hash_table_populate_NC_dim(NC_dimarray *dimsp);

extern void
ncmpio_hash_table_populate_NC_attr(NC *ncp);

/* Begin defined in ncmpio_fill.c -------------------------------------------*/
extern int
ncmpio_inq_default_fill_value(int type, void *fill_value);

extern int
ncmpio_inq_var_fill(NC_var *varp, void *fill_value);

extern int
ncmpio_fill_vars(NC *ncp);

/* Begin defined in ncmpio_nonblocking.c ------------------------------------*/
extern int
ncmpio_getput_zero_req(NC *ncp, int rw_flag);

/* Begin defined in ncmpio_close.c */
extern int
ncmpio_close_files(NC *ncp, int doUnlink);

/* Begin defined in ncmpio_utils.c ------------------------------------------*/
extern void
ncmpio_set_pnetcdf_hints(NC *ncp, MPI_Info info);

extern int
ncmpio_NC_check_name(const char *name, int file_ver);

extern int
ncmpio_last_offset(const NC *ncp, const NC_var *varp, const MPI_Offset starts[],
                   const MPI_Offset counts[], const MPI_Offset strides[],
                   const int rw_flag, MPI_Offset *offset_ptr);

extern int
ncmpio_pack_xbuf(int format, NC_var *varp, MPI_Offset bufcount,
                 MPI_Datatype buftype, int buftype_is_contig, MPI_Offset nelems,
                 MPI_Datatype etype, MPI_Datatype imaptype, int need_convert,
                 int need_swap, size_t xbuf_size, void *buf, void *xbuf);

extern int
ncmpio_unpack_xbuf(int format, NC_var *varp, MPI_Offset bufcount,
                 MPI_Datatype buftype, int buftype_is_contig, MPI_Offset nelems,
                 MPI_Datatype etype, MPI_Datatype imaptype, int need_convert,
                 int need_swap, void *buf, void *xbuf);

#endif /* _NC_H */
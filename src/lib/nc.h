/*
 *	Copyright 1996, University Corporation for Atmospheric Research
 *      See netcdf/COPYRIGHT file for copying and redistribution conditions.
 */
/* $Id$ */
#ifndef _NC_H_
#define _NC_H_

/*
 *	netcdf library 'private' data structures, objects and interfaces
 */

#include	"ncconfig.h"
#include	<stddef.h>	/* size_t */
#include	<sys/types.h>	/* off_t */
#include	"netcdf.h"
#include	"ncio.h"	/* ncio */
#include	"fbits.h"


#ifndef NC_ARRAY_GROWBY
#define NC_ARRAY_GROWBY 4
#endif

/*
 * The extern size of an empty
 * netcdf version 1 file.
 * The initial value of ncp->xsz.
 */
#define MIN_NC_XSZ 32

typedef struct NC NC; /* forward reference */

/*
 *  The internal data types
 */
typedef enum {
	NC_UNSPECIFIED = 0,
/* future	NC_BITFIELD = 7, */
/*	NC_STRING =	8,	*/
	NC_DIMENSION =	10,
	NC_VARIABLE =	11,
	NC_ATTRIBUTE =	12
} NCtype;


/*
 * Counted string for names and such
 */
typedef struct {
	/* all xdr'd */
	size_t nchars;
	char *cp;
} NC_string;

extern NC *
new_NC(const size_t *chunkp);

extern NC *
dup_NC(const NC *ref);

/* Begin defined in string.c */
extern void
free_NC_string(NC_string *ncstrp);

extern int
NC_check_name(const char *name);

extern NC_string *
new_NC_string(size_t slen, const char *str);

extern int
set_NC_string(NC_string *ncstrp, const char *str);

/* End defined in string.c */

/*
 * NC dimension stucture
 */
typedef struct {
	/* all xdr'd */
	NC_string *name;
	size_t size;
} NC_dim;

typedef struct NC_dimarray {
	size_t nalloc;		/* number allocated >= nelems */
	/* below gets xdr'd */
	/* NCtype type = NC_DIMENSION */
	size_t nelems;		/* length of the array */
	NC_dim **value;
} NC_dimarray;

/* Begin defined in dim.c */

extern void
free_NC_dim(NC_dim *dimp);

extern NC_dim *
new_x_NC_dim(NC_string *name);

extern int
find_NC_Udim(const NC_dimarray *ncap, NC_dim **dimpp);

/* dimarray */

extern void
free_NC_dimarrayV0(NC_dimarray *ncap);

extern void
free_NC_dimarrayV(NC_dimarray *ncap);

extern int
dup_NC_dimarrayV(NC_dimarray *ncap, const NC_dimarray *ref);

extern NC_dim *
elem_NC_dimarray(const NC_dimarray *ncap, size_t elem);

extern int
nc_def_dim(int ncid, const char *name, size_t size, int *dimidp);

extern int
nc_rename_dim( int ncid, int dimid, const char *newname);

extern int
nc_inq_dimid(int ncid, const char *name, int *dimid_ptr);

extern int
nc_inq_dim(int ncid, int dimid, char *name, size_t *sizep);

extern int 
nc_inq_dimname(int ncid, int dimid, char *name);

extern int 
nc_inq_dimlen(int ncid, int dimid, size_t *lenp);
/* End defined in dim.c */

/*
 * NC attribute
 */
typedef struct {
	size_t xsz;		/* amount of space at xvalue */
	/* below gets xdr'd */
	NC_string *name;
	nc_type type;		/* the discriminant */
	size_t nelems;		/* length of the array */
	void *xvalue;		/* the actual data, in external representation */
} NC_attr;

typedef struct NC_attrarray {
	size_t nalloc;		/* number allocated >= nelems */
	/* below gets xdr'd */
	/* NCtype type = NC_ATTRIBUTE */
	size_t nelems;		/* length of the array */
	NC_attr **value;
} NC_attrarray;

/* Begin defined in attr.c */

extern void
free_NC_attr(NC_attr *attrp);

extern NC_attr *
new_x_NC_attr(
	NC_string *strp,
	nc_type type,
	size_t nelems);

extern NC_attr **
NC_findattr(const NC_attrarray *ncap, const char *name);

/* attrarray */

extern void
free_NC_attrarrayV0(NC_attrarray *ncap);

extern void
free_NC_attrarrayV(NC_attrarray *ncap);

extern int
dup_NC_attrarrayV(NC_attrarray *ncap, const NC_attrarray *ref);

extern NC_attr *
elem_NC_attrarray(const NC_attrarray *ncap, size_t elem);

extern int
nc_put_att_text(int ncid, int varid, const char *name,
	size_t nelems, const char *value);

extern int
nc_get_att_text(int ncid, int varid, const char *name, char *str);

extern int
nc_put_att_schar(int ncid, int varid, const char *name,
	nc_type type, size_t nelems, const signed char *value);

extern int
nc_get_att_schar(int ncid, int varid, const char *name, signed char *tp);

extern int
nc_put_att_uchar(int ncid, int varid, const char *name,
	nc_type type, size_t nelems, const unsigned char *value);

extern int
nc_get_att_uchar(int ncid, int varid, const char *name, unsigned char *tp);

extern int
nc_put_att_short(int ncid, int varid, const char *name,
	nc_type type, size_t nelems, const short *value);

extern int
nc_get_att_short(int ncid, int varid, const char *name, short *tp);

extern int
nc_put_att_int(int ncid, int varid, const char *name,
	nc_type type, size_t nelems, const int *value);

extern int
nc_get_att_int(int ncid, int varid, const char *name, int *tp);

extern int
nc_put_att_long(int ncid, int varid, const char *name,
	nc_type type, size_t nelems, const long *value);

extern int
nc_get_att_long(int ncid, int varid, const char *name, long *tp);

extern int
nc_put_att_float(int ncid, int varid, const char *name,
	nc_type type, size_t nelems, const float *value);
extern int
nc_get_att_float(int ncid, int varid, const char *name, float *tp);
extern int
nc_put_att_double(int ncid, int varid, const char *name,
	nc_type type, size_t nelems, const double *value);
extern int
nc_get_att_double(int ncid, int varid, const char *name, double *tp);

extern int 
nc_inq_attid(int ncid, int varid, const char *name, int *attnump);

extern int 
nc_inq_atttype(int ncid, int varid, const char *name, nc_type *datatypep);

extern int 
nc_inq_attlen(int ncid, int varid, const char *name, size_t *lenp);

extern int
nc_inq_att(int ncid, int varid, const char *name, 
	nc_type *datatypep, size_t *lenp);

extern int
nc_copy_att(int ncid_in, int varid_in, const char *name, 
		int ncid_out, int ovarid);

extern int
nc_rename_att( int ncid, int varid, const char *name, const char *newname);

extern int
nc_del_att(int ncid, int varid, const char *name);

extern int
nc_inq_attname(int ncid, int varid, int attnum, char *name);
/* End defined in attr.c */
/*
 * NC variable: description and data
 */
typedef struct {
	size_t xsz;		/* xszof 1 element */
	size_t *shape; /* compiled info: dim->size of each dim */
	size_t *dsizes; /* compiled info: the right to left product of shape */
	/* below gets xdr'd */
	NC_string *name;
	/* next two: formerly NC_iarray *assoc */ /* user definition */
	size_t ndims;	/* assoc->count */
	int *dimids;	/* assoc->value */
	NC_attrarray attrs;
	nc_type type;		/* the discriminant */
	size_t len;		/* the total length originally allocated */
	off_t begin;
} NC_var;

typedef struct NC_vararray {
	size_t nalloc;		/* number allocated >= nelems */
	/* below gets xdr'd */
	/* NCtype type = NC_VARIABLE */
	size_t nelems;		/* length of the array */
	NC_var **value;
} NC_vararray;

/* Begin defined in var.c */

extern void
free_NC_var(NC_var *varp);

extern NC_var *
new_x_NC_var(
	NC_string *strp,
	size_t ndims);

/* vararray */

extern void
free_NC_vararrayV0(NC_vararray *ncap);

extern void
free_NC_vararrayV(NC_vararray *ncap);

extern int
dup_NC_vararrayV(NC_vararray *ncap, const NC_vararray *ref);

extern int
NC_var_shape(NC_var *varp, const NC_dimarray *dims);

extern int
NC_findvar(const NC_vararray *ncap, const char *name, NC_var **varpp);

extern NC_var *
NC_lookupvar(NC *ncp, int varid);

extern int
nc_def_var( int ncid, const char *name, nc_type type,
	 int ndims, const int *dimids, int *varidp);

extern int
nc_rename_var(int ncid, int varid, const char *newname);

extern int
nc_inq_var(int ncid, int varid, char *name, nc_type *typep, 
		int *ndimsp, int *dimids, int *nattsp);

extern int
nc_inq_varid(int ncid, const char *name, int *varid_ptr);

extern int 
nc_inq_varname(int ncid, int varid, char *name);

extern int 
nc_inq_vartype(int ncid, int varid, nc_type *typep);

extern int 
nc_inq_varndims(int ncid, int varid, int *ndimsp);

extern int 
nc_inq_vardimid(int ncid, int varid, int *dimids);

extern int 
nc_inq_varnatts(int ncid, int varid, int *nattsp);

extern int
nc_rename_var(int ncid, int varid, const char *newname);
/* End defined in var.c */

#define IS_RECVAR(vp) \
	((vp)->shape != NULL ? (*(vp)->shape == NC_UNLIMITED) : 0 )

struct NC {
	/* links to make list of open netcdf's */
	struct NC *next;
	struct NC *prev;
	/* contains the previous NC during redef. */
	struct NC *old;
	/* flags */
#define NC_INDEP 1	/* in independent data mode, cleared by endindep */
#define NC_CREAT 2	/* in create phase, cleared by ncenddef */
#define NC_INDEF 8	/* in define mode, cleared by ncenddef */
#define NC_NSYNC 0x10	/* synchronise numrecs on change */
#define NC_HSYNC 0x20	/* synchronise whole header on change */
#define NC_NDIRTY 0x40	/* numrecs has changed */
#define NC_HDIRTY 0x80  /* header info has changed */
/*	NC_NOFILL in netcdf.h, historical interface */
	int flags;
	ncio *nciop;
	size_t chunk;	/* largest extent this layer will request from ncio->get() */
	size_t xsz;	/* external size of this header, <= var[0].begin */
	off_t begin_var; /* postion of the first (non-record) var */
	off_t begin_rec; /* postion of the first 'record' */
	size_t recsize; /* length of 'record' */
	/* below gets xdr'd */
	size_t numrecs; /* number of 'records' allocated */
	NC_dimarray dims;
	NC_attrarray attrs;
	NC_vararray vars;
};

#define NC_readonly(ncp) \
	(!fIsSet(ncp->nciop->ioflags, NC_WRITE))

#define NC_IsNew(ncp) \
	fIsSet((ncp)->flags, NC_CREAT)

#define NC_indep(ncp) \
	fIsSet((ncp)->flags, NC_INDEP)

#define NC_indef(ncp) \
	(NC_IsNew(ncp) || fIsSet((ncp)->flags, NC_INDEF)) 

#define set_NC_ndirty(ncp) \
	fSet((ncp)->flags, NC_NDIRTY)

#define NC_ndirty(ncp) \
	fIsSet((ncp)->flags, NC_NDIRTY)

#define set_NC_hdirty(ncp) \
	fSet((ncp)->flags, NC_HDIRTY)

#define NC_hdirty(ncp) \
	fIsSet((ncp)->flags, NC_HDIRTY)

#define NC_dofill(ncp) \
	(!fIsSet((ncp)->flags, NC_NOFILL))

#define NC_doHsync(ncp) \
	fIsSet((ncp)->flags, NC_HSYNC)

#define NC_doNsync(ncp) \
	fIsSet((ncp)->flags, NC_NSYNC)

#define NC_get_numrecs(ncp) \
	((ncp)->numrecs)

#define NC_set_numrecs(ncp, nrecs) \
	{((ncp)->numrecs = (nrecs));}

#define NC_increase_numrecs(ncp, nrecs) \
	{if((nrecs) > (ncp)->numrecs) ((ncp)->numrecs = (nrecs));}
/* Begin defined in nc.c */

extern int
NC_check_id(int ncid, NC **ncpp);

extern int
nc_cktype(nc_type datatype);

extern size_t
ncx_howmany(nc_type type, size_t xbufsize);

extern int
read_numrecs(NC *ncp);

extern int
write_numrecs(NC *ncp);

extern int
NC_sync(NC *ncp);

extern void
free_NC(NC *ncp);

extern void
add_to_NCList(NC *ncp);

extern void
del_from_NCList(NC *ncp);

extern int
read_NC(NC *ncp);

extern int 
NC_enddef(NC *ncp);

extern int 
NC_close(NC *ncp);

extern int
nc_inq(int ncid, int *ndimsp, int *nvarsp, int *nattsp, int *xtendimp);

extern int 
nc_inq_ndims(int ncid, int *ndimsp);

extern int 
nc_inq_nvars(int ncid, int *nvarsp);

extern int 
nc_inq_natts(int ncid, int *nattsp);

extern int 
nc_inq_unlimdim(int ncid, int *xtendimp);
/* End defined in nc.c */
/* Begin defined in v1hpg.c */

extern size_t
ncx_len_NC(const NC *ncp);

extern int
ncx_put_NC(const NC *ncp, void **xpp, off_t offset, size_t extent);

extern int
nc_get_NC( NC *ncp);

/* End defined in v1hpg.c */
/* Begin defined in putget.c */

extern int
fill_NC_var(NC *ncp, const NC_var *varp, size_t recno);

extern int
nc_inq_rec(int ncid, size_t *nrecvars, int *recvarids, size_t *recsizes);

extern int
nc_get_rec(int ncid, size_t recnum, void **datap);

extern int
nc_put_rec(int ncid, size_t recnum, void *const *datap);

/* End defined in putget.c */

/* Begin defined in header.c */
typedef struct bufferinfo {
  ncio *nciop;		
  MPI_Offset offset;	/* current read/write offset in the file */
  void *base;     	/* beginning of read/write buffer */
  void *pos;      	/* current position in buffer */
  size_t size;		/* size of the buffer */
  size_t index;		/* index of current position in buffer */
} bufferinfo;  

extern int
hdr_get_NC(NC *ncp);

extern size_t 
ncx_len_nctype(nc_type type);

extern int
hdr_put_NC_attrarray(bufferinfo *pbp, const NC_attrarray *ncap);

extern size_t
hdr_len_NC(const NC *ncp);

extern int
hdr_get_NC(NC *ncp);

extern int 
hdr_put_NC(NC *ncp, void *buf);

extern int
NC_computeshapes(NC *ncp);

/* end defined in hader.c */

/* begin defined in mpincio.c */
extern int
ncio_create(MPI_Comm comm, const char *path, int ioflags, MPI_Info info,
            ncio **nciopp);

extern int
ncio_open(MPI_Comm comm, const char *path, int ioflags, MPI_Info info,
          ncio **nciopp);
extern int
ncio_sync(ncio *nciop);

extern int
ncio_move(ncio *const nciop, off_t to, off_t from, size_t nbytes);

extern int
NC_computeshapes(NC *ncp);

/* end defined in mpincio.h */

/* begin defined in error.c */
const char * nc_strerror(int err);
/* end defined in error.c */
/*
 * These functions are used to support
 * interface version 2 backward compatiblity.
 * N.B. these are tested in ../nc_test even though they are
 * not public. So, be careful to change the declarations in
 * ../nc_test/tests.h if you change these.
 */

extern int
nc_put_att(int ncid, int varid, const char *name, nc_type datatype,
	size_t len, const void *value);

extern int
nc_get_att(int ncid, int varid, const char *name, void *value);

extern int
nc_put_var1(int ncid, int varid, const size_t *index, const void *value);

extern int
nc_get_var1(int ncid, int varid, const size_t *index, void *value);

extern int
nc_put_vara(int ncid, int varid,
	 const size_t *start, const size_t *count, const void *value);

extern int
nc_get_vara(int ncid, int varid,
	 const size_t *start, const size_t *count, void *value);

extern int
nc_put_vars(int ncid, int varid,
	 const size_t *start, const size_t *count, const ptrdiff_t *stride,
	 const void * value);

extern int
nc_get_vars(int ncid, int varid,
	 const size_t *start, const size_t *count, const ptrdiff_t *stride,
	 void * value);

extern int
nc_put_varm(int ncid, int varid,
	 const size_t *start, const size_t *count, const ptrdiff_t *stride,
	 const ptrdiff_t * map, const void *value);

extern int
nc_get_varm(int ncid, int varid,
	 const size_t *start, const size_t *count, const ptrdiff_t *stride,
	 const ptrdiff_t * map, void *value);

#endif /* _NC_H_ */

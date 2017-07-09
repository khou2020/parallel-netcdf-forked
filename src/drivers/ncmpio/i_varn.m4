dnl Process this m4 file to produce 'C' language file.
dnl
dnl If you see this line, you can ignore the next one.
/* Do not edit this file. It is produced from the corresponding .m4 source */
dnl
/*
 *  Copyright (C) 2014, Northwestern University and Argonne National Laboratory
 *  See COPYRIGHT notice in top-level directory.
 */
/* $Id$ */

#ifdef HAVE_CONFIG_H
# include <config.h>
#endif

#include <stdio.h>
#include <unistd.h>
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif
#include <assert.h>

#include <mpi.h>

#include <pnc_debug.h>
#include <common.h>
#include "nc.h"
#include "ncx.h"
#include "ncmpidtype.h"

/*----< igetput_varn() >-----------------------------------------------------*/
static int
igetput_varn(NC                *ncp,
             NC_var            *varp,
             int                num,
             MPI_Offset* const *starts,  /* [num][varp->ndims] */
             MPI_Offset* const *counts,  /* [num][varp->ndims] */
             void              *buf,
             MPI_Offset         bufcount,
             MPI_Datatype       buftype,   /* data type of the bufer */
             int               *reqidp,    /* OUT: request ID */
             int                rw_flag,   /* WRITE_REQ or READ_REQ */
             int                use_abuf)  /* if use attached buffer */
{
    int i, j, el_size, status=NC_NOERR, free_cbuf=0, isSameGroup, reqid;
    void *cbuf=NULL;
    char *bufp;
    MPI_Offset **_counts=NULL;
    MPI_Datatype ptype;

    if (use_abuf && ncp->abuf == NULL) DEBUG_RETURN_ERROR(NC_ENULLABUF)

    /* it is illegal for starts to be NULL */
    if (starts == NULL)
        DEBUG_RETURN_ERROR(NC_ENULLSTART)
    else { /* it is illegal for any starts[i] to be NULL */
        for (i=0; i<num; i++) {
            if (starts[i] == NULL)
                DEBUG_RETURN_ERROR(NC_ENULLSTART)
        }
    }

    if (counts != NULL) {
        for (j=0; j<num; j++) {
            if (counts[j] == NULL)
                DEBUG_RETURN_ERROR(NC_ENULLCOUNT)
            for (i=0; i<varp->ndims; i++) {
                if (counts[j][i] < 0) /* no negative counts[][] */
                    DEBUG_RETURN_ERROR(NC_ENEGATIVECNT)
            }
        }
    }

    cbuf = buf;
    if (buftype == MPI_DATATYPE_NULL) {
        /* In this case, we make ptype match the variable data type defined
         * in file - no data conversion will be done. Also, it means buf is
         * contiguous. buftype will no longer be used.
         */
        ptype = ncmpio_nc2mpitype(varp->type);
        MPI_Type_size(ptype, &el_size); /* buffer element size */
    }
    else if (bufcount == -1) { /* buftype is an MPI primitive data type */
        /* this subroutine is called from a high-level API
         * Also, it means the user buf is contiguous.
         * Assign ptype to buftype, and buftype will no longer be used.
         */
        ptype = buftype;
        MPI_Type_size(ptype, &el_size); /* buffer element size */
    }
    else { /* (bufcount > 0) flexible API is used */
        /* pack buf into cbuf, a contiguous buffer */
        int isderived, iscontig_of_ptypes;
        MPI_Offset bnelems=0;

        /* ptype (primitive MPI data type) from buftype
         * el_size is the element size of ptype
         * bnelems is the total number of ptype elements in buftype
         */
        status = ncmpio_dtype_decode(buftype, &ptype, &el_size, &bnelems,
                                     &isderived, &iscontig_of_ptypes);

        if (status != NC_NOERR) return status;

        if (bufcount != (int)bufcount) DEBUG_RETURN_ERROR(NC_EINTOVERFLOW)

        /* check if buftype is contiguous, if not, pack to one, cbuf */
        if (! iscontig_of_ptypes && bnelems > 0) {
            int position = 0;
            MPI_Offset packsize = bnelems*el_size;
            if (packsize != (int)packsize) DEBUG_RETURN_ERROR(NC_EINTOVERFLOW)

            cbuf = NCI_Malloc((size_t)packsize);
            free_cbuf = 1;
            /* if not use_abuf, need a callback to free cbuf */

            if (rw_flag == WRITE_REQ)
                MPI_Pack(buf, (int)bufcount, buftype, cbuf, (int)packsize,
                         &position, MPI_COMM_SELF);
        }
    }

    /* We allow counts == NULL and treat this the same as all 1s */
    if (counts == NULL) {
        _counts    = (MPI_Offset**) NCI_Malloc((size_t)num *
                                               sizeof(MPI_Offset*));
        _counts[0] = (MPI_Offset*)  NCI_Malloc((size_t)(num * varp->ndims *
                                               SIZEOF_MPI_OFFSET));
        for (i=1; i<num; i++)
            _counts[i] = _counts[i-1] + varp->ndims;
        for (i=0; i<num; i++)
            for (j=0; j<varp->ndims; j++)
                _counts[i][j] = 1;
    }
    else {
        _counts = (MPI_Offset**) counts;
    }
    /* from this point forward, _counts != NULL */

    /* break buf into num pieces */
    reqid = NC_REQ_NULL;
    isSameGroup=0;
    bufp = (char*)cbuf;
    for (i=0; i<num; i++) {
        MPI_Offset buflen;

        /* check whether start, count, and stride are valid */
        status = ncmpio_start_count_stride_check(ncp, varp, starts[i],
                                                 _counts[i], NULL, rw_flag);
        if (status != NC_NOERR) goto err_check;

        for (buflen=1, j=0; j<varp->ndims; j++)
            buflen *= _counts[i][j];

        if (buflen == 0) continue;
        status = ncmpio_igetput_varm(ncp, varp, starts[i], _counts[i], NULL,
                                     NULL, bufp, buflen, ptype, &reqid,
                                     rw_flag, use_abuf, isSameGroup);
        if (status != NC_NOERR) goto err_check;

        /* use isSamegroup so we end up with one nonblocking request (only the
         * first request gets a request ID back, the rest reuse the same ID.
         * This single ID represents num nonblocking requests */
        isSameGroup=1;
        bufp += buflen * el_size;
    }

    if (free_cbuf) { /* cbuf != buf, cbuf is temp allocated */
        if (rw_flag == READ_REQ) {
            /* Set the last lead request object to let wait() unpack cbuf to
             * buf and free cbuf */
            for (i=ncp->numGetReqs-1; i>=0; i--)
                if (ncp->get_list[i].num_recs > 0)
                    break;
            ncp->get_list[i].tmpBuf   = cbuf;
            ncp->get_list[i].userBuf  = buf;
            ncp->get_list[i].bufcount = (int)bufcount;
            MPI_Type_dup(buftype, &ncp->get_list[i].buftype);
        }
        else { /* WRITE_REQ */
            if (use_abuf)
                /* cbuf has been copied to the attached buffer, so it is safe
                 * to free cbuf now */
                NCI_Free(cbuf);
            else {
                for (i=ncp->numPutReqs-1; i>=0; i--)
                    if (ncp->put_list[i].num_recs > 0)
                        break;
                assert(i >= 0);
                /* Set the last request object to let wait() to free cbuf */
                ncp->put_list[i].tmpBuf = cbuf;
            }
        }
    }

err_check:
    if (_counts != counts) {
        NCI_Free(_counts[0]);
        NCI_Free(_counts);
    }

    if (status != NC_NOERR) {
        if (reqid != NC_REQ_NULL) /* cancel pending nonblocking request */
            ncmpio_cancel(ncp, 1, &reqid, NULL);
        if (free_cbuf) NCI_Free(cbuf);
    }
    if (reqidp != NULL) *reqidp = reqid;

    return status;
}


include(`utils.m4')

dnl
define(`IsBput',    `ifelse(`$1',`bput', `1', `0')')dnl
define(`BufConst',  `ifelse(`$1',`get', , `const')')dnl
dnl
dnl VARN(iget/iput/bput)
dnl
define(`VARN',dnl
`dnl
/*----< ncmpio_$1_varn() >----------------------------------------------------*/
int
ncmpio_$1_varn(void               *ncdp,
               int                 varid,
               int                 num,
               MPI_Offset* const  *starts,
               MPI_Offset* const  *counts,
               BufConst(substr($1,1)) void  *buf,
               MPI_Offset          bufcount,
               MPI_Datatype        buftype,
               int                *reqid,
               nc_type             itype)
{
    int     status;
    NC     *ncp=(NC*)ncdp;
    NC_var *varp=NULL;

    if (reqid != NULL) *reqid = NC_REQ_NULL;

    /* check for zero-size request */
    if (num == 0 || bufcount == 0) return NC_NOERR;

    status = ncmpio_sanity_check(ncp, varid, NULL, NULL, NULL, bufcount,
                                 buftype, API_VARN, (itype==NC_NAT), 0,
                                 ReadWrite($1), NONBLOCKING_IO, &varp);
    if (status != NC_NOERR) return status;

    return igetput_varn(ncp, varp, num, starts, counts, (void*)buf, bufcount,
                        buftype, reqid, ReadWrite($1), IsBput($1));
}
')dnl
dnl

VARN(iput)
VARN(iget)
VARN(bput)


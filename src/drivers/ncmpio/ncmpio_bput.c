/*
 *  Copyright (C) 2003, Northwestern University and Argonne National Laboratory
 *  See COPYRIGHT notice in top-level directory.
 */
/* $Id$ */

/*
 * This file implements the corresponding APIs defined in
 * src/dispatchers/file.c
 *
 * ncmpi_buffer_attach()         : dispatcher->buffer_attach()
 * ncmpi_buffer_detach()         : dispatcher->buffer_detach()
 *
 * and src/dispatchers/var_getput.m4
 * ncmpi_bput_var<kind>_<type>() : dispatcher->bput_var()
 */

#ifdef HAVE_CONFIG_H
# include <config.h>
#endif

#include <stdio.h>
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif
#include <assert.h>

#include <mpi.h>

#include <pnc_debug.h>
#include <common.h>
#include "nc.h"
#include "macro.h"

/*----< ncmpio_buffer_attach() >---------------------------------------------*/
int
ncmpio_buffer_attach(void       *ncdp,
                     MPI_Offset  bufsize)
{
    NC *ncp=(NC*)ncdp;

    if (bufsize <= 0) DEBUG_RETURN_ERROR(NC_ENULLBUF)

    /* check if the buffer has been previously attached
     * note that in nc.c, the NC object is allocated with calloc, so
     * abuf should be initialized to NULL then
     */
    if (ncp->abuf != NULL) DEBUG_RETURN_ERROR(NC_EPREVATTACHBUF)

    ncp->abuf = (NC_buf*) NCI_Malloc(sizeof(NC_buf));

    ncp->abuf->size_allocated = bufsize;
    ncp->abuf->size_used = 0;
    ncp->abuf->table_size = NC_ABUF_DEFAULT_TABLE_SIZE;
    ncp->abuf->occupy_table = (NC_buf_status*)
               NCI_Calloc(NC_ABUF_DEFAULT_TABLE_SIZE, sizeof(NC_buf_status));
    ncp->abuf->tail = 0;
    ncp->abuf->buf = NCI_Malloc((size_t)bufsize);
    return NC_NOERR;
}

/*----< ncmpio_buffer_detach() >---------------------------------------------*/
int
ncmpio_buffer_detach(void *ncdp)
{
    int  i;
    NC  *ncp=(NC*)ncdp;

    /* check if the buffer has been previously attached */
    if (ncp->abuf == NULL) DEBUG_RETURN_ERROR(NC_ENULLABUF)

    /* this API assumes users are responsible for no pending bput */
    for (i=0; i<ncp->numPutReqs; i++) {
        if (ncp->put_list[i].abuf_index >= 0) /* check for a pending bput */
            DEBUG_RETURN_ERROR(NC_EPENDINGBPUT)
            /* return now, so users can call wait and try detach again */
    }

    NCI_Free(ncp->abuf->buf);
    NCI_Free(ncp->abuf->occupy_table);
    NCI_Free(ncp->abuf);
    ncp->abuf = NULL;

    return NC_NOERR;
}

#ifdef THIS_SEEMS_OVER_DONE_IT
/*----< ncmpio_buffer_detach() >---------------------------------------------*/
/* mimic MPI_Buffer_detach()
 * Note from MPI: Even though the 'bufferptr' argument is declared as
 * 'void *', it is really the address of a void pointer.
 */
int
ncmpio_buffer_detach(void       *ncdp,
                     void       *bufptr,
                     MPI_Offset *bufsize)
{
    int  i;
    NC  *ncp=(NC*)ncdp;

    /* check if the buffer has been previously attached */
    if (ncp->abuf == NULL) DEBUG_RETURN_ERROR(NC_ENULLABUF)

    /* check MPICH2 src/mpi/pt2pt/bsendutil.c for why the bufptr is void* */
    *(void **)bufptr = ncp->abuf->buf;
    *bufsize         = ncp->abuf->size_allocated;

    /* this API assumes users are responsible for no pending bput when called */
    for (i=0; i<ncp->numPutReqs; i++) {
        if (ncp->put_list[i].abuf_index >= 0) /* check for a pending bput */
            DEBUG_RETURN_ERROR(NC_EPENDINGBPUT)
            /* return now, so users can call wait and try detach again */
    }

    NCI_Free(ncp->abuf->occupy_table);
    NCI_Free(ncp->abuf);
    ncp->abuf = NULL;

    return NC_NOERR;
}
#endif

/*----< ncmpio_bput_var() >--------------------------------------------------*/
int
ncmpio_bput_var(void             *ncdp,
                int               varid,
                const MPI_Offset *start,
                const MPI_Offset *count,
                const MPI_Offset *stride,
                const MPI_Offset *imap,
                const void       *buf,
                MPI_Offset        bufcount,
                MPI_Datatype      buftype,
                int              *reqid,
                NC_api            api,
                int               reqMode)
{
    int         err;
    NC         *ncp=(NC*)ncdp;
    NC_var     *varp=NULL;
    MPI_Offset *_start, *_count;

#if 0
    if (reqid != NULL) *reqid = NC_REQ_NULL;

    /* check NC_EPERM, NC_EINDEFINE, NC_EINDEP/NC_ENOTINDEP, NC_ENOTVAR,
     * NC_ECHAR, NC_EINVAL */
    err = ncmpio_sanity_check(ncp, varid, bufcount, buftype, reqMode, &varp);
    if (err != NC_NOERR) return err;

    if (fIsSet(reqMode, NC_REQ_ZERO)) /* zero-length request */
        return NC_NOERR;

    /* check NC_EINVALCOORDS, NC_EEDGE, NC_ESTRIDE */
    err = ncmpii_start_count_stride_check(ncp->format, api, varp->ndims,
                              ncp->numrecs, varp->shape, start, count,
                              stride, reqMode);
    if (err != NC_NOERR) return err;
#endif

    /* buffer has not been attached yet */
    if (ncp->abuf == NULL) DEBUG_RETURN_ERROR(NC_ENULLABUF)

    /* obtain NC_var object pointer, varp. Note sanity check for ncdp and
     * varid has been done in dispatchers */
    varp = ncp->vars.value[varid];

    /* for var1 and var cases */
    _start = (MPI_Offset*)start;
    _count = (MPI_Offset*)count;
         if (api == API_VAR)  GET_FULL_DIMENSIONS(_start, _count)
    else if (api == API_VAR1) GET_ONE_COUNT(_count)

    err = ncmpio_igetput_varm(ncp, varp, _start, _count, stride, imap,
                              (void*)buf, bufcount, buftype, reqid, reqMode, 0);

         if (api == API_VAR)  NCI_Free(_start);
    else if (api == API_VAR1) NCI_Free(_count);

    return err;
}
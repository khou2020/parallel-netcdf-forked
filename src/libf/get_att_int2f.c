/* -*- Mode: C; c-basic-offset:4 ; -*- */
/*  
 *  (C) 2001 by Argonne National Laboratory.
 *      See COPYRIGHT in top-level directory.
 *
 * This file is automatically generated by buildiface -infile=../lib/pnetcdf.h -deffile=defs
 * DO NOT EDIT
 */
#include "mpinetcdf_impl.h"


#ifdef F77_NAME_UPPER
#define nfmpi_get_att_int2_ NFMPI_GET_ATT_INT2
#elif defined(F77_NAME_LOWER_2USCORE)
#define nfmpi_get_att_int2_ nfmpi_get_att_int2__
#elif !defined(F77_NAME_LOWER_USCORE)
#define nfmpi_get_att_int2_ nfmpi_get_att_int2
/* Else leave name alone */
#endif


/* Prototypes for the Fortran interfaces */
#include "mpifnetcdf.h"
FORTRAN_API void FORT_CALL nfmpi_get_att_int2_ ( int *v1, int *v2, char *v3 FORT_MIXED_LEN(d3), short*v4, MPI_Fint *ierr FORT_END_LEN(d3) ){
    char *p3;

    {char *p = v3 + d3 - 1;
     int  li;
        while (*p == ' ' && p > v3) p--;
        p++;
        p3 = (char *)malloc( p-v3 + 1 );
        for (li=0; li<(p-v3); li++) { p3[li] = v3[li]; }
        p3[li] = 0; 
    }
    *ierr = ncmpi_get_att_short( *v1, *v2, p3, v4 );
    free( p3 );
}

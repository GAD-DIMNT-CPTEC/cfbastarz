/** @file
 * @brief Fortran-callable routines to read and write characther
 * data byte addressably.
 *
 *  v1.1:
 * - Put diagnostic output under control of define VERBOSE or QUIET
 * - Add option of non-seeking read/write
 * - Return code for fewer data read/written than requested
 *
 *  v1.2:
 * - Add cray compatibility  20 April 1998  Robert Grumbine
 *
 *  v1.3:
 * - Add IBMSP compatibility (IBM4, IBM8)
 * - Add modes BAOPEN_WONLY_TRUNC, BAOPEN_WONLY_APPEND
 * - Use isgraph instead of isalnum + a short list of accepted characters
 * for filename check 12 Dec 2000 Stephen Gilbert
 * - negative return codes are wrapped to positive, revise return codes
 * verify that banio and bacio have same contents, update comments
 * 29 Oct 2008 Robert Grumbine
 *
 *  v1.4:
 * - 21 Nov 2008 Add baciol and baniol functions, versions to work with files
 * over 2 Gb Robert Grumbine
 * - Aug 2012 Jun Wang fix c filename length because the c string
 * needs to end with "null" terminator , and free allocated cfile
 * name realname to avoid memory leak.
 * - Sep 2012 Jun Wang: remove execute permission on the data file
 * generated by bacio.
 *
 * v2.5:
 * Oct. 2021 - Ed Hartnett - Extensive cleanup, testing, and
 * refactor. Converted to use ISO C/Fortran compatibility.
 *
 * @author Robert Grumbine @date 16 March 1998
 */

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#include "clib.h"

/**
 * Do a bacio operation. Available operations include:
 * * opening a file.
 * * writing to an open file.
 * * reading from an open file.
 * * closing an open file.
 *
 * @param mode Specifies operations to be performed. See the
 * clib.inc file for the values. Mode is obtained by adding together
 * the values corresponding to the operations The best method is to
 * include the clib.inc file and refer to the names for the operations
 * rather than rely on hard-coded values.
 * @param start Byte number to start your operation from. 0 is the
 * first byte in the file, not 1.
 * @param size The size of the objects you are trying to read or write
 * (i.e. the size of one element of the type - 4 for integers, for
 * example.)
 * @param no The number of elements to read or write (characters,
 * integers, whatever).
 * @param nactual A pointer that gets the number of elements actually
 * read or written. If the read/write operation succeeded, this will
 * equal the value of parameter no.
 * @param fdes Pointer that gets an integer file id. This is not a
 * Fortran Unit Number You can use it, however, to refer to files
 * you've previously opened.
 * @param fname is the name of the file. This only needs to be defined
 * when you are opening a file. It must be (on the Fortran side)
 * declared as CHARACTER*N, where N is a length greater than or equal
 * to the length of the file name.
 * @param datary is the name of the entity (variable, vector, array)
 * that you want to write data out from or read it in to. The fact
 * that C is declaring it to be a char * does not affect your fortran.
 *
 * This function is called from the Fortran code in baciof.f90.
 *
 * @return ::BA_NOERROR No error.
 * @return ::BA_EROANDWO Tried to open read only and write only.
 * @return ::BA_ERANDW Tried to read and write in the same call.
 * @return ::BA_EINTNAME Internal failure in name processing.
 * @return ::BA_EFILEOPEN Failure in opening file.
 * @return ::BA_ERONWO Tried to read on a write-only file.
 * @return ::BA_ERNOSTART Failed in read to find the 'start' location.
 * @return ::BA_EWANDRO Tried to write to a read only file.
 * @return ::BA_EWNOSTART Failed in write to find the 'start' location.
 * @return ::BA_ECLOSE Error in close.
 * @return ::BA_EFEWDATA Read or wrote fewer data than requested.
 * @return ::BA_EDATANULL Data pointer is NULL.
 *
 * @author Robert Grumbine @date 21 November 2008
 * @author Ed Hartnett @date 18 October, 2021
 */
int
baciol(int mode, long int start, int size, long int no,
       long int *nactual, int *fdes, const char *fname, void *datary)
{
    /* Initialization. */
    *nactual = 0;

    /* Check for illegal combinations of options */
    if ((BAOPEN_RONLY & mode) &&
        ((BAOPEN_WONLY & mode) || (BAOPEN_WONLY_TRUNC & mode) || (BAOPEN_WONLY_APPEND & mode)))
        return BA_EROANDWO;

    if ((BAREAD & mode) && (BAWRITE & mode)) 
        return BA_ERANDW;

    /* Open files with correct read/write and file permission. */
    if (BAOPEN_RONLY & mode)
    {
        *fdes = open(fname, O_RDONLY , S_IRUSR | S_IRGRP | S_IROTH | S_IWUSR | S_IWGRP);
    }
    else if (BAOPEN_WONLY & mode)
    {
        *fdes = open(fname, O_WRONLY | O_CREAT , S_IRUSR | S_IRGRP | S_IROTH | S_IWUSR | S_IWGRP);
    }
    else if (BAOPEN_WONLY_TRUNC & mode)
    {
        *fdes = open(fname, O_WRONLY | O_CREAT | O_TRUNC , S_IRUSR | S_IRGRP | S_IROTH | S_IWUSR | S_IWGRP);
    }
    else if (BAOPEN_WONLY_APPEND & mode)
    {
        *fdes = open(fname, O_WRONLY | O_CREAT | O_APPEND , S_IRUSR | S_IRGRP | S_IROTH | S_IWUSR | S_IWGRP);
    }
    else if (BAOPEN_RW & mode)
    {
        *fdes = open(fname, O_RDWR | O_CREAT , S_IRUSR | S_IRGRP | S_IROTH | S_IWUSR | S_IWGRP);
    }

    /* If the file open didn't work, or a bad fdes was passed in,
     * return error. */
    if (*fdes < 0)
        return BA_EFILEOPEN;

    /* Check for bad mode flags. */
    if (BAREAD & mode &&
        ((BAOPEN_WONLY & mode) || (BAOPEN_WONLY_TRUNC & mode) || (BAOPEN_WONLY_APPEND & mode)))
        return BA_ERONWO;

    /* Read data as requested. */
    if (BAREAD & mode )
    {
        /* Seek the right part of the file. */
        if (!(mode & NOSEEK))
            if (lseek(*fdes, start, SEEK_SET) == -1)
                return BA_ERNOSTART;

        if (datary == NULL)
        {
            printf("Massive catastrophe -- datary pointer is NULL\n");
            return BA_EDATANULL;
        }
        *nactual = read(*fdes, (void *)datary, (size_t)no);
    }

    /* Check for bad mode flag. */
    if (BAWRITE & mode && BAOPEN_RONLY & mode) 
        return BA_EWANDRO;
    
    /* See if we should be writing. */
    if (BAWRITE & mode)
    {
        if (!(mode & NOSEEK))
            if (lseek(*fdes, start, SEEK_SET) == -1)
                return BA_EWNOSTART;

        if (datary == NULL)
        {
            printf("Massive catastrophe -- datary pointer is NULL\n");
            return BA_EDATANULL;
        }
        *nactual = write(*fdes, (void *) datary, (size_t)no);
    }

    /* Close file if requested */
    if (BACLOSE & mode )
        if (close(*fdes) != 0)
            return BA_ECLOSE;

    /* Check that if we were reading or writing, that we actually got
       what we expected. Return 0 (success) if we're here and weren't
       reading or writing. */
    if ((mode & BAREAD || mode & BAWRITE) && (*nactual != no))
        return BA_EFEWDATA;
    else 
        return BA_NOERROR;
}



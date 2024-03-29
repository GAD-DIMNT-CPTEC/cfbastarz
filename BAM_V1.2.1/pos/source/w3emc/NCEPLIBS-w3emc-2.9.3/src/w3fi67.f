C> @file
C> @brief BUFR message decoder.
C> @author Bill Cavanaugh @date 1988-08-31

C> This set of routines will decode a BUFR message and
C> place information extracted from the BUFR message into selected
C> arrays for the user. Those arrays are described in the output
C> argument list. This routine does not include ifod processing.
C>
C> Program history log:
C> - Bill Cavanaugh 1988-08-31
C> - Bill Cavanaugh 1990-12-07 Now utilizing gbyte routines to gather
C> and separate bit fields. This should improve
C> (decrease) the time it takes to decode any
C> BUFR message. Have entered coding that will
C> permit processing BUFR editions 1 and 2.
C> Improved and corrected the conversion into
C> ifod format of decoded BUFR messages.
C> - Bill Cavanaugh 1991-01-18 Program/routines modified to properly handle
C> serial profiler data.
C> - Bill Cavanaugh 1991-04-04 Modified to handle text supplied thru
C> descriptor 2 05 yyy.
C> - Bill Cavanaugh 1991-04-17 Errors in extracting and scaling data
C> corrected. Improved handling of nested queue descriptors is added.
C> - Bill Cavanaugh 1991-05-10 Array 'data' has been enlarged to real*8
C> to better contain very large numbers more accurately. The preious size
C> real*4 could not contain sufficient significant digits. Coding has been
C> introduced to process new table c descriptor 2 06 yyy which permits in
C> line processing of a local descriptor even if the descriptor is not
C> contained in the users table b. A second routine to process ifod messages
C> (ifod0) has been removed in favor of the improved processing of the one
C> remaining (ifod1). New coding has been introduced to permit processing of
C> BUFR messages based on BUFR edition up to and including edition 2. Please
C> note increased size requirements for arrays ident(20) and iptr(40).
C> - Bill Cavanaugh 1991-07-26 Add array mtime to calling sequence to
C> permit inclusion of receipt/transfer times to ifod messages.
C> - Bill Cavanaugh 1991-09-25 All processing of decoded BUFR data into
C> ifod (a local use reformat of BUFR data) has been isolated from this set of
C> routines. For those interested in the ifod form, see w3fl05 in the w3lib
C> routines.
C> - Processing of BUFR messages containing delayed replication has been
C> altered so that single subsets (reports) and and a matching descriptor list
C> for that particular subset will be passed to the user will be passed to the
C> user one at a time to assure that each subset can be fully defined with a
C> minimum of reprocessing.
C> - Processing of associated fields has been tested with messages containing
C> non-compressed data.
C> - In order to facilitate user processing a matching list of scale factors
C> are included with the expanded descriptor list (mstack).
C> - Bill Cavanaugh 1991-11-21 Processing of descriptor 2 03 yyy
C> has corrected to agree with fm94 standards.
C> - Bill Cavanaugh 1991-12-19 Calls to fi6703() and fi6704() have been
C> corrected to agree called program argument list. Some additional entries
C> have been included for communicating with data access routines. Additional
C> error exit provided for the case where table b is damaged.
C> - Bill Cavanaugh 1992-01-24 Routines fi6701(), fi6703() and fi6704()
C> have been modified to handle associated fields all descriptors are set to
C> echo to mstack(1,n)
C> - Bill Cavanaugh 1992-05-21 Further expansion of information collected from
C> within upper air soundings has produced the necessity to expand some of the
C> processing and output arrays. (see remarks below)
C> - Bill Cavanaugh 1992-06-29 Corrected descriptor denoting height of
C> each wind level for profiler conversions.
C> - Bill Cavanaugh 1992-07-23 Expansion of table b requires adjustment
C> of arrays to contain table b values needed to assist in the decoding process.
C> - Arrays containing data from table b:
C>  - kdesc descriptor
C>  - aname descriptor name
C>  - aunits units for descriptor
C>  - mscale scale for value of descriptor
C>  - mref reference value for descriptor
C>  - mwidth bit width for value of descriptor
C>  - Bill Cavanaugh 1992-09-09 First encounter with operator descriptor
C> 2 05 yyy showed error in decoding. That error is corrected with this
C> implementation. Further testing of upper air data has encountered the
C> condition of large (many level) soundings arrays in the decoder have been
C> expanded (again) to allow for this condition.
C> - Bill Cavanaugh 1992-10-02 Modified routine to reformat profiler data
C> (fi6709) to show descriptors, scale value and data in proper order.
C> Corrected an error that prevented user from assigning the second dimension
C> of kdata(500,*).
C> - Bill Cavanaugh 1992-10-20 Removed error that prevented full implementation
C> of previous corrections and made corrections to table b to bring it up to
C> date. Changes include proper reformat of profiler data and user capability
C> for assigning second dimension of kdata array.
C> - Bill Cavanaugh 1993-01-26 Added routine fi6710() to permit reformatting
C> profiler data in BUFR edition 2.
C>
C> @param[in] MSGA Array containing supposed bufr message.
C> @param[out] ISTACK Original array of descriptors extracted from
C> source bufr message.
C> @param[out] MSTACK (A,B)
C> - LEVEL B - Descriptor number
C> - LEVEL A = 1 Descriptor
C>  - = 2 10**N Scaling to return to original value
C> @param[out] IPTR Utility array.
C> - IPTR( 1)- Error return.
C> - IPTR( 2)- Byte count section 1.
C> - IPTR( 3)- Pointer to start of section 1.
C> - IPTR( 4)- Byte count section 2.
C> - IPTR( 5)- Pointer to start of section 2.
C> - IPTR( 6)- Byte count section 3.
C> - IPTR( 7)- Pointer to start of section 3.
C> - IPTR( 8)- Byte count section 4.
C> - IPTR( 9)- Pointer to start of section 4.
C> - IPTR(10)- Start of requested subset, reserved for dar.
C> - IPTR(11)- Current descriptor ptr in iwork.
C> - IPTR(12)- Last descriptor pos in iwork.
C> - IPTR(13)- Last descriptor pos in istack.
C> - IPTR(14)- Number of table b entries.
C> - IPTR(15)- Requested subset pointer, reserved for dar.
C> - IPTR(16)- Indicator for existance of section 2.
C> - IPTR(17)- Number of reports processed.
C> - IPTR(18)- Ascii/text event.
C> - IPTR(19)- Pointer to start of bufr message.
C> - IPTR(20)- Number of lines from table d.
C> - IPTR(21)- Table b switch.
C> - IPTR(22)- Table d switch.
C> - IPTR(23)- Code/flag table switch.
C> - IPTR(24)- Aditional words added by text info.
C> - IPTR(25)- Current bit number.
C> - IPTR(26)- Data width change.
C> - IPTR(27)- Data scale change.
C> - IPTR(28)- Data reference value change.
C> - IPTR(29)- Add data associated field.
C> - IPTR(30)- Signify characters.
C> - IPTR(31)- Number of expanded descriptors in mstack.
C> - IPTR(32)- Current descriptor segment f.
C> - IPTR(33)- Current descriptor segment x.
C> - IPTR(34)- Current descriptor segment y.
C> - IPTR(35)- Unused.
C> - IPTR(36)- Next descriptor may be undecipherable.
C> - IPTR(37)- Unused.
C> - IPTR(38)- Unused.
C> - IPTR(39)- Delayed replication flag.
C>  - 0 - No delayed replication.
C>  - 1 - Message contains delayed replication.
C> - IPTR(40)- Number of characters in text for curr descriptor.
C> @param[out] IDENT Array contains message information extracted from bufr message
C> - IDENT( 1)-Edition number (byte 4, section 1).
C> - IDENT( 2)-Originating center (bytes 5-6, section 1).
C> - IDENT( 3)-Update sequence (byte 7, section 1).
C> - IDENT( 4)-Optional section (byte 8, section 1).
C> - IDENT( 5)-Bufr message type (byte 9, section 1).
C>  - 0 = Surface (land)
C>  - 1 = Surface (ship)
C>  - 2 = Vertical soundings other than satellite
C>  - 3 = Vertical soundings (satellite)
C>  - 4 = Sngl lvl upper-air other than satellite
C>  - 5 = Sngl lvl upper-air (satellite)
C>  - 6 = Radar
C> - IDENT( 6)-Bufr msg sub-type (byte 10, section 1)
C> | type | sbtyp |
C> | :--- | :---- |
C> | 2    |  7   = profiler |
C> - IDENT(7) - bytes 11-12, section 1).
C> - IDENT(8) - Year of century (byte 13, section 1).
C> - IDENT(9) - Month of year (byte 14, section 1).
C> - IDENT(10) - Day of month (byte 15, section 1).
C> - IDENT(11) - Hour of day (byte 16, section 1).
C> - IDENT(12) - Minute of hour (byte 17, section 1).
C> - IDENT(13) - Rsvd by adp centers (byte 18, section 1).
C> - IDENT(14) - Nr of data subsets (byte 5-6, section 3).
C> - IDENT(15) - Observed flag (byte 7, bit 1, section 3).
C> - IDENT(16) - Compression flag (byte 7, bit 2, section 3).
C> - IDENT(17) - Master table number (byte 4, section 1, ed 2 or gtr).
C> @param[out] KDATA Array containing decoded reports from bufr message.
C> @param[in] KNR
C> kdata(report number,parameter number) arrays containing data from table b
C> - ANAME Descriptor name.
C> - AUNITS Units for descriptor.
C> - MSCALE Scale for value of descriptor.
C> - MREF Reference value for descriptor.
C> - MWIDTH Bit width for value of descriptor.
C> @param[out] INDEX Pointer to available subset.
C>
C> @note Error returns:
C> - IPTR(1):
C>  - = 1 'BUFR' Not found in first 125 characters.
C>  - = 2 '7777' Not found in location determined by
C>  by using counts found in each section. one or
C>  more sections have an erroneous byte count or
C>  characters '7777' are not in test message.
C>  - = 3 Message contains a descriptor with f=0 that does
C>  not exist in table b.
C>  - = 4 Message contains a descriptor with f=3 that does
C>  not exist in table d.
C>  - = 5 Message contains a descriptor with f=2 with the
C>  value of x outside the range 1-5.
C>  - = 6 Descriptor element indicated to have a flag value
C>  does not have an entry in the flag table
C>  (to be activated).
C>  - = 7 Descriptor indicated to have a code value does
C>  not have an entry in the code table
C>  (to be activated).
C>  - = 8 Error reading table d.
C>  - = 9 Error reading table b.
C>  - = 10 Error reading code/flag table.
C>  - = 11 Descriptor 2 04 004 not followed by 0 31 021.
C>  - = 12 Data descriptor operator qualifier does not follow
C>  delayed replication descriptor.
C>  - = 13 Bit width on ascii characters not a multiple of 8.
C>  - = 14 Subsets = 0, no content bulletin.
C>  - = 20 Exceeded count for delayed replication pass.
C>  - = 21 Exceeded count for non-delayed replication pass.
C>  - = 22 Section 1 count exceeds 10000.
C>  - = 23 Section 2 count exceeds 10000.
C>  - = 24 Section 3 count exceeds 10000.
C>  - = 25 Section 4 count exceeds 10000.
C>  - = 27 Non zero lowest on text data.
C>  - = 28 Nbinc not nr of characters.
C>  - = 29 Table b appears to be damaged.
C>  - = 99 No more subsets (reports) available in current
C>  bufr mesage.
C>  - = 400 Number of subsets exceeds capability of routine.
C>  - = 401 Number of parameters (and associated fields)
C>  exceeds limits of this program.
C>  - = 500 Value for nbinc has been found that exceeds
C>  standard width plus any bit width change
C>  check all bit widths up to point of error.
C>  - = 501 Corrected width for descriptor is 0 or less.
C>
C>  On the initial call to w3fi67() with a bufr message the argument
C>  index must be set to zero (index = 0). on the return from w3fi67()
C>  'index' will be set to the next available subset/report. when
C>  there are no more subsets available a 99 err return will occur.
C>
C>  If the original bufr message does not contain delayed replication
C>  the bufr message will be completely decoded and 'index' will point
C>  to the first decoded subset. The users will then have the option
C>  of indexing through the subsets on their own or by recalling this
C>  routine (without resetting 'index') to have the routine do the
C>  indexing.
C>
C>  If the original bufr message does contain delayed replication
C>  one subset/report will be decoded at a time and passed back to
C>  the user. this is not an option.
C>
C>  =============================================
C>   TO USE THIS ROUTINE
C>  --------------------------------
C>       1. READ IN BUFR MESSAGE
C>       2. SET INDEX = 0
C>       3. CALL W3FI67(        )
C>       4. IF (IPTR(1).EQ.99) THEN
C>                      NO MORE SUBSETS
C>                     EITHER GO TO 1
C>                     OR TERMINATE IN NO MORE BUFR MESSAGES
C>          END IF
C>       5. IF (IPTR(1).NE.0) THEN
C>                        ERROR CONDITION
C>                     EITHER GO TO 1
C>                     OR TERMINATE IN NO MORE BUFR MESSAGES
C>          END IF
C>       6. THE VALUE OF INDEX INDICATES THE ACTIVE SUBSET SO
C>          IF INTERESTED IN GENERATING AN IFOD MESSAGE
C>              CALL W3FL05 (        )
C>          ELSE
C>              PROCESS DECODED INFORMATION AS REQUIRED
C>          END IF
C>       7. GO TO 3
C>
C>  =============================================
C>       THE ARRAYS TO CONTAIN THE OUTPUT INFORMATION ARE DEFINED
C>       AS FOLLOWS:
C>           KDATA(A,B)  IS THE A DATA ENTRY  (INTEGER VALUE)
C>                       WHERE A IS THE MAXIMUM NUMBER OF REPORTS/SUBSETS
C>                       (FOR THIS VERSION OF THE DECODER A=500)
C>                       THAT MAY BE CONTAINED IN THE BUFR MESSAGE, AND
C>                       WHERE B IS THE MAXIMUM NUMBER OF DESCRIPTOR
C>                       COMBINATIONS THAT MAY BE PROCESSED.
C>                       UPPER AIR DATA AND SOME SATELLITE DATA REQUIRE
C>                       A VALUE FOR B OF 1600, BUT FOR MOST OTHER DATA
C>                       A VALUE FOR B OF 500 WILL SUFFICE
C>           MSTACK(1,B) CONTAINS THE DESCRIPTOR THAT MATCHES THE
C>                       DATA ENTRY
C>           MSTACK(2,B) IS THE SCALE (POWER OF 10) TO BE APPLIED TO
C>                       THE DATA
C>
C> ATTRIBUTES:
C>   LANGUAGE: FORTRAN 77
C>   MACHINE:  NAS
C>
      SUBROUTINE W3FI67(IPTR,IDENT,MSGA,ISTACK,MSTACK,KDATA,KNR,INDEX)
C
      CHARACTER*40   ANAME(700)
      CHARACTER*24   AUNITS(700)
C
C
      INTEGER        MSGA(*),KDATA(500,*)
      INTEGER        IPTR(*),MSTACK(2,*)
      INTEGER        IVALS(500),KNR(*)
      INTEGER        IDENT(*)
      INTEGER        KDESC(1600)
      INTEGER        ISTACK(*),IWORK(1600)
      INTEGER        MSCALE(700)
      INTEGER        MREF(700,3)
      INTEGER        MWIDTH(700)
      INTEGER        INDEX
C
      CHARACTER*4    DIRID(2)
C
      LOGICAL        SEC2
C
      SAVE
C
C     PRINT *,' W3FI67 DECODER'
C                            INITIALIZE ERROR RETURN
      IPTR(1)   = 0
      IF (INDEX.GT.0) THEN
C                                 HAVE RE-ENTRY
          INDEX   = INDEX + 1
C         PRINT *,'RE-ENTRY LOOKING FOR SUBSET NR',INDEX
          IF (INDEX.GT.IDENT(14)) THEN
C                                 ALL SUBSETS PROCESSED
              IPTR(1)  = 99
              IPTR(39) = 0
          ELSE IF (INDEX.LE.IDENT(14)) THEN
              IF (IPTR(39).NE.0) THEN
                  CALL FI6701(IPTR,IDENT,MSGA,ISTACK,IWORK,ANAME,KDATA,
     *               IVALS,
     *               MSTACK,AUNITS,KDESC,MWIDTH,MREF,MSCALE,KNR,INDEX)
              END IF
          END IF
          RETURN
      ELSE
          INDEX  = 1
C         PRINT *,'INITIAL ENTRY FOR THIS BUFR MESSAGE'
      END IF
      IPTR(39)  = 0
C                        FIND 'BUFR' IN FIRST 125 CHARACTERS
      DO 1000 KNOFST = 0, 999, 8
          INOFST     = KNOFST
          CALL GBYTE (MSGA,IVALS,INOFST,8)
          IF (IVALS(1).EQ.66) THEN
              IPTR(19)   = INOFST
              INOFST     = INOFST + 8
              CALL GBYTE (MSGA,IVALS,INOFST,24)
              IF (IVALS(1).EQ.5588562) THEN
C                 PRINT *,'FOUND BUFR AT',IPTR(19)
                  INOFST     = INOFST + 24
                  GO TO 1500
              END IF
          END IF
 1000 CONTINUE
      PRINT *,'BUFR - START OF BUFR MESSAGE NOT FOUND'
      IPTR(1)    = 1
      RETURN
 1500 CONTINUE
      IDENT(1)   = 0
C                            TEST FOR EDITION NUMBER
C  ======================
      CALL GBYTE (MSGA,IDENT(1),INOFST+24,8)
C     PRINT *,'THIS IS AN EDITION ',IDENT(1),' BUFR MESSAGE'
      IF (IDENT(1).GE.2) THEN
          CALL GBYTE (MSGA,IVALS,INOFST,24)
          ITOTAL   = IVALS(1)
          KENDER   = ITOTAL * 8 - 32 + IPTR(19)
          CALL GBYTE (MSGA,ILAST,KENDER,32)
          IF (ILAST.EQ.926365495) THEN
C             PRINT *,'HAVE TOTAL COUNT FROM SEC 0',IVALS(1)
              INOFST   = INOFST + 32
          END IF
          IPTR(3)    = INOFST
C                            SECTION 1 COUNT
          CALL GBYTE (MSGA,IVALS,INOFST,24)
C         PRINT *,'SECTION 1 STARTS AT',INOFST,'  SIZE',IVALS(1)
          INOFST     = INOFST + 24
          IPTR( 2)   = IVALS(1)
          IF (IVALS(1).GT.10000) THEN
              IPTR(1)   = 22
              RETURN
          END IF
C                          GET BUFR MASTER TABLE
          CALL GBYTE (MSGA,IVALS,INOFST,8)
          INOFST     = INOFST + 8
          IDENT(17)  = IVALS(1)
C         PRINT *,'BUFR MASTER TABLE NR',IDENT(17)
      ELSE
          IPTR(3)    = INOFST
C                            SECTION 1 COUNT
          CALL GBYTE (MSGA,IVALS,INOFST,24)
C         PRINT *,'SECTION 1 STARTS AT',INOFST,'  SIZE',IVALS(1)
          INOFST     = INOFST + 32
          IPTR( 2)   = IVALS(1)
          IF (IVALS(1).GT.10000) THEN
              IPTR(1)   = 22
              RETURN
          END IF
      END IF
C  ======================
C                            ORIGINATING CENTER
      CALL GBYTE (MSGA,IVALS,INOFST,16)
      INOFST     = INOFST + 16
      IDENT(2)   = IVALS(1)
C                            UPDATE SEQUENCE
      CALL GBYTE (MSGA,IVALS,INOFST,8)
      INOFST     = INOFST + 8
      IDENT(3)   = IVALS(1)
C                            OPTIONAL SECTION FLAG
      CALL GBYTE (MSGA,IVALS,INOFST,1)
      IDENT(4)   = IVALS(1)
      IF (IDENT(4).GT.0) THEN
          SEC2       = .TRUE.
      ELSE
C         PRINT *,'              NO OPTIONAL SECTION 2'
          SEC2       = .FALSE.
      END IF
      INOFST     = INOFST + 8
C                            MESSAGE TYPE
      CALL GBYTE (MSGA,IVALS,INOFST,8)
      IDENT(5)   = IVALS(1)
      INOFST     = INOFST + 8
C                            MESSAGE SUB-TYPE
      CALL GBYTE (MSGA,IVALS,INOFST,8)
      IDENT(6)   = IVALS(1)
      INOFST     = INOFST + 8
C                           IF BUFR EDITION 0 OR 1 THEN
C                                 NEXT 2 BYTES ARE BUFR TABLE VERSION
C                           ELSE
C                               BYTE 11 IS VER NR OF MASTER TABLE
C                               BYTE 12 IS VER NR OF LOCAL TABLE
      IF (IDENT(1).LT.2) THEN
          CALL GBYTE (MSGA,IVALS,INOFST,16)
          IDENT(7)   = IVALS(1)
          INOFST     = INOFST + 16
      ELSE
C                               BYTE 11 IS VER NR OF MASTER TABLE
          CALL GBYTE (MSGA,IVALS,INOFST,8)
          IDENT(18)  = IVALS(1)
          INOFST     = INOFST + 8
C                               BYTE 12 IS VER NR OF LOCAL TABLE
          CALL GBYTE (MSGA,IVALS,INOFST,8)
          IDENT(19)  = IVALS(1)
          INOFST     = INOFST + 8

      END IF
C                            YEAR OF CENTURY
      CALL GBYTE (MSGA,IVALS,INOFST,8)
      IDENT(8)   = IVALS(1)
      INOFST     = INOFST + 8
C                            MONTH
      CALL GBYTE (MSGA,IVALS,INOFST,8)
      IDENT(9)   = IVALS(1)
      INOFST     = INOFST + 8
C                            DAY
      CALL GBYTE (MSGA,IVALS,INOFST,8)
      IDENT(10)  = IVALS(1)
      INOFST     = INOFST + 8
C                            HOUR
      CALL GBYTE (MSGA,IVALS,INOFST,8)
      IDENT(11)  = IVALS(1)
      INOFST     = INOFST + 8
C                            MINUTE
      CALL GBYTE (MSGA,IVALS,INOFST,8)
      IDENT(12)  = IVALS(1)
C                            RESET POINTER (INOFST) TO START OF
C                                NEXT SECTION
C                                (SECTION 2 OR SECTION 3)
      INOFST     = IPTR(3) + IPTR(2) * 8
      IPTR(4)    = 0
      IPTR(5)    = INOFST
      IF (SEC2) THEN
          IPTR(5)  = INOFST
C                            SECTION 2 COUNT
          CALL GBYTE (MSGA,IPTR(4),INOFST,24)
          INOFST   = INOFST + 32
C         PRINT *,'SECTION 2 STARTS AT',INOFST,' BYTES=',IPTR(4)
          KENTRY  = (IPTR(4) - 4) / 14
C         PRINT *,'SHOULD BE A MAX OF',KENTRY,' REPORTS'
          IF (IDENT(2).EQ.7) THEN
              DO 2000 I = 1, KENTRY
                  CALL GBYTE (MSGA,KDSPL ,INOFST,16)
                  INOFST  = INOFST + 16
                  CALL GBYTE (MSGA,LAT   ,INOFST,16)
                  INOFST  = INOFST + 16
                  CALL GBYTE (MSGA,LON   ,INOFST,16)
                  INOFST  = INOFST + 16
                  CALL GBYTE (MSGA,KDAHR ,INOFST,16)
                  INOFST  = INOFST + 16
                  CALL GBYTE (MSGA,DIRID(1),INOFST,32)
                  INOFST  = INOFST + 32
                  CALL GBYTE (MSGA,DIRID(2),INOFST,16)
                  INOFST  = INOFST + 16
C                 PRINT *,KDSPL,LAT,LON,KDAHR,DIRID(1),DIRID(2)
 2000         CONTINUE
          END IF
C                            RESET POINTER (INOFST) TO START OF
C                                SECTION 3
          INOFST     = IPTR(5) + IPTR(4) * 8
      END IF
C                            BIT OFFSET TO START OF SECTION 3
      IPTR( 7)   = INOFST
C                            SECTION 3 COUNT
      CALL GBYTE (MSGA,IPTR(6),INOFST,24)
C     PRINT *,'SECTION 3 STARTS AT',INOFST,' BYTES=',IPTR(6)
      INOFST     = INOFST + 24
      IF (IPTR(6).GT.10000) THEN
          IPTR(1)   = 24
          RETURN
      END IF
      INOFST     = INOFST + 8
C                            NUMBER OF DATA SUBSETS
      CALL GBYTE (MSGA,IDENT(14),INOFST,16)
      IF (IDENT(14).GT.500) THEN
          PRINT *,'THE NUMBER OF SUBSETS EXCEEDS THE CAPABILITY'
          PRINT *,'OF THIS VERSION OF THE BUFR DECODER. ANOTHER '
          PRINT *,'VERSION MUST BE CONSTRUCTED TO HANDLE AT LEAST'
          PRINT *,IDENT(14),'SUBSETS TO BE ABLE TO PROCESS THIS DATA'
          IPTR(1)  = 400
          RETURN
      END IF
      INOFST     = INOFST + 16
C                            OBSERVED DATA FLAG
      CALL GBYTE (MSGA,IVALS,INOFST,1)
      IDENT(15)  = IVALS(1)
      INOFST     = INOFST + 1
C                            COMPRESSED DATA FLAG
      CALL GBYTE (MSGA,IVALS,INOFST,1)
      IDENT(16)  = IVALS(1)
      INOFST     = INOFST + 7
C                            CALCULATE NUMBER OF DESCRIPTORS
      NRDESC     = (IPTR( 6) - 8) / 2
      IPTR(12)   = NRDESC
      IPTR(13)   = NRDESC
C                            EXTRACT DESCRIPTORS
      CALL GBYTES (MSGA,ISTACK,INOFST,16,0,NRDESC)
C     PRINT *,'INITIAL DESCRIPTOR LIST OF',NRDESC,' DESCRIPTORS'
      DO 10 L = 1, NRDESC
          IWORK(L)   = ISTACK(L)
C         PRINT *,L,ISTACK(L)
   10 CONTINUE
      IPTR(13)   = NRDESC
C                            RESET POINTER TO START OF SECTION 4
      INOFST     = IPTR(7) + IPTR(6) * 8
C                            BIT OFFSET TO START OF SECTION 4
      IPTR( 9)   = INOFST
C                            SECTION 4 COUNT
      CALL GBYTE (MSGA,IVALS,INOFST,24)
      IF (IVALS(1).GT.10000) THEN
          IPTR(1)   = 25
          RETURN
      END IF
C     PRINT *,'SECTION 4 STARTS AT',INOFST,' VALUE',IVALS(1)
      IPTR( 8)   = IVALS(1)
      INOFST     = INOFST + 32
C                            SET FOR STARTING BIT OF DATA
      IPTR(25)   = INOFST
C                            FIND OUT IF '7777' TERMINATOR IS THERE
      INOFST     = IPTR(9) + IPTR(8) * 8
      CALL GBYTE  (MSGA,IVALS,INOFST,32)
C     PRINT *,'SECTION 5 STARTS AT',INOFST,' VALUE',IVALS(1)
      IF (IVALS(1).NE.926365495) THEN
          PRINT *,'BAD SECTION COUNT'
          IPTR(1)     = 2
          RETURN
      ELSE
          IPTR(1)     = 0
      END IF
      CALL FI6701(IPTR,IDENT,MSGA,ISTACK,IWORK,ANAME,KDATA,IVALS,
     *               MSTACK,AUNITS,KDESC,MWIDTH,MREF,MSCALE,KNR,INDEX)
C     PRINT *,'HAVE RETURNED FROM FI6701'
      IF (IPTR(1).NE.0) THEN
          RETURN
      END IF
C                FURTHER PROCESSING REQUIRED FOR PROFILER DATA
      IF (IDENT(5).EQ.2) THEN
          IF (IDENT(6).EQ.7) THEN
C             DO 151 I = 1, 40
C                 IF (I.LE.20) THEN
C                     PRINT *,'IPTR(',I,')=',IPTR(I),
C    *                                       ' IDENT(',I,')= ',IDENT(I)
C                 ELSE
C                     PRINT *,'IPTR(',I,')=',IPTR(I)
C                 END IF
C 151         CONTINUE
C             DO 153 I = 1, KNR(INDEX)
C                PRINT *,I,MSTACK(1,I),MSTACK(2,I),KDATA(1,I),KDATA(2,I)
C 153         CONTINUE
              PRINT *,'REFORMAT PROFILER DATA'
              IF (IDENT(1).LT.2) THEN
                  CALL FI6709(IDENT,MSTACK,KDATA,IPTR)
              ELSE
                  CALL FI6710(IDENT,MSTACK,KDATA,IPTR)
              END IF
              IF (IPTR(1).NE.0) THEN
                  RETURN
              END IF
C             DO 154 I = 1, KNR(INDEX)
C                PRINT *,I,MSTACK(1,I),MSTACK(2,I),KDATA(1,I),KDATA(2,I)
C 154         CONTINUE
          END IF
      END IF
      RETURN
      END

C> @brief Data extraction.
C> @author Bill Cavanaugh @date 1988-09-01

C> Control the extraction of data from section 4 based on
C> data descriptors.
C>
C> Program history log:
C> - Bill Cavanaugh 1988-09-01
C> - Bill Cavanaugh 1991-01-18 Corrections to properly handle non-compressed
C> data.
C> - Bill Cavanaugh 1991-09-23 Coding added to handle single subsets with
C> delayed replication.
C> - Bill Cavanaugh 1992-01-24 Modified to echo descriptors to mstack(1,n)
C>
C> @param[in] IPTR See w5fi67 routine docblock.
C> @param[in] IDENT See w3fi67 routine docblock.
C> @param[in] MSGA Array containing bufr message.
C> @param[inout] ISTACK [in] Original array of descriptors extracted from
C> source bufr message. [out] Arrays containing data from table b.
C> @param[in] MSTACK Working array of descriptors (expanded)and scaling
C> factor.
C> @param[inout] KDESC Image of current descriptor.
C> @param[in] INDEX
C> @param KNR
C> @param[out] IWORK Working descriptor list
C> @param IVALS
C> @param[out] KDATA Array containing decoded reports from bufr message
C> kdata(report number,parameter number).
C> @param[out] ANAME Descriptor name..
C> @param[out] AUNITS Units for descriptor.
C> @param[out] MSCALE Scale for value of descriptor.
C> @param[out] MREF Reference value for descriptor.
C> @param[out] MWIDTH Bit width for value of descriptor.
C>
C> @note Error return:
C> - IPTR(1)
C>  - = 8   ERROR READING TABLE B
C>  - = 9   ERROR READING TABLE D
C>  - = 11  ERROR OPENING TABLE B
C>
C> @author Bill Cavanaugh @date 1988-09-01
      SUBROUTINE FI6701(IPTR,IDENT,MSGA,ISTACK,IWORK,ANAME,KDATA,IVALS,
     *               MSTACK,AUNITS,KDESC,MWIDTH,MREF,MSCALE,KNR,INDEX)

      SAVE
C
      CHARACTER*40   ANAME(*)
      CHARACTER*24   AUNITS(*)
C
      INTEGER        MSGA(*),KDATA(500,*),IVALS(*)
      INTEGER        MSCALE(*),KNR(*)
      INTEGER        LX,LY,LL,J
      INTEGER        MREF(700,3)
      INTEGER        MWIDTH(*)
      INTEGER        IHOLD(33)
      INTEGER        ITBLD(500,11)
      INTEGER        IPTR(*)
      INTEGER        IDENT(*)
      INTEGER        KDESC(*)
      INTEGER        ISTACK(*),IWORK(*)
      INTEGER        MSTACK(2,*),KK
      INTEGER        JDESC
      INTEGER        INDEX
      INTEGER        ITEST(30)
C
      DATA  ITEST  /1,3,7,15,31,63,127,255,
     *             511,1023,2047,4095,8191,16383,
     *             32767, 65535,131071,262143,524287,
     *             1048575,2097151,4194303,8388607,
     *             16777215,33554431,67108863,134217727,
     *             268435455,536870911,1073741823/
C
C     PRINT *,' DECOLL FI6701'
      IF (INDEX.GT.1) THEN
              GO TO 1000
      END IF
C                      ---------  DECOLL  ---------------
      IPTR(23)    = 0
      IPTR(26)    = 0
      IPTR(27)    = 0
      IPTR(28)    = 0
      IPTR(29)    = 0
      IPTR(30)    = 0
      IPTR(36)    = 0
C                            INITIALIZE OUTPUT AREA
C                              SET POINTER TO BEGINNING OF DATA
C                                   SET BIT
      IPTR(17)   = 1
 1000 CONTINUE
C     IPTR(12)   = IPTR(13)
      LL         = 0
      IPTR(11)   = 1
      IF (IPTR(10).EQ.0) THEN
C                              RE-ENTRY POINT FOR MULTIPLE
C                                 NON-COMPRESSED REPORTS
      ELSE
          INDEX     = IPTR(15)
          IPTR(17)  = INDEX
          IPTR(25)  = IPTR(10)
          IPTR(10)  = 0
          IPTR(15)  = 0
      END IF
C     PRINT *,'FI6701 - RPT',IPTR(17),'  STARTS AT',IPTR(25)
      IPTR(24)  = 0
      IPTR(31)  = 0
C                              POINTING AT NEXT AVAILABLE DESCRIPTOR
      MM         = 0
      IF (IPTR(21).EQ.0) THEN
C         PRINT *,' READING TABLE B'
          DO 150 I = 1, 700
              IPTR(21)   = I
              READ(UNIT=20,FMT=20,ERR=9999,END=175)MF,
     *                    MX,MY,
     *                    (ANAME(I)(K:K),K=1,40),
     *                    (AUNITS(I)(K:K),K=1,24),
     *                    MSCALE(I),MREF(I,1),MWIDTH(I)
   20         FORMAT(I1,I2,I3,40A1,24A1,I5,I15,1X,I4)
              IF (MWIDTH(I).EQ.0) THEN
                  IPTR(1)   = 29
                  RETURN
              END IF
              MREF(I,2)  = 0
              IPTR(14)  = I
              KDESC(I)  = MF*16384 + MX*256 + MY
C             PRINT *,I
C             WRITE(6,21) MF,MX,MY,KDESC(I),
C    *                    (ANAME(I)(K:K),K=1,40),
C    *                    (AUNITS(I)(K:K),K=1,24),
C    *                    MSCALE(I),MREF(I,1),MWIDTH(I)
   21         FORMAT(1X,I1,I2,I3,1X,I6,1X,40A1,
     *                                 2X,24A1,2X,I5,2X,I15,1X,I4)
  150     CONTINUE
          PRINT *,'HAVE READ LIMIT OF 700 TABLE B DESCRIPTORS'
          PRINT *,'IF THERE ARE MORE THAT THAT, CORRECT READ LOOP'
  175     CONTINUE
C         CLOSE(UNIT=20,STATUS='KEEP')
          IPTR(21) = 1
      END IF
C     DO WHILE           MM <= 500
   10     CONTINUE
C                              PROCESS THRU THE FOLLOWING
C                              DEPENDING UPON THE VALUE OF 'F' (LF)
          MM     = MM + 1
   12     CONTINUE
          IF (MM.GT.2000) THEN
              GO TO 200
          END IF
C                            END OF CYCLE TEST (SERIAL/SEQUENTIAL)
          IF (IPTR(11).GT.IPTR(12)) THEN
C             PRINT *,' HAVE COMPLETED REPORT SEQUENCE'
              IF (IDENT(16).NE.0) THEN
C                 PRINT *,' PROCESSING COMPRESSED REPORTS'
C                            REFORMAT DATA FROM DESCRIPTOR
C                            FORM TO USER FORM
                  RETURN
              ELSE
C                 WRITE (6,1)
C   1             FORMAT (1H1)
C                 PRINT *,' PROCESSED SERIAL REPORT',IPTR(17),IPTR(25)
                  IPTR(17) = IPTR(17) + 1
                  IF (IPTR(17).GT.IDENT(14)) THEN
                      IPTR(17)  = IPTR(17) - 1
                      GO TO 200
                  END IF
                  DO 300 I = 1, IPTR(13)
                      IWORK(I)  = ISTACK(I)
  300             CONTINUE
C                             RESET POINTERS
                  LL       = 0
                  IPTR(1)   = 0
                  IPTR(11)  = 1
                  IPTR(12)  = IPTR(13)
C                         IS THIS LAST REPORT ?
C                 PRINT *,'READY',IPTR(39),INDEX
                  IF (IPTR(39).GT.0) THEN
                      IF (INDEX.GT.0) THEN
C                         PRINT *,'HERE IS SUBSET NR',INDEX
                          RETURN
                      END IF
                  END IF
                  GO TO 1000
              END IF
          END IF
   14     CONTINUE
C                               GET NEXT DESCRIPTOR
          CALL FI6708 (IPTR,IWORK,LF,LX,LY,JDESC)
C         PRINT *,IPTR(11)-1,'JDESC= ',JDESC,' AND NEXT ',
C    *                       IPTR(11),IWORK(IPTR(11)),IPTR(31)
C         PRINT *,IPTR(11)-1,'DESCRIPTOR',JDESC,LF,LX,LY,
C    *       ' FOR LOC',IPTR(17),IPTR(25)
          IF (IPTR(11).GT.1600) THEN
              IPTR(1)  = 401
              RETURN
          END IF
C
              KPRM        = IPTR(31) + IPTR(24)
              IF (KPRM.GT.1600) THEN
                  IF (KPRM.GT.KOLD) THEN
                      PRINT *,'EXCEEDED  ARRAY SIZE',KPRM,IPTR(31),
     *                        IPTR(24)
                      KOLD  = KPRM
                  END IF
              END IF
C                          REPLICATION PROCESSING
          IF (LF.EQ.1) THEN
C                                        ----------  F1  ---------
              IPTR(31)    = IPTR(31) + 1
              KPRM        = IPTR(31) + IPTR(24)
              MSTACK(1,KPRM)       = JDESC
              MSTACK(2,KPRM)       = 0
              KDATA(IPTR(17),KPRM) = 0
C             PRINT *,'FI6701-1',KPRM,MSTACK(1,KPRM),
C    *                       MSTACK(2,KPRM),KDATA(IPTR(17),KPRM)
              CALL FI6705(IPTR,IDENT,MSGA,IWORK,LX,LY,
     *                                          KDATA,LL,KNR,MSTACK)
              IF (IPTR(1).NE.0) THEN
                  RETURN
              ELSE
                  GO TO 12
              END IF
C
C                             DATA DESCRIPTION OPERATORS
          ELSE IF (LF.EQ.2)THEN
              IF (LX.EQ.5) THEN
              ELSE IF (LX.EQ.4) THEN
                  IPTR(31)       = IPTR(31) + 1
                  KPRM           = IPTR(31) + IPTR(24)
                  MSTACK(1,KPRM) = JDESC
                  MSTACK(2,KPRM) = 0
                  KDATA(IPTR(17),KPRM) = 0
C                 PRINT *,'FI6701-2',KPRM,MSTACK(1,KPRM),
C    *                       MSTACK(2,KPRM),KDATA(IPTR(17),KPRM)
              END IF
              CALL FI6706 (IPTR,LX,LY,IDENT,MSGA,KDATA,IVALS,MSTACK,
     *                 MWIDTH,MREF,MSCALE,J,LL,KDESC,IWORK,JDESC)
              IF (IPTR(1).NE.0) THEN
                  RETURN
              END IF
              GO TO 12
C                              DESCRIPTOR SEQUENCE STRINGS
          ELSE IF (LF.EQ.3) THEN
C             PRINT *,'F3  SEQUENCE DESCRIPTOR'
              IF (IPTR(22).EQ.0) THEN
C                                  READ IN TABLE D, BUT JUST ONCE
                  IERR  = 0
C                 PRINT *,' READING TABLE D'
                  DO 50 I = 1, 500
                      READ(21,15,ERR=9998,END=75 )
     *                                 (IHOLD(J),J=1,33)
   15                 FORMAT(11(I1,I2,I3,1X),3X)
                      IPTR(20)   = I
                      DO 25 JJ = 1, 31, 3
                          KK = (JJ/3) + 1
                          ITBLD(I,KK) = IHOLD(JJ)*16384 +
     *                                 IHOLD(JJ+1)*256 + IHOLD(JJ+2)
                          IF (ITBLD(I,KK).EQ.0) THEN
C                             PRINT 16,(ITBLD(I,L),L=1,11)
                              GO TO 50
                          END IF
   25                 CONTINUE
C                     PRINT 16,(ITBLD(I,L),L=1,11)
   50             CONTINUE
   16             FORMAT(1X,11(I6,1X))
   75             CONTINUE
                  CLOSE(UNIT=21,STATUS='KEEP')
                  IPTR(22)  = 1
              ENDIF
              CALL FI6707(IPTR,IWORK,ITBLD,JDESC)
              IF (IPTR(1).GT.0) THEN
                   RETURN
              END IF
              GO TO 14
C
C                              STANDARD DESCRIPTOR PROCESSING
          ELSE
C             PRINT *,'ENTRY',IPTR(31),JDESC,' AT',IPTR(25)
              KPRM           = IPTR(31) + IPTR(24)
              CALL FI6702(IPTR,IDENT,MSGA,KDATA,KDESC,LL,MSTACK,
     *                    AUNITS,MWIDTH,MREF,MSCALE,JDESC,IVALS,J)
C                             TURN OFF SKIP FLAG AFTER STD DESCRIPTOR
              IPTR(36)   = 0
              IF (IPTR(1).GT.0) THEN
                  RETURN
              ELSE
                  IF (IDENT(16).EQ.0) THEN
                      KNR(IPTR(17))  = IPTR(31)
                  ELSE
                      DO 310 KJ = 1, 500
                          KNR(KJ) = IPTR(31)
  310                 CONTINUE
                  END IF
                  GO TO 10
              END IF
          END IF
C     END IF
C         END DO WHILE
  200 CONTINUE
      IF (IDENT(16).NE.0) THEN
C         PRINT *,'RETURN WITH',IDENT(14),' COMPRESSED REPORTS'
      ELSE
C         PRINT *,'RETURN WITH',IPTR(17),' NON-COMPRESSED REPORTS'
      END IF
      RETURN
 9998 CONTINUE
      PRINT *,' ERROR READING TABLE D'
      IPTR(1)  = 8
      RETURN
 9999 CONTINUE
      PRINT *,' ERROR READING TABLE B'
      IPTR(1)  = 9
      RETURN
      END
C> @brief Process standard descriptor.
C> @author Bill Cavanaugh @date 1988-09-01

C> Process a standard descriptor (f = 0) and store data
C> in output array.
C>
C> Program history log:
C> - Bill Cavanaugh 1988-09-01
C> - Bill Cavanaugh 1991-04-04 Changed to pass width of text fields in bytes.
C>
C> @param[in] IPTR See w3fi67 routine docblock.
C> @param[in] IDENT See w3fi67 routine docblock.
C> @param[in] MSGA Array containing bufr message.
C> @param[inout] KDATA Array containing decoded reports from bufr message.
C> KDATA(Report number, parameter number)
C> @param[inout] KDESC Image of current descriptor.
C> @param[in] MSTACK
C> @param LL
C> @param[out] AUNITS Units for descriptor.
C> @param[out] MSCALE Scale for value of descriptor.
C> @param[out] MREF Reference value for descriptor.
C> @param[out] MWIDTH Bit width for value of descriptor.
C> @param JDESC
C> @param[in] IVALS Array of single parameter values.
C> @param J
C>
C> @note Error return:
C> IPTR(1) = 3 - Message contains a descriptor with f=0
C> that does not exist in table b.
C>
C> @author Bill Cavanaugh @date 1988-09-01
      SUBROUTINE FI6702(IPTR,IDENT,MSGA,KDATA,KDESC,LL,MSTACK,AUNITS,
     *                  MWIDTH,MREF,MSCALE,JDESC,IVALS,J)

      SAVE
C                                          TABLE B ENTRY
      CHARACTER*24   ASKEY
      CHARACTER*24   AUNITS(*)
C                                          TABLE B ENTRY
      INTEGER        MSGA(*)
      INTEGER        IPTR(*)
      INTEGER        IDENT(*)
      INTEGER        J
      INTEGER        JDESC
      INTEGER        KDESC(*)
      INTEGER        MWIDTH(*),MSTACK(2,*),MSCALE(*)
      INTEGER        MREF(700,3),KDATA(500,*),IVALS(*)
C                                          TABLE B ENTRY
C
      DATA  ASKEY /'CCITT IA5               '/
C
C     PRINT *,' FI6702 - STANDARD DESCRIPTOR PROCESSOR'
C                                          GET A MATCH BETWEEN CURRENT
C                                          DESCRIPTOR (JDESC) AND
C                                          TABLE B ENTRY
C     IF (KDESC(356).EQ.0) THEN
C         PRINT *,'FI6702 - KDESC(356) WENT TO ZER0'
C         IPTR(1) = 600
C         RETURN
C     END IF
      K          = 1
      KK         = IPTR(14)
      IF (JDESC.GT.KDESC(KK)) THEN
          K = KK + 1
      END IF
   10 CONTINUE
      IF (K.GT.KK) THEN
          IF (IPTR(36).NE.0) THEN
C                          HAVE SKIP FLAG
              IF (IDENT(16).NE.0) THEN
C                            SKIP OVER COMPRESSED DATA
C                               LOWEST
                  IPTR(25)   = IPTR(25) + IPTR(36)
C                                 NBINC
                  CALL GBYTE (MSGA,IHOLD,IPTR(25),6)
                  IPTR(25)   = IPTR(25) + 6
                  IPTR(31)   = IPTR(31) + 1
                  KPRM       = IPTR(31) + IPTR(24)
                  MSTACK(1,KPRM)  = JDESC
                  MSTACK(2,KPRM)  = 0
                  DO 50 I = 1, IPTR(14)
                      KDATA(I,KPRM)  = 99999
   50             CONTINUE
C                                  PROCESS DIFFERENCES
                  IF (IHOLD.NE.0) THEN
                      IBITS      = IHOLD * IDENT(14)
                      IPTR(25)  = IPTR(25) + IBITS
                  END IF
              ELSE
                  IPTR(31)   = IPTR(31) + 1
                  KPRM       = IPTR(31) + IPTR(24)
                  MSTACK(1,KPRM)  = JDESC
                  MSTACK(2,KPRM)  = 0
                  KDATA(IPTR(17),KPRM)  = 99999
C                      SKIP OVER NON-COMPRESSED DATA
C                 PRINT *,'SKIP NON-COMPRESSED DATA'
                  IPTR(25)   = IPTR(25) + IPTR(36)
              END IF
              RETURN
          ELSE
              PRINT *,'FI6702 - ERROR = 3'
              PRINT *,JDESC,K,KK,J,KDESC(J)
              PRINT *,' '
              PRINT *,'TABLE B'
              DO 20 LL = 1, IPTR(14)
                PRINT *,LL,KDESC(LL)
   20         CONTINUE
              IPTR(1)     = 3
              RETURN
          END IF
      ELSE
          J          = ((KK - K) / 2) + K
      END IF
      IF (JDESC.EQ.KDESC(K)) THEN
          J          = K
          GO TO 15
      ELSE IF (JDESC.EQ.KDESC(KK))THEN
          J          = KK
          GO TO 15
      ELSE IF (JDESC.LT.KDESC(J)) THEN
          K          = K + 1
          KK         = J - 1
          GO TO 10
      ELSE IF (JDESC.GT.KDESC(J)) THEN
          K          = J + 1
          KK         = KK - 1
          GO TO 10
      END IF
   15 CONTINUE
C                                   HAVE A MATCH
C                                        SET FLAG IF TEXT EVENT
      IF (ASKEY(1:9).EQ.AUNITS(J)(1:9)) THEN
          IPTR(18)     = 1
          IPTR(40)     = MWIDTH(J) / 8
      ELSE
          IPTR(18)     = 0
      END IF
      IF (IDENT(16).NE.0) THEN
C                                   COMPRESSED
          CALL FI6703(IPTR,IDENT,MSGA,KDATA,IVALS,MSTACK,
     *                      MWIDTH,MREF,MSCALE,J,JDESC)
          IF (IPTR(1).NE.0) THEN
              RETURN
          END IF
      ELSE
C                                   NOT COMPRESSED
          CALL FI6704(IPTR,MSGA,KDATA,IVALS,MSTACK,
     *                      MWIDTH,MREF,MSCALE,J,LL,JDESC)
      END IF
      RETURN
      END
C> @brief Process compressed data and place individual elements into output
C> array
C> @author Bill Cavanaugh @date 1988-09-01

C> Program history log:
C> - Bill Cavanaugh 1988-09-01
C> - Bill Cavanaugh 1991-04-04 Text handling portion of this routine
C> modified to hanle width of fields in bytes.
C> - Bill Cavanaugh 1991-04-17 Tests showed that the same data in compressed
C> and uncompressed form gave different results. This has been corrected.
C> - Bill Cavanaugh 1991-06-21 Processing of text data has been changed to
C> provide exact reproduction of all characters.
C>
C> @param[in] IPTR See w3fi67() routine docblock.
C> @param[in] IDENT See w3fi67() routine docblock.
C> @param[in] MSGA Array containing bufr message, mstack.
C> @param[in] MSTACK
C> @param[in] IVALS Array of single parameter values.
C> @param[inout] J
C> @param[out] KDATA Array containing decoded reports from bufr message.
C> kdata(report number,parameter number).
C> @param JDESC
C> Arrays Containing data from table b.
C> @param[out] MSCALE Scale for value of descriptor.
C> @param[out] MREF Reference value for descriptor.
C> @param[out] MWIDTH Bit width for value of descriptor.
C>
C> @note List caveats, other helpful hints or information.
C>
C> @author Bill Cavanaugh @date 1988-09-01
      SUBROUTINE FI6703(IPTR,IDENT,MSGA,KDATA,IVALS,MSTACK,
     *                      MWIDTH,MREF,MSCALE,J,JDESC)

      SAVE
C
      INTEGER        MSGA(*),JDESC,MSTACK(2,*)
      INTEGER        IPTR(*),IVALS(*),KDATA(500,*)
      INTEGER        NRVALS,JWIDE,IDATA
      INTEGER        IDENT(*)
      INTEGER        MSCALE(*)
      INTEGER        MREF(700,3)
      INTEGER        J
      INTEGER        MWIDTH(*)
      INTEGER        KLOW(256)
C
      LOGICAL        TEXT
C
      INTEGER        MSK(28)
C
C
      DATA  MSK  /1,3,7,15,31,63,127,
C                  1   2   3   4    5    6    7
     *             255,511,1023,2047,4095,
C                  8     9     10     11     12
     *             8191,16383,32767,65535,
C                  13     14      15      16
     *             131071,262143,524287,
C                  17       18       19
     *             1048575,2097151,4194303,
C                  20       21        22
     *             8388607,16777215,33554431,
C                  23        24         25
     *             67108863,134217727,268435455/
C                  26         27          28
C
C     PRINT *,' FI6703  COMPR    J=',J,' MWIDTH(J) =',MWIDTH(J),
C    *             ' EXTRA BITS =',IPTR(26),' START AT',IPTR(25)
      IF (IPTR(18).EQ.0) THEN
          TEXT    = .FALSE.
      ELSE
          TEXT    = .TRUE.
      END IF
C     PRINT *,'DESCRIPTOR',KPRM
      IF (.NOT.TEXT) THEN
          IF (IPTR(29).GT.0) THEN
C                        WORKING WITH ASSOCIATED FIELDS HERE
              IPTR(31)   = IPTR(31) + 1
              KPRM       = IPTR(31) + IPTR(24)
C                        GET LOWEST
              CALL GBYTE (MSGA,LOWEST,IPTR(25),IPTR(29))
              IPTR(25)   = IPTR(25) + IPTR(29)
C                        GET NBINC
              CALL GBYTE (MSGA,NBINC,IPTR(25),6)
              IPTR(25)   = IPTR(25) + 6
C                        EXTRACT DATA FOR ASSOCIATED FIELD
              IF (NBINC.GT.0) THEN
                 CALL GBYTES (MSGA,IVALS,IPTR(25),NBINC,0,IPTR(14))
                 IPTR(25)   = IPTR(25) + NBINC * IPTR(14)
                 DO 50 I = 1, IPTR(14)
                     KDATA(I,KPRM) = IVALS(I) + LOWEST
                     IF (KDATA(I,KPRM).GE.MSK(NBINC)) THEN
                         KDATA(I,KPRM) = 999999
                     END IF
   50            CONTINUE
              ELSE
                 DO 51 I = 1, IPTR(14)
                     IF (LOWEST.GE.MSK(NBINC)) THEN
                         KDATA(I,KPRM) = 999999
                     ELSE
                         KDATA(I,KPRM) = LOWEST
                     END IF
   51            CONTINUE
              END IF
          END IF
C                                       SET PARAMETER
C                                       ISOLATE STANDARD BIT WIDTH
          JWIDE     = MWIDTH(J) + IPTR(26)
C                                       SINGLE VALUE FOR LOWEST
          NRVALS    = 1
C                                       LOWEST
C         PRINT *,'PARAM',KPRM
          CALL GBYTE (MSGA,LOWEST,IPTR(25),JWIDE)
C         PRINT *,'            LOWEST=',LOWEST,' AT BIT LOC ',IPTR(25)
          IPTR(25)  = IPTR(25) + JWIDE
C                                       ISOLATE COMPRESSED BIT WIDTH
          CALL GBYTE (MSGA,NBINC,IPTR(25),6)
C         PRINT *,'            NBINC=',NBINC,' AT BIT LOC',IPTR(25)
          IF (IPTR(32).EQ.2.AND.IPTR(33).EQ.5) THEN
          ELSE
              IF (NBINC.GT.JWIDE) THEN
C                 PRINT *,'FOR DESCRIPTOR',JDESC
C              PRINT *,J,'NBINC=',NBINC,' LOWEST=',LOWEST,' MWIDTH(J)=',
C    *          MWIDTH(J),' IPTR(26)=',IPTR(26),' AT BIT LOC',IPTR(25)
C                 DO 110 I = 1, KPRM
C                     WRITE (6,111)I,(KDATA(J,I),J=1,6)
C 110             CONTINUE
  111             FORMAT (1X,5HDATA ,I3,6(2X,I10))
                  IPTR(1) = 500
C                 RETURN
                  PRINT *,'NBINC CALLS FOR LARGER BIT WIDTH THAN TABLE',
     *                       ' B  PLUS  WIDTH CHANGES'
              END IF
          END IF
          IPTR(25)  = IPTR(25) + 6
C         PRINT *,'LOWEST',LOWEST,' NBINC=',NBINC
C                                       IF TEXT EVENT, PROCESS TEXT
C                                       GET COMPRESSED VALUES
C         PRINT *,'COMPRESSED VALUES - NONTEXT'
          NRVALS    = IDENT(14)
          IPTR(31)  = IPTR(31) + 1
          KPRM      = IPTR(31) + IPTR(24)
          IF (NBINC.NE.0) THEN
              CALL GBYTES (MSGA,IVALS,IPTR(25),NBINC,0,NRVALS)
              IPTR(25)  = IPTR(25) + NBINC * NRVALS
C                                       RECALCULATE TO ORIGINAL VALUES
              DO 100 I = 1, NRVALS
C                 PRINT *,IVALS(I),MSK(NBINC),NBINC
                  IF (IVALS(I).GE.MSK(NBINC)) THEN
                      KDATA(I,KPRM) = 999999
                  ELSE
                      IF (MREF(J,2).EQ.0) THEN
                         KDATA(I,KPRM)  = IVALS(I) + LOWEST + MREF(J,1)
                     ELSE
                         KDATA(I,KPRM)  = IVALS(I) + LOWEST + MREF(J,3)
                     END IF
                  END IF
  100         CONTINUE
C             PRINT *,I,JDESC,LOWEST,MREF(J,1),MREF(J,3)
C             PRINT *,I,JDESC,(IVALS(K),K=1,8)
          ELSE
              IF (LOWEST.EQ.MSK(MWIDTH(J))) THEN
                  DO 105 I = 1, NRVALS
                      KDATA(I,KPRM)    = 999999
  105             CONTINUE
              ELSE
                  IF (MREF(J,2).EQ.0) THEN
                      ICOMB  = LOWEST + MREF(J,1)
                  ELSE
                      ICOMB  = LOWEST + MREF(J,3)
                  END IF
                  DO 106 I = 1, NRVALS
                      KDATA(I,KPRM) = ICOMB
  106             CONTINUE
              END IF
          END IF
C         PRINT *,'KPRM=',KPRM,'  IPTR(25)=',IPTR(25)
          MSTACK(1,KPRM)  = JDESC
          IF (IPTR(27).NE.0) THEN
              MSTACK(2,KPRM)  = IPTR(27)
          ELSE
              MSTACK(2,KPRM)  = MSCALE(J)
          END IF
C         WRITE (6,80) (DATA(I,KPRM),I=1,10)
C  80     FORMAT(2X,10(F10.2,1X))
      ELSE IF (TEXT) THEN
C         PRINT *,' FOUND TEXT MODE IN COMPRESSED DATA',IPTR(40)
C                                   GET LOWEST
C         PRINT *,' PICKED UP LOWEST',(KLOW(K),K=1,IPTR(40))
          DO 1906 K = 1, IPTR(40)
              CALL GBYTE (MSGA,KLOW,IPTR(25),8)
              IPTR(25)   = IPTR(25) + 8
              IF (KLOW(K).NE.0) THEN
                  IPTR(1)   = 27
                  PRINT *,'NON-ZERO LOWEST ON TEXT DATA'
                  RETURN
              END IF
 1906     CONTINUE
C                                   GET NBINC
          CALL GBYTE (MSGA,NBINC,IPTR(25),6)
C         PRINT *,'NBINC  =',NBINC
          IPTR(25)     = IPTR(25) + 6
          IF (NBINC.NE.IPTR(40)) THEN
              IPTR(1)  = 28
              PRINT *,'NBINC IS NOT THE NUMBER OF CHARACTERS',NBINC
              RETURN
          END IF
C                                   FOR NUMBER OF OBSERVATIONS
          IPTR(31)      = IPTR(31) + 1
          KPRM          = IPTR(31) + IPTR(24)
          ISTART        = KPRM
          I24           = IPTR(24)
          DO 1900 N   = 1, IDENT(14)
              KPRM        = ISTART
              IPTR(24)    = I24
              NBITS       = IPTR(40) * 8
 1700         CONTINUE
C             PRINT *,N,IDENT(14),'KPRM-B=',KPRM,IPTR(24),NBITS
              IF (NBITS.GT.32) THEN
                  CALL GBYTE (MSGA,IDATA,IPTR(25),32)
                  IPTR(25)     = IPTR(25) + 32
                  NBITS        = NBITS - 32
C                               CONVERTS ASCII TO EBCIDIC
C                               COMMENT OUT IF NOT IBM370 COMPUTER
C                 PRINT *,IDATA
                  CALL W3AI39 (IDATA,4)
                  MSTACK(1,KPRM) = JDESC
                  MSTACK(2,KPRM) = 0
                  KDATA(N,KPRM) = IDATA
C                         SET FOR NEXT PART
                  KPRM          = KPRM + 1
                  IPTR(24)      = IPTR(24) + 1
C                 PRINT 1701,1,KDATA(N,KPRM),N,KPRM,NBITS,IDATA
 1701             FORMAT (1X,I1,1X,6HKDATA=,A4,2X,I5,2X,I5,2X,I5,2X,I12)
                  GO TO 1700
              ELSE IF (NBITS.GT.0) THEN
                  CALL GBYTE (MSGA,IDATA,IPTR(25),NBITS)
                  IPTR(25)     = IPTR(25) + NBITS
                  IBUF         = (32 - NBITS) / 8
                  IF (IBUF.GT.0) THEN
                      DO 1750 MP = 1, IBUF
                          IDATA  = IDATA * 256 + 32
 1750                 CONTINUE
                  END IF
C                               CONVERTS ASCII TO EBCIDIC
C                               COMMENT OUT IF NOT IBM370 COMPUTER
                  CALL W3AI39 (IDATA,4)
                  MSTACK(1,KPRM) = JDESC
                  MSTACK(2,KPRM) = 0
                  KDATA(N,KPRM) = IDATA
C                 PRINT 1701,2,KDATA(N,KPRM),N,KPRM,NBITS
                  NBITS          = 0
              END IF
C             WRITE (6,1800)N,(KDATA(N,I),I=KPRS,KPRM)
C1800         FORMAT (2X,I4,2X,3A4)
 1900     CONTINUE
      END IF
      RETURN
      END
C> @brief Process data that is not compressed.
C> @author Bill Cavanaugh @date 1988-09-01

C> Program history log:
C> - Bill Cavanaugh 1988-09-01
C> - Bill Cavanaugh 1991-01-18 Modified to properly handle non-compressed
C> data.
C> - Bill Cavanaugh 1991-04-04 Text handling portion of this routine
C> modified to handle field width in bytes.
C> - Bill Cavanaugh 1991-04-17 Tests showed that the same data in compressed
C> and uncompressed form gave different results. This has been corrected.
C>
C> @param[in] IPTR See w3fi67 routine docblock
C> @param[in] MSGA Array containing bufr message
C> @param[inout] IVALS Array of single parameter values
C> @param[out] KDATA Array containing decoded reports from bufr message.
C> kdata(report number,parameter number)
C> @param[inout] J [in] ? [out] arrays containing data from table b
C> @param[out] MSCALE Scale for value of descriptor
C> @param[in] MSTACK
C> @param LL
C> @param JDESC
C> @param[out] MREF Reference value for descriptor
C> @param[out] MWIDTH Bit width for value of descriptor
C>
C> @note Error return:
C> - IPTR(1) = 13 - Bit width on ASCII chars not a multiple of 8.
C>
C> @author Bill Cavanaugh @date 1988-09-01
      SUBROUTINE FI6704(IPTR,MSGA,KDATA,IVALS,MSTACK,
     *                      MWIDTH,MREF,MSCALE,J,LL,JDESC)

       SAVE
C
      INTEGER        MSGA(*)
      INTEGER        IPTR(*),MREF(700,3),MSCALE(*)
      INTEGER        MWIDTH(*),JDESC
      INTEGER        IVALS(*)
      INTEGER        LSTBLK(3)
      INTEGER        KDATA(500,*),MSTACK(2,*)
      INTEGER        J,LL
      LOGICAL        LKEY
C
C
      INTEGER        ITEST(30)
      DATA  ITEST  /1,3,7,15,31,63,127,255,
     *             511,1023,2047,4095,8191,16383,
     *             32767, 65535,131071,262143,524287,
     *             1048575,2097151,4194303,8388607,
     *             16777215,33554431,67108863,134217727,
     *             268435455,536870911,1073741823/
C
C     PRINT *,' FI6704 NOCMP',J,JDESC,MWIDTH(J),IPTR(26),IPTR(25)
      IF ((IPTR(26)+MWIDTH(J)).LT.1) THEN
          IPTR(1)  = 501
          RETURN
      END IF
C                  --------  NOCMP  --------
C                                ISOLATE BIT WIDTH
      JWIDE    = MWIDTH(J) + IPTR(26)
C                                       IF NOT TEXT EVENT, PROCESS
      IF (IPTR(18).NE.1) THEN
C                                    IF ASSOCIATED FIELD SW ON
          IF (IPTR(29).GT.0) THEN
              IF (JDESC.NE.7957.AND.JDESC.NE.7937) THEN
                  IPTR(31)        = IPTR(31) + 1
                  KPRM            = IPTR(31) + IPTR(24)
                  MSTACK(1,KPRM)  = 33792 + IPTR(29)
                  MSTACK(2,KPRM)  = 0
                  CALL GBYTE (MSGA,IVALS,IPTR(25),IPTR(29))
                  IPTR(25)        = IPTR(25) + IPTR(29)
                  KDATA(IPTR(17),KPRM) = IVALS(1)
C                 PRINT *,'FI6704-A',KPRM,MSTACK(1,KPRM),
C    *                      MSTACK(2,KPRM),IPTR(17),KDATA(IPTR(17),KPRM)
              END IF
          END IF
          IPTR(31) = IPTR(31) + 1
          KPRM     = IPTR(31) + IPTR(24)
          MSTACK(1,KPRM) = JDESC
          IF (IPTR(27).NE.0) THEN
              MSTACK(2,KPRM) = IPTR(27)
          ELSE
              MSTACK(2,KPRM) = MSCALE(J)
          END IF
C                                       GET VALUES
C                                CALL TO GET DATA OF GIVEN BIT WIDTH
          CALL GBYTE (MSGA,IVALS,IPTR(25),JWIDE)
C         PRINT *,'DATA  TO',IPTR(17),KPRM,IVALS(1),JWIDE,IPTR(25)
          IPTR(25) = IPTR(25) + JWIDE
C                                RETURN WITH SINGLE VALUE
          IF (IVALS(1).EQ.ITEST(JWIDE)) THEN
              KDATA(IPTR(17),KPRM) = 999999
          ELSE
              IF (MREF(J,2).EQ.0) THEN
                  KDATA(IPTR(17),KPRM) = IVALS(1) + MREF(J,1)
              ELSE
                  KDATA(IPTR(17),KPRM) = IVALS(1) + MREF(J,3)
              END IF
          END IF
C         PRINT *,'FI6704-B',KPRM,MSTACK(1,KPRM),
C    *                     MSTACK(2,KPRM),IPTR(17),KDATA(IPTR(17),KPRM)
C         IF(JDESC.EQ.2049) THEN
C             PRINT *,'VERT SIG =',KDATA(IPTR(17),KPRM)
C         END IF
C         PRINT *,'FI6704  ',KPRM,MSTACK(1,KPRM),
C    *                       MSTACK(2,KPRM),KDATA(IPTR(17),KPRM)
      ELSE
C                                       IF TEXT EVENT, PROCESS TEXT
C         PRINT *,' FOUND TEXT MODE ****** NOT COMPRESSED *********'
          NRCHRS     = IPTR(40)
          NRBITS     = NRCHRS * 8
C         PRINT *,'CHARS =',NRCHRS,' BITS =',NRBITS
          IPTR(31)        = IPTR(31) + 1
          KANY   = 0
 1800     CONTINUE
          KANY  = KANY + 1
          IF (NRBITS.GT.32) THEN
              CALL GBYTE (MSGA,IDATA,IPTR(25),32)
C             PRINT 1801,KANY,IDATA,IPTR(17),KPRM
C1801         FORMAT (1X,I2,4X,Z8,2(4X,I4))
C                               CONVERTS ASCII TO EBCIDIC
C                               COMMENT OUT IF NOT IBM370 COMPUTER
              CALL W3AI39 (IDATA,4)
              KPRM            = IPTR(31) + IPTR(24)
              KDATA(IPTR(17),KPRM)  = IDATA
              MSTACK(1,KPRM)  = JDESC
              MSTACK(2,KPRM)  = 0
C             PRINT *,KPRM,MSTACK(1,KPRM),MSTACK(2,KPRM),
C    *                   KDATA(IPTR(17),KPRM)
              IPTR(25)    = IPTR(25) + 32
              NRBITS      = NRBITS - 32
              IPTR(24)    = IPTR(24) + 1
              GO TO 1800
          ELSE IF (NRBITS.GT.0) THEN
C             PRINT *,'LAST TEXT WORD'
              CALL GBYTE (MSGA,IDATA,IPTR(25),NRBITS)
              IPTR(25)    = IPTR(25) + NRBITS
C                               CONVERTS ASCII TO EBCIDIC
C                               COMMENT OUT IF NOT IBM370 COMPUTER
              CALL W3AI39 (IDATA,4)
              KPRM            = IPTR(31) + IPTR(24)
              KSHFT           = 32 - NRBITS
              IF (KSHFT.GT.0) THEN
                  KTRY  = KSHFT / 8
                  DO  1722  LAK = 1, KTRY
                      IDATA  = IDATA * 256 + 64
C                     PRINT 1723,IDATA
 1723                 FORMAT (12X,Z8)
 1722             CONTINUE
              END IF
              KDATA(IPTR(17),KPRM) = IDATA
C             PRINT 1801,KANY,IDATA,KDATA(IPTR(17),KPRM),KPRM
              MSTACK(1,KPRM)  = JDESC
              MSTACK(2,KPRM)  = 0
C             PRINT *,KPRM,MSTACK(1,KPRM),MSTACK(2,KPRM),
C    *                   KDATA(IPTR(17),KPRM)
          END IF
C                        TURN OFF TEXT
          IPTR(18)   = 0
      END IF
      RETURN
      END
C> @brief Process a replication descriptor, must extract number
C> of replications of n descriptors from the data stream.
C> @author Bill Cavanaugh @date 1988-09-01

C> Process a replication descriptor, must extract number
C> of replications of n descriptors from the data stream.
C>
C> Program history log:
C> - Bill Cavanaugh 1988-09-01
C>
C> @param[in] IWORK Working descriptor list
C> @param[in] IPTR See w3fi67 routine docblock
C> @param[in] IDENT See w3fi67 routine docblock
C> @param[inout] LX X portion of current descriptor
C> @param[inout] LY Y portion of current descriptor
C> @param[out] KDATA Array containing decoded reports from bufr message.
C> kdata(report number,parameter number)
C> @param LL
C> @param KNR
C> @param MSTACK
C> @param MSGA
C>
C> @note Error return:
C> - IPTR(1)
C>  - = 12  Data descriptor qualifier does not follow
C> delayed replication descriptor.
C>  - = 20  Exceeded count for delayed replication pass.
C>
C> @author Bill Cavanaugh @date 1988-09-01
      SUBROUTINE FI6705(IPTR,IDENT,MSGA,IWORK,LX,LY,
     *                                          KDATA,LL,KNR,MSTACK)

      SAVE
C
      INTEGER        IPTR(*),KNR(*)
      INTEGER        ITEMP(1600),LL
      INTEGER        KTEMP(1600)
      INTEGER        KDATA(500,*)
      INTEGER        LX,MSTACK(2,*)
      INTEGER        LY
      INTEGER        MSGA(*),KVALS(500)
      INTEGER        IWORK(*)
      INTEGER        IDENT(*)
C
C     PRINT *,' REPLICATION FI6705'
C     DO 100 I = 1, IPTR(13)
C         PRINT *,I,IWORK(I)
C 100 CONTINUE
C                         NUMBER OF DESCRIPTORS
      NRSET   = LX
C                         NUMBER OF REPLICATIONS
      NRREPS  = LY
      ICURR   = IPTR(11) - 1
      IPICK   = IPTR(11) - 1
C
      IF (NRREPS.EQ.0) THEN
          IPTR(39)  = 1
C                         SAVE PRIMARY DELAYED REPLICATION DESCRIPTOR
C         IPTR(31)  = IPTR(31) + 1
C         KPRM      = IPTR(31) + IPTR(24)
C         MSTACK(1,KPRM)  = JDESC
C         MSTACK(2,KPRM)  = 0
C         KDATA(IPTR(17),KPRM) = 0
C         PRINT *,'FI6705-1',KPRM,MSTACK(1,KPRM),
C    *                       MSTACK(2,KPRM),KDATA(IPTR(17),KPRM)
C                          DELAYED REPLICATION - MUST GET NUMBER OF
C                              REPLICATIONS FROM DATA.
C                                GET NEXT DESCRIPTOR
          CALL FI6708(IPTR,IWORK,LF,LX,LY,JDESC)
C          PRINT *,' DELAYED REPLICATION',LF,LX,LY,JDESC
C                                MUST BE DATA DESCRIPTION
C                                   OPERATION QUALIFIER
          IF (JDESC.EQ.7937.OR.JDESC.EQ.7947) THEN
              JWIDE     = 8
          ELSE IF (JDESC.EQ.7938.OR.JDESC.EQ.7948) THEN
              JWIDE     = 16
          ELSE
              IPTR(1)   = 12
              RETURN
          END IF

C                             SET SINGLE VALUE FOR SEQUENTIAL,
C                                  MULTIPLE VALUES FOR COMPRESSED
          IF (IDENT(16).EQ.0) THEN
C                               NON COMPRESSED
              CALL GBYTE (MSGA,KVALS,IPTR(25),JWIDE)
C             PRINT *,LF,LX,LY,JDESC,' NR OF REPLICATIONS',KVALS(1)
              IPTR(25)   = IPTR(25) + JWIDE
              IPTR(31)  = IPTR(31) + 1
              KPRM       = IPTR(31) + IPTR(24)
              MSTACK(1,KPRM)  = JDESC
              MSTACK(2,KPRM)  = 0
              KDATA(IPTR(17),KPRM) = KVALS(1)
              NRREPS          = KVALS(1)
C         PRINT *,'FI6705-2',KPRM,MSTACK(1,KPRM),
C    *                       MSTACK(2,KPRM),KDATA(IPTR(17),KPRM)
          ELSE
              NRVALS     = IDENT(14)
              CALL GBYTES (MSGA,KVALS,IPTR(25),JWIDE,0,NRVALS)
              IPTR(25)   = IPTR(25) + JWIDE * NRVALS
              IPTR(31)  = IPTR(31) + 1
              KPRM       = IPTR(31) + IPTR(24)
              MSTACK(1,KPRM)  = JDESC
              MSTACK(2,KPRM)  = 0
              KDATA(IPTR(17),KPRM) = KVALS(1)
              DO 100 I = 1, NRVALS
                  KDATA(I,KPRM) = KVALS(I)
  100         CONTINUE
              NRREPS     = KVALS(1)
          END IF
      ELSE
C         PRINT *,'NOT DELAYED REPLICATION'
      END IF
C                             RESTRUCTURE WORKING STACK W/REPLICATIONS
C     PRINT *,' SAVE OFF',NRSET,' DESCRIPTORS'
C                                 PICK UP DESCRIPTORS TO BE REPLICATED
      DO 1000 I = 1, NRSET
          CALL FI6708(IPTR,IWORK,LF,LX,LY,JDESC)
          ITEMP(I)    = JDESC
C         PRINT *,'REPLICATION        ',I,ITEMP(I)
 1000 CONTINUE
C                              MOVE TRAILING DESCRIPTORS TO HOLD AREA
      LAX       = IPTR(12) - IPTR(11) + 1
C     PRINT *,LAX,' TRAILING DESCRIPTORS TO HOLD AREA',IPTR(11),IPTR(12)
      DO 2000 I = 1, LAX
          CALL FI6708(IPTR,IWORK,LF,LX,LY,JDESC)
          KTEMP(I)   = JDESC
C         PRINT *,'                             ',I,KTEMP(I)
 2000 CONTINUE
C                              REPLICATIONS INTO ISTACK
C     PRINT *,' MUST REPLICATE ',KX,' DESCRIPTORS',KY,' TIMES'
C     PRINT *,'REPLICATIONS INTO STACK. LOC',ICURR
      DO 4000 I = 1, NRREPS
          DO 3000 J = 1, NRSET
              IWORK(ICURR) = ITEMP(J)
C             PRINT *,'FI6705 A',ICURR,IWORK(ICURR)
              ICURR         = ICURR + 1
 3000     CONTINUE
 4000 CONTINUE
C     PRINT *,'                     TO  LOC',ICURR-1
C                              RESTORE TRAILING DESCRIPTORS
C     PRINT *,'TRAILING DESCRIPTORS INTO STACK. LOC',ICURR
      DO 5000 I = 1, LAX
          IWORK(ICURR) = KTEMP(I)
C         PRINT *,'FI6705 B',ICURR,IWORK(ICURR)
          ICURR        = ICURR + 1
 5000 CONTINUE
      IPTR(12)  = ICURR - 1
      IPTR(11)  = IPICK
      RETURN
      END

C> @brief Process operator descriptors.
C> @author Bill Cavanaugh @date 1988-09-01

C> Extract and save indicated change values for use
C> until changes are rescinded, or extract text strings indicated
C> through 2 05 yyy.
C>
C> Program history log:
C> - Bill Cavanaugh 1988-09-01
C> - Bill Cavanaugh 1991-04-04 Modified to handle descriptor 2 05 yyy
C> - Bill Cavanaugh 1991-05-10 Coding has been added to process proposed
C> table c descriptor 2 06 yyy.
C> - Bill Cavanaugh 1991-11-21 Coding has been added to properly process
C> table c descriptor 2 03 yyy, the change
C> to new reference value for selected
C> descriptors.
C>
C> @param[in] IPTR See w3fi67 routine docblock.
C> @param[in] LX X portion of current descriptor.
C> @param[in] LY Y portion of current descriptor.
C> @param[out] KDATA Array containing decoded reports from bufr message.
C> kdata(report number,parameter number)
C> arrays containing data from table b
C> @param[out] MSCALE Scale for value of descriptor
C> @param[out] MREF Reference value for descriptor
C> @param[out] MWIDTH Bit width for value of descriptor
C> @param IDENT
C> @param MSGA
C> @param IVALS
C> @param MSTACK
C> @param J
C> @param LL
C> @param KDESC
C> @param IWORK
C> @param JDESC
C>
C> @note Error return:
C> - IPTR(1) = 5 - Erroneous x value in data descriptor operator
C>
C> @author Bill Cavanaugh @date 1988-09-01
      SUBROUTINE FI6706 (IPTR,LX,LY,IDENT,MSGA,KDATA,IVALS,MSTACK,
     *                       MWIDTH,MREF,MSCALE,J,LL,KDESC,IWORK,JDESC)

      SAVE
      INTEGER        IPTR(*),KDATA(500,*),IVALS(*)
      INTEGER        IDENT(*),IWORK(*)
      INTEGER        MSGA(*),MSTACK(2,*)
      INTEGER        MREF(700,3),KDESC(*)
      INTEGER        MSCALE(*),MWIDTH(*)
      INTEGER        J,JDESC
      INTEGER        LL
      INTEGER        LX
      INTEGER        LY
C
C     PRINT *,' F2 - DATA DESCRIPTOR OPERATOR'
      IF (LX.EQ.1) THEN
C                                CHANGE BIT WIDTH
          IF (LY.EQ.0) THEN
C             PRINT *,' RETURN TO NORMAL WIDTH'
              IPTR(26) = 0
          ELSE
C             PRINT *,' EXPAND WIDTH BY',LY-128,' BITS'
              IPTR(26)  = LY - 128
          END IF
      ELSE IF (LX.EQ.2) THEN
C                                  CHANGE SCALE
          IF (LY.EQ.0) THEN
C                              RESET TO STANDARD SCALE
              IPTR(27) = 0
          ELSE
C                               SET NEW SCALE
              IPTR(27)  = LY - 128
          END IF
      ELSE IF (LX.EQ.3) THEN
C                      CHANGE REFERENCE VALUE
C                                 FOR EACH OF THOSE DESCRIPTORS BETWEEN
C                                 2 03 YYY WHERE Y LT 255 AND
C                                 2 03 255, EXTRACT THE NEW REFERENCE
C                                 VALUE (BIT WIDTH YYY) AND PLACE
C                                 IN TERTIARY TABLE B REF VAL POSITION,
C                                 SET FLAG IN SECONDARY REFVAL POSITION
C                                 THOSE DESCRIPTORS DO NOT HAVE DATA
C                                 ASSOCIATED WITH THEM, BUT ONLY
C                                 IDENTIFY THE TABLE B ENTRIES THAT
C                                 ARE GETTING NEW REFERENCE VALUES.
          KYYY     = LY
          IF (KYYY.GT.0.AND.KYYY.LT.255) THEN
C                               START CYCLING THRU DESCRIPTORS UNTIL
C                               TERMINATE NEW REF VALS IS FOUND
  300         CONTINUE
              CALL FI6708 (IPTR,IWORK,LF,LX,LY,JDESC)
              IF (JDESC.EQ.33791) THEN
C                    IF 2 03 255 THEN RETURN
                  RETURN
              ELSE
C                               FIND MATCHING TABLE B ENTRY
                  DO 500 LJ = 1, IPTR(14)
                      IF (JDESC.EQ.KDESC(LJ)) THEN
C                               TURN ON NEW REF VAL FLAG
                          MREF(LJ,2)  = 1
C                               INSERT NEW REF VAL
                          CALL GBYTE (MSGA,MREF(LJ,3),IPTR(25),KYYY)
C                               GO GET NEXT DESCRIPTOR
                          GO TO 300
                      END IF
  500             CONTINUE
C                         MATCHING DESCRIPTOR NOT FOUND, ERROR ERROR
                  PRINT *,'2 03 YYY - MATCHING DESCRIPTOR NOT FOUND'
                  STOP 203
              END IF
          ELSE IF (KYYY.EQ.0) THEN
C                                      MUST TURN OFF ALL NEW
C                                      REFERENCE VALUES
              DO 400 I = 1, IPTR(14)
                  MREF(I,2)  = 0
  400         CONTINUE
          END IF
C                                      LX = 3
C                                      MUST BE CONCLUDED WITH Y=255
      ELSE IF (LX.EQ.4) THEN
C                             ASSOCIATED VALUES
          IF (LY.EQ.0) THEN
              IPTR(29) = 0
C             PRINT *,'RESET ASSOCIATED VALUES',IPTR(29)
          ELSE
              IPTR(29)  = LY
              IF (IWORK(IPTR(11)).NE.7957) THEN
                  PRINT *,'2 04 YYY NOT FOLLOWED BY 0 31 021'
                  IPTR(1)   = 11
              END IF
C             PRINT *,'SET ASSOCIATED VALUES',IPTR(29)
          END IF
      ELSE IF (LX.EQ.5) THEN
C                        PROCESS TEXT DATA
          IPTR(40)  = LY
          IPTR(18)  = 1
          IF (IDENT(16).EQ.0) THEN
C             PRINT *,'2 05 YYY - TEXT - NONCOMPRESSED MODE'
              CALL FI6704(IPTR,MSGA,KDATA,IVALS,MSTACK,
     *                      MWIDTH,MREF,MSCALE,J,LL,JDESC)
          ELSE
C             PRINT *,'2 05 YYY - TEXT - COMPRESSED MODE'
              CALL FI6703(IPTR,IDENT,MSGA,KDATA,IVALS,MSTACK,
     *                      MWIDTH,MREF,MSCALE,J,JDESC)
              IF (IPTR(1).NE.0) THEN
                  RETURN
              END IF
          ENDIF
          IPTR(18)  = 0
      ELSE IF (LX.EQ.6) THEN
C                          SKIP NEXT DESCRIPTOR
C              SET TO PASS OVER DESCRIPTOR AND DATA
C                     IF DESCRIPTOR NOT IN TABLE B
          IPTR(36)   = LY
C         PRINT *,'SET TO SKIP',LY,' BIT FIELD'
          IPTR(31)       = IPTR(31) + 1
          KPRM           = IPTR(31) + IPTR(24)
          MSTACK(1,KPRM) = 34304 + LY
          MSTACK(2,KPRM) = 0
      ELSE
          IPTR(1)   = 5
      ENDIF
      RETURN
      END

C> @brief Substitute descriptor queue for queue descriptor
C> @author Bill Cavanaugh @date 1988-09-01

C> Substitute descriptor queue for queue descriptor
C>
C> Program history log:
C> - Bill Cavanaugh 1988-09-01
C> - Bill Cavanaugh 1991-04-17 Improved handling of nested queue descriptors.
C> - Bill Cavanaugh 1991-05-28 Improved handling of nested queue descriptors.
C> based on tests with live data.
C>
C> @param[in] IWORK Working descriptor list.
C> @param[in] IPTR See w3fi67 routine docblock.
C> @param[in] ITBLD Array containing descriptor queues.
C> @param[in] JDESC Queue descriptor to be expanded.
C>
C> @author Bill Cavanaugh @date 1988-09-01
      SUBROUTINE FI6707(IPTR,IWORK,ITBLD,JDESC)

      SAVE
C
      INTEGER        IPTR(*),JDESC
      INTEGER        IWORK(*),IHOLD(1600)
      INTEGER        ITBLD(500,11)
C
C     PRINT *,' FI6707  F3 ENTRY',IPTR(11),IPTR(12)
C                                   SET FOR BINARY SEARCH IN TABLE D
C     DO 2020 I = 1, IPTR(12)
C         PRINT *,'ENTRY IWORK',I,IWORK(I)
C2020 CONTINUE
      JLO  = 1
      JHI  = IPTR(20)
C     PRINT *,'LOOKING FOR QUEUE DESCRIPTOR',JDESC
   10 CONTINUE
      JMID  = (JLO + JHI) / 2
C     PRINT *,JLO,ITBLD(JLO,1),JMID,ITBLD(JMID,1),JHI,ITBLD(JHI,1)
C
      IF (JDESC.LT.ITBLD(JMID,1)) THEN
          IF (JDESC.EQ.ITBLD(JLO,1)) THEN
              JMID  = JLO
              GO TO 100
          ELSE
              JLO  = JLO + 1
              JHI  = JMID - 1
              IF (JLO.GT.JMID) THEN
                  IPTR(1)  = 4
                  RETURN
              END IF
              GO TO 10
          END IF
      ELSE IF (JDESC.GT.ITBLD(JMID,1)) THEN
          IF (JDESC.EQ.ITBLD(JHI,1)) THEN
              JMID  = JHI
              GO TO 100
          ELSE
              JLO  = JMID + 1
              JHI  = JHI - 1
              IF (JLO.GT.JHI) THEN
                  IPTR(1) = 4
                  RETURN
              END IF
              GO TO 10
          END IF
      END IF
  100 CONTINUE
C                              HAVE TABLE D MATCH
C     PRINT *,'D ',(ITBLD(JMID,LL),LL=1,11)
C     PRINT *,'TABLE D TO IHOLD'
      IK       = 0
      JK       = 0
      DO 200 KI = 2, 11
          IF (ITBLD(JMID,KI).NE.0) THEN
              IK        = IK + 1
              IHOLD(IK) = ITBLD(JMID,KI)
C             PRINT *,IK,IHOLD(IK)
          ELSE
              GO TO 300
          END IF
  200 CONTINUE
  300 CONTINUE
      KK       = IPTR(11)
      IF (KK.GT.IPTR(12)) THEN
C                          NOTHING MORE TO APPEND
C         PRINT *,'NOTHING MORE TO APPEND'
      ELSE
C                          APPEND TRAILING IWORK TO IHOLD
C         PRINT *,'APPEND FROM ',KK,' TO',IPTR(12)
          DO 500 I = KK, IPTR(12)
              IK  = IK + 1
              IHOLD(IK) = IWORK(I)
  500     CONTINUE
      END IF
C                                RESET IHOLD TO IWORK
C     PRINT *,' RESET IWORK STACK'
      KK       = IPTR(11) - 2
      DO 1000 I = 1, IK
          KK        = KK + 1
          IWORK(KK) = IHOLD(I)
 1000 CONTINUE
      IPTR(12)   = KK
C     PRINT *,' FI6707  F3 EXIT ',IPTR(11),IPTR(12)
C     DO 2000 I = 1, IPTR(12)
C         PRINT *,'EXIT  IWORK',I,IWORK(I)
C2000 CONTINUE
C                                RESET POINTERS
      IPTR(11)   = IPTR(11) - 1
      RETURN
      END
C> @brief Subroutine FI6708
C> @author Bill Cavanaugh @date 1989-01-17

C> Program history log:
C> - Bill Cavanaugh 1988-09-01
C>
C> @param[inout] IPTR See w3fi67() routine docblock.
C> @param[in] IWORK Working descriptor list.
C> @param LF
C> @param LX
C> @param LY
C> @param[in] JDESC Queue descriptor to be expanded.
C>
C> @note List caveats, other helpful hints or information.
C>
C> @author Bill Cavanaugh @date 1989-01-17
      SUBROUTINE FI6708(IPTR,IWORK,LF,LX,LY,JDESC)

      SAVE
      INTEGER       IPTR(*),IWORK(*),LF,LX,LY,JDESC
C
C     PRINT *,' FI6708 NEW DESCRIPTOR PICKUP'
      JDESC    = IWORK(IPTR(11))
      LY       = MOD(JDESC,256)
      IPTR(34) = LY
      LX       = MOD((JDESC/256),64)
      IPTR(33) = LX
      LF       = JDESC / 16384
      IPTR(32) = LF
C     PRINT *,' CURRENT DESCRIPTOR BEING TESTED IS',LF,LX,LY
      IPTR(11) = IPTR(11) + 1
      RETURN
      END
C> @brief Reformat decoded profiler data to show heights instead of
C> height increments.
C> @author Bill Cavanaugh @date 1990-02-14

C> Reformat decoded profiler data to show heights instead of
C> height increments.
C>
C> Program history log:
C> - Bill Cavanaugh 1990-02-14
C>
C> @param[in] IDENT Array contains message information extracted from
C> BUFR message:
C> - IDENT( 1)-EDITION NUMBER     (BYTE 4, SECTION 1)
C> - IDENT( 2)-ORIGINATING CENTER (BYTES 5-6, SECTION 1)
C> - IDENT( 3)-UPDATE SEQUENCE    (BYTE 7, SECTION 1)
C> - IDENT( 4)-                   (BYTE 8, SECTION 1)
C> - IDENT( 5)-BUFR MESSAGE TYPE  (BYTE 9, SECTION 1)
C> - IDENT( 6)-BUFR MSG SUB-TYPE  (BYTE 10, SECTION 1)
C> - IDENT( 7)-                   (BYTES 11-12, SECTION 1)
C> - IDENT( 8)-YEAR OF CENTURY    (BYTE 13, SECTION 1)
C> - IDENT( 9)-MONTH OF YEAR      (BYTE 14, SECTION 1)
C> - IDENT(10)-DAY OF MONTH       (BYTE 15, SECTION 1)
C> - IDENT(11)-HOUR OF DAY        (BYTE 16, SECTION 1)
C> - IDENT(12)-MINUTE OF HOUR     (BYTE 17, SECTION 1)
C> - IDENT(13)-RSVD BY ADP CENTERS(BYTE 18, SECTION 1)
C> - IDENT(14)-NR OF DATA SUBSETS (BYTE 5-6, SECTION 3)
C> - IDENT(15)-OBSERVED FLAG      (BYTE 7, BIT 1, SECTION 3)
C> - IDENT(16)-COMPRESSION FLAG   (BYTE 7, BIT 2, SECTION 3)
C> @param[in] MSTACK Working descriptor list and scaling factor
C> @param[in] KDATA Array containing decoded reports
C> @param[in] IPTR See w3fi67
C>
C> @note List caveats, other helpful hints or information.
C>
C> @author Bill Cavanaugh @date 1990-02-14
      SUBROUTINE FI6709(IDENT,MSTACK,KDATA,IPTR)

      SAVE
C  ----------------------------------------------------------------
C
      INTEGER        ISW
      INTEGER        IDENT(*),KDATA(500,*)
      INTEGER        MSTACK(2,*),IPTR(*)
      INTEGER        KPROFL(500)
      INTEGER        KPROF2(500)
      INTEGER        KSET2(500)
C
C  ----------------------------------------------------------
C                                LOOP FOR NUMBER OF SUBSETS/REPORTS
      DO 3000 I = 1, IDENT(14)
C                                INIT FOR DATA INPUT ARRAY
          MK         = 1
C                                INIT FOR DESC OUTPUT ARRAY
          JK         = 0
C                                LOCATION
          ISW        = 0
          DO 200 J = 1, 3
C                                    LATITUDE
              IF (MSTACK(1,MK).EQ.1282) THEN
                  ISW   = ISW + 1
                  GO TO 100
C                                    LONGITUDE
              ELSE IF (MSTACK(1,MK).EQ.1538) THEN
                  ISW   = ISW + 2
                  GO TO 100
C                                    HEIGHT ABOVE SEA LEVEL
              ELSE IF (MSTACK(1,MK).EQ.1793) THEN
                  IHGT  = KDATA(I,MK)
                  ISW   = ISW + 4
                  GO TO 100
              END IF
              GO TO 200
  100         CONTINUE
              JK             = JK + 1
C                                     SAVE DESCRIPTOR
              KPROFL(JK)     = MSTACK(1,MK)
C                                     SAVE SCALE
              KPROF2(JK)     = MSTACK(2,MK)
C                                      SAVE DATA
              KSET2(JK)  = KDATA(I,MK)
              MK         = MK + 1
  200     CONTINUE
          IF (ISW.NE.7) THEN
              PRINT *,'LOCATION ERROR PROCESSING PROFILER'
              IPTR(1)    = 200
              RETURN
          END IF
C  TIME
          ISW        = 0
          DO 400 J = 1, 7
C                                    YEAR
              IF (MSTACK(1,MK).EQ.1025) THEN
                  ISW   = ISW + 1
                  GO TO 300
C                                    MONTH
              ELSE IF (MSTACK(1,MK).EQ.1026) THEN
                  ISW   = ISW + 2
                  GO TO 300
C                                    DAY
              ELSE IF (MSTACK(1,MK).EQ.1027) THEN
                  ISW   = ISW + 4
                  GO TO 300
C                                    HOUR
              ELSE IF (MSTACK(1,MK).EQ.1028) THEN
                  ISW   = ISW + 8
                  GO TO 300
C                                    MINUTE
              ELSE IF (MSTACK(1,MK).EQ.1029) THEN
                  ISW   = ISW + 16
                  GO TO 300
C                                    TIME SIGNIFICANCE
              ELSE IF (MSTACK(1,MK).EQ.2069) THEN
                  ISW   = ISW + 32
                  GO TO 300
              ELSE IF (MSTACK(1,MK).EQ.1049) THEN
                  ISW   = ISW + 64
                  GO TO 300
              END IF
              GO TO 400
  300         CONTINUE
              JK         = JK + 1
C                             SAVE DESCRIPTOR
              KPROFL(JK) = MSTACK(1,MK)
C                                     SAVE SCALE
              KPROF2(JK)     = MSTACK(2,MK)
C                             SAVE DATA
              KSET2(JK)  = KDATA(I,MK)
              MK         = MK + 1
  400     CONTINUE
          IF (ISW.NE.127) THEN
              PRINT *,'TIME ERROR PROCESSING PROFILER',ISW
              IPTR(1)    = 201
              RETURN
          END IF
C  SURFACE DATA
          KRG        = 0
          ISW        = 0
          DO 600 J = 1, 10
C                                    WIND SPEED
              IF (MSTACK(1,MK).EQ.2818) THEN
                  ISW   = ISW + 1
                  GO TO 500
C                                    WIND DIRECTION
              ELSE IF (MSTACK(1,MK).EQ.2817) THEN
                  ISW   = ISW + 2
                  GO TO 500
C                                    PRESS REDUCED TO MSL
              ELSE IF (MSTACK(1,MK).EQ.2611) THEN
                  ISW   = ISW + 4
                  GO TO 500
C                                    TEMPERATURE
              ELSE IF (MSTACK(1,MK).EQ.3073) THEN
                  ISW   = ISW + 8
                  GO TO 500
C                                    RAINFALL RATE
              ELSE IF (MSTACK(1,MK).EQ.3342) THEN
                  ISW   = ISW + 16
                  GO TO 500
C                                    RELATIVE HUMIDITY
              ELSE IF (MSTACK(1,MK).EQ.3331) THEN
                  ISW   = ISW + 32
                  GO TO 500
C                                    1ST RANGE GATE OFFSET
              ELSE IF (MSTACK(1,MK).EQ.1982.OR.
     *                    MSTACK(1,MK).EQ.1983) THEN
C       CANNOT USE NORMAL PROCESSING FOR FIRST RANGE GATE, MUST SAVE
C        VALUE FOR LATER USE
                  IF (MSTACK(1,MK).EQ.1983) THEN
                      IHGT   = KDATA(I,MK)
                      MK     = MK + 1
                      KRG   = 1
                  ELSE
                      IF (KRG.EQ.0) THEN
                          INCRHT             = KDATA(I,MK)
                          MK    = MK + 1
                          KRG   = 1
C                         PRINT *,'INITIAL INCR =',INCRHT
                      ELSE
                          LHGT  = 500 + IHGT - KDATA(I,MK)
                          ISW   = ISW + 64
C                         PRINT *,'BASE HEIGHT=',LHGT,' INCR=',INCRHT
                      END IF
                  END IF
C                                    MODE #1
              ELSE IF (MSTACK(1,MK).EQ.8128) THEN
                  ISW   = ISW + 128
                  GO TO 500
C                                    MODE #2
              ELSE IF (MSTACK(1,MK).EQ.8129) THEN
                  ISW   = ISW + 256
                  GO TO 500
              END IF
              GO TO 600
  500         CONTINUE
C                              SAVE DESCRIPTOR
              JK             = JK + 1
              KPROFL(JK)     = MSTACK(1,MK)
C                                     SAVE SCALE
              KPROF2(JK)     = MSTACK(2,MK)
C                              SAVE DATA
              KSET2(JK)      = KDATA(I,MK)
C             IF (I.EQ.1) THEN
C                 PRINT *,'   ',JK,KPROFL(JK),KSET2(JK)
C             END IF
              MK             = MK + 1
  600     CONTINUE
  650     CONTINUE
          IF (ISW.NE.511) THEN
              PRINT *,'SURFACE ERROR PROCESSING PROFILER',ISW
              IPTR(1)    = 202
              RETURN
          END IF
C  43 LEVELS
          DO 2000 L = 1, 43
 2020         CONTINUE
              ISW        = 0
C                                    HEIGHT INCREMENT
              IF (MSTACK(1,MK).EQ.1982) THEN
C                 PRINT *,'NEW HEIGHT INCREMENT',KDATA(I,MK)
                  INCRHT  = KDATA(I,MK)
                  MK      = MK + 1
                  IF (LHGT.LT.(9250+IHGT)) THEN
                      LHGT    = IHGT + 500 - INCRHT
                  ELSE
                      LHGT    = IHGT + 9250 - INCRHT
                  END IF
              END IF
C    MUST ENTER HEIGHT OF THIS LEVEL - DESCRIPTOR AND DATA
C          AT THIS POINT     - HEIGHT + INCREMENT + BASE VALUE
              LHGT       = LHGT + INCRHT
C             PRINT *,'LEVEL ',L,LHGT
              IF (L.EQ.37) THEN
                  LHGT       = LHGT + INCRHT
              END IF
              JK          = JK + 1
C                              SAVE DESCRIPTOR
              KPROFL(JK)  = 1798
C                                     SAVE SCALE
              KPROF2(JK)     = 0
C                              SAVE DATA
              KSET2(JK)  = LHGT
C             IF (I.EQ.10) THEN
C                 PRINT *,' '
C                 PRINT *,'HGT',JK,KPROFL(JK),KSET2(JK)
C             END IF
              ISW   = 0
              DO 800 J = 1, 9
  750             CONTINUE
                  IF (MSTACK(1,MK).EQ.1982) THEN
                      GO TO 2020
C                                    U VECTOR VALUE
                  ELSE IF (MSTACK(1,MK).EQ.3008) THEN
                      ISW   = ISW + 1
                      IF (KDATA(I,MK).GE.2047) THEN
                          VECTU              = 32767
                      ELSE
                          VECTU              = KDATA(I,MK)
                      END IF
                      MK    = MK + 1
                      GO TO 800
C                                    V VECTOR VALUE
                  ELSE IF (MSTACK(1,MK).EQ.3009) THEN
                      ISW   = ISW + 2
                      IF (KDATA(I,MK).GE.2047) THEN
                          VECTV              = 32767
                      ELSE
                          VECTV              = KDATA(I,MK)
                      END IF
                      MK    = MK + 1
C IF U VALUE IS ALSO AVAILABLE THEN GENERATE DDFFF
C     DESCRIPTORS AND DATA
                      IF (IAND(ISW,1).NE.0) THEN
                          IF (VECTU.EQ.32767.OR.VECTV.EQ.32767) THEN
C                                               SAVE DD DESCRIPTOR
                              JK             = JK + 1
                              KPROFL(JK)     = 2817
C                                     SAVE SCALE
                              KPROF2(JK)     = 0
C                                               SAVE DD DATA
                              KSET2(JK)      = 32767
C                                               SAVE FFF DESCRIPTOR
                              JK             = JK + 1
                              KPROFL(JK)     = 2818
C                                     SAVE SCALE
                              KPROF2(JK)     = 1
C                                               SAVE FFF DATA
                              KSET2(JK)      = 32767
                          ELSE
C                                               GENERATE DDFFF
                              CALL W3FC05 (VECTU,VECTV,DIR,SPD)
                              NDIR         = DIR
                              SPD          = SPD
                              NSPD         = SPD
C                             PRINT *,'                ',NDIR,NSPD
C                                               SAVE DD DESCRIPTOR
                              JK             = JK + 1
                              KPROFL(JK)     = 2817
C                                     SAVE SCALE
                              KPROF2(JK)     = 0
C                                               SAVE DD DATA
                              KSET2(JK)          = DIR
C                             IF (I.EQ.1) THEN
C                                 PRINT *,'DD ',JK,KPROFL(JK),KSET2(JK)
C                             END IF
C                                               SAVE FFF DESCRIPTOR
                              JK             = JK + 1
                              KPROFL(JK)     = 2818
C                                     SAVE SCALE
                              KPROF2(JK)     = 1
C                                               SAVE FFF DATA
                              KSET2(JK)          = SPD
C                             IF (I.EQ.1) THEN
C                                 PRINT *,'FFF',JK,KPROFL(JK),KSET2(JK)
C                             END IF
                          END IF
                      END IF
                      GO TO 800
C                                    W VECTOR VALUE
                  ELSE IF (MSTACK(1,MK).EQ.3010) THEN
                      ISW   = ISW + 4
                      GO TO 700
C                                    Q/C TEST RESULTS
                  ELSE IF (MSTACK(1,MK).EQ.8130) THEN
                      ISW   = ISW + 8
                      GO TO 700
C                                    U,V QUALITY IND
                ELSE IF(IAND(ISW,16).EQ.0.AND.MSTACK(1,MK).EQ.2070) THEN
                      ISW   = ISW + 16
                      GO TO 700
C                                    W QUALITY IND
                ELSE IF(IAND(ISW,32).EQ.0.AND.MSTACK(1,MK).EQ.2070) THEN
                      ISW   = ISW + 32
                      GO TO 700
C                                    SPECTRAL PEAK POWER
                  ELSE IF (MSTACK(1,MK).EQ.5568) THEN
                      ISW   = ISW + 64
                      GO TO 700
C                                    U,V VARIABILITY
                  ELSE IF (MSTACK(1,MK).EQ.3011) THEN
                      ISW   = ISW + 128
                      GO TO 700
C                                    W VARIABILITY
                  ELSE IF (MSTACK(1,MK).EQ.3013) THEN
                      ISW   = ISW + 256
                      GO TO 700
                  ELSE IF ((MSTACK(1,MK)/16384).NE.0) THEN
                      MK     = MK + 1
                      GO TO 750
                  END IF
                  GO TO 800
  700             CONTINUE
                  JK         = JK + 1
C                                      SAVE DESCRIPTOR
                  KPROFL(JK) = MSTACK(1,MK)
C                                     SAVE SCALE
                  KPROF2(JK)     = MSTACK(2,MK)
C                                      SAVE DATA
                  KSET2(JK)          = KDATA(I,MK)
                  MK         = MK + 1
C                 IF (I.EQ.1) THEN
C                     PRINT *,'   ',JK,KPROFL(JK),KSET2(JK)
C                 END IF
  800         CONTINUE
  850             CONTINUE
              IF (ISW.NE.511) THEN
                  PRINT *,'LEVEL ERROR PROCESSING PROFILER',ISW
                  IPTR(1)    = 203
                  RETURN
              END IF
 2000     CONTINUE
C                        MOVE DATA BACK INTO KDATA ARRAY
          DO 4000 LL = 1, JK
              KDATA(I,LL) = KSET2(LL)
 4000     CONTINUE
 3000 CONTINUE
C     PRINT *,'REBUILT ARRAY'
      DO 5000 LL = 1, JK
C                           DESCRIPTOR
          MSTACK(1,LL)  = KPROFL(LL)
C                           SCALE
          MSTACK(2,LL)  = KPROF2(LL)
C         PRINT *,LL,MSTACK(1,LL),(KDATA(I,LL),I=1,7)
 5000 CONTINUE
C                        MOVE REFORMATTED DESCRIPTORS TO MSTACK ARRAY
      IPTR(31) = JK
      RETURN
      END
C> @brief Reformat profiler edition 2 data
C> @author Bill Cavanaugh @date 1993-01-27

C> Reformat profiler data in edition 2
C>
C> Program history log:
C> - Bill Cavanaugh 1993-01-27
C>
C> @param[in] IDENT Array contains message information extracted from
C> BUFR message:
C> - IDENT( 1)-Edition number     (byte 4, section 1)
C> - IDENT( 2)-Originating center (bytes 5-6, section 1)
C> - IDENT( 3)-Update sequence    (byte 7, section 1)
C> - IDENT( 4)-                   (byte 8, section 1)
C> - IDENT( 5)-BUFR message type  (byte 9, section 1)
C> - IDENT( 6)-BUFR msg sub-type  (byte 10, section 1)
C> - IDENT( 7)-                   (bytes 11-12, section 1)
C> - IDENT( 8)-Year of century    (byte 13, section 1)
C> - IDENT( 9)-Month of year      (byte 14, section 1)
C> - IDENT(10)-Day of month       (byte 15, section 1)
C> - IDENT(11)-Hour of day        (byte 16, section 1)
C> - IDENT(12)-Minute of hour     (byte 17, section 1)
C> - IDENT(13)-Rsvd by adp centers(byte 18, section 1)
C> - IDENT(14)-Nr of data subsets (byte 5-6, section 3)
C> - IDENT(15)-Observed flag      (byte 7, bit 1, section 3)
C> - IDENT(16)-Compression flag   (byte 7, bit 2, section 3)
C> @param[in] MSTACK Working descriptor list and scaling factor
C> @param[in] KDATA Array containing decoded reports from bufr message.
C> kdata(report number,parameter number)
C> (report number limited to value of input argument
C> maxr and parameter number limited to value of input
C> argument maxd)
C> @param[in] IPTR See w3fi67
C>
C> @author Bill Cavanaugh @date 1993-01-27
      SUBROUTINE FI6710(IDENT,MSTACK,KDATA,IPTR)

      INTEGER        ISW
      INTEGER        IDENT(*),KDATA(500,1600)
      INTEGER        MSTACK(2,1600),IPTR(*)
      INTEGER        KPROFL(1600)
      INTEGER        KPROF2(1600)
      INTEGER        KSET2(1600)
C                             LOOP FOR NUMBER OF SUBSETS
      DO 3000 I = 1, IDENT(14)
          MK  = 1
          JK  = 0
          ISW  = 0
          DO 200 J = 1, 5
              IF (MSTACK(1,MK).EQ.257) THEN
C                            BLOCK NUMBER
                  ISW  = ISW + 1
              ELSE IF (MSTACK(1,MK).EQ.258) THEN
C                           STATION NUMBER
                  ISW  = ISW + 2
              ELSE IF (MSTACK(1,MK).EQ.1282) THEN
C                           LATITUDE
                  ISW  = ISW + 4
              ELSE IF (MSTACK(1,MK).EQ.1538) THEN
C                           LONGITUDE
                  ISW  = ISW + 8
              ELSE IF (MSTACK(1,MK).EQ.1793) THEN
C                           HEIGHT OF STATION
                  ISW  = ISW + 16
                  IHGT  = KDATA(I,MK)
              ELSE
                  MK  = MK + 1
                  GO TO 200
              END IF
              JK  = JK + 1
              KPROFL(JK)  = MSTACK(1,MK)
              KPROF2(JK)  = MSTACK(2,MK)
              KSET2(JK)   = KDATA(I,MK)
C             PRINT *,JK,KPROFL(JK),KSET2(JK)
              MK  = MK + 1
  200     CONTINUE
C         PRINT *,'LOCATION ',ISW
          IF (ISW.NE.31) THEN
              PRINT *,'LOCATION ERROR PROCESSING PROFILER'
              IPTR(10)  = 200
              RETURN
          END IF
C                      PROCESS TIME ELEMENTS
          ISW  = 0
          DO 400 J  = 1, 7
              IF (MSTACK(1,MK).EQ.1025) THEN
C                           YEAR
                  ISW  = ISW + 1
              ELSE IF (MSTACK(1,MK).EQ.1026) THEN
C                           MONTH
                  ISW  = ISW + 2
              ELSE IF (MSTACK(1,MK).EQ.1027) THEN
C                           DAY
                  ISW  = ISW + 4
              ELSE IF (MSTACK(1,MK).EQ.1028) THEN
C                           HOUR
                  ISW  = ISW + 8
              ELSE IF (MSTACK(1,MK).EQ.1029) THEN
C                           MINUTE
                  ISW  = ISW + 16
              ELSE IF (MSTACK(1,MK).EQ.2069) THEN
C                           TIME SIGNIFICANCE
                  ISW  = ISW + 32
              ELSE IF (MSTACK(1,MK).EQ.1049) THEN
C                           TIME DISPLACEMENT
                  ISW  = ISW + 64
              ELSE
                  MK  = MK + 1
                  GO TO 400
              END IF
              JK  = JK + 1
              KPROFL(JK)  = MSTACK(1,MK)
              KPROF2(JK)  = MSTACK(2,MK)
              KSET2(JK)   = KDATA(I,MK)
C             PRINT *,JK,KPROFL(JK),KSET2(JK)
              MK  = MK + 1
  400     CONTINUE
C         PRINT *,'TIME ',ISW
          IF (ISW.NE.127) THEN
              PRINT *,'TIME ERROR PROCESSING PROFILER'
              IPTR(1)  = 201
              RETURN
          END IF
C                  SURFACE DATA
          ISW  = 0
C         PRINT *,'SURFACE'
          DO 600 K  = 1, 8
              IF (MSTACK(1,MK).EQ.2817) THEN
                  ISW  = ISW + 1
              ELSE IF (MSTACK(1,MK).EQ.2818) THEN
                  ISW  = ISW + 2
              ELSE IF (MSTACK(1,MK).EQ.2611) THEN
                  ISW  = ISW + 4
              ELSE IF (MSTACK(1,MK).EQ.3073) THEN
                  ISW  = ISW + 8
              ELSE IF (MSTACK(1,MK).EQ.3342) THEN
                  ISW  = ISW + 16
              ELSE IF (MSTACK(1,MK).EQ.3331) THEN
                  ISW  = ISW + 32
              ELSE IF (MSTACK(1,MK).EQ.1797) THEN
                  INCRHT  = KDATA(I,MK)
                  ISW  = ISW + 64
C                 PRINT *,'INITIAL INCREMENT = ',INCRHT
                  MK  = MK + 1
                  GO TO 600
              ELSE IF (MSTACK(1,MK).EQ.6433) THEN
                  ISW  = ISW + 128
              ELSE
                  MK  = MK + 1
                  GO TO 600
              END IF
              JK  = JK + 1
              KPROFL(JK)  = MSTACK(1,MK)
              KPROF2(JK)  = MSTACK(2,MK)
              KSET2(JK)   = KDATA(I,MK)
C             PRINT *,JK,KPROFL(JK),KSET2(JK)
              MK  = MK + 1
  600     CONTINUE
          IF (ISW.NE.255) THEN
              PRINT *,'ERROR PROCESSING PROFILER'
              IPTR(1)  = 204
              RETURN
          END IF
          IF (MSTACK(1,MK).NE.1797) THEN
              PRINT *,'ERROR PROCESSING HEIGHT INCREMENT IN PROFILER'
              IPTR(1)  = 205
              RETURN
          END IF
C                   MUST SAVE THIS HEIGHT VALUE
          LHGT  = 500 + IHGT - KDATA(I,MK)
C         PRINT *,'BASE HEIGHT = ',LHGT,' INCR = ',INCRHT
          MK  = MK + 1
C              PROCESS LEVEL DATA
          DO 2000 L = 1, 43
 2020         CONTINUE
              ISW  = 0
C                       HEIGHT INCREMENT
              IF (MSTACK(1,MK).EQ.1797) THEN
                  INCRHT  = KDATA(I,MK)
C                 PRINT *,'NEW HEIGHT INCREMENT = ',INCRHT
                  MK  = MK + 1
                  IF (LHGT.LT.(9250+IHGT)) THEN
                      LHGT  = LHGT + 500 - INCRHT
                  ELSE
                      LHGT  = LHGT + 9250 -INCRHT
                  END IF
              END IF
C                    MUST ENTER HEIGHT OF THIS LEVEL - DESCRIPTOR AND DA
C                     AT THIS POINT
              LHGT  = LHGT + INCRHT
C             PRINT *,'LEVEL ',L,LHGT
              IF (L.EQ.37) THEN
                  LHGT  = LHGT + INCRHT
              END IF
              JK  = JK + 1
C                        SAVE DESCRIPTOR
              KPROFL(JK)  = 1798
C                       SAVE SCALE
              KPROF2(JK)  = 0
C                        SAVE DATA
              KSET2(JK)   = LHGT
C             PRINT *,JK,KPROFL(JK),KSET2(JK)
              ISW  = 0
              ICON  = 1
              DO 800 J = 1, 10
750               CONTINUE
                  IF (MSTACK(1,MK).EQ.1797) THEN
                        GO TO 2020
                  ELSE IF (MSTACK(1,MK).EQ.6432) THEN
C                               HI/LO MODE
                      ISW  = ISW + 1
                  ELSE IF (MSTACK(1,MK).EQ.6434) THEN
C                               Q/C TEST
                      ISW  = ISW + 2
                  ELSE IF (MSTACK(1,MK).EQ.2070) THEN
                      IF (ICON.EQ.1) THEN
C                               FIRST PASS - U,V CONSENSUS
                           ISW  = ISW + 4
                           ICON  = ICON + 1
                      ELSE
C                               SECOND PASS - W CONSENSUS
                           ISW  = ISW + 64
                      END IF
                  ELSE IF (MSTACK(1,MK).EQ.2819) THEN
C                               U VECTOR VALUE
                      ISW  = ISW + 8
                      IF (KDATA(I,MK).GE.2047) THEN
                          VECTU  = 32767
                      ELSE
                          VECTU  = KDATA(I,MK)
                      END IF
                      MK  = MK + 1
                      GO TO 800
                  ELSE IF (MSTACK(1,MK).EQ.2820) THEN
C                               V VECTOR VALUE
                      ISW  = ISW + 16
                      IF (KDATA(I,MK).GE.2047) THEN
                          VECTV  = 32767
                      ELSE
                          VECTV  = KDATA(I,MK)
                      END IF
                      IF (IAND(ISW,1).NE.0) THEN
                          IF (VECTU.EQ.32767.OR.VECTV.EQ.32767) THEN
C                               SAVE DD DESCRIPTOR
                              JK  = JK + 1
                              KPROFL(JK)  = 2817
                              KPROF2(JK)  = 0
                              KSET2(JK)   = 32767
C                               SAVE FFF DESCRIPTOR
                              JK  = JK + 1
                              KPROFL(JK)  = 2818
                              KPROF2(JK)  = 1
                              KSET2(JK)   = 32767
                          ELSE
                              CALL W3FC05 (VECTU,VECTV,DIR,SPD)
                              NDIR  = DIR
                              SPD   = SPD
                              NSPD  = SPD
C                             PRINT *,'     ',NDIR,NSPD
C                               SAVE DD DESCRIPTOR
                              JK  = JK + 1
                              KPROFL(JK)  = 2817
                              KPROF2(JK)  = 0
                              KSET2(JK)   = NDIR
C                             IF (I.EQ.1) THEN
C                                 PRINT *,'DD ',JK,KPROFL(JK),KSET2(JK)
C                             ENDIF
C                            SAVE FFF DESCRIPTOR
                              JK  = JK + 1
                              KPROFL(JK)  = 2818
                              KPROF2(JK)  = 1
                              KSET2(JK)   = NSPD
C                             IF (I.EQ.1) THEN
C                                 PRINT *,'FFF',JK,KPROFL(JK),KSET2(JK)
C                             ENDIF
                          END IF
                          MK  = MK + 1
                          GO TO 800
                      END IF
                  ELSE IF (MSTACK(1,MK).EQ.2866) THEN
C                               SPEED STD DEVIATION
                      ISW  = ISW + 32
C -- A CHANGE BY KEYSER : POWER DESC. BACK TO 5568
                  ELSE IF (MSTACK(1,MK).EQ.5568) THEN
C                               SIGNAL POWER
                      ISW  = ISW + 128
                  ELSE IF (MSTACK(1,MK).EQ.2822) THEN
C                               W COMPONENT
                      ISW  = ISW + 256
                  ELSE IF (MSTACK(1,MK).EQ.2867) THEN
C                              VERT STD DEVIATION
                      ISW  = ISW + 512
                  ELSE
                      MK  = MK + 1
                      GO TO 750
                  END IF
                  JK  = JK + 1
C                               SAVE DESCRIPTOR
                  KPROFL(JK)  = MSTACK(1,MK)
C                              SAVE SCALE
                  KPROF2(JK)  = MSTACK(2,MK)
C                               SAVE DATA
                  KSET2(JK)   = KDATA(I,MK)
                  MK  = MK + 1
C                 PRINT *,'   ',JK,KPROFL(JK),KSET2(JK)
  800         CONTINUE
  850         CONTINUE
              IF (ISW.NE.1023) THEN
                  PRINT *,'LEVEL ERROR PROCESSING PROFILER',ISW
                  IPTR(1)  = 202
                  RETURN
              END IF
 2000     CONTINUE
          DO 4000 LL = 1,JK
              KDATA(I,LL)  = KSET2(LL)
 4000     CONTINUE
 3000 CONTINUE
C                           MOVE DATA BACK INTO KDATA ARRAY
      DO 5000 LL = 1, JK
C                            DESCRIPTOR
          MSTACK(1,LL)  = KPROFL(LL)
C                          SCALE
          MSTACK(2,LL)  = KPROF2(LL)
C                           DATA
C         PRINT *,LL,MSTACK(1,LL),MSTACK(2,LL),(KDATA(I,LL),I=1,4)
 5000 CONTINUE
      IPTR(31)  = JK
      RETURN
      END

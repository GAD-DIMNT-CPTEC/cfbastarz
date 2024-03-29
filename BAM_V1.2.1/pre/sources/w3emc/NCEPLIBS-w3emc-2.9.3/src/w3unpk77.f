C> @file
C> @brief Decodes single report from bufr messages
C> @author Dennis Keyser @date 2002-03-05

C> This subroutine decodes a single report from bufr messages
C> in a jbufr-type data file. Currently wind profiler, nexrad (vad)
C> wind and goes sounding/radiance data types are valid. Report is
C> returned in quasi-office note 29 unpacked format (see remarks 4.).
C>
C> ### Program History Log:
C> Date | Programmer | Comment
C> -----|------------|--------
C> 1996-12-16 | Dennis Keyser | Original author (based on w3lib routine w3fi77)
C> 1997-06-02 | Dennis Keyser | Added nexrad (vad) wind data type
C> 1997-06-16 | Dennis Keyser | Added goes sounding/radiance data type
C> 1997-09-18 | Dennis Keyser | Added instrument data used in processing,
C> solar zenith angle, and satellite zenith angle
C> to list of parameters returned from goes
C> sounding/radiance data type
C> 1998-07-09 | Dennis Keyser | Modified wind profiler cat. 11 (height, horiz.
C> significance, vert. significance) to account
C> for updates to bufrtable mnemonics in /dcom;
C> changed char. 6 of goes stnid to be unique for
C> two different even or odd satellite id's
C> (every other even or odd sat. id now gets same
C> char. 6 tag)
C> 1998-08-19 | Dennis Keyser | Subroutine now y2k and fortran 90 compliant
C> 1999-03-16 | Dennis Keyser | Incorporated bob kistler's changes needed
C> to port the code to the ibm sp
C> 1999-05-17 | Dennis Keyser | Made changes necessary to port this routine to
C> the ibm sp
C> 1999-09-26 | Dennis Keyser | Changes to make code more portable
C> 2002-03-05 | Dennis Keyser | Accounts for changes in input proflr (wind
C> profiler) bufr dump file after 3/2002: cat. 10
C> surface data now all missing (mnemonics "pmsl",
C> "wdir1","wspd1", "tmdb", "rehu", "reqv" no
C> longer available); cat. 11 mnemonics "acavh",
C> "acavv", "spp0", and "nphl" no longer
C> available; header mnemonic "npsm" is no longer
C> available, header mnemonic "tpse" replaces
C> "tpmi" (avg. time in minutes still output);
C> number of upper-air levels incr. from 43 to up
C> to 64 (size of output "rdata" array incr. from
C> 600 to 1200 to account for this) (will still
C> work properly for input proflr dump files prior
C> to 3/2002)
C>
C> @param[in] IDATE 4-word array holding "central" date to process (yyyy, mm, dd, hh)
C> @param[in] IHE Number of whole hours relative to "idate" for date of
C> earliest bufr message that is to be decoded; earliest date is "idate" +
C> "ihe" hours (if "ihe" is positive, latest message date is after "idate";
C> if "ihe" is negative latest message date is prior to "idate") example:
C> if ihe=1, then earliest date is 1-hr after idate; if ihe=-3, then earliest
C> date is 3-hr prior to idate
C> @param[in] IHL Number of whole hours relative to "idate" for date of
C> latest bufr message that is to be decoded; latest date is "idate" + ("ihl"
C> hours plus 59 min) if "ihl" is positive (latest message date is after
C> "idate"), and "idate" + ("ihl"+1 hours minus 1 min) if "ihl" is negative
C> (latest message date is prior to "idate") example: if ihl=3, then latest
C> date is 3-hr 59-min after idate; if ihl=-2, then latest date is 1-hr 1-min
C> prior to idate
C> @param[in] LUNIT Fortran unit number for input data file
C> @param[out] RDATA Single report returned an a quasi-office note 29 unpacked
C> format (see remarks 4.) (minimum size is 1200 words)
C> @param[inout] IRET [in] Controls degree of unit 6 printout (.ge. 0 -limited
C> printout; = -1 some additional diagnostic printout; = .lt. -1 -extensive
C> printout) (see remarks 3.)
C> [out] Return code as follows:
C> - IRET = 0 ---> Report successfully returned
C> - IRET > 0 ---> No report returned due to:
C>  - = 1 ---> All reports read in, end
C>  - = 2 ---> Lat and/or lon data missing
C>  - = 3 ---> Reserved
C>  - = 4 ---> Some/all date information missing
C>  - = 5 ---> No data levels processed (all levels are missing)
C>  - = 6 ---> Number of levels in report header is not 1
C>  - = 7 ---> Number of levels in another single level sequence is not 1
C>
C> @remark
C> - 1 A condition code (stop) of 15 will occur if the input
C> dates for start and/or stop time are specified incorrectly.
C> - 2 A condition code (stop) of 22 will occur if the
C> characters on this machine are neither ascii nor ebcdic.
C> - 3 The input argument "iret" should be set prior to each
C> call to this subroutine.
C>
C>   ***************************************************************
C>          4)
C>    BELOW IS THE FORMAT OF AN UNPACKED REPORT IN OUTPUT ARRAY RDATA
C>     (EACH WORD REPRESENTS A FULL-WORD ACCORDING TO THE MACHINE)
C>   N O T E :  THIS IS THE SAME FORMAT AS FOR W3LIB ROUTINE W3FI77
C>              EXCEPT WHERE NOTED
C>   ***************************************************************
C>
C> #### FORMAT FOR WIND PROFILER REPORTS
C>   WORD |  CONTENT               |  UNIT               | FORMAT
C>   ---- |  --------------------- | ------------------- | ---------
C>     1  |  LATITUDE                 |  0.01 DEGREES        | REAL
C>     2  |  LONGITUDE                |  0.01 DEGREES WEST   | REAL
C>     3  |  TIME SIGNIFICANCE | (BUFR CODE TABLE "0 08 021")  | INTEGER
C>     4  |  OBSERVATION TIME         |  0.01 HOURS (UTC)    | REAL
C>     5  |  YEAR/MONTH               |  4-CHAR. 'YYMM'  LEFT-JUSTIFIED | CHARACTER
C>     6  |  DAY/HOUR                 |  4-CHARACTERS 'DDHH' | CHARACTER
C>     7  |  STATION ELEVATION        |  METERS              | REAL
C>     8  |  SUBMODE/EDITION NO.      |  (SM X 10) + ED. NO. (ED. NO.=2, CONSTANT; SEE &,~) | INTEGER
C>     9  |  REPORT TYPE              |  71 (CONSTANT)       | INTEGER
C>    10  |  AVERAGING TIME           |  MINUTES (NEGATIVE MEANS PRIOR TO OBS. TIME) | INTEGER
C>    11  |  STN. ID. (FIRST 4 CHAR.) |  4-CHARACTERS LEFT-JUSTIFIED| CHARACTER
C>    12  |  STN. ID. (LAST  2 CHAR.) |  2-CHARACTERS LEFT-JUSTIFIED| CHARACTER
C> 13-34  |  ZEROED OUT - NOT USED    |                      | INTEGER
C>    35  |  CATEGORY 10, NO. LEVELS  |  COUNT               | INTEGER
C>    36  |  CATEGORY 10, DATA INDEX  |  COUNT               | INTEGER
C>    37  |  CATEGORY 11, NO. LEVELS  |  COUNT               | INTEGER
C>    38  |  CATEGORY 11, DATA INDEX  |  COUNT               | INTEGER
C> 39-42  |  ZEROED OUT - NOT USED    |                      | INTEGER
C> 43-END  | UNPACKED DATA GROUPS     | (FOLLOWS)            | REAL
C>
C> #### CATEGORY 10 - WIND PROFILER SFC DATA (EACH LEVEL, SEE WORD 35 ABOVE)
C>     WORD  | PARAMETER          |  UNITS             |  FORMAT
C>     ----  | ---------          |  ----------------- |  -------------
C>(SEE @)1   | SEA-LEVEL PRESSURE |  0.1 MILLIBARS     |  REAL
C>(SEE *)2   | STATION PRESSURE   |  0.1 MILLIBARS     |  REAL
C>(SEE @)3   | HORIZ. WIND DIR.   |  DEGREES           |  REAL
C>(SEE @)4   | HORIZ. WIND SPEED  |  0.1 M/S           |  REAL
C>(SEE @)5   | AIR TEMPERATURE    |  0.1 DEGREES K     |  REAL
C>(SEE @)6   | RELATIVE HUMIDITY  |  PERCENT           |  REAL
C>(SEE @)7   | RAINFALL RATE      |  0.0000001 M/S     |  REAL
C>
C> #### CATEGORY 11 - WIND PROFILER UPPER-AIR DATA (FIRST LEVEL IS SURFACE) (EACH LEVEL, SEE WORD 37 ABOVE)
C>     WORD  | PARAMETER            | UNITS               | FORMAT
C>     ----  | ---------            | -----------------   | -------------
C>       1   | HEIGHT ABOVE SEA-LVL | METERS              | REAL
C>       2   | HORIZ. WIND DIR.     | DEGREES             | REAL
C>       3   | HORIZ. WIND SPEED    | 0.1 M/S             | REAL
C>       4   | QUALITY CODE         | (SEE %)             | INTEGER
C>       5   | VERT. WIND COMP. (W) | 0.01 M/S            | REAL
C>(SEE @)6   | HORIZ. CONSENSUS NO. | (SEE $)             | INTEGER
C>(SEE @)7   | VERT.  CONSENSUS NO. | (SEE $)             | INTEGER
C>(SEE @)8   | SPECTRAL PEAK POWER  | DB                  | REAL
C>       9   | HORIZ. WIND SPEED    | 0.1 M/S             | REAL
C>           | STANDARD DEVIATION   | 0.1 M/S             | REAL
C>      10   | VERT. WIND COMPONENT | 0.1 M/S             | REAL
C>           | STANDARD DEVIATION   | 0.1 M/S             | REAL
C>(SEE @)11  | MODE                 | (SEE #)             | INTEGER
C>
C> ##### SEE:
C> - *-  ALWAYS MISSING
C> - &-  THIS IS A CHANGE FROM FORMAT IN W3LIB ROUTINE W3FI77
C> - %-  0 - MEDIAN AND SHEAR CHECKS BOTH PASSED
C>  - 2 - MEDIAN AND SHEAR CHECK RESULTS INCONCLUSIVE
C>  - 4 - MEDIAN CHECK PASSED; SHEAR CHECK FAILED
C>  - 8 - MEDIAN CHECK FAILED; SHEAR CHECK PASSED
C>  - 12 - MEDIAN AND SHEAR CHECKS BOTH FAILED
C> - $-  NO. OF INDIVIDUAL 6-MINUTE AVERAGE MEASUREMENTS THAT WERE
C>      INCLUDED IN FINAL ESTIMATE OF AVERAGED WIND (RANGE: 0, 2-10)
C>      (BASED ON A ONE-HOUR AVERAGE)
C> - #-  1 - DATA FROM LOW MODE
C>      2 - DATA FROM HIGH MODE
C>      3 - MISSING
C> - @-  THIS PARAMETER IS NO LONGER AVAILABLE AFTER 3/2002 AND IS SET
C>      TO MISSING (99999 FOR INTEGER OR 99999. FOR REAL)
C> - ~-  SUBMODE IS NO LONGER AVAILABLE AFTER 3/2002 AND IS SET TO 3
C>      (ITS MISSING VALUE)
C>
C>XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
C>               FORMAT FOR GOES SOUNDING/RADIANCE REPORTS
C>XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
C>                           HEADER
C>   WORD   CONTENT                   UNIT                 FORMAT
C>   ----   ----------------------    -------------------  ---------
C>     1    LATITUDE                  0.01 DEGREES         REAL
C>     2    LONGITUDE                 0.01 DEGREES WEST    REAL
C>     3    FIELD OF VIEW NUMBER      NUMERIC              INTEGER
C>     4    OBSERVATION TIME          0.01 HOURS (UTC)     REAL
c>vvvvvdak port
C>     5    YEAR/MONTH                4-CHAR. 'YYMM'       CHARACTER
c>aaaaadak port
C>                                    LEFT-JUSTIFIED
C>     6    DAY/HOUR                  4-CHARACTERS 'DDHH'  CHARACTER
C>     7    STATION ELEVATION         METERS               REAL
C>     8    PROCESS. TECHNIQUE        (=21-CLEAR;          INTEGER
C>     8    PROCESS. TECHNIQUE       =23-CLOUD-CORRECTED)
C>     9    REPORT TYPE               61 (CONSTANT)        INTEGER
C>    10    QUALITY FLAG      (BUFR CODE TABLE "0 33 002") INTEGER
C>    11    STN. ID. (FIRST 4 CHAR.)  4-CHARACTERS         CHARACTER
C>                                    LEFT-JUSTIFIED
C>    12    STN. ID. (LAST  2 CHAR.)  2-CHARACTERS         CHARACTER
C>                                    LEFT-JUSTIFIED (SEE %)
C>
C> 13-26    ZEROED OUT - NOT USED
C>    27    CATEGORY 08, NO. LEVELS   COUNT                INTEGER
C>    28    CATEGORY 08, DATA INDEX   COUNT                INTEGER
C> 29-38    ZEROED OUT - NOT USED
C>    39    CATEGORY 12, NO. LEVELS   COUNT                INTEGER
C>    40    CATEGORY 12, DATA INDEX   COUNT                INTEGER
C>    41    CATEGORY 13, NO. LEVELS   COUNT                INTEGER
C>    42    CATEGORY 13, DATA INDEX   COUNT                INTEGER
C>
C> 43-END   UNPACKED DATA GROUPS      (FOLLOWS)            REAL
C>
C>   CATEGORY 12 - SATELLITE SOUNDING LEVEL DATA (FIRST LEVEL IS SURFACE;
C>                 EACH LEVEL, SEE 39 ABOVE)
C>     WORD   PARAMETER            UNITS               FORMAT
C>     ----   ---------            -----------------   -------------
C>       1    PRESSURE             0.1 MILLIBARS       REAL
C>       2    GEOPOTENTIAL         METERS              REAL
C>       3    TEMPERATURE          0.1 DEGREES C       REAL
C>       4    DEWPOINT TEMPERATURE 0.1 DEGREES C       REAL
C>       5    NOT USED             SET TO MISSING      REAL
C>       6    NOT USED             SET TO MISSING      REAL
C>       7    QUALITY MARKERS      4-CHARACTERS        CHARACTER
C>                                 LEFT-JUSTIFIED (SEE &)
C>
C>   CATEGORY 13 - SATELLITE RADIANCE "LEVEL" DATA (EACH "LEVEL", SEE
C>                 41 ABOVE)
C>     WORD   PARAMETER            UNITS               FORMAT
C>     ----   ---------            -----------------   -------------
C>       1    CHANNEL NUMBER       NUMERIC             INTEGER
C>       2    BRIGHTNESS TEMP.     0.01 DEG. KELVIN    REAL
C>       3    QUALITY MARKERS      4-CHARACTERS        CHARACTER
C>                                 LEFT-JUSTIFIED (SEE &&)
C>
C>   CATEGORY 08 - ADDITIONAL (MISCELLANEOUS) DATA (EACH LEVEL, SEE @
C>                 BELOW)
C>     WORD   PARAMETER            UNITS               FORMAT
C>     ----   ---------            -----------------   -------------
C>       1    VARIABLE             SEE @ BELOW         REAL
C>       2    CODE FIGURE          SEE @ BELOW         REAL
C>       3    MARKERS              2-CHARACTERS        CHARACTER
C>                                 LEFT-JUSTIFIED (SEE #)
C>
C>  %-  SIXTH CHARACTER OF STATION ID IS A TAGGED AS FOLLOWS:
C>          "I" - GOES-EVEN-1 (252, 256, ...) SAT. , CLEAR COLUMN  RETR.
C>          "J" - GOES-EVEN-1 (252, 256, ...) SAT. , CLD-CORRECTED RETR.

C>          "L" - GOES-ODD-1  (253, 257, ...) SAT. , CLEAR COLUMN  RETR.
C>          "M" - GOES-ODD-1  (253, 257, ...) SAT. , CLD-CORRECTED RETR.

C>          "O" - GOES-EVEN-2 (254, 258, ...) SAT. , CLEAR COLUMN  RETR.
C>          "P" - GOES-EVEN-2 (254, 258, ...) SAT. , CLD-CORRECTED RETR.

C>          "Q" - GOES-ODD-2  (251, 255, ...) SAT. , CLEAR COLUMN  RETR.
C>          "R" - GOES-ODD-2  (251, 255, ...) SAT. , CLD-CORRECTED RETR.

C>          "?" - EITHER SATELLITE AND/OR RETRIEVAL TYPE UNKNOWN

C>  &-  FIRST  CHARACTER IS Q.M. FOR GEOPOTENTIAL
C>      SECOND CHARACTER IS Q.M. FOR TEMPERATURE
C>      THIRD  CHARACTER IS Q.M. FOR DEWPOINT TEMPERATURE
C>      FOURTH CHARACTER IS NOT USED
C>          " " - INDICATES DATA NOT SUSPECT
C>          "Q" - INDICATES DATA ARE SUSPECT
C>          "F" - INDICATES DATA ARE BAD
C>  &&- FIRST  CHARACTER IS Q.M. FOR BRIGHTNESS TEMPERATURE
C>      SECOND-FOURTH CHARACTERS ARE NOT USED
C>          " " - INDICATES DATA NOT SUSPECT
C>          "Q" - INDICATES DATA ARE SUSPECT
C>          "F" - INDICATES DATA ARE BAD
C>  @-  NUMBER OF "LEVELS" FROM WORD 27.  MAXIMUM IS 12, AND ARE ORDERED
C>      AS FOLLOWS (IF A DATUM ARE MISSING THAT LEVEL NOT STORED)
C>           1 - LIFTED INDEX ---------- .01 DEG. KELVIN -- C. FIG. 250.
C>           2 - TOTAL PRECIP. WATER  -- .01 MILLIMETERS -- C. FIG. 251.
C>           3 - 1. TO .9 SIGMA P.WATER- .01 MILLIMETERS -- C. FIG. 252.
C>           4 - .9 TO .7 SIGMA P.WATER- .01 MILLIMETERS -- C. FIG. 253.
C>           5 - .7 TO .3 SIGMA P.WATER- .01 MILLIMETERS -- C. FIG. 254.
C>           6 -  SKIN TEMPERATURE ----- .01 DEG. KELVIN -- C. FIG. 255.
C>           7 -  CLOUD TOP TEMPERATURE- .01 DEG. KELVIN -- C. FIG. 256.
C>           8 -  CLOUD TOP PRESSURE --- .1 MILLIBARS ----- C. FIG. 257.
C>           9 -  CLOUD AMOUNT (BUFR TBL. C.T. 0-20-011) -- C. FIG. 258.
C>          10 -  INSTR. DATA USED IN PROC.
C>                             (BUFR TBL. C.T. 0-02-021) -- C. FIG. 259.
C>          11 -  SOLAR ZENITH ANGLE --- .01 DEGREE ------- C. FIG. 260.
C>          12 -  SAT. ZENITH ANGLE ---- .01 DEGREE ------- C. FIG. 261.
C>  #-  FIRST  CHARACTER IS Q.M. FOR THE DATUM
C>          " " - INDICATES DATA NOT SUSPECT
C>          "Q" - INDICATES DATA ARE SUSPECT
C>          "F" - INDICATES DATA ARE BAD
C>      SECOND CHARACTER IS NOT USED
C>
C>XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
C>                FORMAT FOR NEXRAD (VAD) WIND REPORTS
C>XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
C>                           HEADER
C>   WORD   CONTENT                   UNIT                 FORMAT
C>   ----   ----------------------    -------------------  ---------
C>     1    LATITUDE                  0.01 DEGREES         REAL
C>     2    LONGITUDE                 0.01 DEGREES WEST    REAL
C>     3    ** RESERVED **            SET TO 99999         INTEGER
C>     4    OBSERVATION TIME          0.01 HOURS (UTC)     REAL
c>vvvvvdak port
C>     5    YEAR/MONTH                4-CHAR. 'YYMM'       CHARACTER
c>aaaaadak port
C>                                    LEFT-JUSTIFIED
C>     6    DAY/HOUR                  4-CHARACTERS 'DDHH'  CHARACTER
C>     7    STATION ELEVATION         METERS               REAL
C>     8    ** RESERVED **            SET TO 99999         INTEGER
C>
C>     9    REPORT TYPE               72 (CONSTANT)        INTEGER
C>    10    ** RESERVED **            SET TO 99999         INTEGER
C>    11    STN. ID. (FIRST 4 CHAR.)  4-CHARACTERS         CHARACTER
C>                                    LEFT-JUSTIFIED
C>    12    STN. ID. (LAST  2 CHAR.)  2-CHARACTERS         CHARACTER
C>                                    LEFT-JUSTIFIED
C>
C> 13-18    ZEROED OUT - NOT USED                          INTEGER
C>    19    CATEGORY 04, NO. LEVELS   COUNT                INTEGER
C>    20    CATEGORY 04, DATA INDEX   COUNT                INTEGER
C> 21-42    ZEROED OUT - NOT USED                          INTEGER
C>
C> 43-END   UNPACKED DATA GROUPS      (FOLLOWS)            REAL
C>
C>   CATEGORY 04 - UPPER-AIR WINDS-BY-HEIGHT DATA(FIRST LEVEL IS SURFACE)
C>                 (EACH LEVEL, SEE WORD 19 ABOVE)
C>     WORD   PARAMETER            UNITS               FORMAT
C>     ----   ---------            -----------------   -------------
C>       1    HEIGHT ABOVE SEA-LVL METERS              REAL
C>       2    HORIZ. WIND DIR.     DEGREES             REAL
C>       3    HORIZ. WIND SPEED    0.1 M/S (SEE *)     REAL
C>       4    QUALITY MARKERS      4-CHARACTERS        CHARACTER
C>                                 LEFT-JUSTIFIED (SEE %)
C>
C>  *-  UNITS HERE DIFFER FROM THOSE IN TRUE UNPACKED OFFICE NOTE 29
C>      (WHERE UNITS ARE KNOTS)
C>  %-  THE FIRST THREE CHARACTERS ARE ALWAYS BLANK, THE FOURTH
C>      CHARACTER IS A "CONFIDENCE LEVEL" WHICH IS RELATED TO THE ROOT-
C>      MEAN-SQUARE VECTOR ERROR FOR THE HORIZONTAL WIND.  IT IS
C>      DEFINED AS FOLLOWS:
C>               'A' = RMS OF  1.9 KNOTS
C>               'B' = RMS OF  3.9 KNOTS
C>               'C' = RMS OF  5.8 KNOTS
C>               'D' = RMS OF  7.8 KNOTS
C>               'E' = RMS OF  9.7 KNOTS
C>               'F' = RMS OF 11.7 KNOTS
C>               'G' = RMS  > 13.6 KNOTS
C>XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
C>
C>   FOR ALL REPORT TYPES, MISSING VALUES ARE:
C>                       99999. FOR REAL
C>                       99999  FOR INTEGER
C>                       9'S    FOR CHARACTERS IN WORD  5,  6 OF HEADER
C>                       BLANK  FOR CHARACTERS IN WORD 11, 12 OF HEADER
C>                              AND FOR CHARACTERS IN ANY CATEGORY LEVEL
C>
C> @author Dennis Keyser @date 2002-03-05
      SUBROUTINE W3UNPK77(IDATE,IHE,IHL,LUNIT,RDATA,IRET)
      CHARACTER*4  CBUFR
      INTEGER  IDATE(4),LSDATE(4),jdate(8),IDATA(1200)
      dimension  rinc(5)
      REAL  RDATA(*),RDATX(1200)
      COMMON /PK77BB/kdate(8),ldate(8),IPRINT
      COMMON /PK77CC/INDEX
      COMMON /PK77DD/LSHE,LSHL,ICDATE(5),IDDATE(5)
      COMMON /PK77FF/IFOV(3),KNTSAT(250:260)

      SAVE

      EQUIVALENCE (RDATX,IDATA)
      DATA ITM/0/,LUNITL/-99/,KOUNT/0/
      IPRINT = 0
      IF(IRET.LT.0)  IPRINT = IABS(IRET)
      IRET = 0
      IF(ITM.EQ.0)  THEN
C-----------------------------------------------------------------------

C FIRST AND ONLY TIME INTO THIS SUBROUTINE DO A FEW THINGS....

         ITM = 1
         IFOV = 0
         KNTSAT = 0
C DETERMINE MACHINE WORD LENGTH IN BYTES (=8 FOR CRAY) AND TYPE OF
C  CHARACTER SET {ASCII(ICHTP=0) OR EBCDIC(ICHTP=1)}
         CALL W3FI04(IENDN,ICHTP,LW)
         PRINT 2213, LW, ICHTP, IENDN
 2213    FORMAT(/' ---> W3UNPK77: CALL TO W3FI04 RETURNS: LW = ',I3,
     $    ', ICHTP = ',I3,', IENDN = ',I3/)
         IF(ICHTP.GT.1)  THEN
C CHARACTERS ON THIS MACHINE ARE NEITHER ASCII OR EBCDIC!! -- STOP 22
            PRINT 217
  217       FORMAT(' *** W3UNPK77 ERROR: CHARACTERS ON THIS MACHINE ',
     $       'ARE NEITHER ASCII NOR EBCDIC - STOP 22'/)
            CALL ERREXIT(22)
         END IF
C-----------------------------------------------------------------------
      END IF
      IF(LUNIT.NE.LUNITL)  THEN
C-----------------------------------------------------------------------

C IF THE INPUT DATA UNIT NUMBER ARGUMENT IS DIFFERENT THAT THE LAST TIME
C  THIS SUBR. WAS CALLED, PRINT NEW HEADER, SET JRET = 1

         LUNITL = LUNIT
         JRET = 1
         PRINT 101, LUNIT
  101    FORMAT(//' ---> W3UNPK77: VERSION 03/05/2002: JBUFR DATA SET ',
     $    'READ FROM UNIT ',I4/)
C-----------------------------------------------------------------------
      ELSE

C FOR SUBSEQUENT TIMES INTO THIS SUBR. W/ SAME LUNIT AS LAST TIME,
C  TEST INPUT DATE & HR RANGE ARGUMENTS AGAINST THEIR VALUES THE LAST
C  TIME SUBR. CALLED -- IF THEY ARE DIFFERENT, SET JRET = 1 (ELSE
C  JRET = 0), WILL TEST JRET SOON

         JRET = 1
         DO I = 4,1,-1
            IF(IDATE(I).NE.LSDATE(I))  GO TO 88
         ENDDO
         IF(IHE.NE.LSHE.OR.IHL.NE.LSHL)  GO TO 88
         JRET = 0
   88    CONTINUE
C-----------------------------------------------------------------------
      END IF
      IF(JRET.EQ.1)  THEN
         PRINT 6680
 6680 FORMAT(/' JRET = 1 - REWIND DATA FILE & SET-UP TO DO DATE CHECK'/)
C-----------------------------------------------------------------------

C COME HERE IF FIRST CALL TO SUBROUTINE OR IF INPUT DATA UNIT NUMBER OR
C  IF INPUT DATE/TIME OR RANGE IN TIME HAS BEEN CHANGED FROM LAST CALL

C           CLOSE BUFR DATA SET (IN CASE OPEN FROM PREVIOUS RUN)
C       REWIND INPUT BUFR DATA SET, GET CENTER TIME AND DUMP TIME,
C                          OPEN BUFR DATA SET

C     SET-UP TO DETERMINE IF BUFR MESSAGE IS WITHIN REQUESTED DATES

C (ALSO SET INDEX=0, FORCES BUFR MSG TO BE READ BEFORE RPTS ARE DECODED)

C-----------------------------------------------------------------------

         CALL CLOSBF(LUNIT)

         REWIND LUNIT

         READ(LUNIT,END=9999,ERR=9999) CBUFR
         IF(CBUFR.NE.'BUFR') GO TO 9999

         call datelen(10)

         CALL DUMPBF(LUNIT,ICDATE,IDDATE)
cppppp
         print *,'CENTER DATE (ICDATE) = ',icdate
         print *,'DUMP DATE (IDDATE)   = ',iddate
cppppp

         if(icdate(1).le.0)  then
C COME HERE IF CENTER DATE COULD NOT BE READ FROM FIRST DUMMY MESSAGE
C  - RETURN WITH IRET = 1
            print *, ' *** W3UNPK77 ERROR: CENTER DATE COULD NOT BE ',
     $       'OBTAINED FROM INPUT FILE ON UNIT ',lunit
            go to 9998
         end if
         if(iddate(1).le.0)  then
C COME HERE IF DUMP DATE COULD NOT BE READ FROM SECOND DUMMY MESSAGE
C  - RETURN WITH IRET = 1
            print *, ' *** W3UNPK77 ERROR: DUMP DATE COULD NOT BE ',
     $       'OBTAINED FROM INPUT FILE ON UNIT ',lunit
            go to 9998
         end if
         IF(ICDATE(1).LT.100)  THEN

C If 2-digit year returned in ICDATE(1), must use "windowing" technique
C  to create a 4-digit year

C IMPORTANT: IF DATELEN(10) IS CALLED, THE DATE HERE SHOULD ALWAYS
C            CONTAIN A 4-DIGIT YEAR, EVEN IF INPUT FILE IS NOT
C            Y2K COMPLIANT (BUFRLIB DOES THE WINDOWING HERE)

            PRINT *, '##W3UNPK77 - THE FOLLOWING SHOULD NEVER ',
     $       'HAPPEN!!!!!'
            PRINT *, '##W3UNPK77 - 2-DIGIT YEAR IN ICDATE(1) ',
     $       'RETURNED FROM DUMPBF (ICDATE IS: ',ICDATE,') - USE ',
     $       'WINDOWING TECHNIQUE TO OBTAIN 4-DIGIT YEAR'
            IF(ICDATE(1).GT.20)  THEN
               ICDATE(1) = 1900 + ICDATE(1)
            ELSE
               ICDATE(1) = 2000 + ICDATE(1)
            ENDIF
            PRINT *, '##WW3UNPK77 - CORRECTED ICDATE(1) WITH 4-DIGIT ',
     $       'YEAR, ICDATE NOW IS: ',ICDATE
         ENDIF

         IF(IDDATE(1).LT.100)  THEN

C If 2-digit year returned in IDDATE(1), must use "windowing" technique
C  to create a 4-digit year

C IMPORTANT: IF DATELEN(10) IS CALLED, THE DATE HERE SHOULD ALWAYS
C            CONTAIN A 4-DIGIT YEAR, EVEN IF INPUT FILE IS NOT
C            Y2K COMPLIANT (BUFRLIB DOES THE WINDOWING HERE)

            PRINT *, '##W3UNPK77 - THE FOLLOWING SHOULD NEVER ',
     $       'HAPPEN!!!!!'
            PRINT *, '##W3UNPK77 - 2-DIGIT YEAR IN IDDATE(1) ',
     $       'RETURNED FROM DUMPBF (IDDATE IS: ',IDDATE,') - USE ',
     $       'WINDOWING TECHNIQUE TO OBTAIN 4-DIGIT YEAR'
            IF(IDDATE(1).GT.20)  THEN
               IDDATE(1) = 1900 + IDDATE(1)
            ELSE
               IDDATE(1) = 2000 + IDDATE(1)
            ENDIF
            PRINT *, '##W3UNPK77 - CORRECTED IDDATE(1) WITH 4-DIGIT ',
     $       'YEAR, IDDATE NOW IS: ',IDDATE
         END IF

C  OPEN BUFR FILE - READ IN DICTIONARY MESSAGES (TABLE A, B, D ENTRIES)

         CALL OPENBF(LUNIT,'IN',LUNIT)
         PRINT 100, LUNIT
  100    FORMAT(/5X,'===> BUFR DATA SET IN UNIT',I3,' SUCCESSFULLY ',
     $    'OPENED FOR INPUT; DCTNY MESSAGES CONTAIN BUFR TABLES A,B,D'/)
         INDEX = 0
         KOUNT = 0
         jdate(1:3) = idate(1:3)
         jdate(4) = 0
         jdate(5) = idate(4)
         jdate(6:8) = 0
         PRINT 6681, IDATE
 6681 FORMAT(/' %%% REQUESTED "CENTRAL" DATE IS :',I5,3I3,'  0'/)
C DETERMINE EARLIEST DATE FOR ACCEPTING BUFR MESSAGES FOR DECODING
         call w3movdat((/0.,real(ihe),0.,0.,0./),jdate,kdate)
         print 6682, (kdate(i),i=1,3),kdate(5),kdate(6)
 6682 FORMAT(/' --> EARLIEST DATE FOR ACCEPTING BUFR MSGS IS:',I5,4I3/)
C DETERMINE LATEST   DATE FOR ACCEPTING BUFR MESSAGES FOR DECODING
         if(ihl.ge.0)  then
           xminl = (ihl * 60) + 59
         else
           xminl = ((ihl + 1) * 60) - 1
         end if
         call w3movdat((/0.,0.,xminl,0.,0./),jdate,ldate)
         print 6683, (ldate(i),i=1,3),ldate(5),ldate(6)
 6683 FORMAT(/' -->  LATEST  DATE FOR ACCEPTING BUFR MSGS IS:',I5,4I3/)
         call w3difdat(ldate,kdate,3,rinc)
         IF(rinc(3).LT.0)  THEN
            PRINT 104
  104       FORMAT(' *** W3UNPK77 ERROR: DATES SPECIFIED INCORRECTLY -',
     $       ' STOP 15'/)
            CALL ERREXIT(15)
         END IF
C-----------------------------------------------------------------------
      END IF
C SUBR. UNPK7701 RETURNS A SINGLE DECODED REPORT FROM BUFR MESSAGE
      CALL UNPK7701(LUNIT,ITP,IRET)
C IRET=1 MEANS ALL DATA HAVE BEEN DECODED FOR SPECIFIED TIME PERIOD
C  (REWIND DATA FILE AND RETURN W/ IRET=1)
C IRET.GE.2 MEANS REPORT NOT RETURNED DUE TO ERROR IN DECODING (RETURN)
C  (ACTUALLY IRET.GE.2 CURRENTLY CANNOT HAPPEN OUT OF UNPK7701)
      IF(IRET.GE.1)  THEN
         IF(IRET.EQ.1)  THEN
            REWIND LUNIT
            IF(ITP.EQ.2)  THEN
               PRINT 8101, IFOV
 8101 FORMAT(/' ---> W3UNPK77: SUMMARY OF GOES REPORT COUNTS GROUPED',
     $ ' BY F-O-V NO. (PRIOR TO ANY FILTERING BY CALLING PROGRAM)'/15X,
     $ '# WITH F-O-V NO. 00 TO 02:',I6,' - GET "BAD" Q.MARK'/15X,
     $ '# WITH F-O-V NO. 03 TO 09:',I6,' - GET "SUSPECT" Q.MARK'/15X,
     $ '# WITH F-O-V NO. 10 TO 25:',I6,' - GET "NEUTRAL" Q.MARK'/20X,
     $ '(NOTE: RADIANCES ALWAYS HAVE NEUTRAL Q.MARK)'/)
               PRINT 8102
 8102 FORMAT(/' ---> W3UNPK77: SUMMARY OF GOES REPORT COUNTS GROUPED',
     $ ' BY SATELLITE ID (PRIOR TO ANY FILTERING BY CALLING PROGRAM)'/)
               DO  IDSAT = 250,259
                  IF(KNTSAT(IDSAT).GT.0) PRINT 8103, IDSAT,KNTSAT(IDSAT)
               ENDDO
 8103 FORMAT(15X,'NUMBER FROM SAT. ID',I4,4X,':',I6)
               IF(KNTSAT(260).GT.0)  PRINT 8104
 8104 FORMAT(15X,'NUMBER FROM UNKNOWN SAT. ID:',I6)
               PRINT 8105
 8105          FORMAT(/)
            END IF
         END IF
         GO TO 99
      END IF
      KOUNT = KOUNT + 1
C INITIALIZE THE OUTPUT ON29 ARRAY
      CALL UNPK7702(RDATA,ITP)
      IF(ITP.EQ.1)  THEN
C-----------------------------------------------------------------------
C          THE FOLLOWING PERTAINS TO WIND PROFILER REPORTS
C-----------------------------------------------------------------------
C STORE THE HEADER INFORMATION INTO ON29 FORMAT
         CALL UNPK7703(LUNIT,RDATA,IRET)
C IRET.GE.2 MEANS RPT NOT RETURNED DUE TO MSG DATA IN HDR (RETURN)
         IF(IRET.GE.2)  GO TO 99
C STORE THE SURFACE DATA INTO ON29 FORMAT (CATEGORY 10)
         CALL UNPK7704(LUNIT,RDATA)
C STORE THE UPPER-AIR DATA INTO ON29 FORMAT (CATEGORY 11)
         CALL UNPK7705(LUNIT,RDATA)
         RDATX(1:1200) = RDATA(1:1200)
         IF(IDATA(35)+IDATA(37).EQ.0)  IRET = 5
      ELSE  IF(ITP.EQ.2)  THEN
C-----------------------------------------------------------------------
C        THE FOLLOWING PERTAINS TO GOES SOUNDING/RADIANCE REPORTS
C-----------------------------------------------------------------------
C STORE THE HEADER INFORMATION INTO ON29 FORMAT
         CALL UNPK7708(LUNIT,RDATA,KOUNT,IRET)
C IRET.GE.2 MEANS RPT NOT RETURNED DUE TO MSG DATA IN HDR (RETURN)
         IF(IRET.GE.2)  GO TO 99
C STORE THE UPPER-AIR DATA/RADIANCE INTO ON29 FORMAT (CATEGORY 12, 13)
         CALL UNPK7709(LUNIT,RDATA,IRET)
      ELSE  IF(ITP.EQ.3)  THEN
C-----------------------------------------------------------------------
C       THE FOLLOWING PERTAINS TO NEXRAD (VAD) WIND REPORTS
C-----------------------------------------------------------------------
C STORE THE HEADER INFORMATION INTO ON29 FORMAT
         CALL UNPK7706(LUNIT,RDATA,IRET)
C IRET.GE.2 MEANS RPT NOT RETURNED DUE TO MSG DATA IN HDR (RETURN)
         IF(IRET.GE.2)  GO TO 99
C STORE THE UPPER-AIR DATA INTO ON29 FORMAT (CATEGORY 4)
         CALL UNPK7707(LUNIT,RDATA,IRET)
C-----------------------------------------------------------------------
      END IF
   99 CONTINUE
C PRIOR TO RETURNING SAVE INPUT DATE & HR RANGE ARGUMENTS FROM THIS CALL
      lsdate = idate
      LSHE = IHE
      LSHL = IHL
      RETURN
C-----------------------------------------------------------------------
 9999 CONTINUE
C COME HERE IF NULL OR NON-BUFR FILE IS INPUT - RETURN WITH IRET = 1
      PRINT *, ' *** W3UNPK77 ERROR: INPUT FILE IN UNIT ',LUNIT,' IS ',
     $ 'EITHER A NULL OR NON-BUFR FILE'
 9998 continue
      REWIND LUNIT
      IRET = 1
      lsdate = idate
      LSHE = IHE
      LSHL = IHL
      END
C> @brief Reads a single report out of bufr dataset
C> @author Dennis Keyser @date 1996-12-16

C> Calls bufrlib routines to read in a bufr message and then read a single
C> report (subset) out of the message.
C>
C> ### Program History Log:
C> Date | Programmer | Comment
C> -----|------------|--------
C> 1996-12-16 | Dennis Keyser NP22 | Initial.
C>
C> @param[in] LUNIT Fortran unit number for input data file.
C> @param[out] ITP The type of report that has been decoded {=1 - wind profiler,
C> =2 - goes sndg, =3 - nexrad(vad) wind}
C> @param[out] IRET Return code as described in w3unpk77 docblock
C>
C> @author Dennis Keyser @date 1996-12-16
      SUBROUTINE UNPK7701(LUNIT,ITP,IRET)
      CHARACTER*8   SUBSET
      integer  mdate(4),ndate(8)
      dimension  rinc(5)
      COMMON /PK77BB/kdate(8),ldate(8),IPRINT
      COMMON /PK77CC/INDEX
      COMMON /PK77DD/LSHE,LSHL,ICDATE(5),IDDATE(5)

      SAVE

      DATA  IREC/0/

   10 CONTINUE
C=======================================================================
      IF(INDEX.EQ.0)  THEN

C  READ IN NEXT BUFR MESSAGE

         CALL READMG(LUNIT,SUBSET,IBDATE,JRET)
         IF(JRET.NE.0)  THEN
C-----------------------------------------------------------------------
            PRINT 101
  101   FORMAT(' ---> W3UNPK77: ALL BUFR MESSAGES READ IN AND DECODED'/)
            IRET = 1
            RETURN
C-----------------------------------------------------------------------
         END IF
         if(ibdate.lt.100000000)  then
c If input BUFR file does not return messages with a 4-digit year,
c  something is wrong (even non-compliant BUFR messages should
c  construct a 4-digit year as long as datelen(10) has been called
            print *, '##W3UNP777/UNPK7701 - A 10-digit Sect. 1 BUFR ',
     $       'message date was not returned in unit ',lunit,' - ',
     $       'problem with BUFR file - ier = 1'
            iret = 1
            return
         end if
         CALL UFBCNT(LUNIT,IREC,ISUB)
         MDATE(1) = IBDATE/1000000
         MDATE(2) = MOD((IBDATE/10000),100)
         MDATE(3) = MOD((IBDATE/100),100)
         MDATE(4) = MOD(IBDATE,100)
C ALL JBUFR MESSAGES CURRENTLY HAVE "00" FOR MINUTES IN SECTION 1
         ndate(1:3) = mdate(1:3)
         ndate(4) = 0
         ndate(5) = mdate(4)
         ndate(6:8) = 0
         IF(IPRINT.GE.1)  THEN
            PRINT *,'HAVE SUCCESSFULLY READ IN A BUFR MESSAGE'
            PRINT 103
  103       FORMAT(' BUFR FOUND BEGINNING AT BYTE    1 OF MESSAGE')
            PRINT 105, IREC,MDATE,SUBSET
  105       FORMAT(8X,'HAVE READ IN A BUFR MESSAGE NO.',I3,', DATE: ',
     $      I6,3I4,'   0; TABLE A ENTRY = ',A8,' AND EDIT. NO. =    2'/)
         END IF
         IF(SUBSET.EQ.'NC002007')  THEN
            IF(IPRINT.GE.1)  PRINT *, 'THIS MESSAGE CONTAINS WIND ',
     $       'PROFILER REPORTS'
            ITP = 1
         ELSE  IF(SUBSET.EQ.'NC002008')  THEN
            IF(IPRINT.GE.1)  PRINT *, 'THIS MESSAGE CONTAINS NEXRAD ',
     $       '(VAD) WIND REPORTS'
            ITP = 3
         ELSE  IF(SUBSET.EQ.'NC003001')  THEN
            IF(IPRINT.GE.1)  PRINT *, 'THIS MESSAGE CONTAINS GOES ',
     $       'SOUNDING/RADIANCE REPORTS'
            ITP = 2
         ELSE
            PRINT 107, IREC
  107 FORMAT(' *** W3UNPK77 WARNING: BUFR MESSAGE NO.',I3,' CONTAINS ',
     $ 'REPORTS THAT CANNOT BE DECODED BY W3UNPK77, TRY READING NEXT ',
     $ 'MSG'/)
            INDEX = 0
            GO TO 10
         END IF
         call w3difdat(kdate,ndate,3,rinc)
         kmin = rinc(3)
         call w3difdat(ldate,ndate,3,rinc)
         lmin = rinc(3)
C CHECK DATE OF MESSAGE AGAINST SPECIFIED TIME RANGES
         if((kmin.gt.0.or.lmin.lt.0).AND.IREC.GT.2)  then
            PRINT 106, IREC,MDATE
  106 FORMAT('  BUFR MESSAGE NO.',I3,' WITH DATE:',I5,3I3,'  0 NOT W/I',
     $ ' REQ. TIME RANGE, TRY READING NEXT MSG'/)
            INDEX = 0
            GO TO 10
         END IF
      END IF
C=======================================================================
C  READ NEXT SUBSET (REPORT) IN MESSAGE

      IF(IPRINT.GT.1)  PRINT *,'CALL READSB'
      CALL READSB(LUNIT,JRET)
      IF(IPRINT.GT.1)  PRINT *,'BACK FROM READSB'
      IF(JRET.NE.0) THEN
         IF(INDEX.GT.0)  THEN

C ALL SUBSETS IN THIS MESSAGE PROCESSED, READ IN NEXT MESSAGE (IF ALL
C  MESSAGES READ IN NO MORE DATA TO PROCESS)

            IF(IPRINT.GT.1)  PRINT *, 'ALL REPORTS IN THIS MESSAGE ',
     $       'DECODED, GO ON TO NEXT MESSAGE'
         ELSE

C THERE WERE NO SUBSETS FOUND IN THIS BUFR MESSAGE, GOOD CHANCE IT IS
C  ONE OF TWO DUMMY MESSAGES AT TOP OF FILE INDICATING CENTER TIME AND
C  DATA DUMP TIME ONLY; READ IN NEXT MESSAGE

            IF(IREC.EQ.1)  THEN
               PRINT 4567, ICDATE
 4567 FORMAT(/'===> BUFR MESSAGE NO.  1 IS A DUMMY MESSAGE CONTAINING ',
     $ 'ONLY CENTER DATE (',I5,4I3,') - NO DATA - GO ON TO NEXT ',
     $ 'MESSAGE'/)
            ELSE IF(IREC.EQ.2)  THEN
               PRINT 4568, IDDATE
 4568 FORMAT(/'===> BUFR MESSAGE NO.  2 IS A DUMMY MESSAGE CONTAINING ',
     $ 'ONLY  DUMP  DATE (',I5,4I3,') - NO DATA - GO ON TO NEXT ',
     $ 'MESSAGE'/)
            ELSE
               PRINT 4569, IREC,MDATE
 4569 FORMAT(/'===> BUFR MESSAGE NO.',I3,' (DATE:',I5,3I3,'  0) ',
     $ 'CONTAINS ZERO REPORTS FOR SOME UNEXPLAINED REASON - GO ON TO ',
     $ 'NEXT MESSAGE'/)
            END IF
         END IF
         INDEX = 0
         GO TO 10
      END IF
C-----------------------------------------------------------------------
      IF(IPRINT.GT.1)  PRINT *, 'READY TO PROCESS NEW DECODED REPORT'
C***********************************************************************
C            A SINGLE REPORT HAS BEEN SUCCESSFULLY DECODED
C***********************************************************************
      INDEX = INDEX + 1
      IF(IPRINT.GE.1)  PRINT *, 'WORKING WITH SUBSET NUMBER ',INDEX
      RETURN
      END
C> @brief Initializes the output array for a report.
C> @author Dennis Keyser @date 1996-12-16

C> Initializes the output array which holds a single report in the quasi-office
C> note 29 unpacked format to all missing.
C>
C> ### Program History Log:
C> Date | Programmer | Comment
C> -----|------------|--------
C> 1996-12-16 | Dennis Keyser NP22 | Initial.
C> @param[in] ITP the type of report that has been decoded {=1 - wind profiler, =2 - goes sndg, =3 - nexrad(vad) wind}
C> @param[out] RDATA single report returned an a quasi-office note 29 unpacked format; all data are missing
C>
C> @author Dennis Keyser @date 1996-12-16
      SUBROUTINE UNPK7702(RDATA,ITP)
      REAL  RDATA(*),RDATX(1200)
      INTEGER  IDATA(1200),IRTYP(3)
      CHARACTER*8  COB
C
      SAVE
C
      EQUIVALENCE (RDATX,IDATA),(COB,IOB)
      DATA  XMSG/99999./,IMSG/99999/,IRTYP/71,61,72/
      RDATX(1)  = XMSG
      RDATX(2)  = XMSG
      IDATA(3)  = IMSG
      RDATX(4)  = XMSG
      COB = '999999  '
      IDATA(5)  = IOB
      COB = '9999    '
      IDATA(6)  = IOB
      RDATX(7)  = XMSG
      IDATA(8)  = IMSG
      IDATA(9)  =  IRTYP(ITP)
      IDATA(10) = IMSG
      COB = '        '
      IDATA(11) = IOB
      IDATA(12) = IOB
C
C       ALL TYPES -- LOAD ZEROS INTO THE DEFINING WORD PAIRS
C
      IDATA(13:42) = 0
C
C       ALL TYPES -- LOAD MISSINGS INTO THE DATA PORTION
C
      RDATX(43:1200) = XMSG
      IF(ITP.EQ.1)  THEN
C
C       PROFILER -- LOAD INTEGER MISSING WHERE APPROPRIATE
C          (Current limit of 104 Cat. 11 levels)
C
         IDATA(53:1200:11) = IMSG
         IDATA(55:1200:11) = IMSG
         IDATA(56:1200:11) = IMSG
         IDATA(60:1200:11) = IMSG
      ELSE  IF(ITP.EQ.2)  THEN
C
C       GOES -- LOAD DEFAULT OF BLANK CHARACTERS INTO CAT. 12
C               LEVEL QUALITY MARKERS
C          (Current limit of 50 Cat. 12 levels)
C          (could be expanded if need be)
C
         IDATA(49:392:7) = IOB
C
C       GOES -- LOAD DEFAULT OF BLANK CHARACTER INTO FIRST CAT. 08
C               LEVEL QUALITY MARKER
C          (Current limit of 9 Cat. 08 levels)
C          (could be expanded if need be)
C
         IDATA(395:419:3) = IOB
C       GOES -- LOAD INTEGER MISSING INTO CAT. 13 LEVEL CHANNEL NUMBER
C            -- LOAD DEFAULT OF BLANK CHARACTER INTO CAT. 13 LEVEL
C               QUALITY MARKER
C          (Current limit of 60 Cat. 13 levels)
C          (could be expanded if need be)
C
         IDATA(420:599:3) = IMSG
         IDATA(422:599:3) = IOB
      ELSE  IF(ITP.EQ.3)  THEN
C
C       VADWND -- LOAD DEFAULT OF BLANK CHARACTER INTO HGHT CAT. 04
C                 LEVEL QUALITY MARKER
C            (Current limit of 70 Cat. 04 levels)
C            (could be expanded if need be)
C
         IDATA(46:1200:4) = IOB
      END IF
      RDATA(1:1200) = RDATX(1:1200)
      RETURN
      END
C> @brief Fills in header in o-put array - pflr rpt.
C> @author Dennis Keyser @date 2002-03-05

C> For report (subset) read out of bufr message (passed in
C> internally via bufrlib storage), calls bufrlib routine to decode
C> header data for wind profiler report.  header is then filled into
C> the output array which holds a single wind profiler report in the
C> quasi-office note 29 unpacked format.
C>
C> ### Program History Log:
C> Date | Programmer | Comment
C> -----|------------|--------
C> 1996-12-16 | Dennis Keyser NP22 | Initial.
C> 2002-03-05 | Dennis Keyser | Accounts for changes in input proflr (wind profiler) bufr dump file after 3/2002: mnemonic "npsm" is no longer available, mnemonic "tpse" replaces "tpmi" (avg. time in minutes still output) (will still work properly for input proflr dump files prior to 3/2002)
C>
C> @param[in] LUNIT Fortran unit number for input data file
C> @param[inout] RDATA Single wind profiler report in a quasi-office note 29 unpacked format with [out] header information filled in [in] all data initialized as missing
C> @param[out] IRET Return code as described in w3unpk77 docblock
C>
C> @author Dennis Keyser @date 2002-03-05
      SUBROUTINE UNPK7703(LUNIT,RDATA,IRET)
      CHARACTER*6   STNID
      CHARACTER*8   COB
      CHARACTER*35  HDR1,HDR2
      INTEGER  IDATA(1200)
      REAL(8) HDR_8(16)
      REAL  HDR(16),RDATA(*),RDATX(1200)
      COMMON /PK77BB/kdate(8),ldate(8),IPRINT

      SAVE

      EQUIVALENCE  (RDATX,IDATA),(COB,IOB)
      DATA  XMSG/99999./,IMSG/99999/
      DATA  HDR1/'CLAT CLON TSIG SELV NPSM TPSE WMOB '/
      DATA  HDR2/'WMOS YEAR MNTH DAYS HOUR MINU TPMI '/
      RDATX(1:1200) = RDATA(1:1200)
      HDR_8 = 10.0E10
      CALL UFBINT(LUNIT,HDR_8,16,1,NLEV,HDR1//HDR2);HDR=HDR_8
      IF(NLEV.NE.1)  THEN
C.......................................................................
C PROBLEM: THE NUMBER OF DECODED "LEVELS" IS NOT WHAT IS EXPECTED --
C  SET IRET = 6 AND RETURN
         PRINT 217, NLEV
  217 FORMAT(/' ##W3UNPK77: THE NUMBER OF DECODED "LEVELS" (=',I5,') ',
     $ 'IS NOT WHAT IS EXPECTED (1) - IRET = 6'/)
         IRET = 6
         RETURN
C.......................................................................
      END IF

C         LATITUDE (STORED AS REAL)

      M = 1
      IF(IPRINT.GT.1)  PRINT 199, HDR(1),M
  199 FORMAT(5X,'HDR HERE IS: ',F17.4,'; INDEX IS: ',I3)
      IF(HDR(1).LT.XMSG)  THEN
         RDATX(1) = NINT(HDR(1) * 100.)
         NNNNN = 1
         IF(IPRINT.GT.1)  PRINT 198, NNNNN,RDATX(NNNNN)
  198 FORMAT(5X,'DATA(',I5,') STORED AS: ',F10.2)
      ELSE
         IRET = 2
         PRINT 102
  102    FORMAT(' *** W3UNPK77 ERROR: LAT MISSING FOR WIND PROFILER ',
     $    'REPORT'/)
         RETURN
      END IF

C         LONGITUDE (STORED AS REAL)

      M = 2
      IF(IPRINT.GT.1)  PRINT 199, HDR(2),M
      IF(HDR(2).LT.XMSG)  THEN
         RDATX(2) = NINT(MOD((36000.-(HDR(2)*100.)),36000.))
         NNNNN = 2
         IF(IPRINT.GT.1)  PRINT 198, NNNNN,RDATX(NNNNN)
      ELSE
         IRET = 2
         PRINT 104
  104    FORMAT(' *** W3UNPK77 ERROR: LON MISSING FOR WIND PROFILER ',
     $    'REPORT'/)
         RETURN
      END IF

C         TIME SIGNIFICANCE (STORED AS INTEGER)

      M = 3
      IF(IPRINT.GT.1)  PRINT 199, HDR(3),M
      IF(HDR(3).LT.XMSG)  IDATA(3) = NINT(HDR(3))
      NNNNN = 3
      IF(IPRINT.GT.1)  PRINT 197, NNNNN,IDATA(NNNNN)
  197 FORMAT(5X,'IDATA(',I5,') STORED AS: ',I10)

C         STATION ELEVATION (FROM REPORTED STN. HGHT; STORED IN OUTPUT)
C          (STORED AS REAL)

      M = 4
      IF(IPRINT.GT.1)  PRINT 199, HDR(4),M
      IF(HDR(4).LT.XMSG)  RDATX(7) = NINT(HDR(4))
      NNNNN = 7
      IF(IPRINT.GT.1)  PRINT 198, NNNNN,RDATX(NNNNN)

C         SUBMODE INFORMATION
C         EDITION NUMBER (ALWAYS = 2)
C         (PACKED AS SUBMODE TIMES 10 PLUS EDITION NUMBER - INTEGER)
C          {NOTE: After 3/2002, the submode information is no longer
C                  available and is stored as missing (3).}

      M = 5
      IEDTN = 2
      IDATA(8) = (3 * 10) + IEDTN
      IF(IPRINT.GT.1)  PRINT 199, HDR(5),M
      IF(HDR(5).LT.XMSG)  IDATA(8) = (NINT(HDR(5)) * 10) + IEDTN
      NNNNN = 8
      IF(IPRINT.GT.1)  PRINT 197, NNNNN,IDATA(NNNNN)

C         AVERAGING TIME (STORED AS INTEGER)
C        (NOTE: Prior to 3/2002, this is decoded in minutes, after
C                3/2002 this is decoded in seconds - in either case
C                it is stored in minutes)

      M = 6
      IF(IPRINT.GT.1)  PRINT 199, HDR(6),M
      IF(IPRINT.GT.1)  PRINT 199, HDR(14),M
      IF(HDR(6).LT.XMSG)  THEN
         IDATA(10) = NINT(HDR(6)/60.)
      ELSE  IF(HDR(14).LT.XMSG)  THEN
         IDATA(10) = NINT(HDR(14))
      END IF
      NNNNN = 10
      IF(IPRINT.GT.1)  PRINT 197, NNNNN,IDATA(NNNNN)
C-----------------------------------------------------------------------

C         STATION IDENTIFICATION (STORED AS CHARACTER)
C         (OBTAINED FROM ENCODED WMO BLOCK/STN NUMBERS)

      STNID = '      '

C            WMO BLOCK NUMBER (STORED AS CHARACTER)

      M = 7
      IF(IPRINT.GT.1)  PRINT 199, HDR(7),M
      IF(HDR(7).LT.XMSG)  WRITE(STNID(1:2),'(I2.2)')  NINT(HDR(7))

C            WMO STATION NUMBER (STORED AS CHARACTER)

      M = 8
      IF(IPRINT.GT.1)  PRINT 199, HDR(8),M
      IF(HDR(8).LT.XMSG)  WRITE(STNID(3:5),'(I3.3)')  NINT(HDR(8))
      COB(1:4) = STNID(1:4)
      IDATA(11) = IOB
      NNNNN = 11
      IF(IPRINT.GT.1)  PRINT 196, NNNNN,COB(1:4)
  196 FORMAT(5X,'IDATA(',I5,') STORED IN CHARACTER AS: "',A4,'"')
      COB(1:4) = STNID(5:6)//'  '
      IDATA(12) = IOB
      NNNNN = 12
      IF(IPRINT.GT.1)  PRINT 196, NNNNN,COB(1:4)

cvvvvvdak port
C         LOAD THE YEAR/MONTH (STORED AS CHARACTER IN FORM YYMM)
caaaaadak port

      M = 9
      IF(IPRINT.GT.1)  PRINT 199, HDR(9),M
      IYEAR = IMSG
      IF(HDR(9).LT.XMSG) IYEAR = NINT(HDR(9))
      M = 10
      IF(IPRINT.GT.1)  PRINT 199, HDR(10),M
      IF(HDR(10).LT.XMSG.AND.IYEAR.LT.IMSG)  THEN
cvvvvvdak port
         IYEAR = MOD(IYEAR,100)
caaaaadak port
         IYEAR = NINT(HDR(10)) + (IYEAR * 100)
cvvvvvdak port
cdak     WRITE(COB,'(I6.6,2X)')  IYEAR
         WRITE(COB,'(I4.4,4X)')  IYEAR
caaaaadak port
         IDATA(5) = IOB
         NNNNN = 5
         IF(IPRINT.GT.1)  PRINT 9196, NNNNN,COB(1:6)
 9196 FORMAT(5X,'IDATA(',I5,') STORED IN CHARACTER AS: "',A6,'"')
      ELSE
         GO TO 30
      END IF

C         LOAD THE DAY/HOUR (STORED AS CHARACTER IN FORM DDHH)
C          AND THE OBSERVATION TIME (STORED AS REAL)

      M = 11
      IF(IPRINT.GT.1)  PRINT 199, HDR(11),M
      IDAY = IMSG
      IF(HDR(11).LT.XMSG)  IDAY = NINT(HDR(11))
      M = 12
      IF(IPRINT.GT.1)  PRINT 199, HDR(12),M
      IF(HDR(12).LT.XMSG.AND.IDAY.LT.IMSG)  THEN
         IHRT = NINT(HDR(12))
         M = 13
         IF(IPRINT.GT.1)  PRINT 199, HDR(13),M
         IF(HDR(13).GE.XMSG)  GO TO 30
         RMNT = HDR(13)
         RDATX(4) = NINT((IHRT * 100.) + (RMNT * 100.)/60.)
         NNNNN = 4
         IF(IPRINT.GT.1)  PRINT 198, NNNNN,RDATX(NNNNN)
         IHRT = IHRT + (IDAY * 100)
         WRITE(COB(1:4),'(I4.4)')  IHRT
         IDATA(6) = IOB
         NNNNN = 6
         IF(IPRINT.GT.1)  PRINT 196, NNNNN,COB(1:4)
      ELSE
         GO TO 30
      END IF
      RDATA(1:1200) = RDATX(1:1200)
      RETURN
   30 CONTINUE
      IRET = 4
      RETURN
      END
C> @brief Fills cat.10 into o-put array - pflr rpt
C> @author Dennis Keyser @date 2002-03-05

C> For report (subset) read out of bufr message (passed in
C> internally via bufrlib storage), calls bufrlib routine to decode
C> surface data for wind profiler report. Surface data are then
C> filled into the output array as category 10. The ouput array
C> holds a single wind profiler report in the quasi-office note 29
C> unpacked format.
C>
C> ### Program History Log:
C> Date | Programmer | Comment
C> -----|------------|--------
C> 1996-12-16 | Dennis Keyser NP22 | Initial.
C> 2002-03-05 | Dennis Keyser | Accounts for changes in input proflr (wind profiler) bufr dump file after 3/2002: surface data now all missing (mnemonics "pmsl", "wdir1","wspd1", "tmdb", "rehu", "reqv" no longer available) (will still work properly for input proflr dump files prior to 3/2002)
C>
C> @param[in] LUNIT Fortran unit number for input data file
C> @param[inout] RDATA Single wind profiler report in a quasi-office note 29 unpacked format with [out] header information filled in [in] all data initialized as missing
C>
C> @remark Called by subroutine w3unpkb7.  after 3/2002, there is no surface data available.
C>
C$$$
      SUBROUTINE UNPK7704(LUNIT,RDATA)
      CHARACTER*40  SRFC
      INTEGER  IDATA(1200)
      REAL(8) SFC_8(8)
      REAL  SFC(8),RDATA(*),RDATX(1200)
      COMMON /PK77BB/kdate(8),ldate(8),IPRINT

      SAVE

      EQUIVALENCE (RDATX,IDATA)
      DATA  XMSG/99999./
      DATA  SRFC/'PMSL WDIR1 WSPD1 TMDB REHU REQV         '/
      RDATX(1:1200) = RDATA(1:1200)
      SFC_8 = 10.0E10
      CALL UFBINT(LUNIT,SFC_8,8,1,NLEV,SRFC);SFC=SFC_8
      IF(NLEV.NE.1)  THEN
C.......................................................................
C PROBLEM: THE NUMBER OF DECODED "LEVELS" IS NOT WHAT IS EXPECTED --
         PRINT 217, NLEV
  217 FORMAT(/' ##W3UNPK77: THE NUMBER OF DECODED "LEVELS" (=',I5,') ',
     $ 'IS NOT WHAT IS EXPECTED (1) - NO SFC DATA PROCESSED'/)
         GO TO 99
C.......................................................................
      END IF

C       MSL PRESSURE (STORED AS REAL)

      M = 1
      IF(IPRINT.GT.1)  PRINT 199, SFC(1),M
  199 FORMAT(5X,'SFC HERE IS: ',F17.4,'; INDEX IS: ',I3)
      IF((SFC(1)*0.1).LT.XMSG)  RDATX(43) = NINT(SFC(1) * 0.1)
      NNNNN = 43
      IF(IPRINT.GT.1)  PRINT 198, NNNNN,RDATX(43)
  198 FORMAT(5X,'RDATA(',I5,') STORED AS: ',F10.2)

C       SURFACE HORIZONTAL WIND DIRECTION (STORED AS REAL)

      M = 2
      IF(IPRINT.GT.1)  PRINT 199, SFC(2),M
      IF(SFC(2).LT.XMSG)  RDATX(43+2) = NINT(SFC(2))
      NNNNN = 43 + 2
      IF(IPRINT.GT.1)  PRINT 198, NNNNN,RDATX(43+2)

C       SURFACE HORIZONTAL WIND SPEED (STORED AS REAL)

      M = 3
      IF(IPRINT.GT.1)  PRINT 199, SFC(3),M
      IF(SFC(3).LT.XMSG)  RDATX(43+3) = NINT(SFC(3) * 10.)
      NNNNN = 43 + 3
      IF(IPRINT.GT.1)  PRINT 198, NNNNN,RDATX(43+3)

C       SURFACE TEMPERATURE (STORED AS REAL)

      M = 4
      IF(IPRINT.GT.1)  PRINT 199, SFC(4),M
      IF(SFC(4).LT.XMSG)  RDATX(43+4) = NINT(SFC(4) * 10.)
      NNNNN = 43 + 4
      IF(IPRINT.GT.1)  PRINT 198, NNNNN,RDATX(43+4)

C       RELATIVE HUMIDITY (STORED AS REAL)

      M = 5
      IF(IPRINT.GT.1)  PRINT 199, SFC(5),M
      IF(SFC(5).LT.XMSG)  RDATX(43+5) = NINT(SFC(5))
      NNNNN = 43 + 5
      IF(IPRINT.GT.1)  PRINT 198, NNNNN,RDATX(43+5)

C       RAINFALL RATE (STORED AS REAL)

      M = 6
      IF(IPRINT.GT.1)  PRINT 199, SFC(6),M
      IF(SFC(6).LT.XMSG)  RDATX(43+6) = NINT(SFC(6) * 1.E7)
      NNNNN = 43 + 6
      IF(IPRINT.GT.1)  PRINT 198, NNNNN,RDATX(43+6)

C       SET CATEGORY COUNTERS FOR SURFACE DATA

      IDATA(35) = 1
      IDATA(36) = 43
   99 CONTINUE
      IF(IPRINT.GT.1)  PRINT *, 'IDATA(35)=',IDATA(35),'; IDATA(36)=',
     $ IDATA(36)
      RDATA(1:1200) = RDATX(1:1200)
      RETURN
      END
C> @brief Fills cat.11 into o-put array - pflr rpt
C> @author Dennis Keyser @date 2002-03-05

C> For report (subset) read out of bufr message (passed in
C> internally via bufrlib storage), calls bufrlib routine to decode
C> upper-air data for wind profiler report.  upper-air data are then
C> filled into the output array as category 11.  the ouput array
C> holds a single wind profiler report in the quasi-office note 29
C> unpacked format.
C>
C> ### Program History Log:
C> Date | Programmer | Comment
C> -----|------------|--------
C> 1996-12-16 | Dennis Keyser NP22 | Initial.
C> 1998-07-09 | Dennis Keyser | Modified wind profiler cat. 11 (height, horiz. significance, vert. significance) processing to account for updates to bufrtable mnemonics in /dcom
C> 2002-03-05 | Dennis Keyser | Accounts for changes in input proflr (wind profiler) bufr dump file after 3/2002: mnemonics "acavh", "acavv", "spp0", and "nphl" no longer available; (will still work properly for input proflr dump files prior to 3/2002)
C>
C> @param[in] LUNIT Fortran unit number for input data file
C> @param[inout] RDATA Single wind profiler report in a quasi-office note 29 unpacked format with [out] header information filled in [in] all data initialized as missing
C>
C$$$
      SUBROUTINE UNPK7705(LUNIT,RDATA)
      CHARACTER*31  UAIR1,UAIR2
      CHARACTER*16  UAIR3
      INTEGER  IDATA(1200)
      REAL(8) UAIR_8(16,255)
      REAL  UAIR(16,255),RDATA(*),RDATX(1200)
      COMMON /PK77BB/kdate(8),ldate(8),IPRINT

      SAVE

      EQUIVALENCE (RDATX,IDATA)
      DATA  XMSG/99999./
      DATA  UAIR1/'HEIT WDIR WSPD NPQC WCMP ACAVH '/
      DATA  UAIR2/'ACAVV SPP0 SDHS SDVS NPHL      '/
      DATA  UAIR3/'HAST ACAV1 ACAV2'/
      RDATX(1:1200) = RDATA(1:1200)
      NSFC = 0
      ILVL = 0
      ILC =  0
C FIRST UPPER-AIR LEVEL IS THE SURFACE INFORMATION
      IF(IPRINT.GT.1)  PRINT 1078, ILC,ILVL
 1078 FORMAT(' ATTEMPTING 1ST (SFC) LVL WITH ILC =',I5,'; NO. LEVELS ',
     $ 'PROCESSED TO NOW =',I5)
      RDATX(50+ILC) = RDATX(7)
      IF(IPRINT.GT.1)  PRINT 198, 50+ILC,RDATX(50+ILC)
  198 FORMAT(5X,'RDATA(',I5,') STORED AS: ',F10.2)
      IF(RDATX(50+ILC).LT.XMSG)  NSFC = 1
      IF(IDATA(35).GE.1)  THEN
         RDATX(50+ILC+1) = RDATX(IDATA(36)+2)
         RDATX(50+ILC+2) = RDATX(IDATA(36)+3)
      END IF
      IF(IPRINT.GT.1)  PRINT 198, 50+ILC+1,RDATX(50+ILC+1)
      IF(RDATX(50+ILC+1).LT.XMSG)  NSFC = 1
      IF(IPRINT.GT.1)  PRINT 198, 50+ILC+2,RDATX(50+ILC+2)
      IF(RDATX(50+ILC+2).LT.XMSG)  NSFC = 1
      ILVL = ILVL + 1
      ILC = ILC + 11
      IF(IPRINT.GT.1) PRINT *,'HAVE COMPLETED LEVEL ',ILVL,' WITH ',
     $ 'NSFC=',NSFC,'; GOING INTO NEXT LEVEL WITH ILC=',ILC
      UAIR_8 = 10.0E10
      CALL UFBINT(LUNIT,UAIR_8,16,255,NLEV,UAIR1//UAIR2//UAIR3)
      UAIR=UAIR_8
      IF(NLEV.EQ.0)  THEN
C.......................................................................
C PROBLEM: THE NUMBER OF DECODED "LEVELS" IS ZERO --
         IF(NSFC.EQ.0)  THEN
C ... NO UPPER AIR DATA PROCESSED
            PRINT 217
  217       FORMAT(/' ##W3UNPK77: NO UPPER-AIR DATA PROCESSED FOR THIS',
     $       ' REPORT -- NLEV = 0 AND NSFC = 0'/)
            GO TO 99
         ELSE
C ... ONLY FIRST (SURFACE) UPPER AIR LEVEL DATA PROCESSED
            PRINT 218
  218 FORMAT(/' ##W3UNPK77: NO UPPER-AIR DATA ABOVE FIRST (SURFACE) ',
     $ 'LEVEL PROCESSED FOR THIS REPORT -- NLEV = 0 AND NSFC > 0'/)
            GO TO 98
         END IF
C.......................................................................
      END IF
      IF(IPRINT.GT.1)  PRINT 1068, NLEV
 1068 FORMAT(' THIS REPORT CONTAINS ',I3,' LEVELS OF DATA (NOT ',
     $ 'INCLUDING BOTTOM -SURFACE- LEVEL)')
      DO I = 1,NLEV
         IF(IPRINT.GT.1)  PRINT 1079, ILC,ILVL
 1079 FORMAT(' ATTEMPTING NEW LEVEL WITH ILC =',I5,'; NO. LEVELS ',
     $ 'PROCESSED TO NOW =',I5)

C       HEIGHT ABOVE SEA-LEVEL (STORED AS REAL)
C        (NOTE: At one time, possibly even now, the height above sea
C               level was erroneously stored under mnemonic "HAST"
C               when it should have been stored under mnemonic "HEIT".
C               ("HAST" is defined as the height above the station.)
C               Will test first for valid data in "HEIT" - if missing,
C               then will use data in "HAST" - this will allow this
C               routine to transition w/o change when the fix is made.)

         IF(UAIR(1,I).LT.XMSG)  THEN
            M = 1
            IF(IPRINT.GT.1)  PRINT 199, UAIR(1,I),M
  199 FORMAT(5X,'UAIR HERE IS: ',F17.4,'; INDEX IS: ',I3)
            RDATX(50+ILC) = NINT(UAIR(1,I))
         ELSE
            M = 12
            IF(IPRINT.GT.1)  PRINT 199, UAIR(12,I),M
            IF(UAIR(12,I).LT.XMSG)  RDATX(50+ILC) = NINT(UAIR(12,I))
         END IF
         IF(IPRINT.GT.1)  PRINT 198, 50+ILC,RDATX(50+ILC)
         ILVL = ILVL + 1

C       HORIZONTAL WIND DIRECTION (STORED AS REAL)

         M = 2
         IF(IPRINT.GT.1)  PRINT 199, UAIR(2,I),M
         IF(UAIR(2,I).LT.XMSG)  RDATX(50+ILC+1) = NINT(UAIR(2,I))
         IF(IPRINT.GT.1)  PRINT 198, 50+ILC+1,RDATX(50+ILC+1)

C       HORIZONTAL WIND SPEED (STORED AS REAL)

         M = 3
         IF(IPRINT.GT.1)  PRINT 199, UAIR(3,I),M
         IF(UAIR(3,I).LT.XMSG)  RDATX(50+ILC+2) =NINT(UAIR(3,I) * 10.)
         IF(IPRINT.GT.1)  PRINT 198, 50+ILC+2,RDATX(50+ILC+2)

C       QUALITY CODE (STORED AS INTEGER)

         M = 4
         IF(IPRINT.GT.1)  PRINT 199, UAIR(4,I),M
         IF(UAIR(4,I).LT.XMSG)  IDATA(50+ILC+3) = NINT(UAIR(4,I))
         IF(IPRINT.GT.1)  PRINT 197, 50+ILC+3,IDATA(50+ILC+3)
  197 FORMAT(5X,'IDATA(',I5,') STORED AS: ',I10)

C       VERTICAL WIND COMPONENT (W) (STORED AS REAL)

         M = 5
         IF(IPRINT.GT.1)  PRINT 199, UAIR(5,I),M
         IF(UAIR(5,I).LT.XMSG)  RDATX(50+ILC+4) = NINT(UAIR(5,I) * 100.)
         IF(IPRINT.GT.1)  PRINT 198, 50+ILC+4,RDATX(50+ILC+4)

C       HORIZONTAL CONSENSUS NUMBER (STORED AS INTEGER)
C        (NOTE: Prior to 2/18/1999, the horizonal consensus number was
C                stored under mnemonic "ACAV1".
C               From 2/18/1999 through 3/2002, the horizontal consensus
C                number was stored under mnemonic "ACAVH".
C               After 3/2002, the horizontal consensus number is no
C                longer stored.
C               Will test first for valid data in "ACAVH" - if missing,
C                then will test for data in "ACAV1" - this will allow
C                this routine to work properly with historical data.)

         IF(IPRINT.GT.1)  PRINT 199, UAIR(6,I),M
         IF(IPRINT.GT.1)  PRINT 199, UAIR(13,I),M
         IF(UAIR(6,I).LT.XMSG)  THEN
            M = 6
            IDATA(50+ILC+5) = NINT(UAIR(6,I))
         ELSE
            M = 13
            IF(UAIR(13,I).LT.XMSG)  IDATA(50+ILC+5) = NINT(UAIR(13,I))
         END IF
         IF(IPRINT.GT.1)  PRINT 197, 50+ILC+5,IDATA(50+ILC+5)

C       VERTICAL CONSENSUS NUMBER (STORED AS INTEGER)
C        (NOTE: Prior to 2/18/1999, the vertical consensus number was
C                stored under mnemonic "ACAV2".
C               From 2/18/1999 through 3/2002, the vertical consensus
C                number was stored under mnemonic "ACAVV".
C               After 3/2002, the vertical consensus number is no
C                longer stored.
C               Will test first for valid data in "ACAVV" - if missing,
C                then will test for data in "ACAV2" - this will allow
C                this routine to work properly with historical data.)

         IF(IPRINT.GT.1)  PRINT 199, UAIR(7,I),M
         IF(IPRINT.GT.1)  PRINT 199, UAIR(14,I),M
         IF(UAIR(7,I).LT.XMSG)  THEN
            M = 7
            IDATA(50+ILC+6) = NINT(UAIR(7,I))
         ELSE
            M = 14
            IF(UAIR(14,I).LT.XMSG)  IDATA(50+ILC+6) = NINT(UAIR(14,I))
         END IF
         IF(IPRINT.GT.1)  PRINT 197, 50+ILC+6,IDATA(50+ILC+6)

C       SPECTRAL PEAK POWER (STORED AS REAL)
C        (NOTE: After 3/2002, the spectral peak power is no longer
C                stored.)

         M = 8
         IF(IPRINT.GT.1)  PRINT 199, UAIR(8,I),M
         IF(UAIR(8,I).LT.XMSG)  RDATX(50+ILC+7) = NINT(UAIR(8,I))
         IF(IPRINT.GT.1)  PRINT 198, 50+ILC+7,RDATX(50+ILC+7)

C       HORIZONTAL WIND SPEED STANDARD DEVIATION (STORED AS REAL)

         M = 9
         IF(IPRINT.GT.1)  PRINT 199, UAIR(9,I),M
         IF(UAIR(9,I).LT.XMSG)  RDATX(50+ILC+8)=NINT(UAIR(9,I) * 10.)
         IF(IPRINT.GT.1)  PRINT 198, 50+ILC+8,RDATX(50+ILC+8)

C       VERTICAL WIND COMPONENT STANDARD DEVIATION (STORED AS REAL)

         M = 10
         IF(IPRINT.GT.1)  PRINT 199, UAIR(10,I),M
         IF(UAIR(10,I).LT.XMSG)  RDATX(50+ILC+9) =NINT(UAIR(10,I) * 10.)
         IF(IPRINT.GT.1)  PRINT 198, 50+ILC+9,RDATX(50+ILC+9)

C       MODE INFORMATION (STORED AS INTEGER)
C        (NOTE: After 3/2002, the mode information is no longer stored.)

         M = 11
         IF(IPRINT.GT.1)  PRINT 199, UAIR(11,I),M
         IF(UAIR(11,I).LT.XMSG)  IDATA(50+ILC+10) = NINT(UAIR(11,I))
         IF(IPRINT.GT.1)  PRINT 197, 50+ILC+10,IDATA(50+ILC+10)
C.......................................................................
         ILC = ILC + 11
         IF(IPRINT.GT.1)  PRINT *,'HAVE COMPLETED LEVEL ',ILVL,
     $    '; GOING INTO NEXT LEVEL WITH ILC=',ILC
      ENDDO

C       SET CATEGORY COUNTERS FOR UPPER-AIR DATA

   98 CONTINUE
      IDATA(37) = ILVL
      IDATA(38) = 50
   99 CONTINUE
      IF(IPRINT.GT.1)  PRINT *, 'NSFC=',NSFC,'; IDATA(37)=',IDATA(37),
     $ '; IDATA(38)=',IDATA(38)
      RDATA(1:1200) = RDATX(1:1200)
      RETURN
      END
C> @brief Fills in header in o-put array - vadw rpt.
C> @author Dennis Keyser @date 1997-06-02

C> For report (subset) read out of bufr message (passed in
C> internally via bufrlib storage), calls bufrlib routine to decode
C> header data for nexrad (vad) wind report. Header is then filled
C> into the output array which holds a single vad wind report in the
C> quasi-office note 29 unpacked format.
C>
C> ### Program History Log:
C> Date | Programmer | Comment
C> -----|------------|--------
C> 1997-06-02 | Dennis Keyser NP22 | Initial.
C>
C> @param[in] LUNIT Fortran unit number for input data file
C> @param[inout] RDATA Single wind profiler report in a quasi-office note 29 unpacked format with [out] header information filled in [in] all data initialized as missing
C> @param[out] IRET Return code as described in w3unpk77 docblock
C>
C> @author Dennis Keyser @date 1997-06-02
      SUBROUTINE UNPK7706(LUNIT,RDATA,IRET)
      CHARACTER*8   STNID,COB
      CHARACTER*45  HDR1
      INTEGER  IDATA(1200)
      REAL(8) HDR_8(9)
      REAL  HDR(9),RDATA(*),RDATX(1200)
      COMMON /PK77BB/kdate(8),ldate(8),IPRINT

      SAVE

      EQUIVALENCE  (RDATX,IDATA),(STNID,HDR_8(4)),(COB,IOB)
      DATA  XMSG/99999./,IMSG/99999/
      DATA  HDR1/'CLAT CLON SELV RPID YEAR MNTH DAYS HOUR MINU '/
      RDATX(1:1200) = RDATA(1:1200)
      HDR_8 = 10.0E10
      CALL UFBINT(LUNIT,HDR_8,9,1,NLEV,HDR1);HDR=HDR_8
      IF(NLEV.NE.1)  THEN
C.......................................................................
C PROBLEM: THE NUMBER OF DECODED "LEVELS" IS NOT WHAT IS EXPECTED --
C  SET IRET = 6 AND RETURN
         PRINT 217, NLEV
  217 FORMAT(/' ##W3UNPK77: THE NUMBER OF DECODED "LEVELS" (=',I5,') ',
     $ 'IS NOT WHAT IS EXPECTED (1) - IRET = 6'/)
         IRET = 6
         RETURN
C.......................................................................
      END IF

C         LATITUDE (STORED AS REAL)

      M = 1
      IF(IPRINT.GT.1)  PRINT 199, HDR(1),M
  199 FORMAT(5X,'HDR HERE IS: ',F17.4,'; INDEX IS: ',I3)
      IF(HDR(1).LT.XMSG)  THEN
         RDATX(1) = NINT(HDR(1) * 100.)
         NNNNN = 1
         IF(IPRINT.GT.1)  PRINT 198, NNNNN,RDATX(NNNNN)
  198 FORMAT(5X,'RDATA(',I5,') STORED AS: ',F10.2)
      ELSE
         IRET = 2
         PRINT 102
  102    FORMAT(' *** W3UNPK77 ERROR: LAT MISSING FOR VAD WIND REPORT'/)
         RETURN
      END IF

C         LONGITUDE (STORED AS REAL)

      M = 2
      IF(IPRINT.GT.1)  PRINT 199, HDR(2),M
      IF(HDR(2).LT.XMSG)  THEN
         RDATX(2) = NINT(MOD((36000.-(HDR(2)*100.)),36000.))
         NNNNN = 2
         IF(IPRINT.GT.1)  PRINT 198, NNNNN,RDATX(NNNNN)
      ELSE
         IRET = 2
         PRINT 104
  104    FORMAT(' *** W3UNPK77 ERROR: LON MISSING FOR VAD WIND REPORT'/)
         RETURN
      END IF

C         STATION ELEVATION (FROM REPORTED STN. HGHT; STORED IN OUTPUT)
C          (STORED AS REAL)

      M = 3
      IF(IPRINT.GT.1)  PRINT 199, HDR(3),M
      IF(HDR(3).LT.XMSG)  RDATX(7) = NINT(HDR(3))
      NNNNN = 7
      IF(IPRINT.GT.1)  PRINT 198, NNNNN,RDATX(NNNNN)

C         STATION IDENTIFICATION (STORED AS CHARACTER)
C            ('99'//LAST 3-CHARACTERS OF PRODUCT SOURCE ID//'   ')

      M = 4
      IF(IPRINT.GT.1)  PRINT 299, STNID,M
  299 FORMAT(5X,'HDR HERE IS: ',9X,A8,'; INDEX IS: ',I3)
      COB(1:4) = '99'//STNID(2:3)
      IDATA(11) = IOB
      NNNNN = 11
      IF(IPRINT.GT.1)  PRINT 196, NNNNN,COB(1:4)
  196 FORMAT(5X,'IDATA(',I5,') STORED IN CHARACTER AS: "',A4,'"')
      COB(1:4) = STNID(4:4)//'   '
      IDATA(12) = IOB
      NNNNN = 12
      IF(IPRINT.GT.1)  PRINT 196, NNNNN,COB(1:4)

cvvvvvdak port
C         LOAD THE YEAR/MONTH (STORED AS CHARACTER IN FORM YYMM)
caaaaadak port

      M = 5
      IF(IPRINT.GT.1)  PRINT 199, HDR(5),M
      IYEAR = IMSG
      IF(HDR(5).LT.XMSG) IYEAR = NINT(HDR(5))
      M = 6
      IF(IPRINT.GT.1)  PRINT 199, HDR(6),M
      IF(HDR(6).LT.XMSG.AND.IYEAR.LT.IMSG)  THEN
cvvvvvdak port
         IYEAR = MOD(IYEAR,100)
caaaaadak port
         IYEAR = NINT(HDR(6)) + (IYEAR * 100)
cvvvvvdak port
cdak     WRITE(COB,'(I6.6,2X)')  IYEAR
         WRITE(COB,'(I4.4,4X)')  IYEAR
caaaaadak port
         IDATA(5) = IOB
         NNNNN = 5
         IF(IPRINT.GT.1)  PRINT 9196, NNNNN,COB(1:6)
 9196 FORMAT(5X,'IDATA(',I5,') STORED IN CHARACTER AS: "',A6,'"')
      ELSE
         GO TO 30
      END IF

C         LOAD THE DAY/HOUR (STORED AS CHARACTER IN FORM DDHH)
C          AND THE OBSERVATION TIME (STORED AS REAL)

      M = 7
      IF(IPRINT.GT.1)  PRINT 199, HDR(7),M
      IDAY = IMSG
      IF(HDR(7).LT.XMSG)  IDAY = NINT(HDR(7))
      M = 8
      IF(IPRINT.GT.1)  PRINT 199, HDR(8),M
      IF(HDR(8).LT.XMSG.AND.IDAY.LT.IMSG)  THEN
         IHRT = NINT(HDR(8))
         M = 9
         IF(IPRINT.GT.1)  PRINT 199, HDR(9),M
         IF(HDR(9).GE.XMSG)  GO TO 30
         RMNT = HDR(9)
         RDATX(4) = NINT((IHRT * 100.) + (RMNT * 100.)/60.)
         NNNNN = 4
         IF(IPRINT.GT.1)  PRINT 198, NNNNN,RDATX(NNNNN)
         IHRT = IHRT + (IDAY * 100)
         WRITE(COB(1:4),'(I4.4)')  IHRT
         IDATA(6) = IOB
         NNNNN = 6
         IF(IPRINT.GT.1)  PRINT 196, NNNNN,COB(1:4)
      ELSE
         GO TO 30
      END IF
      RDATA(1:1200) = RDATX(1:1200)
      RETURN
   30 CONTINUE
      IRET = 4
      RETURN
      END
C> @brief Fills cat. 4 into o-put array - vadw rpt
C> @author Dennis Keyser @date 1997-06-02

C> For report (subset) read out of bufr message (passed in
C> internally via bufrlib storage), calls bufrlib routine to decode
C> upper-air data for nexrad (vad) wind report. Upper-air data are
C> then filled into the output array as category 4. The ouput array
C> holds a single vad wind report in the quasi-office note 29
C> unpacked format.
C>
C> ### Program History Log:
C> Date | Programmer | Comment
C> -----|------------|--------
C> 1997-06-02 | Dennis Keyser NP22 | Initial.
C>
C> @param[in] LUNIT Fortran unit number for input data file
C> @param[inout] RDATA Single wind profiler report in a quasi-office note 29 unpacked format with [out] header information filled in [in] all data initialized as missing
C> @param[out] IRET Return code as described in w3unpk77 docblock
C>
C> @author Dennis Keyser @date 1997-06-02
      SUBROUTINE UNPK7707(LUNIT,RDATA,IRET)
      CHARACTER*1  CRMS(0:12)
      CHARACTER*8  COB
      CHARACTER*25  UAIR1
      INTEGER  IDATA(1200)
      REAL(8) UAIR_8(5,255)
      REAL  UAIR(5,255),RDATA(*),RDATX(1200)
      COMMON /PK77BB/kdate(8),ldate(8),IPRINT

      SAVE

      EQUIVALENCE (RDATX,IDATA),(COB,IOB)
      DATA  XMSG/99999./
      DATA  UAIR1/'HEIT WDIR WSPD RMSW QMWN '/
      DATA  CRMS/' ','A',' ','B',' ','C',' ','D',' ','E',' ','F',' '/
      RDATX(1:1200) = RDATA(1:1200)
      NSFC = 0
      ILVL = 0
      ILC =  0
C FIRST CATEGORY 4 LEVEL UPPER-AIR LEVEL CONTAINS ONLY HEIGHT (ELEV)
      IF(IPRINT.GT.1)  PRINT 1078, ILC,ILVL
 1078 FORMAT(' ATTEMPTING 1ST (SFC) LVL WITH ILC =',I5,'; NO. LEVELS ',
     $ 'PROCESSED TO NOW =',I5)
      RDATX(43+ILC) = RDATX(7)
      IF(IPRINT.GT.1)  PRINT 198, 43+ILC,RDATX(43+ILC)
  198 FORMAT(5X,'RDATA(',I5,') STORED AS: ',F10.2)
      IF(RDATX(43+ILC).LT.XMSG)  NSFC = 1
C NOTE: The following was added because of a problem on the sgi-ha
C       platform related to equivalencing character and non-character
C       -- for now the addition of these two lines will set the quality
C          mark for sfc. cat . 4 level to  the correct value of "    "
C          rather than to "9999" - Mary McCann notified SGI of this
C          problem on 08-21-1998
      cob = '        '
      idata(43+ilc+3) = iob
      ILVL = ILVL + 1
      ILC = ILC + 4
      IF(IPRINT.GT.1) PRINT *,'HAVE COMPLETED LEVEL ',ILVL,' WITH ',
     $ 'NSFC=',NSFC,'; GOING INTO NEXT LEVEL WITH ILC=',ILC
      UAIR_8 = 10.0E10
      CALL UFBINT(LUNIT,UAIR_8,5,255,NLEV,UAIR1);UAIR=UAIR_8
      IF(NLEV.EQ.0)  THEN
C.......................................................................
C PROBLEM: THE NUMBER OF DECODED "LEVELS" IS ZERO --
         IF(NSFC.EQ.0)  THEN
C ... NO UPPER AIR DATA PROCESSED
            PRINT 217
  217       FORMAT(/' ##W3UNPK77: NO UPPER-AIR DATA PROCESSED FOR THIS',
     $       ' REPORT -- NLEV = 0 AND NSFC = 0'/)
            GO TO 99
         ELSE
C ... ONLY FIRST (SURFACE) UPPER AIR LEVEL DATA PROCESSED
            PRINT 218
  218 FORMAT(/' ##W3UNPK77: NO UPPER-AIR DATA ABOVE FIRST (SURFACE) ',
     $ 'LEVEL PROCESSED FOR THIS REPORT -- NLEV = 0 AND NSFC > 0'/)
            GO TO 98
         END IF
C.......................................................................
      END IF
      IF(IPRINT.GT.1)  PRINT 1068, NLEV
 1068 FORMAT(' THIS REPORT CONTAINS ',I3,' LEVELS OF DATA (NOT ',
     $ 'INCLUDING BOTTOM -SURFACE- LEVEL)')
      DO I = 1,NLEV
         IF(IPRINT.GT.1)  PRINT 1079, ILC,ILVL
 1079 FORMAT(' ATTEMPTING NEW LEVEL WITH ILC =',I5,'; NO. LEVELS ',
     $ 'PROCESSED TO NOW =',I5)

C       HEIGHT ABOVE SEA-LEVEL (STORED AS REAL)

         M = 1
         IF(IPRINT.GT.1)  PRINT 199, UAIR(1,I),M
  199 FORMAT(5X,'UAIR HERE IS: ',F17.4,'; INDEX IS: ',I3)
         IF(UAIR(1,I).LT.XMSG)  THEN
            RDATX(43+ILC) = NINT(UAIR(1,I))

C       ... WE HAVE A VALID CATEGORY 4 LEVEL -- THERE IS A VALID HEIGHT

            ILVL = ILVL + 1
         ELSE

C       ... WE DO NOT HAVE A VALID CATEGORY 4 LEVEL -- THERE IS NO VALID
C            HEIGHT GO ON TO NEXT INPUT LEVEL

            IF(IPRINT.GT.1)  PRINT *, 'HEIGHT MISSING ON INPUT ',
     $       ' LEVEL ',I,', ALL OTHER DATA SET TO MSG ON THIS LEVEL'
            GO TO 10
         END IF
         IF(IPRINT.GT.1)  PRINT 198, 43+ILC,RDATX(43+ILC)

C       HORIZONTAL WIND DIRECTION (STORED AS REAL)

         M = 2
         IF(IPRINT.GT.1)  PRINT 199, UAIR(2,I),M
         IF(UAIR(2,I).LT.XMSG)  RDATX(43+ILC+1) = NINT(UAIR(2,I))
         IF(IPRINT.GT.1)  PRINT 198, 43+ILC+1,RDATX(43+ILC+1)

C       HORIZONTAL WIND SPEED (STORED AS REAL) (OUTPUT STORED
C       AS METERS/SECOND TIMES TEN, NOT IN KNOTS AS ON29 WOULD
C       INDICATE FOR CAT. 4 WIND SPEED)

         M = 3
         IF(IPRINT.GT.1)  PRINT 199, UAIR(3,I),M
         IF(UAIR(3,I).LT.XMSG)  RDATX(43+ILC+2) =NINT(UAIR(3,I) * 10.)
         IF(IPRINT.GT.1)  PRINT 198, 43+ILC+2,RDATX(43+ILC+2)

C       CONFIDENCE LEVEL (BASED ON RMS VECTOR WIND ERROR)
C       (NOTE: CONVERTED TO ORIGINAL LETTER INDICATOR AND PACKED
C        IN BYTE 4 OF CATEGORY 4 QUALITY MARKER LOCATION -- SEE
C        W3UNPK77 DOCBLOCK REMARKS 5. FOR UNPACKED VAD WIND REPORT
C        LAYOUT FOR VALUES

         M = 4
         IF(IPRINT.GT.1)  PRINT 199, UAIR(4,I),M
         IF(UAIR(4,I).LT.XMSG)  THEN

C       ... CONVERT FROM M/S TO KNOTS

CDAKCDAK    KRMS = INT(1.93333 * UAIR(4,I))
            KRMS = INT(1.9425 * UAIR(4,I))
            COB = '        '
            IF(KRMS.LT.13)  THEN
               COB(4:4) = CRMS(KRMS)
            ELSE
               COB(4:4) = 'G'
            END IF
            IDATA(43+ILC+3) = IOB
         END IF
         IF(IPRINT.GT.1)  PRINT 196, 43+ILC+3,COB(1:4)
  196 FORMAT(5X,'IDATA(',I5,') STORED IN CHARACTER AS: "',A4,'"')

C       ON29 WIND QUALITY MARKER (CURRENTLY NOT STORED)

         M = 5
         IF(IPRINT.GT.1)  PRINT 199, UAIR(5,I),M
C.......................................................................
         ILC = ILC + 4
         IF(IPRINT.GT.1)  PRINT *,'HAVE COMPLETED LEVEL ',ILVL,
     $    '; GOING INTO NEXT LEVEL WITH ILC=',ILC

   10    CONTINUE
      ENDDO

C       SET CATEGORY COUNTERS FOR UPPER-AIR DATA

   98 CONTINUE
      IDATA(19) = ILVL
   99 CONTINUE
      IF(IDATA(19).EQ.0)  THEN
         IDATA(20) = 0
         IRET = 5
      ELSE
         IDATA(20) = 43
      END IF
      IF(IPRINT.GT.1)  PRINT *, 'NSFC=',NSFC,'; IDATA(37)=',IDATA(37),
     $ '; IDATA(38)=',IDATA(38)
      RDATA(1:1200) = RDATX(1:1200)
      RETURN
      END
C> @brief Fills in header in o-put array - goes snd
C> @author Dennis Keyser @date 1998-07-09

C> For report (subset) read out of bufr message (passed in
C> internally via bufrlib storage), calls bufrlib routine to decode
C> header data for goes sounding report. Header is then filled into
C> the output array which holds a single goes sounding report in the
C> quasi-office note 29 unpacked format.
C>
C> ### Program History Log:
C> Date | Programmer | Comment
C> -----|------------|--------
C> 1997-06-05 | Dennis Keyser NP22 | Initial.
C> 1998-07-09 | Dennis Keyser | Changed char. 6 of goes stnid to be unique for two different even or odd satellite id's (every other even or odd sat. id now gets same char. 6 tag)
C>
C> @param[in] LUNIT Fortran unit number for input data file
C> @param[inout] RDATA Single wind profiler report in a quasi-office note 29 unpacked format with [out] header information filled in [in] all data initialized as missing
C> @param[in] KOUNT Number of reports processed including this one
C> @param[out] IRET Return code as described in w3unpk77 docblock
C>
C> @author Dennis Keyser @date 1998-07-09
      SUBROUTINE UNPK7708(LUNIT,RDATA,KOUNT,IRET)
      CHARACTER*1  C6TAG(3,0:3)
      CHARACTER*8   STNID,COB
      CHARACTER*35  HDR1,HDR2
      INTEGER  IDATA(1200)
      REAL(8) HDR_8(12)
      REAL  HDR(12),RDATA(*),RDATX(1200)
      COMMON /PK77BB/kdate(8),ldate(8),IPRINT
      COMMON /PK77FF/IFOV(3),KNTSAT(250:260)

      SAVE

      EQUIVALENCE  (RDATX,IDATA),(COB,IOB)
      DATA  XMSG/99999./,IMSG/99999/
      DATA  HDR1/'CLAT CLON ACAV GSDP QMRK SAID YEAR '/
      DATA  HDR2/'MNTH DAYS HOUR MINU SECO           '/


C     CURRENT LIST OF  SATELLITE IDENTIFIERS (BUFR C.F. 0-01-007)
C     -----------------------------------------------------------

C       GOES  6 -- 250     GOES  9 -- 253     GOES 12 -- 256
C       GOES  7 -- 251     GOES 10 -- 254     GOES 13 -- 257
C       GOES  8 -- 252     GOES 11 -- 255     GOES 14 -- 258

C  IDSAT =       -- EVEN1 --   --- ODD1 --   -- EVEN2 --   --- ODD2 --
C   Sat. No. -   252,256,...   253,257,...   250,254,...   251,255,...
C  IRTYP =       CLR COR UNKN  CLR COR UNKN  CLR COR UNKN  CLR COR UNKN
C                --- --- ----  --- --- ----  --- --- ----  --- --- ----

      DATA C6TAG/'I','J','?',  'L','M','?',  'O','P','?',  'Q','R','?' /

      RDATX(1:1200) = RDATA(1:1200)
      HDR_8 = 10.0E10
      CALL UFBINT(LUNIT,HDR_8,12,1,NLEV,HDR1//HDR2);HDR=HDR_8
      IF(NLEV.NE.1)  THEN
C.......................................................................
C PROBLEM: THE NUMBER OF DECODED "LEVELS" IS NOT WHAT IS EXPECTED --
C  SET IRET = 6 AND RETURN
         PRINT 217, NLEV
  217 FORMAT(/' ##W3UNPK77: THE NUMBER OF DECODED "LEVELS" (=',I5,') ',
     $ 'IS NOT WHAT IS EXPECTED (1) - IRET = 6'/)
         IRET = 6
         RETURN
C.......................................................................
      END IF

C         LATITUDE (STORED AS REAL)

      M = 1
      IF(IPRINT.GT.1)  PRINT 199, HDR(1),M
  199 FORMAT(5X,'HDR HERE IS: ',F17.4,'; INDEX IS: ',I3)
      IF(HDR(1).LT.XMSG)  THEN
         RDATX(1) = NINT(HDR(1) * 100.)
         NNNNN = 1
         IF(IPRINT.GT.1)  PRINT 198, NNNNN,RDATX(NNNNN)
  198 FORMAT(5X,'RDATA(',I5,') STORED AS: ',F10.2)
      ELSE
         IRET = 2
         PRINT 102
  102    FORMAT(' *** W3UNPK77 ERROR: LAT MISSING FOR GOES SOUNDING'/)
         RETURN
      END IF

C         LONGITUDE (STORED AS REAL)

      M = 2
      IF(IPRINT.GT.1)  PRINT 199, HDR(2),M
      IF(HDR(2).LT.XMSG)  THEN
         RDATX(2) = NINT(MOD((36000.-(HDR(2)*100.)),36000.))
         NNNNN = 2
         IF(IPRINT.GT.1)  PRINT 198, NNNNN,RDATX(NNNNN)
      ELSE
         IRET = 2
         PRINT 104
  104    FORMAT(' *** W3UNPK77 ERROR: LON MISSING FOR GOES SOUNDING'/)
         RETURN
      END IF

C         NUMBER OF FIELDS OF VIEW - SAMPLE SIZE (STORED AS INTEGER)

      M = 3
      IF(IPRINT.GT.1)  PRINT 199, HDR(3),M
      IF(HDR(3).LT.XMSG)  IDATA(3) = NINT(HDR(3))
      NNNNN = 3
      IF(IPRINT.GT.1)  PRINT 197, NNNNN,IDATA(NNNNN)
  197 FORMAT(5X,'IDATA(',I5,') STORED AS: ',I10)

C         STATION ELEVATION (FROM HEIGHT OF FIRST -SURFACE- LEVEL)
C          (STORED AS REAL) -- STORED IN SUBROUTINE UNPK7709


C         RETRIEVAL TYPE (GEOSTATIONARY SATELLITE DATA-PROCESSING
C         TECHNIQUE USED) (STORED AS INTEGER)

      M = 4
      IF(IPRINT.GT.1)  PRINT 199, HDR(4),M
      IF(HDR(4).LT.XMSG)  IDATA(8) = NINT(HDR(4))
      IRTYP = 3
      IF(IDATA(8).EQ.21)  THEN
         IRTYP = 1
      ELSE  IF(IDATA(8).EQ.23)  THEN
         IRTYP = 2
      END IF
      NNNNN = 8
      IF(IPRINT.GT.1)  PRINT 197, NNNNN,IDATA(NNNNN)

C         PRODUCT QUALITY BIT FLAGS - QUALITY INFO. (STORED AS INTEGER)

      M = 5
      IF(IPRINT.GT.1)  PRINT 199, HDR(5),M
      IF(HDR(5).LT.XMSG)  IDATA(10) = NINT(HDR(5))
      NNNNN = 10
      IF(IPRINT.GT.1)  PRINT 197, NNNNN,IDATA(NNNNN)

C         STATION IDENTIFICATION (STORED AS CHARACTER)
C         (FIRST 5-CHARACTERS OBTAINED FROM 5-DIGIT COUNT NUMBER,
C          6'TH CHARACTER OBTAINED FROM SAT. ID/RETRIEVAL TYPE TAG)

      WRITE(STNID(1:5),'(I5.5)') MIN(KOUNT,99999)

C DECODE THE SATELLITE ID

      M = 6
      IDSAT = 2
      IF(IPRINT.GT.1)  PRINT 199, HDR(6),M
      IF(HDR(6).LT.XMSG)  THEN
         IDSAT = MOD(NINT(HDR(6)),4)
         IF(NINT(HDR(6)).GT.249.AND.NINT(HDR(6)).LT.260)  THEN
            KNTSAT(NINT(HDR(6))) = KNTSAT(NINT(HDR(6))) + 1
         ELSE
            KNTSAT(260) = KNTSAT(260) + 1
         END IF
      END IF
      IF(IPRINT.GT.1)  PRINT 2197, IDSAT,IRTYP
 2197 FORMAT(5X,'IDSAT IS: ',I10,', IRTYP IS: ',I10)
      STNID(6:6) = C6TAG(IRTYP,IDSAT)
      COB(1:4) = STNID(1:4)
      IDATA(11) = IOB
      NNNNN = 11
      IF(IPRINT.GT.1)  PRINT 196, NNNNN,COB(1:4)
  196 FORMAT(5X,'IDATA(',I5,') STORED IN CHARACTER AS: "',A4,'"')
      COB(1:4) = STNID(5:6)//'  '
      IDATA(12) = IOB
      NNNNN = 12
      IF(IPRINT.GT.1)  PRINT 196, NNNNN,COB(1:4)

cvvvvvdak port
C         LOAD THE YEAR/MONTH (STORED AS CHARACTER IN FORM YYMM)
caaaaadak port

      M = 7
      IF(IPRINT.GT.1)  PRINT 199, HDR(7),M
      IYEAR = IMSG
      IF(HDR(7).LT.XMSG) IYEAR = NINT(HDR(7))
      M = 8
      IF(IPRINT.GT.1)  PRINT 199, HDR(8),M
      IF(HDR(8).LT.XMSG.AND.IYEAR.LT.IMSG)  THEN
cvvvvvdak port
         IYEAR = MOD(IYEAR,100)
caaaaadak port
         IYEAR = NINT(HDR(8)) + (IYEAR * 100)
cvvvvvdak port
cdak     WRITE(COB,'(I6.6,2X)')  IYEAR
         WRITE(COB,'(I4.4,4X)')  IYEAR
caaaaadak port
         IDATA(5) = IOB
         NNNNN = 5
         IF(IPRINT.GT.1)  PRINT 9196, NNNNN,COB(1:6)
 9196 FORMAT(5X,'IDATA(',I5,') STORED IN CHARACTER AS: "',A6,'"')
      ELSE
         GO TO 30
      END IF

C         LOAD THE DAY/HOUR (STORED AS CHARACTER IN FORM DDHH)
C          AND THE OBSERVATION TIME (STORED AS REAL)

      M = 9
      IF(IPRINT.GT.1)  PRINT 199, HDR(9),M
      M = 10
      IF(IPRINT.GT.1)  PRINT 199, HDR(10),M
      IF(HDR(10).LT.XMSG.AND.HDR(9).LT.IMSG)  THEN
         M = 11
         IF(IPRINT.GT.1)  PRINT 199, HDR(11),M
         IF(HDR(11).GE.XMSG)  GO TO 30
         M = 12
         IF(IPRINT.GT.1)  PRINT 199, HDR(12),M
         IF(HDR(12).GE.XMSG)  GO TO 30
         RDATX(4) = NINT(((HDR(10) + ((HDR(11) * 60.) + HDR(12))/3600.)
     $    * 100.) + 0.0000000001)
         NNNNN = 4
         IF(IPRINT.GT.1)  PRINT 198, NNNNN,RDATX(NNNNN)
         IDAYHR = NINT(HDR(10)) + (NINT(HDR(9)) * 100)
         WRITE(COB(1:4),'(I4.4)')  IDAYHR
         IDATA(6) = IOB
         NNNNN = 6
         IF(IPRINT.GT.1)  PRINT 196, NNNNN,COB(1:4)
      ELSE
         GO TO 30
      END IF
      RDATA(1:1200) = RDATX(1:1200)
      RETURN
   30 CONTINUE
      IRET = 4
      RETURN
      END
C> @brief Fills cat. 12,8 to o-put array -goes sndg
C> @author Dennis Keyser @date 1997-06-05

C> For report (subset) read out of bufr message (passed in
C> internally via bufrlib storage), calls bufrlib routine to decode
C> upper-air (sounding) and additional data for goes sounding. Upper-
C> air data are then filled into the output array as category 12
C> (satellite sounding) and additional data are filled as category 8.
C> The ouput array holds a single goes sounding in the quasi-office
C> note 29 unpacked format.
C>
C> ### Program History Log:
C> Date | Programmer | Comment
C> -----|------------|--------
C> 1997-06-05 | Dennis Keyser NP22 | Initial.
C>
C> @param[in] LUNIT Fortran unit number for input data file
C> @param[inout] RDATA Single wind profiler report in a quasi-office note 29 unpacked format with [out] header information filled in [in] all data initialized as missing
C> @param[out] IRET Return code as described in w3unpk77 docblock
C>
C> @author Dennis Keyser @date 1997-06-05
      SUBROUTINE UNPK7709(LUNIT,RDATA,IRET)
      CHARACTER*1  CQMFLG
      CHARACTER*8  COB
      CHARACTER*37  CAT8A,CAT8B
      CHARACTER*48  UAIR1,RAD1
      INTEGER  IDATA(1200),ICDFG(12)
      REAL(8) UAIR_8(4,255),CAT8_8(12),RTCSF_8,RAD_8(2,255)
      REAL  UAIR(4,255),CAT8(12),RDATA(*),RDATX(1200),SC8(12),RAD(2,255)
      COMMON /PK77BB/kdate(8),ldate(8),IPRINT
      COMMON /PK77FF/IFOV(3),KNTSAT(250:260)

      SAVE

      EQUIVALENCE (RDATX,IDATA),(COB,IOB)
      DATA  XMSG/99999./,YMSG/99999.8/
      DATA  UAIR1/'PRLC HGHT TMDB TMDP                             '/
      DATA  RAD1 /'CHNM TMBR                                       '/
      DATA  CAT8A/'GLFTI PH2O PH2O19 PH2O97 PH2O73 TMSK '/
      DATA  CAT8B/'GCDTT CDTP CLAM   SIDU   SOEL   ELEV '/
      DATA ICDFG/ 50 , 51 , 52 , 53 , 54 , 55 , 56 ,57 ,58,59, 60 , 61 /
      DATA   SC8/100.,100.,100.,100.,100.,100.,100.,10.,1.,1.,100.,100./
      RDATX(1:1200) = RDATA(1:1200)

C ALL NON-RADIANCE DATA WILL BE Q.C.'D ACCORDING TO NUMBER OF FIELDS-OF-
C  VIEW FOR RETRIEVAL:  0-2 --> BAD, 3-9 --> SUSPECT, 10-25 OR MISSING
C   --> NEUTRAL

      CQMFLG = ' '
      IF(IDATA(3).LT.3)  THEN
         CQMFLG = 'F'
         IFOV(1) = IFOV(1) + 1
      ELSE  IF(IDATA(3).LT.10.OR.IDATA(10).EQ.1)  THEN
         CQMFLG = 'Q'
         IF(IDATA(3).LT.10)  IFOV(2) = IFOV(2) + 1
      END IF
      IF(IDATA(3).GT.9)  IFOV(3) = IFOV(3) + 1

C***********************************************************************
C                  FILL CATEGORY 12 PART OF OUTPUT
C***********************************************************************

      ILVL = 0
      ILC =  0
      UAIR_8 = 10.0E10
      CALL UFBINT(LUNIT,UAIR_8,4,255,NLEV,UAIR1);UAIR=UAIR_8
      IF(NLEV.EQ.0)  THEN
C.......................................................................
C PROBLEM: THE NUMBER OF DECODED "LEVELS" IS ZERO --
         PRINT 217
  217    FORMAT(/' ##W3UNPK77: NO UPPER-AIR (SOUNDING) DATA PROCESSED ',
     $   'FOR THIS  REPORT -- NLEV = 0'/)
         GO TO 98
      ELSE  IF(NLEV.GT.50)  THEN
C.......................................................................
C PROBLEM: THE NUMBER OF DECODED "LEVELS" IS GREATER THAN LIMIT OF 50 --
         PRINT 218
  218    FORMAT(/' ##W3UNPK77: NO UPPER-AIR (SOUNDING) DATA PROCESSED ',
     $   'FOR THIS  REPORT -- NLEV > 50'/)
         GO TO 98
C.......................................................................
      END IF
      IF(IPRINT.GT.1)  PRINT 1068, NLEV
 1068 FORMAT(' THIS REPORT CONTAINS',I4,' INPUT LEVELS OF SOUNDING ',
     $ 'DATA')
      DO I = 1,NLEV
         IF(IPRINT.GT.1)  PRINT 1079, I,ILC,ILVL
 1079 FORMAT(' ATTEMPTING NEW CAT. 12 INPUT LEVEL NUMBER',I4,' WITH ',
     $ 'ILC =',I5,'; NO. LEVELS PROCESSED TO NOW =',I5)

C       LEVEL PRESSURE (STORED AS REAL)

         M = 1
         IF(IPRINT.GT.1)  PRINT 199, UAIR(1,I),M
  199 FORMAT(5X,'UAIR HERE IS: ',F17.4,'; INDEX IS: ',I3)
         IF(I.EQ.1)  THEN
            PSFC = UAIR(1,I) * 0.1
         ELSE  IF(UAIR(1,I)*0.1.GE.YMSG)  THEN
C WE DO NOT HAVE A VALID CATEGORY 12 LEVEL -- THERE IS NO VALID PRESSURE
C  -- GO ON TO NEXT INPUT LEVEL (IF SFC LEVEL MSG, CONTINUE PROCESSING)
            IF(IPRINT.GT.1)  PRINT *, 'PRESSURE MISSING ON INPUT',
     $       ' LEVEL ',I,', SKIP THE PROCESSING OF THIS LEVEL'
            GO TO 10
         ELSE  IF(UAIR(1,I)*0.1.GE.PSFC)  THEN
C WE DO NOT HAVE A VALID CATEGORY 12 LEVEL -- THE INPUT LEVEL PRESSURE
C  IS BELOW THE SURFACE PRESSURE -- GO ON TO THE NEXT INPUT LEVEL
            IF(IPRINT.GT.1)  PRINT *,'PRESSURE ON INPUT LEVEL ',I,
     $       ' IS BELOW GROUND, SKIP THE PROCESSING OF THIS LEVEL'
            GO TO 10
         END IF

C WE HAVE A VALID CATEGORY 12 LEVEL -- THERE IS A VALID PRESSURE

         IF(UAIR(1,I)*0.1.LT.XMSG)  RDATX(43+ILC) = NINT(UAIR(1,I)*0.1)
         ILVL = ILVL + 1
         IF(IPRINT.GT.1)  PRINT 198, 43+ILC,RDATX(43+ILC)
  198 FORMAT(5X,'RDATA(',I5,') STORED AS: ',F10.2)

C       GEOPOTENTIAL HEIGHT (STORED AS REAL)

         M = 2
         IF(IPRINT.GT.1)  PRINT 199, UAIR(2,I),M
         IF(UAIR(2,I).LT.XMSG)  RDATX(43+ILC+1) = NINT(UAIR(2,I))
         IF(IPRINT.GT.1)  PRINT 198, 43+ILC+1,RDATX(43+ILC+1)
         IF(I.EQ.1)  THEN
            IF(IPRINT.GT.1)  PRINT *, 'THIS IS SURFACE LEVEL, SO ',
     $       'STORE HEIGHT ALSO AS ELEVATION IN HEADER'
            IF(UAIR(2,1).LT.XMSG)  RDATX(7) = NINT(UAIR(2,1))
            NNNNN = 7
            IF(IPRINT.GT.1)  PRINT 198, NNNNN,RDATX(NNNNN)
         END IF

C       TEMPERATURE (STORED AS REAL)

         M = 3
         IF(IPRINT.GT.1)  PRINT 199, UAIR(3,I),M
         ITMP = NINT(UAIR(3,I)*100.)
         IF(UAIR(3,I).LT.XMSG)
     $    RDATX(43+ILC+2) = NINT((ITMP - 27315) * 0.1)
         IF(IPRINT.GT.1)  PRINT 198, 43+ILC+2,RDATX(43+ILC+2)

C       DEWPOINT TEMPERATURE (STORED AS REAL)

         M = 4
         IF(IPRINT.GT.1)  PRINT 199, UAIR(4,I),M
         ITMP = NINT(UAIR(4,I)*100.)
         IF(UAIR(4,I).LT.XMSG)
     $    RDATX(43+ILC+3) = NINT((ITMP - 27315) * 0.1)
         IF(IPRINT.GT.1)  PRINT 198, 43+ILC+3,RDATX(43+ILC+3)

C       QUALITY MARKERS (STORED AS CHARACTER)

         COB = CQMFLG//CQMFLG//CQMFLG//'     '
         IDATA(43+ILC+6) = IOB
         IF(IPRINT.GT.1)  PRINT 196, 43+ILC+6,COB(1:4)
  196 FORMAT(5X,'IDATA(',I5,') STORED IN CHARACTER AS: "',A4,'"')
C.......................................................................
         ILC = ILC + 7
         IF(I+1.LE.NLEV.AND.IPRINT.GT.1)  PRINT *,'HAVE COMPLETED ',
     $    'LEVEL ',ILVL,'; GOING INTO NEXT LEVEL WITH ILC=',ILC

   10    CONTINUE
      ENDDO

C       SET CATEGORY COUNTERS FOR CATEGORY 12 (SOUNDING) DATA

      IDATA(39) = ILVL
   98 CONTINUE
      IF(IPRINT.GT.1)  PRINT *, IDATA(39),' CAT. 12 LEVELS PROCESSED'
      IF(IDATA(39).GT.0)  IDATA(40) = 43

C***********************************************************************
C                  FILL CATEGORY 8 PART OF OUTPUT
C                  WILL ATTEMPT TO FILL 12 "LEVELS"
C LVL  1- LIFTED INDEX (DEG. K X 100 - RELATIVE) -------- CODE FIG. 250.
C LVL  2- TOTAL COLUMN PRECIPITABLE WATER (MM X 100) ---- CODE FIG. 251.
C LVL  3- 1. TO .9 SIGMA LAYER PRECIP. WATER (MM X 100) - CODE FIG. 252.
C LVL  4- .9 TO .7 SIGMA LAYER PRECIP. WATER (MM X 100) - CODE FIG. 253.
C LVL  5- .7 TO .3 SIGMA LAYER PRECIP. WATER (MM X 100) - CODE FIG. 254.
C LVL  6- SKIN TEMPERATURE (DEG. K X 100) --------------- CODE FIG. 255.
C LVL  7- CLOUD TOP TEMPERATURE (DEG. K X 100) ---------- CODE FIG. 256.
C LVL  8- CLOUD TOP PRESSURE (MB X 10) ------------------ CODE FIG. 257.
C LVL  9- CLOUD AMOUNT (C. FIG. BUFR TABLE 0-20-011) ---- CODE FIG. 258.
C LVL 10- INSTR. DATA USED IN PROC.
C                       (C. FIG. BUFR TABLE 0-02-021) --- CODE FIG. 259.
C LVL 11- SOLAR ZENITH ANGLE (SOLAR ELEV) (DEG. X 100) -- CODE FIG. 260.
C LVL 12- SATELLITE ZENITH ANGLE (ELEV) (DEG. X 100)  --- CODE FIG. 261.
C
C     IF DATA ONE ANY LEVEL ARE MISSING, THAT LEVEL IS NOT PROCESSED
C***********************************************************************

      ILVL = 0
      ILC = 0
      CAT8_8 = 10.0E10
      CALL UFBINT(LUNIT,CAT8_8,12,1,NLEV8,CAT8A//CAT8B);CAT8=CAT8_8
      IF(NLEV8.NE.1)  THEN
         IF(NLEV8.EQ.0)  THEN
C.......................................................................
C PROBLEM: THE NUMBER OF DECODED "LEVELS" IS ZERO --
            PRINT 318
  318 FORMAT(/' ##W3UNPK77: NO ADDITIONAL (CAT. 8) DATA PROCESSED FOR ',
     $ 'THIS  REPORT -- NLEV8 = 0'/)
            GO TO 99
C.......................................................................
         ELSE
C.......................................................................
C PROBLEM: THE NUMBER OF DECODED "LEVELS" IS NOT WHAT IS EXPECTED --
C  SET IRET = 7 AND RETURN
            PRINT 219, NLEV8
  219 FORMAT(/' ##W3UNPK77: THE NUMBER OF DECODED "LEVELS" (=',I5,') ',
     $ 'IS NOT WHAT IS EXPECTED (1) - IRET = 7'/)
            IRET = 7
            RETURN
C.......................................................................
         END IF
      END IF

C THE TEMPERATURE CHANNEL SELECTION FLAG WILL BE USED LATER TO
C  DETERMINE Q. MARK FOR SKIN TEMPERATURE (IF 0 - OK, OTHERWISE - BAD)

      RTCSF_8 = 10.0E10
      CALL UFBINT(LUNIT,RTCSF_8,1,1,NLEV0,'TCSF');RTCSF=RTCSF_8
      ITCSF = 1
      M = 1
      IF(IPRINT.GT.1)  PRINT 299, RTCSF,M
  299 FORMAT(5X,'RTCSF HERE IS: ',F17.4,'; INDEX IS: ',I3)
      IF(RTCSF.LT.XMSG)  ITCSF = NINT(RTCSF)
      IF(IPRINT.GT.1)  PRINT 1798, ITCSF
 1798 FORMAT(5X,'ITCSF IS: ',I10)

C LOOP THROUGH THE 12 POSSIBLE ADDITIONAL DATA

      DO M = 1,12
         IF(IPRINT.GT.1)  PRINT 6079, M,ILC,ILVL
 6079 FORMAT(' ATTEMPTING MISCEL. INPUT',I5,' WITH ILC =',I5,'; NO. ',
     $ 'OUTPUT CAT.  8 LVLS PROCESSED TO NOW =',I5)
         IF(IPRINT.GT.1)  PRINT 399, CAT8(M),M
  399 FORMAT(5X,'CAT8 HERE IS: ',F17.4,'; INDEX IS: ',I3)
         IF(CAT8(M).LT.XMSG)  THEN

C WE HAVE A VALID CATEGORY 8 "LEVEL"

            ILVL = ILVL + 1

C STORE THE DATUM IN WORD 1 OF THE CAT. 8 LEVEL

            RDATX(393+ILC) = NINT(CAT8(M) * SC8(M))
            IF(IPRINT.GT.1)  PRINT 198, 393+ILC,RDATX(393+ILC)

C STORE THE CAT. 8 CODE FIGURE IN WORD 2 OF THE CAT. 8 LEVEL

            RDATX(393+ILC+1) = REAL(200+ICDFG(M))
            IF(IPRINT.GT.1)  PRINT 198, 393+ILC+1,RDATX(393+ILC+1)

C STORE THE QUALITY MARKER IN BYTE 1 OF WORD 3 OF THE CAT. 8 LEVEL

            COB = CQMFLG//'       '

C IF THIS DATUM IS SKIN TEMPERATURE AND THE TEMPERATURE CHANNEL
C  SELECTION FLAG IS BAD (.NE. 0), SET QUALITY MARKER TO "F"

            IF(M.EQ.6.AND.ITCSF.NE.0)  COB(1:1) = 'F'
            IDATA(393+ILC+2) = IOB
            IF(IPRINT.GT.1)  PRINT 196, 393+ILC+2,COB(1:4)
            ILC = ILC + 3
            IF(M.LT.12.AND.IPRINT.GT.1) PRINT *,'HAVE COMPLETED OUTPUT',
     $       ' LVL',ILVL,'; GOING INTO NEXT INPUT DATUM WITH ILC=',ILC
         ELSE
            IF(IPRINT.GT.1)  PRINT *, 'DATUM MISSING ON INPUT ',M,
     $       ', GO ON TO NEXT INPUT DATUM (NO. LVLS PROCESSED SO ',
     $       'FAR=',ILVL,'; ILC=',ILC,')'
         END IF
      ENDDO

C       SET CATEGORY COUNTERS FOR CATEGORY 8 (ADDITIONAL) DATA

      IDATA(27) = ILVL
   99 CONTINUE
      IF(IPRINT.GT.1)  PRINT *, IDATA(27),' CAT. 08 LEVELS PROCESSED'
      IF(IDATA(27).GT.0)  IDATA(28) = 393

C***********************************************************************
C              FILL CATEGORY 13 PART OF OUTPUT (RADIANCES)
C***********************************************************************

      ILVL = 0
      ILC =  0
      RAD_8 = 10.0E10
      CALL UFBINT(LUNIT,RAD_8,2,255,NLEV13,RAD1);RAD=RAD_8
      IF(NLEV13.EQ.0)  THEN
C.......................................................................
C PROBLEM: THE NUMBER OF DECODED "LEVELS" IS ZERO --
         PRINT 417
  417    FORMAT(/' ##W3UNPK77: NO RADIANCE DATA PROCESSED FOR THIS ',
     $    'REPORT -- NLEV13 = 0'/)
         GO TO 100
      ELSE  IF(NLEV13.GT.60)  THEN
C.......................................................................
C PROBLEM: THE NUMBER OF DECODED "LEVELS" IS GREATER THAN LIMIT OF 60 --
         PRINT 418
  418    FORMAT(/' ##W3UNPK77: NO RADIANCE DATA PROCESSED FOR THIS ',
     $    'REPORT -- NLEV13 > 60'/)
         GO TO 100
C.......................................................................
      END IF
      IF(IPRINT.GT.1)  PRINT 2068, NLEV13
 2068 FORMAT(' THIS REPORT CONTAINS',I4,' INPUT LEVELS (CHANNELS) OF ',
     $ 'RADIANCE DATA')
      DO I = 1,NLEV13
         IF(IPRINT.GT.1)  PRINT 2079, I,ILC,ILVL
 2079 FORMAT(' ATTEMPTING NEW CAT. 13 INPUT "LEVEL" NUMBER',I4,' WITH ',
     $ 'ILC =',I5,'; NO. LEVELS (CHANNELS) PROCESSED TO NOW =',I5)

C       CHANNEL NUMBER (STORED AS INTEGER)

         M = 1
         IF(IPRINT.GT.1)  PRINT 499, RAD(1,I),M
  499 FORMAT(5X,'RAD  HERE IS: ',F17.4,'; INDEX IS: ',I3)
         IF(RAD(1,I).GE.YMSG)  THEN
C WE DO NOT HAVE A VALID CATEGORY 13 LEVEL -- THERE IS NO VALID CHANNEL
C  NUMBER -- GO ON TO NEXT INPUT LEVEL
            IF(IPRINT.GT.1)  PRINT *, 'CHANNEL NUMBER MISSING ON INPUT',
     $       ' LEVEL ',I,', SKIP THE PROCESSING OF THIS LEVEL'
            GO TO 210
         END IF

C WE HAVE A VALID CATEGORY 13 LEVEL -- THERE IS A VALID CHANNEL NUMBER

         IDATA(429+ILC) = NINT(RAD(1,I))
         ILVL = ILVL + 1
         IF(IPRINT.GT.1)  PRINT 197, 429+ILC,IDATA(429+ILC)
  197 FORMAT(5X,'IDATA(',I5,') STORED AS: ',I10)

C       BRIGHTNESS TEMPERATURE (STORED AS REAL)

         M = 2
         IF(IPRINT.GT.1)  PRINT 499, RAD(2,I),M
         IF(RAD(2,I).LT.XMSG)  RDATX(429+ILC+1) = NINT(RAD(2,I) * 100.)
         IF(IPRINT.GT.1)  PRINT 198, 429+ILC+1,RDATX(429+ILC+1)

C       QUALITY MARKERS (STORED AS CHARACTER)

         COB = '        '
         IDATA(429+ILC+2) = IOB
         IF(IPRINT.GT.1)  PRINT 196, 429+ILC+2,COB(1:4)
C.......................................................................
         ILC = ILC + 3
         IF(I+1.LE.NLEV13.AND.IPRINT.GT.1)  PRINT *,'HAVE COMPLETED ',
     $    'LEVEL ',ILVL,'; GOING INTO NEXT LEVEL WITH ILC=',ILC

  210    CONTINUE
      ENDDO

C       SET CATEGORY COUNTERS FOR CATEGORY 13 (RADIANCE) DATA

      IDATA(41) = ILVL
  100 CONTINUE
      IF(IPRINT.GT.1)  PRINT *, IDATA(41),' CAT. 13 LEVELS PROCESSED'
      IF(IDATA(41).GT.0)  IDATA(42) = 429

      IF(IDATA(27)+IDATA(39)+IDATA(41).EQ.0)  IRET = 5

      IF(IPRINT.GT.1)  PRINT *,'IDATA(39)=',IDATA(39),'; IDATA(40)=',
     $ IDATA(40),'; IDATA(27)=',IDATA(27),'; IDATA(28)=',IDATA(28),
     $ '; IDATA(41)=',IDATA(41),'; IDATA(42)=',IDATA(42)

      RDATA(1:1200) = RDATX(1:1200)
      RETURN
      END

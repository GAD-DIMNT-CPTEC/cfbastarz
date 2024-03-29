C> @file
C> @brief Printer contour subroutine.
C> @author Ralph Jones @date 1989-10-13

C> Prints a two-dimensional grid of any shape, with
C> contouring, if desired. grid values are scaled according to
C> to constants specified by the programer, rounded, and printed
C> as 4,3, or 2 digit integers with sign, the sign marking the
C> grid position of the printed number. if contouring is requested,
C> bessel's interpolation formula is used to optain the contour lines.
C> contours are indicated by alphabetic characters ranging from a to
C> h or numeric characters from 0 to 9. contour origin and interval
C> are specified by the programmer in terms of printed values.
C>
C> Program history log:
C> - Ralph Jones 1989-10-13
C> - Ralph Jones 1992-05-02 Add save
C>
C> @param[in] RDATA  Real array of grid data to be printed.
C> @param[in] KTBL Integer array with shape of array.
C> @param[in] CNST Real array of four elements, used in
C> scaling for printing and contouring.
C> @param[in] TITLE  Is a array of 132 characters or less of
C> hollerith data, 1st char. must be blank.
C> printed at bottom of the map.
C> @param[in] KRECT 1 if grid is rectangular, 0 otherwise.
C> @param[in] KCONTR 1 for contouring , 0 otherwise.
C> @param[in] LINEV 0 is for 6 lines per vertical inch,
C> non-zero 8 lines per vertical inch.
C> @param[in] IWIDTH Number of characters in print line,
C> 132 is standard printer.
C>
C> @note Normal subroutine return, unless number of rows is greater than 200,
C> prints error message and exits.
C>
C> @author Ralph Jones @date 1989-10-13
      SUBROUTINE W3FP05(RDATA,KTBL,CNST,TITLE,KRECT,KCONTR,LINEV,IWIDTH)
C
       REAL            CNST(4)
       REAL            RDATA(1)
       REAL            RWA(28)
       REAL            RWB(28)
       REAL            RWC(28)
       REAL            RWD(28)
       REAL            VDJA(29)
       REAL            VDJB(28)
       REAL            VDJC(28)
C
       INTEGER         KALFA(16)
       INTEGER         KALPH(20)
       INTEGER         KHTBL(10)
       INTEGER         KLINE(126)
       INTEGER         KLINES(132)
       INTEGER         KNUMB(20)
       INTEGER         KRLOC(200)
       INTEGER         KTBL(407)
       INTEGER         OUTPUT
       INTEGER         PAGNL
       INTEGER         PAGNR
       INTEGER         PAGN3
       INTEGER         PCCNT
       INTEGER         PCFST
       INTEGER         PGCNT
       INTEGER         PGCNTA
       INTEGER         PGFST
       INTEGER         PGFSTA
       INTEGER         PGMAX
C
       LOGICAL         DONE
       LOGICAL         LCNTR
       LOGICAL         RECT
C
       CHARACTER*1     TITLE(*)
C
       EQUIVALENCE     (CRMX,VDJA(29))
       EQUIVALENCE     (KLINE(1),KLINES(8))
       EQUIVALENCE     (VDJC(1),RWA(1))
C
C      ... THE VAULUE CRMX IS MACHINE DEPENDENT, IT SHOULD BE
C      ... SET TO A VALUE A LITTLE LESS THAN THE LARGEST POSITIVE
C      ... FLOATING  POINT NUMBER FOR THE COMPUTER.
C
       SAVE
C
       DATA  CRMX  /10.E70/
       DATA  KALFA/
     A 1HA,1H ,1HB,1H ,1HC,1H ,1HD,1H ,1HE,1H ,1HF,
     B 1H ,1HG,1H ,1HH,1H /
       DATA  KHASTR/1H*/
       DATA  KHBLNK/1H /
       DATA  KHDOLR/1H$/
       DATA  KHMNS /1H-/
       DATA  KHPLUS/1H+/
       DATA  KHRSTR/1H1/
       DATA  KHTBL /1H0,1H1,1H2,1H3,1H4,1H5,1H6,1H7,1H8,1H9/
C
C     ... LIMNRW IS LIMIT ON NUMBER OF ROWS ALLOWED
C     ...   AND IS DIMENSION OF KRLOC ...
C
       DATA  LIMNRW/200/
       DATA  KNUMB /1H0,1H ,1H1,1H ,1H2,1H ,1H3,1H ,1H4,1H ,
     1              1H5,1H ,1H6,1H ,1H7,1H ,1H8,1H ,1H9,1H /
       DATA  OUTPUT/6/
       DATA  R5    /.2/
       DATA  R50   /.02/
C
 8000  FORMAT (1H0,10X,44HERROR FROM W3FP05 ... NUMBER OF ROWS IN YOUR,
     1         9H ARRAY = ,I4,24H WHICH EXCEEDS LIMIT OF ,I4)
 8100  FORMAT (1HT)
 8200  FORMAT (1HS)
 8300  FORMAT (1H /1H /1H )
 8400  FORMAT (1H /1H )
 8500  FORMAT (132A1)
 8600  FORMAT (132A1)
C
C           COMPUTE VALUES FOR PRINTER WIDTH
C
         IF (IWIDTH.GE.132.OR.IWIDTH.LE.0) PGMAX = 25
         IF (IWIDTH.GE.1.AND.IWIDTH.LE.22) PGMAX = 3
         IF (IWIDTH.GT.22.AND.IWIDTH.LT.132) PGMAX = (IWIDTH-7)/5
         PAGN3 = PGMAX + 3
         LW = PGMAX * 5 + 7
         VDJA(PAGN3 + 1) = CRMX
         MXPG = PGMAX * 5 + 7
C
         IF (LINEV .EQ. 0) GO TO  100
C     ...OTHERWISE LINEV IS NON-ZERO, SO 8 LINES/INCH IS DESIRED...
           LINATE = 1
           R4 = 0.250
           R32 = 0.03125
           CON2 = 10.0
           NBTWN = 3
           GO TO  200
C
 100     CONTINUE
           LINATE = 2
           R4 = 0.33333333
           R32 = 1.0/18.0
           CON2 = 6.0
           NBTWN = 2
C
 200     CONTINUE
         PGCNTA = 0
         PGFSTA = 0
         RECT  =  .FALSE.
         DONE = .FALSE.
         KZ = 0
         KZA = 1000
         A = CNST(1)
         KCA = 2*(1-KRECT)
C           TO SET NO. OF DIGITS TO BE PRINTED
C           WHICH IS A FUNCTION OF THE TENS POSITION IN KCONTR
         NODIG = IABS(KCONTR/10)
         NODIG = 3 - NODIG
C           WHERE C(NODIG) + 1 IS NO. OF DIGITS TO BE PRINTED
         IF (NODIG.LT.1 .OR. NODIG.GT.3) NODIG = 3
C           ANY OUT-OF-RANGE WILL GET 4 DIGITS
         LCNTR = .FALSE.
         NCONQ = IABS(MOD(KCONTR,10))
         IF (NCONQ .EQ. 0) GO TO 400
         IF (NCONQ .LE. 2) GO TO 300
C           OTHERWISE RESET NCONQ
         NCONQ = 0
         GO TO 400
 300     CONTINUE
         LCNTR = .TRUE.
C           WITH NCONQ=1 FOR LETTERS,AND =2 FOR NUMBERS IN CONTOUR BANDS
 400     CONTINUE
         IF (NCONQ .EQ. 2) GO TO 600
C        OTHERWISE SET AS LETTERS
C
         KCOW = 16
         DO 500  J = 1,KCOW
           KALPH(J) = KALFA(J)
 500     CONTINUE
         GO TO  800
C
 600     CONTINUE
         KCOW = 20
         DO 700  J = 1,KCOW
           KALPH(J) = KNUMB(J)
 700     CONTINUE
C
800      CONTINUE
         RADJ = 4 * KCOW
         KD=1
C *** SET UP TABLE OF INDICES CORRESPONDING TO FIRST ITEM IN EACH ROW
C ***     THIS IS KRLOC
C *** PICK OUT SIZE AND ROW NUMBER OF LARGEST ROW (KCMX AND KCLMX)
C *** KZA LEFT-JUSTIFIES MAP IF ALL ROWS HAVE COMMON MINIMAL OFFSET
         IF (KTBL(1 ).EQ.(-1)) GO TO  1100
C *** ONE-DIMENSIONAL FORM
         KTF=3
         KZA=0
         IMIN = KTBL(2)
         JMAX = KTBL(3)+KTBL(1)-1
         NRWS = KTBL(1)
         IF (NRWS .GT. LIMNRW) GO TO 1200
         KC = KCA * (NRWS-1) + 1
C
         DO 1000 J = 1,NRWS
           K = NRWS-J+1
           KRLOC(K) = KD
           IF (KTBL(KC+4)+KTBL(KC+3).LE.KZ ) GO TO 900
             KCLMX = K
             IMAX = KTBL(KC+4)+KTBL(KC+3)
             KZ = IMAX
             KCMX = KRLOC(K)+KTBL(KC+4)
 900       CONTINUE
           KD = KD+KTBL(KC+4)
           KC = KC-KCA
 1000    CONTINUE
         GO TO  1600
C *** TWO-DIMENSIONAL FORM
C *** THE TWO-DIMENSIONAL FORM IS COMPILER-DEPENDENT
C *** IT DEPENDS ON THE TWO-DIMENSIONAL ARRAY BEING STORED COLUMN-WISE
C *** THAT IS, WITH THE FIRST INDEX VARYING THE FASTEST
 1100    CONTINUE
         IMIN = KTBL(6)
         JMIN = KTBL(7)
         NRWS = KTBL(5)
         IF (NRWS .LE. LIMNRW) GO TO  1300
C     ... ELSE, NRWS EXCEEDS LIMIT ALLOWED ...
 1200    CONTINUE
         WRITE (OUTPUT,8000) NRWS,LIMNRW
         GO TO  7400
C
 1300    CONTINUE
         JMAX  = KTBL(7) +KTBL(5)-1
         KC = 1
         DO 1500 J = 1,NRWS
           KRLOC(J) = KTBL(2)*(KTBL(4)-J)+KTBL(KC+7)+1
           IF (KTBL(KC+7)+KTBL(KC+8).LE.KZ) GO TO 1400
             IMAX = KTBL(KC+7)+KTBL(KC+8)
             KZ = IMAX
             KCMX = KRLOC(J)+KTBL(KC+8)
             KCLMX = J
 1400      CONTINUE
           IF (KTBL(KC+7).LT.KZA) KZA = KTBL(KC+7)
           KC = KC + KCA
 1500    CONTINUE
         IMAX = IMAX-KZA
         KTF = 7
 1600    CONTINUE
         PAGNL = 0
         PAGNR = PGMAX
         IF (.NOT.LCNTR) GO TO 1700
           ADC = (CNST(1)-CNST(4))/CNST(3)+RADJ
           BC = CNST(2)/CNST(3)
C *** PRINT I-LABELS ACROSS TOP OF MAP
 1700    CONTINUE
C ***    WHICH PREPARES CDC512 PRINTER FOR 8 LINES PER INCH
         IF (LINATE.EQ.1) WRITE (OUTPUT,8100)
C     ...WHICH PREPARES PRINTER FOR 6 LINES PER INCH
         IF (LINATE.EQ.2) WRITE (OUTPUT,8200)
         KLINES(1) = KHRSTR
         ASSIGN 1800 TO KBR
         GO TO 6900
C
 1800    CONTINUE
         IF (.NOT.LCNTR) GO TO 2000
C *** INITIALIZE CONTOUR WORKING AREA
           DO 1900 J=1,PAGN3
             RWC(J)=CRMX
             RWD(J)=CRMX
 1900      CONTINUE
C *** SET UP CONTOUR DATA AND PAGE LIMITERS FOR FIRST TWO ROWS
C
 2000    CONTINUE
         KRA  =  1
         KC = KTF+1
         ASSIGN 2100 TO KBR
         GO TO 5900
C
 2100    CONTINUE
         KRA = 2
         KC = KC+KCA
         ASSIGN 2200 TO KBR
         GO TO 5900
C
 2200    CONTINUE
         KR = 0
C *** TEST IF THIS IS LAST PAGE
         IF (IMAX.GT.PGMAX-1) GO TO 2300
           LMR = IMAX*5 + 2
           DONE = .TRUE.
C *** DO LEFT J-LABELS
 2300    CONTINUE
         JCURR = JMAX
C
 2400    CONTINUE
         KR = KR + 1
         KRA = KR+2
         KC = KC+KCA
         KTA = MOD(JCURR,10)
         KTB = MOD(JCURR,100)/10
         KTC  =  MOD(JCURR,1000)/100
         IF (KR .EQ. 1 .OR. (.NOT. LCNTR)) GO TO 2500
           GO TO  2600
 2500      CONTINUE
           IF (LINATE.EQ.1) WRITE (OUTPUT,8300)
           IF (LINATE.EQ.2) WRITE (OUTPUT,8400)
 2600    CONTINUE
         KLINES(2) = KHPLUS
         KLINES(1) = KHBLNK
         IF (JCURR.LT.0) KLINES(2)=KHMNS
         KTA=IABS(KTA)
         KTB=IABS(KTB)
         KTC = IABS(KTC)
         IF (KTC .EQ. 0) GO TO 2700
           KLINES(3) = KHTBL(KTC+1)
           KLINES(4) = KHTBL(KTB+1)
           KLINES(5) = KHTBL(KTA+1)
           GO TO 2800
C
 2700      CONTINUE
           KLINES(3) = KHTBL(KTB+1)
           KLINES(4) = KHTBL(KTA+1)
           KLINES(5) = KHBLNK
C
 2800      CONTINUE
         DO 2900  J = 6,MXPG
           KLINES(J) = KHBLNK
 2900    CONTINUE
         IF (.NOT.DONE) GO TO 3000
C *** DO RIGHT J-LABELS IF LAST PAGE OF MAP
           KLINE(LMR) = KLINES(2)
           KLINE(LMR+1) = KLINES(3)
           KLINE(LMR+2) = KLINES(4)
           KLINE(LMR+3) = KLINES(5)
C *** FETCH AND CONVERT GRID VALUES TO A1 FORMAT FOR WHOLE LINE
 3000    CONTINUE
         KRX = KRLOC(KR)
         KLX = 5*PGFST+1
         IF (PGCNT.EQ.0) GO TO 4000
           DO 3800 KK = 1,PGCNT
           TEMP = RDATA(KRX)*CNST(2)+A
           KTEMP = ABS(TEMP)+.5
           KLINE(KLX) = KHPLUS
           IF (TEMP.LT.0.0) KLINE(KLX) = KHMNS
           GO TO (3300,3200,3100),NODIG
 3100        CONTINUE
             KTA = MOD(KTEMP,10000)/1000
C
 3200        CONTINUE
             KTB = MOD(KTEMP,1000)/100
C
 3300      CONTINUE
           KTC = MOD(KTEMP,100)/10
           KTD = MOD(KTEMP,10)
           GO TO (3400,3500,3600),NODIG
 3400        CONTINUE
             KLINE(KLX+1) = KHTBL(KTC+1)
             KLINE(KLX+2) = KHTBL(KTD+1)
             GO TO  3700
 3500        CONTINUE
             KLINE(KLX+1) = KHTBL(KTB+1)
             KLINE(KLX+2) = KHTBL(KTC+1)
             KLINE(KLX+3) = KHTBL(KTD+1)
             GO TO  3700
 3600        CONTINUE
             KLINE(KLX+1) = KHTBL(KTA+1)
             KLINE(KLX+2) = KHTBL(KTB+1)
             KLINE(KLX+3) = KHTBL(KTC+1)
             KLINE(KLX+4) = KHTBL(KTD+1)
 3700    CONTINUE
         KLX = KLX + 5
         KRX = KRX+1
 3800    CONTINUE
C *** FOLLOWING CHECKS FOR POLE POINT AND INSERTS PROPER CHARACTER.
         IF (JCURR.NE.0) GO TO 4000
         IF (IMIN.LT.(-25).OR.IMIN.GT.0) GO TO 4000
         KX = -IMIN
         IF (KX.LT.PGFST.AND.KX.GT.PGCNT+PGFST) GO TO 4000
         KX = 5*KX
         IF (KLINE(KX+1).EQ.KHMNS) GO TO 3900
           KLINE(KX) = KHDOLR
           GO TO 4000
 3900    CONTINUE
         KLINE(KX+1) = KHASTR
C *** PRINT LINE OF MAP DATA
 4000    CONTINUE
           WRITE (OUTPUT,8500) (KLINES(II),II=1,MXPG)
           KRLOC(KR) = KRX
           JCURR = JCURR - 1
C *** TEST BOTTOM OF MAP
         IF (KR.EQ.NRWS) GO TO 5700
C *** SET UP CONTOUR DATA AND PAGE LIMITERS FOR NEXT ROW
         ASSIGN 4100 TO KBR
         GO TO 5900
C
 4100    CONTINUE
         IF (.NOT.LCNTR) GO TO 2400
C *** DO CONTOURING
         DO 4200 JJ=1,MXPG
             KLINES(JJ)=KHBLNK
 4200    CONTINUE
C *** VERTICAL INTERPOLATIONS
         DO 4700 KK = 1,PAGN3
           IF (RWB(KK).LT.CRMX.AND.RWC(KK).LT.CRMX) GO TO  4300
             VDJB(KK) = CRMX
             VDJC(KK) = CRMX
             GO TO 4600
 4300      CONTINUE
           IF (RWA(KK).LT.CRMX.AND.RWD(KK).LT.CRMX) GO TO  4400
             VDJC(KK) = 0.
             GO TO  4500
 4400    CONTINUE
         VDJC(KK) = R32*(RWA(KK)+RWD(KK)-RWB(KK)-RWC(KK))
 4500    CONTINUE
         VDJB(KK) = R4*(RWC(KK)-RWB(KK)-CON2*VDJC(KK))
 4600    CONTINUE
         VDJA(KK)=RWB(KK)
 4700    CONTINUE
C     ...DO 2 OR 3 ROWS OF CONTOURING BETWEEN GRID ROWS...
         DO 5600 LL = 1,NBTWN
           DO 4800 KK = 1,PAGN3
             VDJB(KK) = VDJC(KK) + VDJB(KK)
             VDJA(KK) = VDJB(KK) + VDJA(KK)
 4800      CONTINUE
C     ...WHERE VDJA HAS THE INTERPOLATED VALUE FOR THIS INTER-ROW
C *** HORIZONTAL INTERPOLATIONS
           HDC = 0.0
           IF (VDJA(1).GE.CRMX) GO TO 4900
           HDC = R50*(VDJA(4)+VDJA(1)-VDJA(2)-VDJA(3))
 4900    CONTINUE
         KXB = 0
         DO 5200 KK = 1,PGMAX
           IF (VDJA(KK+1).GE.CRMX) GO TO 5100
           HDA = VDJA(KK+1)
           IF (VDJA(KK+2).GE.CRMX) GO TO 5500
           IF (VDJA(KK+3).GE.CRMX) HDC = 0.
        HDB = R5*(VDJA(KK+2)-VDJA(KK+1)-15.*HDC)
C *** COMPUTE AND STORE CONTOUR CHARACTERS, 5 PER POINT
           KHDA=HDA
           KDB = IABS(MOD(KHDA,KCOW))
           KLINE(KXB+1) = KALPH(KDB+1)
           DO 5000 JJ=2,5
           HDB = HDB+HDC
           HDA = HDA+HDB
           KHDA = HDA
           KDB = IABS(MOD(KHDA,KCOW))
           KXA = KXB+JJ
           KLINE(KXA) = KALPH(KDB+1)
 5000    CONTINUE
         HDC = R50*(VDJA(KK+4)+VDJA(KK+1)-VDJA(KK+2)-VDJA(KK+3))
         IF (VDJA(KK+4).GE.CRMX) HDC = 0.
 5100    CONTINUE
         KXB = KXB+5
 5200    CONTINUE
 5300    CONTINUE
         WRITE (OUTPUT,8500) (KLINES(II),II=1,MXPG)
         DO 5400 KK = 1,MXPG
           KLINES(KK) = KHBLNK
 5400    CONTINUE
         GO TO 5600
C
 5500    CONTINUE
         KHDA = HDA
         KDB = IABS(MOD(KHDA,KCOW))
         KLINE(KXB+1) = KALPH(KDB+1)
         GO TO 5300
 5600    CONTINUE
         GO TO 2400
C
 5700    CONTINUE
         IF (LINATE.EQ.1)  WRITE (OUTPUT,8300)
         IF (LINATE.EQ.2)  WRITE (OUTPUT,8400)
         KLINES(1) = KHBLNK
C *** PRINT I-LABELS ACROSS BOTTOM OF PAGE
         ASSIGN 5800 TO KBR
         GO TO 6900
C
 5800    CONTINUE
         IF (LINATE.EQ.1)  WRITE (OUTPUT,8300)
         IF (LINATE.EQ.2)  WRITE (OUTPUT,8400)
C *** PRINT TITLE
         WRITE (OUTPUT,8600) (TITLE(II),II=1,LW)
C *** TEST END OF MAP
           IF (KRLOC(KCLMX).EQ.KCMX) RETURN
C *** ADJUST PAGE LINE BOUNDARIES
C
         IF (IMAX.GT.PGMAX)IMAX = IMAX-PGMAX
         IMIN = KA
         PAGNL = PAGNL + PGMAX
         PAGNR = PAGNR + PGMAX
         GO TO   1700
C *** ROUTINE TO PRE-STORE ROWS FOR CONTOURING AND COMPUTE LINE LIMITERS
C
 5900    CONTINUE
         PGFST = PGFSTA
         PGCNT = PGCNTA
         IF (KRA.GT.NRWS) GO TO 6800
           KRFST = KTBL(KC)-KZA
           KRCNT = KTBL(KC+1)
           KFX = KRLOC(KRA)
           IF (RECT) GO TO  6100
           IF (KRFST-PAGNL.LE.(-1)) GO TO 6400
             PCFST = KRFST-PAGNL+1
             IF (PCFST.GE.PAGN3) GO TO 6700
               PGFSTA = PCFST-1
               PCCNT = MIN(PAGNR-KRFST+2,KRCNT)
               IF (PGFSTA.EQ.0) GO TO 6600
               PGCNTA = MIN(PAGNR-KRFST,KRCNT)
               IF (PGCNTA.GT.0) GO TO 6000
                 PGCNTA = 0
                 GO TO 6100
 6000          CONTINUE
               RECT = KRECT.EQ.1.AND.PGCNTA.LE.KRCNT
 6100    CONTINUE
         IF (.NOT.LCNTR) GO TO KBR,(1800,2100,2200,4100,5800)
         DO 6200 KK = 1,PAGN3
           RWA(KK) = RWB(KK)
           RWB(KK) = RWC(KK)
           RWC(KK) = RWD(KK)
           RWD(KK) = CRMX
 6200    CONTINUE
C
         IF (PCCNT.EQ.0) GO TO KBR,(1800,2100,2200,4100,5800)
           KPC = PCFST+1
           KPD = PCCNT
         DO 6300 KK = 1,PCCNT
           RWD(KPC) = RDATA(KFX)*BC+ADC
           KFX = KFX+1
           KPC = KPC + 1
 6300    CONTINUE
         GO TO KBR,(1800,2100,2200,4100,5800)
C
 6400      CONTINUE
           PCFST = 0
           PGFSTA = 0
           KFX = KFX-1
           PCCNT = KRFST+KRCNT-PAGNL+1
           IF (PCCNT.LT.PAGN3) GO TO 6500
             PCCNT = PAGN3
             PGCNTA = PGMAX
             GO TO 6100
 6500      CONTINUE
           IF (PCCNT.GT.0) GO TO 6600
           PGCNTA = 0
           PCCNT = 0
           GO TO 6100
C
 6600    CONTINUE
         PGCNTA = MIN(PGMAX,KRCNT+KRFST-PAGNL)
         GO TO 6100
C
 6700        CONTINUE
             PGCNTA = 0
 6800    CONTINUE
         PCCNT = 0
         GO TO 6100
C
C *** ROUTINE TO PRINT I-LABELS
C
 6900    CONTINUE
         DO 7000 KK = 2,MXPG
           KLINES(KK) =  KHBLNK
 7000    CONTINUE
C
C
         KK = 1
         KA = IMIN
         LBL = MIN(IMAX,PGMAX)
C
         DO 7300 JJ = 1,LBL
           KLINE(KK) = KHPLUS
           IF (KA.LT.0) KLINE(KK) = KHMNS
           KTA = IABS(MOD(KA,100))/10
           KTB = IABS(MOD(KA,10))
           KTC = IABS(MOD(KA,1000))/100
           IF (KTC .EQ. 0) GO TO 7100
             KLINE(KK+1) = KHTBL(KTC+1)
             KLINE(KK+2) = KHTBL(KTA+1)
             KLINE(KK+3) = KHTBL(KTB+1)
             GO TO  7200
C
 7100      CONTINUE
           KLINE(KK+1) = KHTBL(KTA+1)
           KLINE(KK+2) = KHTBL(KTB+1)
C
 7200    CONTINUE
         KK = KK + 5
         KA = KA+1
 7300    CONTINUE
C
         WRITE (OUTPUT,8500) (KLINES(II),II=1,MXPG)
C
         GO TO KBR,(1800,2100,2200,4100,5800)
C
 7400    RETURN
C
       END

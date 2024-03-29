C> @file
C> @brief Sends fax,varian,afos,awips, maps & bulls
C> @author Peter Henrichsen @date 1997-01-09

C> Sets up the arguments for sub dbn_alert which posts transmission
C> availability to various statfiles. The input key words for w3fq07() may be
C> read in via the parm field or from a data card see remarks for examples.
C>
C> ### Program History Log:
C> Date | Programmer | Comments
C> -----|------------|---------
C> 1997-01-09 | Peter Henrichsen | Initial
C>
C> @param[in] LPARM Character*1 100 byte array containing ascii
C> flags and key words.
C> @param[in] NUMBYT Integer number of bytes of ascii data in lparm.
C> @param[in] OUTFIL Integer unit number of file to post to the
C> telecommunications gateway computer system.
C> @param[in] CARDFIL Integer unit number of file to read to get data
C> control card in lue of parm. this is only necessary
C> when parm(5:5) = 'a'.
C> @param[out] KRTN See return conditions.
C> Return conditions:
C> KRTN = 0 good return, file posted for transmission
C> KRTN = 1 good return, file not posted for transmission test flag was on ie
C> k=test or there was an "n" the 1st byte of the input data card.
C> KRTN = 2 bad  return, posting not attempted, the "k" key was missing.
C> KRTN = 3 bad  return, posting not attempted, parm less than than 6 bytes.
C> KRTN = 4 bad  return, card reader empty.
C> KRTN = 5 bad  return, error return from sub dbn_alert.
C>
C> FTNNF001 - File that contains the data to send. where 'nn' can be any
C> number from 01 to 99 except 5 or 6. This file must be assigned with u:nn.
C>
C> FTXXF001 - Input cards, only necessary if lparm(3-6) ='card'. a sample data
C> card is: m=ft24f001,k=afos (all on one card starting in col 1).
C> If col 1 = 'n' then the data set is not posted to the monitior,ie., w3fq07()
C> will return to calling program with out sending the product.
C> (xx has default of 05. however this number can be any unit number you wish.
C>
C> @note The key words that are passed to sub in lparm may be in any order in
C> the lparm array or data card. there is one key word that is mandatory. they are:
C> K=KKKKKKK Where KKKKKKKK is up to a 24 byte ascii keyword left-justified
C> which identifies what dbnet is to do with the input data file.
C>
C> 'KKKKKKKK' Is generally a keyword such as: 'FAXX', 'TRAN','AFOS','AWIP'
C> but may be: any one of these type-keys.
C>
C> Type-keys | Functions
C> ----------|----------
C> AFOS              | Posts AFOS utf map file to CRAY OSO'S statusfile.
C> AWIP              | Posts AWIPS map file to CRAY OSO'S statusfile.
C> FAXX              | Posts nmc6bit map file to CRAY OSO'S statusfile.
C> GRIB              | Posts wmo grib file to CRAY OSO'S statusfile.
C> TRAN              | Posts wmo bulletin file to CRAY OSO'S statusfile.
C> XTRN              | Posts xtrn file to CRAY OSO'S statusfile.
C> IG_DATA_ipsa1     | Sends data file to the intergraph ipsa1.
C> IG_DATA_ipsa2     | Sends data file to the intergraph ipsa2.
C> IG_DATA_lzr_srv1  | Sends data file to the intergraph lzr_srv1.
C> IG_PLTF_ipsa1     | Sends AFOS plot file to the intergraph ipsa1.
C> IG_PLTF_ipsa2     | Sends AFOS plot file to the intergraph ipsa2.
C> IG_PLTF_lzr_srv1  | Sends AFOS plot file to the intergraph lzr_srv1.
C> IG_6BIT_lzr_srv1  | Sends nmc6bit file to the intergraph lzr_srv1.
C> TPC_6BIT_nhc-hp13 | Sends nmc6bit file to nhc-hp13 at TPC.
C> OSO_IG_6BIT_lzr_srv1 | Posts nmc6bit file to CRAY OSO'S  statusfile and then Sends nmc6bit file to the intergraph lzr_srv1.
C> OSO_TPC_6BIT_nhc-hp13 | Posts nmc6bit file to CRAY OSO'S statusfile and then Sends nmc6bit file to nhc-hp13 at TPC.
C>
C> Where outfil is the file number containg the data.
C>
C> A sample: M=PETERS,K=FAXX where A ',' or A ' ' Terminates the key word.
C> Where a comma or blank terminates the key word.
C>
C> The M= is an optional key word. the 'M' key word is the model name
C> if missing the "missing" is used other wise it may by any
C> 24 byte ASCII string.
C>
C> A sample: M=AVN,K=AFOS, where a comma or blank terminates the key word.
C>
C> @author Peter Henrichsen @date 1997-01-09
      SUBROUTINE W3FQ07(LPARM,NUMBYT,OUTFIL,CARDFIL,KRTN)
C
C
      CHARACTER*(*) LPARM
C
      CHARACTER*80  BLNK80
      CHARACTER*80  FILNAM
      CHARACTER*80  OUTXT
      CHARACTER*80  STRING

C
      CHARACTER*55 CHTEST
      DATA         CHTEST
     1/'THIS WAS A TEST, PRODUCTS NOT POSTED FOR TRANSMISSION.:'/
C      '1234567890123456789012345678901234567890123456789012345
C
      CHARACTER*52 NOTSNT
      DATA         NOTSNT
     1   /'** FILE NOT POSTED FOR TRANSMISSION AVAILABILITY **:'/
C         '1234567890123456789012345678901234567890123456789012'/
C

      CHARACTER*52 MESAG1
      DATA         MESAG1
     1 /'FILE NOT POSTED FOR TRANSMISSION, FOUND BYPASS FLAG:'/
C    1 /'1234567890123456789012345678901234567890123456789012/
      CHARACTER*56 MESAG2
      DATA         MESAG2
     1 /'FILE NOT POSTED FOR TRANSMISSION, "K" KEY FLAG MISSINGS:'/
C    1 /'12345678901234567890123456789012345678901234567890123456
      CHARACTER*46 MESAG3
      DATA         MESAG3
     1    /'ERROR W3FQ07, LESS THAN 6 BYTES IN PARM FIELD:'/
C    1    /'12345678901234567890123456789012345678901234567890123456'/

      CHARACTER*55 MESAG4
      DATA         MESAG4
     1    /'ERROR W3FQ07, CARD FILE EMPTY. CHECK JCL CARD FIILE   :'/
      CHARACTER*42 MESAG5
      DATA         MESAG5
     1    /'ERROR RETURN FROM SUB DBN_ALERT,RETURN=  :'/
C    1    /'12345678901234567890123456789012345678901234567890123456'/
C
      CHARACTER*40 BLNK40
      DATA         BLNK40
     1    /'                                        '/
      CHARACTER*24  BUFFER
      DATA          BUFFER/'                        '/
      CHARACTER*24  JOBNAM
      DATA          JOBNAM/'UNKOWN                  '/
C
      CHARACTER*12 CTEXT
      CHARACTER*4 CPLMIZ
      DATA        CPLMIZ  /'L999'/
C
      CHARACTER*04 LTRS
      DATA         LTRS   /'K=M='/
C
      CHARACTER*24  BLANK
      DATA        BLANK       /'                        '/

      CHARACTER*24 IFAXX
      DATA         IFAXX      /'FAXX                    '/

      CHARACTER*24 KEYWRD
      CHARACTER*24 MODNAM
C
      CHARACTER*4  AWIP
      DATA         AWIP        /'AWIP'/
      CHARACTER*4  IFAX
      DATA         IFAX        /'FAX '/

C
      CHARACTER*1  IQUOT
C
      DATA       INUNIT        /5/
      INTEGER    CARDFIL
      INTEGER    OUTFIL
      INTEGER    NK,NM,NJ,NF,KRET4
C

      LOGICAL*1  BYPASS
      LOGICAL*1  GOTFLN
      LOGICAL*1  GOTKEY
      LOGICAL*1  GOTMOD
      LOGICAL*1  GOTJOB
      LOGICAL*1  LCARDS
      LOGICAL*1  KPRINT
C
        IQUOT  = CHAR(27)
        BLNK80 = BLNK40//BLNK40
C
C
        WRITE(6,FMT='('' USING W3FQ07 CRAY VERSION 97.008 08:40.'')')
C
C . . . PICKUP PARAMETERS.
C
C . . . CHECK TO SEE IF BYTE COUNT LESS THAN 6 IF SO PRODUCT NOT SENT.
C
      IF(NUMBYT.LT.6) THEN
C
C . . . BYTE COUNT LESS THAN 6.
C
             KRTN = 3
             WRITE(6,FMT='('' W3FQ07: '',A)') NOTSNT(1:52)
             WRITE(6,FMT='('' W3FQ07: '',A)') MESAG3(1:46)
             CALL CONSOL(NOTSNT)
             CALL CONSOL(MESAG3)
      ELSE

C
C . . . BYTE COUNT GREATER THAN OR EQUAL TO 6,
C . . . START TO PROCESS FLAGS
C
C
      LCARDS = .FALSE.
      GOTKEY = .FALSE.
      GOTMOD = .FALSE.
      GOTJOB = .FALSE.
      GOTFLN = .FALSE.

          IF(LPARM(5:5).EQ.'A') LCARDS = .TRUE.
C
C . . . . FILL KEYS WITH BLANKS.
C
          IF(LCARDS)THEN
C
              NUMBYT = 80
C
C . . . BLANK OUT LPARM.............................
C
             LPARM(1:NUMBYT) = BLNK80(1:NUMBYT)
C
C . . . READ DATA CARD TO GET DATA KEYWORDS TO SEND.
C
C        CHECK TO SEE IF CARDFIL IS GOOD
C
           IF(CARDFIL.GT.0)THEN
           ELSE
            CARDFIL  = INUNIT
           ENDIF
           WRITE(6,FMT='('' W3FQ07: READING CARD FROM UNIT '',
     1           I4)') CARDFIL
              READ(CARDFIL,FMT='(80A1)',END=940)
     1         (LPARM(I:I),I=1,NUMBYT)
C
           WRITE(6,FMT='('' W3FQ07: PARM='',
     1           A)')LPARM(1:NUMBYT)
C
C         CHECK TO SEE IF INTERFACE OFF FLAG IS SET....
C . . . . IF THERE IS AN 'N' IN THE 1ST COL OF DATA CARD CALL TO
C         DBN_ALERT WILL BE BYPASSED.
C
           IF(LPARM(1:1).EQ.'N') BYPASS = .TRUE.
C
C
C         CHECK TO SEE IF EXTRA PRINT FLAG IS SET....
C . . . . IF THERE IS AN 'P' IN THE 1ST COL OF DATA CARD
C         TURN ON 'KPRNT' FLAG.
C
            KPRINT = .FALSE.
           IF(LPARM(1:1).EQ.'P') KPRINT = .TRUE.
          ENDIF
          IF(KPRINT)THEN
              WRITE(6,FMT='('' PARM='',A)') LPARM(1:NUMBYT)
          ENDIF
C
           IF(BYPASS)THEN
          WRITE(6,FMT='(1H0,A)')MESAG1(1:52)
          KRTN = 7
           CALL CONSOL(MESAG1)
           ELSE
              IF(.NOT.LCARDS)
     1         WRITE(6,FMT='('' PARM='',A)') LPARM(1:NUMBYT)
                 NUM = 0
            DO 840 LK  = 1,10,2
C
              DO 820 MM  = 1,NUMBYT
C
                NEXT = MM+1
               IF(LPARM(MM:NEXT).EQ.LTRS(LK:LK+1))THEN
                   KSTART = NEXT + 1
                   LOC    = NEXT + 1
C              WRITE(6,FMT='('' FOUND'',A,'' AT LOC '',I3,
C    1         '' AND WILL START SEARCHING AT'',I4,'' IN ARRAY '',
C    2         ''OF LENGHT'',I4)')LPARM(MM:NEXT),MM,KSTART,NUMBYT
C
                    LLOC = 0
                 DO 8010 NI = KSTART,NUMBYT
                    LOC = NI
                   IF(LPARM(NI:NI).EQ.',')THEN
                   ELSE IF(LPARM(NI:NI).EQ.IQUOT)THEN
                   ELSE IF(LPARM(NI:NI).EQ.' ')THEN
                   ELSE
                    LLOC = NI
                    GO TO 8010
                   ENDIF
                  GO TO 8015
8010             CONTINUE
               WRITE(6,FMT='('' I FELL THROUGH LOOP WITH LOC='',I4,
     1         '' WITH LLOC='',I4,'' & KSTART='',I4,
     2          '' NUMBYT='',I4,'' THEREFORE ADD "1" TO LOC'')')
     3          LOC,LLOC,KSTART,NUMBYT
                   IF(LLOC.EQ.KSTART) LOC = LLOC + 1
8015           CONTINUE
                   IF(LOC.GT.KSTART) THEN
C
C              HAVE A FLAG LOAD IT INTO PROPER WORD
C
C       IF(KPRINT) THEN
                   WRITE(6,FMT='('' FOUND THE KEY WORD: '',A,
     1             '' AT LOCATION '',I2,'' IN LPARM ARRAY.'',/)')
     2             LPARM(KSTART:LLOC),KSTART
C       ENDIF
                     IF(LK.EQ.1) THEN

                       KEYWRD = LPARM(KSTART:LLOC)
                       NK = LLOC - KSTART+1
                       GOTKEY = .TRUE.
                       NUM = NUM + 1
                     ELSE IF(LK.EQ.3) THEN
                       MODNAM = LPARM(KSTART:LLOC)
                       NM = LLOC - KSTART+1
                       GOTMOD = .TRUE.
                       NUM = NUM + 1
                     ENDIF
                   ELSE
                    GO TO 820
                   ENDIF
               ELSE
C              GO SEARCH SOME MORE.
                    GO TO 820
               ENDIF
C
               GOTO 840
 820         CONTINUE
C
 840         CONTINUE
              NUMGOD = 2
C
           IF(NUM.LT.NUMGOD) THEN
C
C             DID NOT FIND A MATCH OF A KEY LETTER CHECK TO SEE WHICH
C             ONE IT WAS.
C
              IF(GOTKEY)THEN
                MODNAM(1:8) = 'MISSGING'
                NM = 8
                GOTMOD = .TRUE.
              ELSE
               KRTN = 2
             WRITE(6,FMT='('' W3FQ07: '',A)') NOTSNT(1:52)
             WRITE(6,FMT='('' W3FQ07: '',A)') MESAG2(1:46)
C
              CALL CONSOL(NOTSNT)
              CALL CONSOL(MESAG2)
              GO TO 900
              ENDIF
           ENDIF
C
C
              WRITE(6,FMT='('' PARM='',A)') LPARM(1:NUMBYT)
              WRITE(6,FMT='('' MODNAM='',A,'' KEYWRD='',A,
     1        /)')MODNAM(1:NM),KEYWRD(1:NK)
C
C
C         CHECK TO SEE IF FIRST 4 BYTES OF KEYWRD = FAX .
C          IF IT DOES, CHANGE IT TO FAXX .
C
                IF(KEYWRD(1:NK).EQ.'FAX')THEN
                 KEYWRD(1:4) = 'FAXX'
                 NK = 4
                ENDIF
                IF(KEYWRD(1:NK).EQ.'TEST')THEN
                 BYPASS = .TRUE.
              WRITE(6,FMT='('' W3FQ07: BYPASS FLAG ON, '',
     1                      ''SKIP POSTING FILE.'',/)')
                 GO TO 900
                ENDIF
C
C             MUST NOW I MUST GET THE JOB NAME AND UNIT NAME FOR
C             CALL TO DBN_ALERT.
C
C . . .       READ IN JOBNAME
              JCHARS = GETENV('QSUB_REQNAME',BUFFER)
              NJ = 0
                IF(BUFFER(1:8).EQ.'        ')THEN
                 JOBNAM(1:8) = 'MSG_JOBNM'
                 NJ = 8
                ELSE
                 DO II =1,8
                  IF(BUFFER(II:II).NE.' ')THEN
                   NJ = NJ + 1
                   JOBNAM(NJ:NJ) = BUFFER(II:II)
                  ENDIF
                 ENDDO
                ENDIF
C
             WRITE(6,FMT='('' W3FQ07: JOB NAME JOBNAM= :'',A,
     1         ''!'')') JOBNAM(1:24)
              WRITE(6,FMT='('' W3FQ07: JOB NAME= '',A,
     1         '' NJ='',I3)') JOBNAM(1:NJ),NJ
C
C . . .       READ IN FILE NAME
C
                 KRTN = 0

                 CALL ASNQUNIT(OUTFIL,STRING,ISTAT)
              WRITE(6,FMT='('' W3FQ07:OUTFIL NAME= '',
     1         A,'' ISTAT='',I4)')STRING(1:80),ISTAT
C                SEARCH FOR LENGHT OF FILE NAME.
C
                KRET = ISTAT
                IF(KRET.EQ.0) THEN
                  ISTRT = 0
                DO I = 1,80
                  IF(ISTRT.EQ.0)THEN
                   IF(STRING(I:I).EQ.'/')THEN
                    ISTRT = I
                   ENDIF
                  ELSE
                   IF(STRING(I:I).EQ.' ')THEN
                    IEND = I
                    GOTO 775
                   ENDIF
                  ENDIF
                ENDDO
 775            NF = IEND - ISTRT
                OUTXT(1:NF) = STRING(ISTRT:IEND)
                 WRITE(6,FMT='('' W3FQ07: OUTXT= '',
     1          A,'' NF='',I3)')OUTXT(1:NF),NF
C
               WRITE(6,FMT='('' W3FQ07: CALLING DBN_ALERT WITH'',
     1         '' :'',A,'' NK='',I2,'' '',A,'' NM='',I2,'' '',
     2         A,'' NJ='',I2,'' '',A,'' NF='',I3)')KEYWRD(1:NK),
     3          NK,MODNAM(1:NM),NM,JOBNAM(1:NJ),NJ,OUTXT(1:NF),NF

                  CALL DBN_ALERT(KEYWRD,NK,MODNAM,NM,JOBNAM,NJ,
     1                 OUTXT,NF,KRET4)
                  KRET=KRET4
C
               ENDIF
                IF(KRET.EQ.0) THEN
C               COMES HERE FOR NORMAL STOP.
C
                 FILNAM(1:8) = 'POSTING '
                 FILNAM(9:9+NK-1) = KEYWRD(1:NK)
                 JLOC = 9 + NK
                 FILNAM(JLOC:JLOC+6) = ' FILE '
                  LOC = JLOC + 6
                 FILNAM(LOC+1:LOC+1+NF) = OUTXT(1:NF)
                  JOC = LOC + NF + 1
                 FILNAM(JOC:JOC) = ':'
                 WRITE(6,FMT='('' W3FQ07: KRET='',I4,'' THEREFORE '',
     1          A)')KRET,FILNAM(1:JOC)
                 CALL CONSOL(FILNAM)
                ELSE
                  KRTN = 5
                 CALL INT2CH(KRET,CTEXT,2,CPLMIZ)
                 MESAG5(40:41) = CTEXT(1:2)
                   WRITE(6,FMT='('' W3FQ07: '',
     1             A)')MESAG5(1:42)
                 CALL CONSOL(NOTSNT)
                 CALL CONSOL(MESAG5)
                ENDIF
C
 900    CONTINUE
       ENDIF
       GO TO 1000
 940  CONTINUE
           CALL INT2CH(CARDFIL,CTEXT,2,CPLMIZ)
              MESAG4(53:54) = CTEXT(1:2)
             CALL CONSOL(NOTSNT)
             CALL CONSOL(MESAG4)
             WRITE(6,FMT='('' W3FQ07: '',A)') NOTSNT
             WRITE(6,FMT='('' W3FQ07: '',A)') MESAG4
        KRTN = 4
       ENDIF
1000  RETURN
      END

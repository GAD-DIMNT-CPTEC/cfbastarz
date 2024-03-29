C> @file
C> @brief Convert (361,181) grid to (65,65) n. hemi. grid
C> @author Ralph Jones @date 1993-03-29

C> Convert a global 1.0 degree lat.,lon. 361 by
C> 181 grid to a polar stereographic 65 by 65 grid. The polar
C> stereographic map projection is true at 60 deg. n. , the mesh
C> length is 381 km. and the oriention is 105 deg. w. This is the
C> same as w3ft43v() except the oriention is 105 deg. w.
C>
C> ### Program History Log:
C> Date | Programmer | Comment
C> -----|------------|--------
C> 1993-03-29 | Ralph Jones | Add save statement.
C>
C> @param[in] ALOLA 361*181 grid 1.0 deg. lat,lon grid
C> 65341 point grid. 360 * 181 one degree grib grid 3 was flipped, greenwish added
C> to right side to make 361 * 181.
C> @param[in] INTERP 1 linear interpolation , ne.1 biquadratic
C> @param[out] APOLA 65*65 grid of northern hemisphere. 4225 point grid is
C> awips grid type 201
C>
C> @note
C> - 1. W1 and w2 are used to store sets of constants which are
C> reusable for repeated calls to the subroutine.
C> - 2. Wind components are not rotated to the 65*65 grid orientation
C> after interpolation. You may use w3fc08() to do this.
C> - 3. All points below equator are on this grid.
C>
C> @author Ralph Jones @date 1993-03-29
      SUBROUTINE W3FT201(ALOLA,APOLA,INTERP)
C
       PARAMETER   (NPTS=4225,II=65,JJ=65)
       PARAMETER   (ORIENT=105.0,IPOLE=33,JPOLE=33)
       PARAMETER   (XMESH=381.0)
C
       REAL        R2(NPTS),      WLON(NPTS)
       REAL        XLAT(NPTS),    XI(II,JJ),   XJ(II,JJ)
       REAL        XII(NPTS),     XJJ(NPTS),   ANGLE(NPTS)
       REAL        ALOLA(361,181), APOLA(NPTS), ERAS(NPTS,4)
       REAL        W1(NPTS),      W2(NPTS)
       REAL        XDELI(NPTS),   XDELJ(NPTS)
       REAL        XI2TM(NPTS),   XJ2TM(NPTS)
C
       INTEGER     IV(NPTS),      JV(NPTS),    JY(NPTS,4)
       INTEGER     IM1(NPTS),     IP1(NPTS),   IP2(NPTS)
C
       LOGICAL     LIN
C
       SAVE
C
       EQUIVALENCE (XI(1,1),XII(1)),(XJ(1,1),XJJ(1))
C
       DATA  DEGPRD/57.2957795/
       DATA  EARTHR/6371.2/
       DATA  INTRPO/99/
       DATA  ISWT  /0/
C
      LIN = .FALSE.
      IF (INTERP.EQ.1) LIN = .TRUE.
C
      IF  (ISWT.EQ.1)  GO TO  900
C
        DEG    = 1.0
        GI2    = (1.86603 * EARTHR) / XMESH
        GI2    = GI2 * GI2
C
C     NEXT 32 LINES OF CODE PUTS SUBROUTINE W3FB01 IN LINE
C
      DO 100 J = 1,JJ
         XJ1 = J - JPOLE
         DO 100 I = 1,II
             XI(I,J) = I - IPOLE
             XJ(I,J) = XJ1
 100     CONTINUE
C
      DO 200 KK = 1,NPTS
        R2(KK)   = XJJ(KK) * XJJ(KK) + XII(KK) * XII(KK)
        XLAT(KK) = DEGPRD *
     &      ASIN((GI2 - R2(KK)) / (GI2 + R2(KK)))
 200  CONTINUE
C
      XII(2113) = 1.0
      DO 300 KK = 1,NPTS
        ANGLE(KK) = DEGPRD * ATAN2(XJJ(KK),XII(KK))
 300  CONTINUE
C
      DO 400 KK = 1,NPTS
        IF (ANGLE(KK).LT.0.0) ANGLE(KK) = ANGLE(KK) + 360.0
 400  CONTINUE
C
      DO 500 KK = 1,NPTS
        WLON(KK) = 270.0 + ORIENT - ANGLE(KK)
 500  CONTINUE
C
      DO 600 KK = 1,NPTS
        IF (WLON(KK).LT.0.0)   WLON(KK) = WLON(KK) + 360.0
 600  CONTINUE
C
      DO 700 KK = 1,NPTS
        IF (WLON(KK).GE.360.0) WLON(KK) = WLON(KK) - 360.0
 700  CONTINUE
C
      XLAT(2113) = 90.0
      WLON(2113) =  0.0
C
      DO 800 KK = 1,NPTS
        W1(KK)  = (360.0 - WLON(KK)) / DEG + 1.0
        W2(KK)  = XLAT(KK) / DEG + 91.0
 800  CONTINUE
C
      ISWT   = 1
      INTRPO = INTERP
      GO TO 1000
C
C     AFTER THE 1ST CALL TO W3FT201 TEST INTERP, IF IT HAS
C     CHANGED RECOMPUTE SOME CONSTANTS
C
  900 CONTINUE
        IF (INTERP.EQ.INTRPO) GO TO 2100
        INTRPO = INTERP
C
 1000 CONTINUE
        DO 1100 K = 1,NPTS
          IV(K)    = W1(K)
          JV(K)    = W2(K)
          XDELI(K) = W1(K) - IV(K)
          XDELJ(K) = W2(K) - JV(K)
          IP1(K)   = IV(K) + 1
          JY(K,3)  = JV(K) + 1
          JY(K,2)  = JV(K)
 1100   CONTINUE
C
      IF (LIN) GO TO 1400
C
      DO 1200 K = 1,NPTS
        IP2(K)   = IV(K) + 2
        IM1(K)   = IV(K) - 1
        JY(K,1)  = JV(K) - 1
        JY(K,4)  = JV(K) + 2
        XI2TM(K) = XDELI(K) * (XDELI(K) - 1.0) * .25
        XJ2TM(K) = XDELJ(K) * (XDELJ(K) - 1.0) * .25
 1200 CONTINUE
C
      DO 1300 KK = 1,NPTS
         IF (IV(KK).EQ.1) THEN
           IP2(KK) = 3
           IM1(KK) = 360
         ELSE IF (IV(KK).EQ.360) THEN
           IP2(KK) = 2
           IM1(KK) = 359
         ENDIF
 1300 CONTINUE
C
 1400 CONTINUE
C
      IF (LIN) GO TO 1700
C
      DO 1500 KK = 1,NPTS
        IF (JV(KK).GE.180) XJ2TM(KK) = 0.0
 1500 CONTINUE
C
      DO 1600 KK = 1,NPTS
        IF (IP2(KK).LT.1)   IP2(KK) = 1
        IF (IM1(KK).LT.1)   IM1(KK) = 1
        IF (IP2(KK).GT.361) IP2(KK) = 361
        IF (IM1(KK).GT.361) IM1(KK) = 361
 1600 CONTINUE
C
 1700 CONTINUE
      DO 1800 KK = 1,NPTS
        IF (IV(KK).LT.1)    IV(KK)  = 1
        IF (IP1(KK).LT.1)   IP1(KK) = 1
        IF (IV(KK).GT.361)  IV(KK)  = 361
        IF (IP1(KK).GT.361) IP1(KK) = 361
 1800 CONTINUE
C
C     LINEAR INTERPOLATION
C
      DO 1900 KK = 1,NPTS
        IF (JY(KK,2).GT.181) JY(KK,2) = 181
        IF (JY(KK,3).GT.181) JY(KK,3) = 181
 1900 CONTINUE
C
      IF (.NOT.LIN) THEN
      DO 2000 KK = 1,NPTS
        IF (JY(KK,1).GT.181) JY(KK,1) = 181
        IF (JY(KK,4).GT.181) JY(KK,4) = 181
 2000 CONTINUE
      ENDIF
C
 2100 CONTINUE
      IF (LIN) THEN
C
C     LINEAR INTERPOLATION
C
      DO 2200 KK = 1,NPTS
        ERAS(KK,2) = (ALOLA(IP1(KK),JY(KK,2))-ALOLA(IV(KK),JY(KK,2)))
     &             * XDELI(KK) + ALOLA(IV(KK),JY(KK,2))
        ERAS(KK,3) = (ALOLA(IP1(KK),JY(KK,3))-ALOLA(IV(KK),JY(KK,3)))
     &             * XDELI(KK) + ALOLA(IV(KK),JY(KK,3))
 2200 CONTINUE
C
      DO 2300 KK = 1,NPTS
        APOLA(KK) = ERAS(KK,2) + (ERAS(KK,3) - ERAS(KK,2))
     &            * XDELJ(KK)
 2300 CONTINUE
C
      ELSE
C
C     QUADRATIC INTERPOLATION
C
      DO 2400 KK = 1,NPTS
        ERAS(KK,1)=(ALOLA(IP1(KK),JY(KK,1))-ALOLA(IV(KK),JY(KK,1)))
     &            * XDELI(KK) + ALOLA(IV(KK),JY(KK,1)) +
     &            ( ALOLA(IM1(KK),JY(KK,1)) - ALOLA(IV(KK),JY(KK,1))
     &            - ALOLA(IP1(KK),JY(KK,1))+ALOLA(IP2(KK),JY(KK,1)))
     &            * XI2TM(KK)
        ERAS(KK,2)=(ALOLA(IP1(KK),JY(KK,2))-ALOLA(IV(KK),JY(KK,2)))
     &            * XDELI(KK) + ALOLA(IV(KK),JY(KK,2)) +
     &            ( ALOLA(IM1(KK),JY(KK,2)) - ALOLA(IV(KK),JY(KK,2))
     &            - ALOLA(IP1(KK),JY(KK,2))+ALOLA(IP2(KK),JY(KK,2)))
     &            * XI2TM(KK)
        ERAS(KK,3)=(ALOLA(IP1(KK),JY(KK,3))-ALOLA(IV(KK),JY(KK,3)))
     &            * XDELI(KK) + ALOLA(IV(KK),JY(KK,3)) +
     &            ( ALOLA(IM1(KK),JY(KK,3)) - ALOLA(IV(KK),JY(KK,3))
     &            - ALOLA(IP1(KK),JY(KK,3))+ALOLA(IP2(KK),JY(KK,3)))
     &            * XI2TM(KK)
        ERAS(KK,4)=(ALOLA(IP1(KK),JY(KK,4))-ALOLA(IV(KK),JY(KK,4)))
     &            * XDELI(KK) + ALOLA(IV(KK),JY(KK,4)) +
     &            ( ALOLA(IM1(KK),JY(KK,4)) - ALOLA(IV(KK),JY(KK,4))
     &            - ALOLA(IP1(KK),JY(KK,4))+ALOLA(IP2(KK),JY(KK,4)))
     &            * XI2TM(KK)
 2400      CONTINUE
C
       DO 2500 KK = 1,NPTS
         APOLA(KK) = ERAS(KK,2) + (ERAS(KK,3) - ERAS(KK,2))
     &             * XDELJ(KK)  + (ERAS(KK,1) - ERAS(KK,2)
     &             - ERAS(KK,3) + ERAS(KK,4)) * XJ2TM(KK)
 2500  CONTINUE
C
      ENDIF
C
C     SET POLE POINT , WMO STANDARD FOR U OR V
C
      APOLA(2113) = ALOLA(181,181)
C
      RETURN
      END

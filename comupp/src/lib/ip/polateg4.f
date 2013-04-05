C-----------------------------------------------------------------------
      SUBROUTINE POLATEG4(IPOPT,KGDSI,KGDSO,MI,MO,KM,IBI,LI,GI,
     &                    NO,RLAT,RLON,CROT,SROT,IBO,LO,XO,YO,IRET)
C$$$  SUBPROGRAM DOCUMENTATION BLOCK
C
C SUBPROGRAM:  POLATEG4   INTERPOLATE SCALAR FIELD GRADIENTS (SPECTRAL)
C   PRGMMR: IREDELL       ORG: W/NMC23       DATE: 96-04-10
C
C ABSTRACT: THIS SUBPROGRAM PERFORMS SPECTRAL INTERPOLATION
C           FROM ANY GRID TO ANY GRID FOR SCALAR FIELDS,
C           RETURNING THEIR VECTOR GRADIENTS.
C           IT REQUIRES THAT THE INPUT FIELDS BE UNIFORMLY GLOBAL.
C           OPTIONS ALLOW CHOICES BETWEEN TRIANGULAR SHAPE (IPOPT(1)=0)
C           AND RHOMBOIDAL SHAPE (IPOPT(1)=1) WHICH HAS NO DEFAULT;
C           A SECOND OPTION IS THE TRUNCATION (IPOPT(2)) WHICH DEFAULTS 
C           TO A SENSIBLE TRUNCATION FOR THE INPUT GRID (IF OPT(2)=-1).
C           NOTE THAT IF THE OUTPUT GRID IS NOT FOUND IN A SPECIAL LIST,
C           THEN THE TRANSFORM BACK TO GRID IS NOT VERY FAST.
C           THIS SPECIAL LIST CONTAINS GLOBAL CYLINDRICAL GRIDS,
C           POLAR STEREOGRAPHIC GRIDS CENTERED AT THE POLE
C           AND MERCATOR GRIDS.
C           ONLY HORIZONTAL INTERPOLATION IS PERFORMED.
C           THE GRIDS ARE DEFINED BY THEIR GRID DESCRIPTION SECTIONS
C           (PASSED IN INTEGER FORM AS DECODED BY SUBPROGRAM W3FI63).
C           THE CURRENT CODE RECOGNIZES THE FOLLOWING PROJECTIONS:
C             (KGDS(1)=000) EQUIDISTANT CYLINDRICAL
C             (KGDS(1)=001) MERCATOR CYLINDRICAL
C             (KGDS(1)=003) LAMBERT CONFORMAL CONICAL
C             (KGDS(1)=004) GAUSSIAN CYLINDRICAL (SPECTRAL NATIVE)
C             (KGDS(1)=005) POLAR STEREOGRAPHIC AZIMUTHAL
C             (KGDS(1)=202) ROTATED EQUIDISTANT CYLINDRICAL (ETA NATIVE)
C           WHERE KGDS COULD BE EITHER INPUT KGDSI OR OUTPUT KGDSO.
C           AS AN ADDED BONUS THE NUMBER OF OUTPUT GRID POINTS
C           AND THEIR LATITUDES AND LONGITUDES ARE ALSO RETURNED.
C           ON THE OTHER HAND, THE OUTPUT CAN BE A SET OF STATION POINTS
C           IF KGDSO(1)<0, IN WHICH CASE THE NUMBER OF POINTS
C           AND THEIR LATITUDES AND LONGITUDES MUST BE INPUT.
C           OUTPUT BITMAPS WILL NOT BE CREATED.
C        
C PROGRAM HISTORY LOG:
C   96-04-10  IREDELL
C 2001-06-18  IREDELL  IMPROVE DETECTION OF SPECIAL FAST TRANSFORM
C
C USAGE:    CALL POLATEG4(IPOPT,KGDSI,KGDSO,MI,MO,KM,IBI,LI,GI,
C    &                    NO,RLAT,RLON,CROT,SROT,IBO,LO,GO,IRET)
C
C   INPUT ARGUMENT LIST:
C     IPOPT    - INTEGER (20) INTERPOLATION OPTIONS
C                IPOPT(1)=0 FOR TRIANGULAR, IPOPT(1)=1 FOR RHOMBOIDAL;
C                IPOPT(2) IS TRUNCATION NUMBER
C                (DEFAULTS TO SENSIBLE IF IPOPT(2)=-1).
C     KGDSI    - INTEGER (200) INPUT GDS PARAMETERS AS DECODED BY W3FI63
C     KGDSO    - INTEGER (200) OUTPUT GDS PARAMETERS
C                (KGDSO(1)<0 IMPLIES RANDOM STATION POINTS)
C     MI       - INTEGER SKIP NUMBER BETWEEN INPUT GRID FIELDS IF KM>1
C                OR DIMENSION OF INPUT GRID FIELDS IF KM=1
C     MO       - INTEGER SKIP NUMBER BETWEEN OUTPUT GRID FIELDS IF KM>1
C                OR DIMENSION OF OUTPUT GRID FIELDS IF KM=1
C     KM       - INTEGER NUMBER OF FIELDS TO INTERPOLATE
C     IBI      - INTEGER (KM) INPUT BITMAP FLAGS (MUST BE ALL 0)
C     LI       - LOGICAL*1 (MI,KM) INPUT BITMAPS (IF SOME IBI(K)=1)
C     GI       - REAL (MI,KM) INPUT FIELDS TO INTERPOLATE
C     NO       - INTEGER NUMBER OF OUTPUT POINTS (ONLY IF KGDSO(1)<0)
C     RLAT     - REAL (NO) OUTPUT LATITUDES IN DEGREES (IF KGDSO(1)<0)
C     RLON     - REAL (NO) OUTPUT LONGITUDES IN DEGREES (IF KGDSO(1)<0)
C     CROT     - REAL (NO) VECTOR ROTATION COSINES (IF KGDSO(1)<0)
C     SROT     - REAL (NO) VECTOR ROTATION SINES (IF KGDSO(1)<0)
C                (UGRID=CROT*UEARTH-SROT*VEARTH;
C                 VGRID=SROT*UEARTH+CROT*VEARTH)
C
C   OUTPUT ARGUMENT LIST:
C     NO       - INTEGER NUMBER OF OUTPUT POINTS (ONLY IF KGDSO(1)>=0)
C     RLAT     - REAL (MO) OUTPUT LATITUDES IN DEGREES (IF KGDSO(1)>=0)
C     RLON     - REAL (MO) OUTPUT LONGITUDES IN DEGREES (IF KGDSO(1)>=0)
C     IBO      - INTEGER (KM) OUTPUT BITMAP FLAGS
C     LO       - LOGICAL*1 (MO,KM) OUTPUT BITMAPS (ALWAYS OUTPUT)
C     GO       - REAL (MO,KM) OUTPUT FIELDS INTERPOLATED
C     IRET     - INTEGER RETURN CODE
C                0    SUCCESSFUL INTERPOLATION
C                2    UNRECOGNIZED INPUT GRID OR NO GRID OVERLAP
C                3    UNRECOGNIZED OUTPUT GRID
C                41   INVALID NONGLOBAL INPUT GRID
C                42   INVALID SPECTRAL METHOD PARAMETERS
C                43   UNIMPLEMENTED OUTPUT GRID
C
C SUBPROGRAMS CALLED:
C   GDSWIZ       GRID DESCRIPTION SECTION WIZARD
C   SPTRUN       SPECTRALLY TRUNCATE GRIDDED SCALAR FIELDS
C   SPTRUNS      SPECTRALLY INTERPOLATE SCALARS TO POLAR STEREO.
C   SPTRUNM      SPECTRALLY INTERPOLATE SCALARS TO MERCATOR
C   SPTRUNG      SPECTRALLY INTERPOLATE SCALARS TO STATIONS
C
C ATTRIBUTES:
C   LANGUAGE: FORTRAN 77
C
C$$$
      INTEGER IPOPT(20)
      INTEGER KGDSI(200),KGDSO(200)
      INTEGER IBI(KM),IBO(KM)
      LOGICAL*1 LI(MI,KM),LO(MO,KM)
      REAL GI(MI,KM),XO(MO,KM),YO(MO,KM)
      REAL RLAT(MO),RLON(MO)
      REAL CROT(MO),SROT(MO)
      REAL XPTS(MO),YPTS(MO)
      REAL GO2(MO,KM)
      PARAMETER(FILL=-9999.)
      PARAMETER(RERTH=6.3712E6)
      PARAMETER(PI=3.14159265358979,DPR=180./PI)
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C  COMPUTE NUMBER OF OUTPUT POINTS AND THEIR LATITUDES AND LONGITUDES.
      IRET=0
      IF(KGDSO(1).GE.0) THEN
        CALL GDSWIZ(KGDSO, 0,MO,FILL,XPTS,YPTS,RLON,RLAT,NO,1,
     &              CROT,SROT)
        IF(NO.EQ.0) IRET=3
      ENDIF
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C  AFFIRM APPROPRIATE INPUT GRID
C    LAT/LON OR GAUSSIAN
C    NO BITMAPS
C    FULL ZONAL COVERAGE
C    FULL MERIDIONAL COVERAGE
      IDRTI=KGDSI(1)
      IM=KGDSI(2)
      JM=KGDSI(3)
      RLON1=KGDSI(5)*1.E-3
      RLON2=KGDSI(8)*1.E-3
      ISCAN=MOD(KGDSI(11)/128,2)
      JSCAN=MOD(KGDSI(11)/64,2)
      NSCAN=MOD(KGDSI(11)/32,2)
      IF(IDRTI.NE.0.AND.IDRTI.NE.4) IRET=41
      DO K=1,KM
        IF(IBI(K).NE.0) IRET=41
      ENDDO
      IF(IRET.EQ.0) THEN
        IF(ISCAN.EQ.0) THEN
          DLON=(MOD(RLON2-RLON1-1+3600,360.)+1)/(IM-1)
        ELSE
          DLON=-(MOD(RLON1-RLON2-1+3600,360.)+1)/(IM-1)
        ENDIF
        IG=NINT(360/ABS(DLON))
        IPRIME=1+MOD(-NINT(RLON1/DLON)+IG,IG)
        IMAXI=IG
        JMAXI=JM
        IF(MOD(IG,2).NE.0.OR.IM.LT.IG) IRET=41
      ENDIF
      IF(IRET.EQ.0.AND.IDRTI.EQ.0) THEN
        RLAT1=KGDSI(4)*1.E-3
        RLAT2=KGDSI(7)*1.E-3
        DLAT=(RLAT2-RLAT1)/(JM-1)
        JG=NINT(180/ABS(DLAT))
        IF(JM.EQ.JG) IDRTI=256
        IF(JM.NE.JG.AND.JM.NE.JG+1) IRET=41
      ELSEIF(IRET.EQ.0.AND.IDRTI.EQ.4) THEN
        JG=KGDSI(10)*2
        IF(JM.NE.JG) IRET=41
      ENDIF
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C  SET PARAMETERS
      IF(IRET.EQ.0) THEN
        IROMB=IPOPT(1)
        MAXWV=IPOPT(2)
        IF(MAXWV.EQ.-1) THEN
          IF(IROMB.EQ.0.AND.IDRTI.EQ.4) MAXWV=(JMAXI-1)
          IF(IROMB.EQ.1.AND.IDRTI.EQ.4) MAXWV=(JMAXI-1)/2
          IF(IROMB.EQ.0.AND.IDRTI.EQ.0) MAXWV=(JMAXI-3)/2
          IF(IROMB.EQ.1.AND.IDRTI.EQ.0) MAXWV=(JMAXI-3)/4
          IF(IROMB.EQ.0.AND.IDRTI.EQ.256) MAXWV=(JMAXI-1)/2
          IF(IROMB.EQ.1.AND.IDRTI.EQ.256) MAXWV=(JMAXI-1)/4
        ENDIF
        IF((IROMB.NE.0.AND.IROMB.NE.1).OR.MAXWV.LT.0) IRET=42
      ENDIF
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C  INTERPOLATE
      IF(IRET.EQ.0) THEN
        IF(NSCAN.EQ.0) THEN
          ISKIPI=1
          JSKIPI=IM
        ELSE
          ISKIPI=JM
          JSKIPI=1
        ENDIF
        IF(ISCAN.EQ.1) ISKIPI=-ISKIPI
        IF(JSCAN.EQ.0) JSKIPI=-JSKIPI
        ISPEC=0
C  SPECIAL CASE OF GLOBAL CYLINDRICAL GRID
        IF((KGDSO(1).EQ.0.OR.KGDSO(1).EQ.4).AND.
     &     MOD(KGDSO(2),2).EQ.0.AND.KGDSO(5).EQ.0.AND.
     &     KGDSO(11).EQ.0) THEN
          IDRTO=KGDSO(1)
          IMO=KGDSO(2)
          JMO=KGDSO(3)
          RLON2=KGDSO(8)*1.E-3
          DLONO=(MOD(RLON2-1+3600,360.)+1)/(IMO-1)
          IGO=NINT(360/ABS(DLONO))
          IF(IMO.EQ.IGO.AND.IDRTO.EQ.0) THEN
            RLAT1=KGDSO(4)*1.E-3
            RLAT2=KGDSO(7)*1.E-3
            DLAT=(RLAT2-RLAT1)/(JMO-1)
            JGO=NINT(180/ABS(DLAT))
            IF(JMO.EQ.JGO) IDRTO=256
            IF(JMO.EQ.JGO.OR.JMO.EQ.JGO+1) ISPEC=1
          ELSEIF(IMO.EQ.IGO.AND.IDRTO.EQ.4) THEN
            JGO=KGDSO(10)*2
            IF(JMO.EQ.JGO) ISPEC=1
          ENDIF
          IF(ISPEC.EQ.1) THEN
             CALL SPTRUND(IROMB,MAXWV,IDRTI,IMAXI,JMAXI,IDRTO,IMO,JMO,
     &                    KM,IPRIME,ISKIPI,JSKIPI,MI,0,0,MO,0,GI,GM,
     &                    XO,YO)
          ELSE
            IRET=43
          ENDIF
        ELSE
          IRET=43
        ENDIF
      ENDIF
      IF(IRET.EQ.0) THEN
        DO K=1,KM
          IBO(K)=0
          DO N=1,NO
            LO(N,K)=.TRUE.
          ENDDO
        ENDDO
      ELSE
CMIC$ DO ALL AUTOSCOPE
        DO K=1,KM
          IBO(K)=1
          DO N=1,NO
            LO(N,K)=.FALSE.
            XO(N,K)=0.
            YO(N,K)=0.
          ENDDO
        ENDDO
      ENDIF
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      END

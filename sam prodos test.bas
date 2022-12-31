

]
]LIST

 5  PRINT "S.A.M. will say what y
     ou type"
 6  PRINT "/Q    - quit"
 7  PRINT "/S nn - set speed, /S
     60 is normal"
 8  PRINT "/P nn - set pitch, /P
     72 is normal"
 9  PRINT "/O ppppp - use phoneme
     s, like AE4PUL"
 10  PRINT  CHR$ (4)"BLOAD SAM,A$
     4000"
 30 SAM = 16384:SP = SAM + 9:PI =
     SAM + 10:ER = SAM + 11
 35 EC = SAM + 12:RE = SAM + 13:B
     P = SAM + 14
 40 SS = 60:PP = 72
 50  POKE SP,SS: POKE PI,PP
 55  FOR I = 0 TO 6: READ B: POKE
     768 + I,B: NEXT
 56  POKE EC,0: POKE RE,255: POKE
     BP,0
 100  INPUT "> ";A$
 101  IF  MID$ (A$,1,2) = "/S" THEN
      POKE SP, VAL ( MID$ (A$,3))
     : GOTO 100
 102  IF  MID$ (A$,1,2) = "/P" THEN
      POKE PI, VAL ( MID$ (A$,3))
     : GOTO 100
 103  IF  MID$ (A$,1,2) = "/Q" THEN
      END
 105  IF  MID$ (A$,1,2) = "/O" THEN
     A$ =  CHR$ (16) +  MID$ (A$,
     3): GOSUB 500:A$ =  CHR$ (20
     )
 110  GOSUB 500
 120  GOTO 100
 500  POKE BP,0
 510  PRINT  CHR$ (4)"PR#A$300": PRINT
     A$: PRINT  CHR$ (4)"PR#0"
 520  RETURN
 1000  DATA  216,120,32,38,65,88,
     96


]CALL-151

*300L
0300-   D8          CLD
0301-   78          SEI
0302-   20 26 41    JSR   $4126
0305-   58          CLI
0306-   60          RTS



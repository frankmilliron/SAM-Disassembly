; Target assembler: cc65 v2.19.0 [--target none -C SAM Disassembly_cc65.cfg]
; 6502bench SourceGen v1.8.3
         .setcpu "6502"
MON_CSWL =       $36        ;character output hook (lo)
MON_CSWH =       $37        ;character output hook (hi)
SPKR     =       $c030      ;RW toggle speaker
MON_BELL1 =      $fbdd      ;sound bell regardless of output device
MON_COUT1 =      $fdf0      ;print Acc to screen

         .org    $4000
         jmp     Setup      ;CALL 16384

         jmp     PhenomeMode ;CALL 16387

         jmp     TextMode   ;CALL 16390

Speed:   .byte   $46        ;$4009/16393: Speed Setting (Default value $3C/60)
Pitch:   .byte   $f0        ;$400A/16394: Pitch Setting (Default value $48/72)
Error:   .byte   $ff        ;$400B/16395: Error
Echo:    .byte   $00        ;$400C/16396: $00=no echo to screen, $FF=echo char to screen
Mode:    .byte   $00        ;$400D/16397: $00=phenome mode, $ff=text mode
BufPos:  .byte   $2a        ;Current input buffer position
AStore:  .byte   $8d        ;Accumulator storage
InputBuf:
         .byte   "BAH7T, AH4DHER TAYMZ AY TAO5K VEH4RIY LOW." ;SAM input buffer ($100 bytes)
         .byte   $0d
         .byte   "TIXN WER7DZ."
         .byte   $0d
         .byte   "THAHSAYZER-AA5N AH DIH2SK."
         .byte   $0d
         .byte   $4a,$1f,$cd,$06,$11,$c3,$bc,$1b,$fe,$3b,$c2,$72,$1f,$cd,$0a,$20
         .byte   $cd,$06,$11,$3a,$85,$01,$fe,$04,$c2,$52,$1f,$3a,$89,$01,$fe,$0a
         .byte   $ca,$bc,$1b,$fe,$1a,$ca,$8b,$1f,$fe,$21,$ca,$bc,$1b,$c3,$52,$1f
         .byte   $fe,$21,$ca,$bc,$1b,$fe,$1a,$ca,$8b,$1f,$3e,$53,$cd,$18,$02,$c3
         .byte   $52,$1f,$7b,$95,$6f,$7a,$9c,$67,$c9,$21,$cf,$01,$7e,$34,$b7,$ca
         .byte   $a7,$1b,$cd,$06,$11,$cd,$a6,$20,$21,$11,$01,$36,$0d,$21,$0d,$01
         .byte   $cd,$12,$02,$2a,$cb,$01,$eb,$2a,$d4,$01,$cd,$84,$1f,$e5,$2a,$cd
         .byte   $01,$eb,$2a,$d4,$01,$cd,$84,$1f,$5c,$16,$00,$e1,$cd,$69,$18,$eb
         .byte   $cd,$a9,$20,$21,$11,$01,$11,$d6,$1f,$1a,$b7,$ca,$e4,$1f,$77,$23
         .byte   $13,$c3,$cb,$1f,$48,$20,$55,$53,$45,$20,$46,$41,$43,$54,$4f,$52
         .byte   $0d,$00,$21,$0e,$01,$cd,$12,$02,$2a,$ed,$20,$22,$d0

Setup:   lda     #<AddChar  ;Change output hooks to point to SAM input parser
         sta     MON_CSWL
         lda     #>AddChar
         sta     MON_CSWH
Setup1:  lda     #$00
         sta     Echo       ;Turn echo off
         sta     BufPos     ;Reset current buffer position
         lda     #$ff
         sta     Mode       ;Set text entry mode
         rts

AddChar: sta     AStore     ;Add character to input buffer
         txa
         pha
         tya
         pha
         lda     AStore
         and     #$7f       ;High ASCII
         cmp     #$20       ;Do we have a control character?
         bcc     Control1
         ldy     BufPos
         sta     InputBuf,y ;Add character to SAM input buffer
         inc     BufPos
         bit     Echo
         bpl     Done
         ora     #$80
         jsr     MON_COUT1  ;Echo output to screen
Done:    pla                ;Done adding characters to buffer
         tay
         pla
         tax
         lda     AStore
         rts

Control1:
         cmp     #$05       ;Ctrl-E
         bne     Control2
         lda     #$ff
         sta     Echo       ;Turn echo on
         bne     Done

Control2:
         cmp     #$0e       ;Ctrl-N
         bne     Control3
         lda     #$00
         sta     Echo       ;Turn echo off (Default in Setup)
         beq     Done

Control3:
         cmp     #$14       ;Ctrl-T
         bne     Control4
         lda     #$ff       ;Set text entry mode (Default in Setup)
         sta     Mode
         bne     Done

Control4:
         cmp     #$10       ;Ctrl-P
         bne     Control5
         lda     #$00       ;Set phenome entry mode
         sta     Mode
         beq     Done

Control5:
         cmp     #$0d       ;Ctrl-M
         bne     Done
         ldy     BufPos
         sta     InputBuf,y ;Add last character
         bit     Echo
         beq     No_LF
         lda     #$8d       ;High-ASCII return character
         jsr     MON_COUT1  ;Line Feed to screen
No_LF:   bit     Mode       ;Which playback mode?
         bne     DoTextMode
         jsr     PhenomeMode
         jmp     Done

DoTextMode:
         jsr     TextMode
         jmp     Done

PhenomeMode:
         jsr     BackupZP   ;Parse buffer for phenome entry
PlayPhenome:
         lda     #$ff       ;Jumps here once text converted to phenomes
         sta     Error
         jsr     L4676
         lda     Error
         cmp     #$ff
         bne     Exit
         jsr     L47C3
         jsr     L49A9
         jsr     L4701
         jsr     L63F4
         jsr     L4726
         lda     Speed
         sta     L621B+1
         lda     Pitch
         sta     L603E+1
@Loop:   lda     InputTemp1,x
         cmp     #$50
         bcs     @L41DB
         inx
         bne     @Loop
         beq     @L41E0

@L41DB:  lda     #$ff
         sta     InputTemp1,x
@L41E0:  jsr     L632F
         lda     #$ff
         sta     DoneFlag   ;(Was already #$FF?)
         jsr     L63AC
Exit:    jmp     RestoreZP

InputTemp1:
         .byte   $36,$37,$38,$0a,$45,$46,$47,$03,$fe,$00,$0a,$29,$0f,$00,$45,$46
         .byte   $47,$31,$15,$1b,$26,$00,$31,$15,$00,$45,$46,$47,$0b,$4b,$4c,$4d
         .byte   $00,$28,$07,$12,$05,$00,$18,$34,$14,$01,$fe,$ff,$15,$00,$28,$32
         .byte   $15,$20,$01,$fe,$ff,$20,$00,$20,$0f,$1e,$0e,$1c,$1f,$fe,$19,$0f
         .byte   $39,$3a,$3b,$26,$01,$fe,$ff,$37,$38,$17,$07,$21,$0a,$1c,$1c,$ff
         .byte   $00,$08,$1b,$00,$0a,$00,$00,$20,$36,$37,$38,$05,$2a,$2b,$00,$20
         .byte   $06,$1c,$23,$0a,$20,$31,$15,$26,$0f,$04,$fe,$09,$1c,$00,$0a,$00
         .byte   $39,$3a,$3b,$06,$20,$3f,$40,$41,$01,$fe,$ff
         .byte   " KAEN NAW4 OW4N YOHR OW3N KAA4PIY AHV SAE5M. YOH4R KUMPYUW3TER"
         .byte   " IHZ REH4DIY TUX TAOK.",$22,$0d,$0a,"490 GOSUB 5",$0d,$0a,"500"
         .byte   " END",$0d,$0a
         .byte   $1a
         .byte   "CS 2:SETCOLOR 2,0,0:?"
DoneFlag:
         .byte   $ff
         .byte   $23        ;Part of Index02?
InputTemp2:
         .byte   $08,$01,$02,$0f,$07,$02,$02,$12,$04,$00,$0e,$06,$0b,$00,$04,$02
         .byte   $02,$0c,$09,$07,$06,$00,$0c,$07,$00,$06,$02,$02,$0e,$06,$01,$04
         .byte   $00,$08,$0b,$0a,$08,$00,$06,$0e,$0d,$12,$04,$0f,$08,$00,$08,$0f
         .byte   $0d,$02,$12,$04,$0b,$02,$00,$02,$0e,$02,$07,$07,$04,$01,$08,$1c
         .byte   $08,$01,$01,$0a,$12,$01,$06,$01,$02,$05,$08,$02,$08,$07,$05,$06
         .byte   $00,$0b,$07,$00,$06,$00,$00,$02,$08,$01,$02,$0b,$06,$02,$00,$02
         .byte   $0c,$07,$02,$06,$02,$0c,$09,$06,$11,$08,$02,$13,$07,$00,$06,$00
         .byte   $07,$01,$01,$0e,$02,$0a,$01,$02,$12,$02
         .byte   " options followed by the speed e.g., 300, 1>>0.",$0d,$0a,$0a
         .byte   "            EXAMPLE:  SBO1T.600 will set the modem",$0d,$0a," "
         .byte   "                     to run at "
Index03: .res    3,$08
         .byte   $07
         .res    6,$00
         .byte   $04
         .res    14,$00
         .res    3,$06
         .byte   $05
         .res    4,$00
         .byte   $05
         .byte   $04
         .res    221,$00
StressInputTable:
         .byte   "*123456789"
Index05: .byte   " .?,-IIEAAAAUAIEUORLWYWRLWYMNNDQSSFT//ZZVDC*J***EAOAOUB**D**G*"
         .byte   "*G**P**T**K**K**UUU"
Index06: .byte   "*****YHHEAHOHXXRXHXXXXH******XX**H*HHX*H*HH*****YYYWWW********"
         .byte   "*X***********X**LMN"
Index07: .res    5,$00
         .byte   $a4
         .res    5,$a4
         .res    2,$84
         .res    2,$a4
         .res    7,$84
         .res    5,$44
         .res    3,$4c
         .byte   $48
         .byte   $4c
         .res    6,$40
         .res    4,$44
         .byte   $48
         .byte   $40
         .byte   $4c
         .byte   $44
         .res    2,$00
         .res    3,$b4
         .res    3,$94
         .res    12,$4e
         .res    12,$4b
Index08: .byte   $80
         .res    4,$c1
         .res    18,$00
         .res    4,$10
         .byte   $08
         .byte   $0c
         .byte   $08
         .byte   $04
         .byte   $40
         .byte   $24
         .res    2,$20
         .byte   $24
         .res    2,$00
         .byte   $24
         .res    2,$20
         .byte   $24
         .res    2,$20
         .byte   $00
         .byte   $20
         .res    11,$00
         .res    3,$04
         .res    9,$00
         .res    3,$04
         .res    6,$00

SaveReg: sta     $fc        ;save registers
         stx     $fb
         sty     $fa
         rts

RestReg: lda     $fc        ;restore registers
         ldx     $fb
         ldy     $fa
         rts

L4644:   jsr     SaveReg
         ldx     #$ff
         ldy     #$00
@Loop:   dex
         dey
         lda     InputTemp1,x
         sta     InputTemp1,y
         lda     InputTemp2,x
         sta     InputTemp2,y
         lda     Index03,x
         sta     Index03,y
         cpx     $f6
         bne     @Loop
         lda     $f9
         sta     InputTemp1,x
         lda     $f8
         sta     InputTemp2,x
         lda     $f7
         sta     Index03,x
         jsr     RestReg
         rts

L4676:   ldx     #$00
         txa
         tay
         sta     $ff
@Loop:   sta     Index03,y
         iny
         cpy     #$ff
         bne     @Loop
L4684:   lda     InputBuf,x
         cmp     #$0d
         beq     FoundReturn
         sta     $fe
         inx
         lda     InputBuf,x
         sta     $fd
         ldy     #$00
@Loop:   lda     Index05,y
         cmp     $fe
         bne     @L46A7
         lda     Index06,y
         cmp     #$2a
         beq     @L46A7
         cmp     $fd
         beq     @L46AE
@L46A7:  iny
         cpy     #$51
         bne     @Loop
         beq     @L46BA

@L46AE:  tya
         ldy     $ff
         sta     InputTemp1,y
         inc     $ff
         inx
         jmp     L4684

@L46BA:  ldy     #$00
@Loop1:  lda     Index06,y
         cmp     #$2a
         bne     @L46CA
         lda     Index05,y
         cmp     $fe
         beq     @L46D1
@L46CA:  iny
         cpy     #$51
         bne     @Loop1
         beq     @L46DC

@L46D1:  tya
         ldy     $ff
         sta     InputTemp1,y
         inc     $ff
         jmp     L4684

@L46DC:  lda     $fe
         ldy     #$08
@Loop2:  cmp     StressInputTable,y
         beq     SetStress
         dey
         bne     @Loop2
         stx     Error
         jsr     ErrorBell
         rts

SetStress:
         tya
         ldy     $ff
         dey
         sta     Index03,y
         jmp     L4684

FoundReturn:
         lda     #$ff
         ldy     $ff
         sta     InputTemp1,y
         rts

L4701:   ldy     #$00
@Loop:   lda     InputTemp1,y
         cmp     #$ff
         beq     @Exit
         tax
         lda     Index03,y
         beq     @L471B
         bmi     @L471B
         lda     L57E0,x
         sta     InputTemp2,y
         jmp     @L4721

@L471B:  lda     L5830,x
         sta     InputTemp2,y
@L4721:  iny
         jmp     @Loop

@Exit:   rts

L4726:   lda     #$00
         sta     $ff
@L472A:  ldx     $ff
         lda     InputTemp1,x
         cmp     #$ff
         bne     @L4734
         rts

@L4734:  sta     $f9
         tay
         lda     Index07,y
         tay
         and     #$02
         bne     @L4744
         inc     $ff
         jmp     @L472A

@L4744:  tya
         and     #$01
         bne     @L4775
         inc     $f9
         ldy     $f9
         lda     Index03,x
         sta     $f7
         lda     L5830,y
         sta     $f8
         inx
         stx     $f6
         jsr     L4644
         inc     $f9
         ldy     $f9
         lda     L5830,y
         sta     $f8
         inx
         stx     $f6
         jsr     L4644
         inc     $ff
         inc     $ff
         inc     $ff
         jmp     @L472A

@L4775:  inx
         lda     InputTemp1,x
         beq     @L4775
         sta     $f5
         cmp     #$ff
         bne     @L4784
         jmp     @L4796

@L4784:  tay
         lda     Index07,y
         and     #$08
         bne     @L47BE
         lda     $f5
         cmp     #$24
         beq     @L47BE
         cmp     #$25
         beq     @L47BE
@L4796:  ldx     $ff
         lda     Index03,x
         sta     $f7
         inx
         stx     $f6
         ldx     $f9
         inx
         stx     $f9
         lda     L5830,x
         sta     $f8
         jsr     L4644
         inc     $f6
         inx
         stx     $f9
         lda     L5830,x
         sta     $f8
         jsr     L4644
         inc     $ff
         inc     $ff
@L47BE:  inc     $ff
         jmp     @L472A

L47C3:   lda     #$00
         sta     $ff
@L47C7:  ldx     $ff
         lda     InputTemp1,x
         bne     @L47D3
         inc     $ff
         jmp     @L47C7

@L47D3:  cmp     #$ff
         bne     @L47D8
         rts

@L47D8:  tay
         lda     Index07,y
         and     #$10
         beq     @L47FF
         lda     Index03,x
         sta     $f7
         inx
         stx     $f6
         lda     Index07,y
         and     #$20
         beq     @L47FB
         lda     #$15
@L47F1:  sta     $f9
         jsr     L4644
         ldx     $ff
         jmp     @L4923

@L47FB:  lda     #$14
         bne     @L47F1

@L47FF:  lda     InputTemp1,x
         cmp     #$4e
         bne     @L481D
         lda     #$18
@L4808:  sta     $f9
         lda     Index03,x
         sta     $f7
         lda     #$0d
         sta     InputTemp1,x
         inx
         stx     $f6
         jsr     L4644
         jmp     @L49A4

@L481D:  cmp     #$4f
         bne     @L4825
         lda     #$1b
         bne     @L4808

@L4825:  cmp     #$50
         bne     @L482D
         lda     #$1c
         bne     @L4808

@L482D:  tay
         lda     Index07,y
         and     #$80
         beq     @L4860
         lda     Index03,x
         beq     @L4860
         inx
         lda     InputTemp1,x
         bne     @L4860
         inx
         ldy     InputTemp1,x
         lda     Index07,y
         and     #$80
         beq     @L4860
         lda     Index03,x
         beq     @L4860
         stx     $f6
         lda     #$00
         sta     $f7
         lda     #$1f
         sta     $f9
         jsr     L4644
         jmp     @L49A4

@L4860:  ldx     $ff
         lda     InputTemp1,x
         cmp     #$17
         bne     @L4899
         dex
         lda     InputTemp1,x
         cmp     #$45
         bne     @L4879
         lda     #$2a
         sta     InputTemp1,x
         jmp     @L4941

@L4879:  cmp     #$39
         bne     @L4885
         lda     #$2c
         sta     InputTemp1,x
         jmp     @L494A

@L4885:  tay
         inx
         lda     Index07,y
         and     #$80
         bne     @L4891
         jmp     @L49A4

@L4891:  lda     #$12
         sta     InputTemp1,x
         jmp     @L49A4

@L4899:  cmp     #$18
         bne     @L48B4
         dex
         ldy     InputTemp1,x
         inx
         lda     Index07,y
         and     #$80
         bne     @L48AC
         jmp     @L49A4

@L48AC:  lda     #$13
         sta     InputTemp1,x
         jmp     @L49A4

@L48B4:  cmp     #$20
         bne     @L48CC
         dex
         lda     InputTemp1,x
         cmp     #$3c
         beq     @L48C3
         jmp     @L49A4

@L48C3:  inx
         lda     #$26
         sta     InputTemp1,x
         jmp     @L49A4

@L48CC:  cmp     #$48
         bne     @L48E7
         inx
         ldy     InputTemp1,x
         dex
         lda     Index07,y
         and     #$20
         beq     @L48DF
         jmp     @L4902

@L48DF:  lda     #$4b
         sta     InputTemp1,x
         jmp     @L4902

@L48E7:  cmp     #$3c
         bne     @L4902
         inx
         ldy     InputTemp1,x
         dex
         lda     Index07,y
         and     #$20
         beq     @L48FA
         jmp     @L49A4

@L48FA:  lda     #$3f
         sta     InputTemp1,x
         jmp     @L49A4

@L4902:  ldy     InputTemp1,x
         lda     Index07,y
         and     #$01
         beq     @L4923
         dex
         lda     InputTemp1,x
         inx
         cmp     #$20
         beq     @L4919
         tya
         jmp     @L4962

@L4919:  sec
         tya
         sbc     #$0c
         sta     InputTemp1,x
         jmp     @L49A4

@L4923:  lda     InputTemp1,x
         cmp     #$35
         bne     @L4941
         dex
         ldy     InputTemp1,x
         inx
         lda     Index08,y
         and     #$04
         bne     @L4939
         jmp     @L49A4

@L4939:  lda     #$10
         sta     InputTemp1,x
         jmp     @L49A4

@L4941:  cmp     #$2a
         bne     @L494A
@L4945:  tay
         iny
         jmp     @L4951

@L494A:  cmp     #$2c
         beq     @L4945
         jmp     @L4962

@L4951:  sty     $f9
         inx
         stx     $f6
         dex
         lda     Index03,x
         sta     $f7
         jsr     L4644
         jmp     @L49A4

@L4962:  cmp     #$45
         bne     @L4968
         beq     @L496F

@L4968:  cmp     #$39
         beq     @L496F
         jmp     @L49A4

@L496F:  dex
         ldy     InputTemp1,x
         inx
         lda     Index07,y
         and     #$80
         beq     @L49A4
         inx
         lda     InputTemp1,x
         beq     @L4998
         tay
         lda     Index07,y
         and     #$80
         beq     @L49A4
         lda     Index03,x
         bne     @L49A4
@L498E:  ldx     $ff
         lda     #$1e
         sta     InputTemp1,x
         jmp     @L49A4

@L4998:  inx
         lda     InputTemp1,x
         tay
         lda     Index07,y
         and     #$80
         bne     @L498E
@L49A4:  inc     $ff
         jmp     @L47C7

L49A9:   lda     #$00
         sta     $ff
@L49AD:  ldx     $ff
         ldy     InputTemp1,x
         cpy     #$ff
         bne     @L49B7
         rts

@L49B7:  lda     Index07,y
         and     #$40
         beq     @L49D6
         inx
         ldy     InputTemp1,x
         lda     Index07,y
         and     #$80
         beq     @L49D6
         ldy     Index03,x
         beq     @L49D6
         bmi     @L49D6
         iny
         dex
         tya
         sta     Index03,x
@L49D6:  inc     $ff
         jmp     @L49AD

ZPbackup:
         .byte   $4f,$80,$00,$00,$15,$ab,$05,$ab,$f2,$bc,$22,$bd,$5a,$bd,$b6,$bd ;Could be zeroed out?
         .byte   $0c,$01,$00,$00,$4c,$0b,$22,$01,$f1,$94,$00,$00,$00,$00,$00,$80
         .byte   "COPYRIGHT 1982 DON'T ASK - ALL RIGHTS l buffer to disk, XON se"
         .byte   "nt to resume."
         .byte   $0d,$0a,$0a,$00,$3a,$1e,$01,$cd,$9c,$1c,$20,$20,$2d,$20,$54,$72
         .byte   $45,$45,$73,$66,$65,$72,$20,$41,$53,$43,$49,$49,$20,$66,$69,$6c
         .byte   $65,$20,$74,$6f,$20,$72,$65,$6d,$6f,$74,$65,$0d,$0a,$0a,$00,$3a
         .byte   $14,$01,$b7,$3a,$20,$01,$c2,$92,$35,$cd,$9c,$1c,$20,$20,$2d,$20
         .byte   $53,$65,$6e,$64,$20,$6c,$6f,$63,$61,$6c,$20,$63,$6f,$6e,$74,$72
         .byte   $6f,$6c,$20,$63,$68,$61,$72,$61,$63,$74,$65,$72,$20,$74,$6f,$20
         .byte   $72,$65,$6d,$6f,$74,$65,$0d,$0a,$0a,$00,$c3,$c9,$35,$cd,$9c,$1c
         .byte   $20,$20,$2d,$20,$4e,$65,$78,$74,$20,$63,$68,$61,$72,$61,$63,$74
         .byte   $65,$72,$20,$77,$69,$6c,$6c,$20,$62,$65,$20,$75,$73,$65,$64,$20
         .byte   $66,$6f,$72,$20,$6c,$6f,$63,$61,$6c,$20,$63,$6f,$6e,$74,$72,$6f
         .byte   $6c,$0d,$0a,$00,$cd,$ab,$1c,$0d,$0a,$44,$65,$66,$61,$75,$6c,$74
         .byte   $20,$44,$72,$69,$76,$65,$20,$00,$0e,$19
L4B00:   .res    3,$00
         .res    6,$10
         .res    6,$20
         .res    7,$30
         .res    7,$40
         .res    8,$50
         .res    12,$60
         .res    31,$70
         .res    12,$60
         .res    8,$50
         .res    7,$40
         .res    7,$30
         .res    6,$20
         .res    6,$10
         .res    5,$00
         .res    6,$f0
         .res    6,$e0
         .res    7,$d0
         .res    7,$c0
         .res    8,$b0
         .res    12,$a0
         .res    31,$90
         .res    12,$a0
         .res    8,$b0
         .res    7,$c0
         .res    7,$d0
         .res    6,$e0
         .res    6,$f0
         .res    2,$00
L4C00:   .res    128,$90
         .res    128,$70
L4D00:   .res    18,$00
         .res    2,$01
         .res    2,$02
         .res    2,$03
         .res    2,$04
         .res    2,$05
         .res    2,$06
         .res    2,$07
         .byte   $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f
         .byte   $00,$01,$03,$04,$06,$07,$09,$0a,$0c,$0d,$0f,$10,$12,$13,$15,$16
         .byte   $00,$02,$04,$06,$08,$0a,$0c,$0e,$10,$12,$14,$16,$18,$1a,$1c,$1e
         .byte   $00,$02,$05,$07,$0a,$0c,$0f,$11,$14,$16,$19,$1b,$1e,$20,$23,$25
         .byte   $00,$03,$06,$09,$0c,$0f,$12,$15,$18,$1b,$1e,$21,$24,$27,$2a,$2d
         .byte   $00,$03,$07,$0a,$0e,$11,$15,$18,$1c,$1f,$23,$26,$2a,$2d,$31,$34
         .byte   $00,$fc,$f8,$f4,$f0,$ec,$e8,$e4,$e0,$dc,$d8,$d4,$d0,$cc,$c8,$c4
         .byte   $00,$fc,$f9,$f5,$f2,$ee,$eb,$e7,$e4,$e0,$dd,$d9,$d6,$d2,$cf,$cb
         .byte   $00,$fd,$fa,$f7,$f4,$f1,$ee,$eb,$e8,$e5,$e2,$df,$dc,$d9,$d6,$d3
         .byte   $00,$fd,$fb,$f8,$f6,$f3,$f1,$ee,$ec,$e9,$e7,$e4,$e2,$df,$dd,$da
         .byte   $00,$fe,$fc,$fa,$f8,$f6,$f4,$f2,$f0,$ee,$ec,$ea,$e8,$e6,$e4,$e2
         .byte   $00,$fe,$fd,$fb,$fa,$f8,$f7,$f5,$f4,$f2,$f1,$ef,$ee,$ec,$eb,$e9
         .byte   $00,$ff,$fe,$fd,$fc,$fb,$fa,$f9,$f8,$f7,$f6,$f5,$f4,$f3,$f2,$f1
         .byte   $00,$ff,$ff,$fe,$fe,$fd,$fd,$fc,$fc,$fb,$fb,$fa,$fa,$f9,$f9,$f8
L4E00:   .byte   $d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d9,$da,$db,$dd,$de,$e1,$e5,$e8
         .byte   $e9,$eb,$eb,$eb,$ea,$e9,$e7,$e7,$e7,$e7,$e7,$e7,$e7,$e7,$e9,$ea
         .byte   $ec,$ed,$ed,$ed,$ed,$ed,$ed,$ea,$e6,$e3,$e3,$e3,$e3,$e3,$e3,$e3
         .byte   $e3,$e4,$e5,$e6,$e6,$e7,$e8,$e9,$e9,$e9,$e9,$e9,$eb,$ed,$ed,$ed
         .byte   $ed,$ed,$ed,$ed,$ec,$ec,$ec,$ec,$ea,$e8,$e7,$e5,$e3,$e3,$e3,$e3
         .byte   $e3,$e3,$e3,$e4,$e5,$e6,$e6,$e7,$e8,$e9,$e9,$ea,$eb,$ec,$ed,$ed
         .byte   $ed,$ed,$ed,$ed,$ed,$ed,$eb,$e7,$e4,$e3,$e2,$e1,$e0,$df,$df,$e0
         .byte   $e1,$e1,$e3,$e5,$e6,$e9,$eb,$ed,$ed,$ed,$ed,$ed,$ed,$ed,$ec,$eb
         .byte   $ea,$e9,$e7,$e5,$e5,$e4,$e2,$e1,$df,$dd,$dc,$db,$da,$da,$db,$dc
         .byte   $dd,$df,$e0,$e1,$e3,$e4,$e5,$e7,$e7,$e7,$e8,$e8,$e9,$e9,$ea,$ea
         .byte   $eb,$eb,$eb,$eb,$ea,$ea,$e9,$ea,$eb,$ec,$ed,$ed,$ee,$ee,$ef,$f0
         .byte   $f1,$f2,$f3,$f4,$f5,$f6,$f8,$f9,$fa,$fc,$fd,$fe,$00,$01,$02,$03
         .byte   $02,$00,$fe,$fd,$fa,$f7,$f6,$f3,$f1,$f0,$ee,$ec,$eb,$e9,$e7,$e7
         .byte   $e7,$e7,$e7,$e7,$e7,$e7,$e7,$14,$12,$0f,$0d,$0b,$08,$08,$08,$08
         .byte   $08,$08,$08,$08,$08,$b9,$1a,$20,$a0,$ad,$17,$8b,$ca,$98,$19,$6d
         .byte   $52,$cb,$1d,$90,$fb,$3d,$61,$3a,$56,$50,$7e,$8a,$52,$f6,$37,$b2
L4F00:   .byte   $17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$13,$0f,$0a
         .byte   $0a,$0a,$0a,$0a,$0c,$0f,$12,$12,$12,$12,$12,$12,$12,$12,$0f,$0c
         .byte   $09,$06,$06,$06,$06,$06,$06,$0d,$14,$1b,$1b,$1b,$1b,$1b,$1b,$1b
         .byte   $1a,$18,$17,$15,$14,$12,$11,$0f,$0f,$0f,$0f,$0f,$0b,$06,$06,$06
         .byte   $06,$06,$06,$07,$09,$09,$09,$09,$0c,$10,$13,$17,$1b,$1b,$1b,$1b
         .byte   $1b,$1b,$1a,$18,$17,$15,$14,$12,$11,$0f,$0f,$0d,$0b,$09,$06,$06
         .byte   $06,$06,$06,$06,$06,$06,$0b,$10,$15,$15,$15,$15,$15,$15,$15,$15
         .byte   $15,$15,$13,$10,$0e,$0b,$09,$06,$06,$06,$06,$06,$06,$06,$06,$06
         .byte   $07,$07,$08,$08,$08,$08,$0a,$0c,$0e,$10,$13,$13,$13,$13,$13,$13
         .byte   $13,$13,$13,$13,$13,$12,$12,$12,$12,$12,$11,$10,$0f,$0e,$0d,$0c
         .byte   $0a,$0a,$0a,$0b,$0c,$0d,$0e,$0e,$0e,$0e,$0f,$10,$11,$12,$12,$12
         .byte   $12,$12,$12,$12,$12,$12,$11,$11,$10,$0f,$0f,$0e,$0d,$0d,$0d,$0d
         .byte   $0d,$0d,$0d,$0d,$0e,$10,$11,$13,$13,$13,$13,$13,$13,$13,$13,$13
         .byte   $13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13
         .byte   $13,$13,$13,$13,$13,$6e,$64,$20,$6d,$65,$73,$73,$61,$67,$65,$2c
         .byte   $0d,$0a,$77,$68,$65,$72,$65,$20,$30,$3d,$31,$31,$30,$2c,$20,$31
L5000:   .byte   $2c,$2c,$2c,$2c,$2c,$2c,$2c,$2c,$2c,$2c,$2c,$2c,$2c,$2d,$2e,$2f
         .byte   $2f,$2f,$2f,$2f,$2f,$30,$31,$31,$31,$31,$31,$31,$31,$31,$35,$39
         .byte   $3d,$42,$42,$42,$42,$42,$42,$39,$30,$27,$27,$27,$27,$27,$27,$27
         .byte   $2a,$2e,$32,$36,$39,$3d,$41,$45,$45,$45,$45,$45,$3a,$2e,$2e,$2e
         .byte   $2e,$2e,$2e,$30,$33,$33,$33,$33,$31,$2f,$2c,$2a,$27,$27,$27,$27
         .byte   $27,$27,$2a,$2e,$32,$36,$39,$3d,$41,$45,$45,$45,$44,$43,$42,$42
         .byte   $42,$42,$42,$42,$42,$42,$37,$2b,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f
         .byte   $1f,$1f,$27,$30,$39,$42,$4b,$54,$54,$54,$54,$54,$54,$54,$4c,$43
         .byte   $3a,$31,$28,$28,$28,$28,$2d,$32,$38,$3d,$43,$43,$43,$43,$43,$41
         .byte   $3f,$3d,$3a,$38,$36,$33,$33,$33,$33,$33,$37,$3c,$41,$45,$4a,$4f
         .byte   $54,$54,$4a,$3f,$34,$29,$1e,$1e,$1e,$1e,$1e,$1e,$1e,$1e,$1e,$1e
         .byte   $1e,$1e,$1e,$1e,$1e,$1e,$1e,$1e,$1e,$1e,$1e,$1e,$1d,$1d,$1d,$1d
         .byte   $1d,$1d,$1d,$1d,$26,$30,$39,$43,$43,$43,$43,$43,$43,$43,$43,$43
         .byte   $43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43
         .byte   $43,$43,$43,$43,$43,$6f,$64,$65,$20,$73,$65,$74,$0d,$0a,$00,$c9
         .byte   $cd,$ab,$1c
         .byte   "Checksum mode"
L5100:   .byte   $57,$57,$57,$57,$57,$57,$57,$57,$57,$57,$57,$57,$57,$59,$5b,$5d
         .byte   $5d,$5d,$5d,$5d,$53,$49,$3e,$3e,$3e,$3e,$3e,$3e,$3e,$3e,$4c,$5b
         .byte   $6a,$79,$79,$79,$79,$79,$79,$6e,$63,$58,$58,$58,$58,$58,$58,$58
         .byte   $58,$59,$59,$5a,$5b,$5b,$5c,$5d,$5d,$5d,$5d,$5d,$57,$51,$51,$51
         .byte   $51,$51,$51,$57,$5d,$5d,$5d,$5d,$5c,$5b,$5a,$59,$58,$58,$58,$58
         .byte   $58,$58,$58,$59,$59,$5a,$5b,$5b,$5c,$5d,$5d,$64,$6b,$72,$79,$79
         .byte   $79,$79,$79,$79,$79,$79,$6e,$63,$58,$58,$58,$58,$58,$58,$58,$58
         .byte   $58,$58,$59,$5a,$5b,$5c,$5d,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5b,$57
         .byte   $54,$50,$4c,$4c,$4c,$4c,$4f,$52,$55,$58,$5b,$5b,$5b,$5b,$5b,$57
         .byte   $53,$4f,$4b,$47,$43,$3e,$3e,$3e,$3e,$3e,$44,$4b,$52,$59,$60,$67
         .byte   $6e,$6e,$6e,$6e,$6e,$6e,$6e,$6e,$6e,$6a,$66,$61,$5d,$58,$58,$58
         .byte   $58,$58,$58,$58,$58,$57,$56,$55,$54,$53,$52,$51,$50,$50,$50,$50
         .byte   $50,$50,$50,$50,$52,$55,$58,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b
         .byte   $5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b
         .byte   $5b,$5b,$5b,$5b,$5b,$c2,$cf,$3c,$cd,$ab,$1c,$4e,$4f,$54,$20,$00
         .byte   $cd,$ab,$1c
         .byte   "sent after <C"
L5200:   .byte   $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0d,$0b,$08
         .byte   $08,$08,$08,$08,$08,$08,$09,$09,$09,$09,$09,$09,$09,$09,$05,$03
         .byte   $02,$00,$00,$00,$00,$00,$00,$03,$06,$0f,$0f,$0f,$0f,$0f,$0f,$0f
         .byte   $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0d,$0d,$0d,$0d,$0d,$0b,$09,$09,$09
         .byte   $09,$09,$09,$09,$08,$08,$08,$08,$08,$09,$0b,$0d,$0f,$0f,$0f,$0f
         .byte   $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0d,$0d,$08,$04,$02,$00,$00
         .byte   $00,$00,$00,$00,$00,$00,$03,$06,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
         .byte   $0f,$0f,$0b,$06,$04,$03,$02,$00,$00,$00,$00,$00,$00,$00,$02,$02
         .byte   $03,$04,$08,$08,$08,$08,$08,$09,$09,$0b,$0d,$0d,$0d,$0d,$0d,$0d
         .byte   $0d,$0d,$0d,$0d,$0d,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b
         .byte   $0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0d,$0d,$0f,$0f,$0f
         .byte   $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0d,$0d,$0d,$0d,$0b,$0b,$0b,$0b
         .byte   $0b,$0b,$0b,$0b,$06,$04,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00
         .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
         .byte   $00,$00,$00,$00,$00,$a4,$02,$02,$aa,$50,$02,$02,$50,$02,$02,$02
         .byte   $00,$02,$02,$9d,$00,$00,$9d,$00,$02,$00,$e0,$02,$01,$9d,$00,$02
L5300:   .byte   $09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$06,$04,$02
         .byte   $02,$02,$02,$02,$03,$04,$08,$08,$08,$08,$08,$08,$08,$08,$05,$03
         .byte   $02,$00,$00,$00,$00,$00,$00,$02,$04,$0b,$0b,$0b,$0b,$0b,$0b,$0b
         .byte   $0b,$0b,$0b,$0b,$0b,$0b,$0b,$09,$09,$09,$09,$09,$04,$02,$02,$02
         .byte   $02,$02,$02,$02,$02,$02,$02,$02,$03,$04,$05,$08,$0b,$0b,$0b,$0b
         .byte   $0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$09,$09,$05,$03,$02,$00,$00
         .byte   $00,$00,$00,$00,$00,$00,$02,$04,$09,$09,$09,$09,$09,$09,$09,$09
         .byte   $09,$09,$06,$04,$03,$02,$02,$00,$00,$00,$06,$00,$00,$00,$00,$01
         .byte   $01,$02,$02,$02,$02,$02,$03,$04,$05,$08,$0b,$0b,$0b,$0b,$0b,$0b
         .byte   $0b,$0b,$0b,$0b,$0b,$09,$09,$09,$09,$09,$09,$09,$09,$08,$08,$08
         .byte   $06,$06,$06,$06,$05,$05,$04,$04,$04,$04,$05,$06,$08,$09,$09,$09
         .byte   $09,$09,$09,$09,$09,$09,$08,$08,$06,$06,$05,$05,$04,$04,$04,$04
         .byte   $04,$04,$04,$04,$03,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00
         .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
         .byte   $00,$00,$00,$00,$00,$02,$4f,$00,$02,$aa,$02,$02,$02,$02,$02,$aa
         .byte   $02,$02,$02,$00,$02,$00,$02,$02,$02,$00,$00,$02,$02,$02,$00,$02
L5400:   .byte   $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00
         .byte   $00,$00,$00,$00,$01,$02,$03,$03,$03,$03,$03,$03,$03,$03,$02,$02
         .byte   $02,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01
         .byte   $01,$02,$02,$02,$02,$03,$03,$04,$04,$04,$04,$04,$02,$00,$00,$00
         .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01
         .byte   $01,$01,$01,$02,$02,$02,$02,$03,$03,$04,$04,$03,$02,$02,$00,$00
         .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
         .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00
         .byte   $00,$00,$00,$00,$00,$00,$01,$02,$02,$03,$04,$04,$04,$04,$04,$04
         .byte   $04,$04,$04,$04,$04,$03,$03,$03,$03,$03,$03,$03,$03,$04,$04,$04
         .byte   $04,$04,$04,$03,$02,$02,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00
         .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
         .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
         .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
         .byte   $00,$00,$00,$00,$00,$9d,$00,$00,$02,$4f,$02,$a4,$02,$a4,$a4,$02
         .byte   $02,$aa,$00,$02,$02,$02,$a4,$a4,$02,$02,$50,$50,$02,$02,$02,$4f
L5500:   .res    14,$00
         .res    6,$03
         .res    15,$00
         .res    2,$19
         .res    30,$00
         .res    6,$01
         .res    25,$00
         .res    2,$19
         .res    27,$00
         .res    8,$03
         .res    94,$00
         .byte   $12,$02,$2a,$cb,$01,$eb,$2a,$d4,$01,$cd,$84,$1f,$e5,$2a,$cd,$01
         .byte   $eb,$2a,$d4,$01,$cd,$84,$1f,$5c,$16,$00,$e1
L5600:   .byte   $00,$13,$13,$13,$13,$0a,$0e,$13,$18,$1b,$17,$15,$10,$14,$0e,$12
         .byte   $0e,$12,$12,$10,$0d,$0f,$0b,$12,$0e,$0b,$09,$06,$06,$06,$06,$11
         .byte   $06,$06,$06,$06,$0e,$10,$09,$0a,$08,$0a,$06,$06,$06,$05,$06,$00
         .byte   $13,$1b,$15,$1b,$12,$0d,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06
         .byte   $06,$06,$06,$06,$06,$06,$06,$06,$06,$0a,$0a,$06,$06,$06,$2c,$13
L5650:   .byte   $00,$43,$43,$43,$43,$54,$49,$43,$3f,$28,$2c,$1f,$25,$2d,$49,$31
         .byte   $24,$1e,$33,$25,$1d,$45,$18,$32,$1e,$18,$53,$2e,$36,$56,$36,$43
         .byte   $49,$4f,$1a,$42,$49,$25,$33,$42,$28,$2f,$4f,$4f,$42,$4f,$6e,$00
         .byte   $48,$27,$1f,$2b,$1e,$22,$1a,$1a,$1a,$42,$42,$42,$6e,$6e,$6e,$54
         .byte   $54,$54,$1a,$1a,$1a,$42,$42,$42,$6d,$56,$6d,$54,$54,$54,$7f,$7f
L56A0:   .byte   $00,$5b,$5b,$5b,$5b,$6e,$5d,$5b,$58,$59,$57,$58,$52,$59,$5d,$3e
         .byte   $52,$58,$3e,$6e,$50,$5d,$5a,$3c,$6e,$5a,$6e,$51,$79,$65,$79,$5b
         .byte   $63,$6a,$51,$79,$5d,$52,$5d,$67,$4c,$5d,$65,$65,$79,$65,$79,$00
         .byte   $5a,$58,$58,$58,$58,$52,$51,$51,$51,$79,$79,$79,$70,$6e,$6e,$5e
         .byte   $5e,$5e,$51,$51,$51,$79,$79,$79,$65,$65,$70,$5e,$5e,$5e,$08,$01
L56F0:   .byte   $00,$00,$00,$00,$00,$0d,$0d,$0e,$0f,$0f,$0f,$0f,$0f,$0c,$0d,$0c
         .byte   $0f,$0f,$0d,$0d,$0d,$0e,$0d,$0c,$0d,$0d,$0d,$0c,$09,$09,$00,$00
         .byte   $00,$00,$00,$00,$00,$00,$0b,$0b,$0b,$0b,$00,$00,$01,$0b,$00,$02
         .byte   $0e,$0f,$0f,$0f,$0f,$0d,$02,$04,$00,$02,$04,$00,$01,$04,$00,$01
         .byte   $04,$00,$00,$00,$00,$00,$00,$00,$00,$0c,$00,$00,$00,$00,$0f,$0f
L5740:   .byte   $00,$00,$00,$00,$00,$0a,$0b,$0d,$0e,$0d,$0c,$0c,$0b,$09,$0b,$0b
         .byte   $0c,$0c,$0c,$08,$08,$0c,$08,$0a,$08,$08,$0a,$03,$09,$06,$00,$00
         .byte   $00,$00,$00,$00,$00,$00,$03,$05,$03,$04,$00,$00,$00,$05,$0a,$02
         .byte   $0e,$0d,$0c,$0d,$0c,$08,$00,$01,$00,$00,$01,$00,$00,$01,$00,$00
         .byte   $01,$00,$00,$00,$00,$00,$00,$00,$00,$0a,$00,$00,$0a,$00,$00,$00
L5790:   .byte   $00,$00,$00,$00,$00,$08,$07,$08,$08,$01,$01,$00,$01,$00,$07,$05
         .byte   $01,$00,$06,$01,$00,$07,$00,$05,$01,$00,$08,$00,$00,$03,$00,$00
         .byte   $00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$0e,$01
         .byte   $09,$01,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
         .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$00,$00,$05,$00,$13,$10
L57E0:   .byte   $00,$12,$12,$12,$08,$0b,$09,$0b,$0e,$0f,$0b,$10,$0c,$06,$06,$0e
         .byte   $0c,$0e,$0c,$0b,$08,$08,$0b,$0a,$09,$08,$08,$08,$08,$08,$03,$05
         .byte   $02,$02,$02,$02,$02,$02,$06,$06,$08,$06,$06,$02,$09,$04,$02,$01
         .byte   $0e,$0f,$0f,$0f,$0e,$0e,$08,$02,$02,$07,$02,$01,$07,$02,$02,$07
         .byte   $02,$02,$08,$02,$02,$06,$02,$02,$07,$02,$04,$07,$01,$04,$05,$05
L5830:   .byte   $00,$12,$12,$12,$08,$08,$08,$08,$08,$0b,$06,$0c,$0a,$05,$05,$0b
         .byte   $0a,$0a,$0a,$09,$08,$07,$09,$07,$06,$08,$06,$07,$07,$07,$02,$05
         .byte   $02,$02,$02,$02,$02,$02,$06,$06,$07,$06,$06,$02,$08,$03,$01,$1e
         .byte   $0d,$0c,$0c,$0c,$0e,$09,$06,$01,$02,$05,$01,$01,$06,$01,$02,$06
         .byte   $01,$02,$08,$02,$02,$04,$02,$02,$06,$01,$04,$06,$01,$04,$c7,$ff
L5880:   .byte   $00,$02,$02,$02,$02,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
         .byte   $04,$04,$03,$02,$04,$04,$02,$02,$02,$02,$02,$01,$01,$01,$01,$01
         .byte   $01,$01,$01,$01,$01,$01,$02,$02,$02,$01,$00,$01,$00,$01,$00,$05
         .byte   $05,$05,$05,$05,$04,$04,$02,$00,$01,$02,$00,$01,$02,$00,$01,$02
         .byte   $00,$01,$02,$00,$02,$02,$00,$01,$03,$00,$02,$03,$00,$02,$a0,$a0
L58D0:   .byte   $00,$02,$02,$02,$02,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
         .byte   $04,$04,$03,$03,$04,$04,$03,$03,$03,$03,$03,$01,$02,$03,$02,$01
         .byte   $03,$03,$03,$03,$01,$01,$03,$03,$03,$02,$02,$03,$02,$03,$00,$00
         .byte   $05,$05,$05,$05,$04,$04,$02,$00,$02,$02,$00,$03,$02,$00,$04,$02
         .byte   $00,$03,$02,$00,$02,$02,$00,$02,$03,$00,$03,$03,$00,$03,$b0,$a0
L5920:   .byte   $00,$1f,$1f,$1f,$1f,$02,$02,$02,$02,$02,$02,$02,$02,$02,$05,$05
         .byte   $02,$0a,$02,$08,$05,$05,$0b,$0a,$09,$08,$08,$a0,$08,$08,$17,$1f
         .byte   $12,$12,$12,$12,$1e,$1e,$14,$14,$14,$14,$17,$17,$1a,$1a,$1d,$1d
         .byte   $02,$02,$02,$02,$02,$02,$1a,$1d,$1b,$1a,$1d,$1b,$1a,$1d,$1b,$1a
         .byte   $1d,$1b,$17,$1d,$17,$17,$1d,$17,$17,$1d,$17,$17,$1d,$17,$17,$17
L5970:   .res    32,$00
         .byte   $f1,$e2,$d3,$bb,$7c,$95,$01,$02,$03,$03,$00,$72,$00,$02
         .res    21,$00
         .byte   $1b
         .res    2,$00
         .byte   $19
         .res    9,$00
         .byte   $38,$84,$6b,$19,$c6,$63,$18,$86,$73,$98,$c6,$b1,$1c,$ca,$31,$8c
         .byte   $c7,$31,$88,$c2,$30,$98,$46,$31,$18,$c6,$35,$0c,$ca,$31,$0c,$c6
         .byte   $21,$10,$24,$69,$12,$c2,$31,$14,$c4,$71,$08,$4a,$22,$49,$ab,$6a
         .byte   $a8,$ac,$49,$51,$32,$d5,$52,$88,$93,$6c,$94,$22,$15,$54,$d2,$25
         .byte   $96,$d4,$50,$a5,$46,$21,$08,$85,$6b,$18,$c4,$63,$10,$ce,$6b,$18
         .byte   $8c,$71,$19,$8c,$63,$35,$0c,$c6,$33,$99,$cc,$6c,$b5,$4e,$a2,$99
         .byte   $46,$21,$28,$82,$95,$2e,$e3,$30,$9c,$c5,$30,$9c,$a2,$b1,$9c,$67
         .byte   $31,$88,$66,$59,$2c,$53,$18,$84,$67,$50,$ca,$e3,$0a,$ac,$ab,$30
         .byte   $ac,$62,$30,$8c,$63,$10,$94,$62,$b1,$8c,$82,$28,$96,$33,$98,$d6
         .byte   $b5,$4c,$62,$29,$a5,$4a,$b5,$9c,$c6,$31,$14,$d6,$38,$9c,$4b,$b4
         .byte   $86,$65,$18,$ae,$67,$1c,$a6,$63,$19,$96,$23,$19,$84,$13,$08,$a6
         .byte   $52,$ac,$ca,$22,$89,$6e,$ab,$19,$8c,$62,$34,$c4,$62,$19,$86,$63
         .byte   $18,$c4,$23,$58,$d6,$a3,$50,$42,$54,$4a,$ad,$4a,$25,$11,$6b,$64
         .byte   $89,$4a,$63,$39,$8a,$23,$31,$2a,$ea,$a2,$a9,$44,$c5,$12,$cd,$42
         .byte   $34,$8c,$62,$18,$8c,$63,$11,$48,$66,$31,$9d,$44,$33,$1d,$46,$31
         .byte   $9c,$c6,$b1,$0c,$cd,$32,$88,$c4,$73,$18,$86,$73,$08,$d6,$63,$58
         .byte   $07,$81,$e0,$f0,$3c,$07,$87,$90,$3c,$7c,$0f,$c7,$c0,$c0,$f0,$7c
         .byte   $1e,$07,$80,$80,$00,$1c,$78,$70,$f1,$c7,$1f,$c0,$0c,$fe,$1c,$1f
         .byte   $1f,$0e,$0a,$7a,$c0,$71,$f2,$83,$8f,$03,$0f,$0f,$0c,$00,$79,$f8
         .byte   $61,$e0,$43,$0f,$83,$e7,$18,$f9,$c1,$13,$da,$e9,$63,$8f,$0f,$83
         .byte   $83,$87,$c3,$1f,$3c,$70,$f0,$e1,$e1,$e3,$87,$b8,$71,$0e,$20,$e3
         .byte   $8d,$48,$78,$1c,$93,$87,$30,$e1,$c1,$c1,$e4,$78,$21,$83,$83,$c3
         .byte   $87,$06,$39,$e5,$c3,$87,$07,$0e,$1c,$1c,$70,$f4,$71,$9c,$60,$36
         .byte   $32,$c3,$1e,$3c,$f3,$8f,$0e,$3c,$70,$e3,$c7,$8f,$0f,$0f,$0e,$3c
         .byte   $78,$f0,$e3,$87,$06,$f0,$e3,$07,$c1,$99,$87,$0f,$18,$78,$70,$70
         .byte   $fc,$f3,$10,$b1,$8c,$8c,$31,$7c,$70,$e1,$86,$3c,$64,$6c,$b0,$e1
         .byte   $e3,$0f,$23,$8f,$0f,$1e,$3e,$38,$3c,$38,$7b,$8f,$07,$0e,$3c,$f4
         .byte   $17,$1e,$3c,$78,$f2,$9e,$72,$49,$e3,$25,$36,$38,$58,$39,$e2,$de
         .byte   $3c,$78,$78,$e1,$c7,$61,$e1,$e1,$b0,$f0,$f0,$c3,$c7,$0e,$38,$c0
         .byte   $f0,$ce,$73,$73,$18,$34,$b0,$e1,$c7,$8e,$1c,$3c,$f8,$38,$f0,$e1
         .byte   $c1,$8b,$86,$8f,$1c,$78,$70,$f0,$78,$ac,$b1,$8f,$39,$31,$db,$38
         .byte   $61,$c3,$0e,$0e,$38,$78,$73,$17,$1e,$39,$1e,$38,$64,$e1,$f1,$c1
         .byte   $4e,$0f,$40,$a2,$02,$c5,$8f,$81,$a1,$fc,$12,$08,$64,$e0,$3c,$22
         .byte   $e0,$45,$07,$8e,$0c,$32,$90,$f0,$1f,$20,$49,$e0,$f8,$0c,$60,$f0
         .byte   $17,$1a,$41,$aa,$a4,$d0,$8d,$12,$82,$1e,$1e,$03,$f8,$3e,$03,$0c
         .byte   $73,$80,$70,$44,$26,$03,$24,$e1,$3e,$04,$4e,$04,$1c,$c1,$09,$cc
         .byte   $9e,$90,$21,$07,$90,$43,$64,$c0,$0f,$c6,$90,$9c,$c1,$5b,$03,$e2
         .byte   $1d,$81,$e0,$5e,$1d,$03,$84,$b8,$2c,$0f,$80,$b1,$83,$e0,$30,$41
         .byte   $1e,$43,$89,$83,$50,$fc,$24,$2e,$13,$83,$f1,$7c,$4c,$2c,$c9,$0d
         .byte   $83,$b0,$b5,$82,$e4,$e8,$06,$9c,$07,$a0,$99,$1d,$07,$3e,$82,$8f
         .byte   $70,$30,$74,$40,$ca,$10,$e4,$e8,$0f,$92,$14,$3f,$06,$f8,$84,$88
         .byte   $43,$81,$0a,$34,$39,$41,$c6,$e3,$1c,$47,$03,$b0,$b8,$13,$0a,$c2
         .byte   $64,$f8,$18,$f9,$60,$b3,$c0,$65,$20,$60,$a6,$8c,$c3,$81,$20,$30
         .byte   $26,$1e,$1c,$38,$d3,$01,$b0,$26,$40,$f4,$0b,$c3,$42,$1f,$85,$32
         .byte   $26,$60,$40,$c9,$cb,$01,$ec,$11,$28,$40,$fa,$04,$34,$e0,$70,$4c
         .byte   $8c,$1d,$07,$69,$03,$16,$c8,$04,$23,$e8,$c6,$9a,$0b,$1a,$03,$e0
         .byte   $76,$06,$05,$cf,$1e,$bc,$58,$31,$71,$66,$00,$f8,$3f,$04,$fc,$0c
         .byte   $74,$27,$8a,$80,$71,$c2,$3a,$26,$06,$c0,$1f,$05,$0f,$98,$40,$ae
         .byte   $01,$7f,$c0,$07,$ff,$00,$0e,$fe,$00,$03,$df,$80,$03,$ef,$80,$1b
         .byte   $f1,$c2,$00,$e7,$e0,$18,$fc,$e0,$21,$fc,$80,$3c,$fc,$40,$0e,$7e
         .byte   $00,$3f,$3e,$00,$0f,$fe,$00,$1f,$ff,$00,$3e,$f0,$07,$fc,$00,$7e
         .byte   $10,$3f,$ff,$00,$3f,$38,$0e,$7c,$01,$87,$0c,$fc,$c7,$00,$3e,$04
         .byte   $0f,$3e,$1f,$0f,$0f,$1f,$0f,$02,$83,$87,$cf,$03,$87,$0f,$3f,$c0
         .byte   $07,$9e,$60,$3f,$c0,$03,$fe,$00,$3f,$e0,$77,$e1,$c0,$fe,$e0,$c3
         .byte   $e0,$01,$df,$f8,$03,$07,$00,$7e,$70,$00,$7c,$38,$18,$fe,$0c,$1e
         .byte   $78,$1c,$7c,$3e,$0e,$1f,$1e,$1e,$3e,$00,$7f,$83,$07,$db,$87,$83
         .byte   $07,$c7,$07,$10,$71,$ff,$00,$3f,$e2,$01,$e0,$c1,$c3,$e1,$00,$7f
         .byte   $c0,$05,$f0,$20,$f8,$f0,$70,$fe,$78,$79,$f8,$02,$3f,$0c,$8f,$03
         .byte   $0f,$9f,$e0,$c1,$c7,$87,$03,$c3,$c3,$b0,$e1,$e1,$c1,$e3,$e0,$71
         .byte   $f0,$00,$fc,$70,$7c,$0c,$3e,$38,$0e,$1c,$70,$c3,$c7,$03,$81,$c1
         .byte   $c7,$e7,$00,$0f,$c7,$87,$19,$09,$ef,$c4,$33,$e0,$c1,$fc,$f8,$70
         .byte   $f0,$78,$f8,$f0,$61,$c7,$00,$1f,$f8,$01,$7c,$f8,$f0,$78,$70,$3c
         .byte   $7c,$ce,$0e,$21,$83,$cf,$08,$07,$8f,$08,$c1,$87,$8f,$80,$c7,$e3
         .byte   $00,$07,$f8,$e0,$ef,$00,$39,$f7,$80,$0e,$f8,$e1,$e3,$f8,$21,$9f
         .byte   $c0,$ff,$03,$f8,$07,$c0,$1f,$f8,$c4,$04,$fc,$c4,$c1,$bc,$87,$f0
         .byte   $0f,$c0,$7f,$05,$e0,$25,$ec,$c0,$3e,$84,$47,$f0,$8e,$03,$f8,$03
         .byte   $fb,$c0,$19,$f8,$07,$9c,$0c,$17,$f8,$07,$e0,$1f,$a1,$fc,$0f,$fc
         .byte   $01,$f0,$3f,$00,$fe,$03,$f0,$1f,$00,$fd,$00,$ff,$88,$0d,$f9,$01
         .byte   $ff,$00,$70,$07,$c0,$3e,$42,$f3,$0d,$c4,$7f,$80,$fc,$07,$f0,$5e
         .byte   $c0,$3f,$00,$78,$3f,$81,$ff,$01,$f8,$01,$c3,$e8,$0c,$e4,$64,$8f
         .byte   $e4,$0f,$f0,$07,$f0,$c2,$1f,$00,$7f,$c0,$6f,$80,$7e,$03,$f8,$07
         .byte   $f0,$3f,$c0,$78,$0f,$82,$07,$fe,$22,$77,$70,$02,$76,$03,$fe,$00
         .byte   $fe,$67,$00,$7c,$c7,$f1,$8e,$c6,$3b,$e0,$3f,$84,$f3,$19,$d8,$03
         .byte   $99,$fc,$09,$b8,$0f,$f8,$00,$9d,$24,$61,$f9,$0d,$00,$fd,$03,$f0
         .byte   $1f,$90,$3f,$01,$f8,$1f,$d0,$0f,$f8,$37,$01,$f8,$07,$f0,$0f,$c0
         .byte   $3f,$00,$fe,$03,$f8,$0f,$c0,$3f,$00,$fa,$03,$f0,$0f,$80,$ff,$01
         .byte   $b8,$07,$f0,$01,$fc,$01,$bc,$80,$13,$1e,$00,$7f,$e1,$40,$7f,$a0
         .byte   $7f,$b0,$00,$3f,$c0,$1f,$c0,$38,$0f,$f0,$1f,$80,$ff,$01,$fc,$03
         .byte   $f1,$7e,$01,$fe,$01,$f0,$ff,$00,$7f,$c0,$1d,$07,$f0,$0f,$c0,$7e
         .byte   $06,$e0,$07,$e0,$0f,$f8,$06,$c1,$fe,$01,$fc,$03,$e0,$0f,$00,$fc
Index09: .byte   $0a,$29,$0f,$45,$46,$47,$31,$15,$1b,$26,$31,$15,$45,$46,$47,$0b
         .byte   $4b,$4c,$4d,$28,$07,$12,$05,$18,$34,$14,$01,$ff,$20,$01,$ff,$e8
         .byte   $bc,$ee,$41,$b9,$9a,$45,$29,$80,$f0,$0d,$bc,$ee,$43,$f0,$08,$30
         .byte   $06,$c8,$ca,$98,$9d,$ee,$43,$e6,$ff,$4c,$ad,$49
Index10: .byte   $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$06,$06,$06,$05
         .byte   $00,$00,$00,$05,$04,$00,$00,$00,$00,$00,$00,$05,$00,$00,$20,$69
         .byte   "COPYRIGHT 1982 DON'T ASK - A"
Index11: .byte   $0e,$06,$0b,$04,$02,$02,$0c,$09,$07,$06,$0c,$07,$06,$02,$02,$0e
         .byte   $06,$01,$04,$08,$0b,$0a,$08,$06,$0e,$0d,$12,$0d,$02,$12
         .byte   "N sent to resume.",$0d,$0a,$0a
         .byte   $00,$3a,$1e,$01,$cd,$9c,$1c,$20,$20,$2d
Index12: .byte   $00,$01,$02,$02,$02,$03,$03,$04,$04,$05,$06,$08,$09,$0b,$0d,$0f
Index13: .byte   $00,$00,$e0,$e6,$ec,$f3,$f9,$00,$06,$0c,$06

L5F8F:   ldy     #$00
         bit     $f2
         bpl     @L5F9E
         sec
         lda     #$00
         sbc     $f2
         sta     $f2
         ldy     #$80
@L5F9E:  sty     $ef
         lda     #$00
         ldx     #$08
@L5FA4:  asl     $f2
         rol     A
         cmp     $f1
         bcc     @L5FAF
         sbc     $f1
         inc     $f2
@L5FAF:  dex
         bne     @L5FA4
         sta     $f0
         bit     $ef
         bpl     @Exit
         sec
         lda     #$00
         sbc     $f2
         sta     $f2
@Exit:   rts

BackupZP:
         ldx     #$1f
@Loop:   lda     $e0,x
         sta     ZPbackup,x
         dex
         bne     @Loop
         rts

RestoreZP:
         ldx     #$1f
@Loop:   lda     ZPbackup,x
         sta     $e0,x
         dex
         bne     @Loop
         rts

L5FD6:   lda     Index09
         cmp     #$ff
         bne     @L5FDE
         rts

@L5FDE:  lda     #$00
         tax
         sta     $e9
L5FE3:   ldy     $e9
         lda     Index09,y
         sta     $f5
         cmp     #$ff
         bne     @L5FF1
         jmp     L604E

@L5FF1:  cmp     #$01
         bne     @L5FF8
         jmp     L62EE

@L5FF8:  cmp     #$02
         bne     L5FFF
         jmp     L62F4

L5FFF:   lda     Index10,y
         sta     $e8
         lda     Index11,y
         sta     $e7
         ldy     $e8
         iny
         lda     Index13,y
         sta     $e8
         ldy     $f5
L6013:   lda     L5600,y
         sta     L4F00,x
         lda     L5650,y
         sta     L5000,x
         lda     L56A0,y
         sta     L5100,x
         lda     L56F0,y
         sta     L5200,x
         lda     L5740,y
         sta     L5300,x
         lda     L5790,y
         sta     L5400,x
         lda     L5970,y
         sta     L5500,x
         clc
L603E:   lda     #$f0
         adc     $e8
         sta     L4E00,x
         inx
         dec     $e7
         bne     L6013
         inc     $e9
         bne     L5FE3
L604E:   lda     #$00
         sta     $e9
         sta     $ee
         tax
@L6055:  ldy     Index09,x
         inx
         lda     Index09,x
         cmp     #$ff
         bne     @L6063
         jmp     @L6162

@L6063:  tax
         lda     L5920,x
         sta     $f5
         lda     L5920,y
         cmp     $f5
         beq     @L608C
         bcc     @L607F
         lda     L5880,y
         sta     $e8
         lda     L58D0,y
         sta     $e7
         jmp     @L6096

@L607F:  lda     L58D0,x
         sta     $e8
         lda     L5880,x
         sta     $e7
         jmp     @L6096

@L608C:  lda     L5880,y
         sta     $e8
         lda     L5880,x
         sta     $e7
@L6096:  clc
         lda     $ee
         ldy     $e9
         adc     Index11,y
         sta     $ee
         adc     $e7
         sta     $ea
         lda     #$00
         sta     $eb
         lda     #$4e
         sta     $ec
         sec
         lda     $ee
         sbc     $e8
         sta     $e6
         clc
         lda     $e8
         adc     $e7
         sta     $e3
         tax
         dex
         dex
         bpl     @L60C2
         jmp     @L615B

@L60C2:  lda     $e3
         sta     $e5
         lda     $ec
         cmp     #$4e
         bne     @L6109
         ldy     $e9
         lda     Index11,y
         lsr     A
         sta     $e1
         iny
         lda     Index11,y
         lsr     A
         sta     $e2
         clc
         lda     $e1
         adc     $e2
         sta     $e5
         clc
         lda     $ee
         adc     $e2
         sta     $e2
         sec
         lda     $ee
         sbc     $e1
         sta     $e1
         ldy     $e2
         lda     ($eb),y
         sec
         ldy     $e1
         sbc     ($eb),y
         sta     $f2
         lda     $e5
         sta     $f1
         jsr     L5F8F
         ldx     $e5
         ldy     $e1
         jmp     @L611F

@L6109:  ldy     $ea
         sec
         lda     ($eb),y
         ldy     $e6
         sbc     ($eb),y
         sta     $f2
         lda     $e5
         sta     $f1
         jsr     L5F8F
         ldx     $e5
         ldy     $e6
@L611F:  lda     #$00
         sta     $f5
         clc
@L6124:  lda     ($eb),y
         adc     $f2
         sta     $ed
         iny
         dex
         beq     @L6150
         clc
         lda     $f5
         adc     $f0
         sta     $f5
         cmp     $e5
         bcc     @L6149
         lda     $f5
         sbc     $e5
         sta     $f5
         bit     $ef
         bmi     @L6147
         inc     $ed
         bne     @L6149
@L6147:  dec     $ed
@L6149:  lda     $ed
         sta     ($eb),y
         clc
         bcc     @L6124

@L6150:  inc     $ec
         lda     $ec
         cmp     #$55
         beq     @L615B
         jmp     @L60C2

@L615B:  inc     $e9
         ldx     $e9
         jmp     @L6055

@L6162:  lda     $ee
         clc
         ldy     $e9
         adc     Index11,y
         sta     $ed
         ldx     #$00
@Loop:   lda     L4F00,x
         lsr     A
         sta     $f5
         sec
         lda     L4E00,x
         sbc     $f5
         sta     L4E00,x
         dex
         bne     @Loop
         lda     #$00
         sta     $e8
         sta     $e7
         sta     $e6
         sta     $ee
         lda     #$48
         sta     $ea
         lda     #$03
         sta     $f5
         lda     #$00
         sta     $eb
         lda     #$52
         sta     $ec
@L619A:  ldy     #$00
@L619C:  lda     ($eb),y
         tax
         lda     Index12,x
         sta     ($eb),y
         dey
         bne     @L619C
         inc     $ec
         dec     $f5
         bne     @L619A
         ldy     #$00
         lda     L4E00,y
         sta     $e9
         tax
         lsr     A
         lsr     A
         sta     $f5
         sec
         txa
         sbc     $f5
         sta     $e3
         jmp     L61CE

L61C2:   jsr     L6267
         iny
         iny
         dec     $ed
         dec     $ed
         jmp     L6218

L61CE:   lda     L5500,y
         sta     $e4
         and     #$f8
         bne     L61C2
         ldx     $e8
         clc
         lda     L4B00,x
         ora     L5200,y
         tax
         lda     L4D00,x
         sta     $f5
         ldx     $e7
         lda     L4B00,x
         ora     L5300,y
         tax
         lda     L4D00,x
         adc     $f5
         sta     $f5
         ldx     $e6
         lda     L4C00,x
         ora     L5400,y
         tax
         lda     L4D00,x
         adc     $f5
         adc     #$88
         eor     $2f
         bpl     @L6211
         bit     SPKR
         eor     $2f
         sta     $2f
@L6211:  dec     $ea
         bne     L621F
         iny
         dec     $ed
L6218:   bne     L621B
         rts

L621B:   lda     #$46
         sta     $ea
L621F:   dec     $e9
         bne     @L623E
@L6223:  lda     L4E00,y
         sta     $e9
         tax
         lsr     A
         lsr     A
         sta     $f5
         sec
         txa
         sbc     $f5
         sta     $e3
         lda     #$00
         sta     $e8
         sta     $e7
         sta     $e6
         jmp     L61CE

@L623E:  dec     $e3
         bne     @L624C
         lda     $e4
         beq     @L624C
         jsr     L6267
         jmp     @L6223

@L624C:  clc
         lda     $e8
         adc     L4F00,y
         sta     $e8
         clc
         lda     $e7
         adc     L5000,y
         sta     $e7
         clc
         lda     $e6
         adc     L5100,y
         sta     $e6
         jmp     L61CE

L6267:   sty     $ee
         lda     $e4
         tay
         and     #$07
         tax
         dex
         stx     $f5
         lda     Index14,x
         sta     $f2
         clc
         lda     #$59
         adc     $f5
         sta     $ec
         lda     #$c0
         sta     $eb
         tya
         and     #$f8
         bne     @L6293
         ldy     $ee
         lda     L4E00,y
         lsr     A
         lsr     A
         lsr     A
         lsr     A
         jmp     @L62BD

@L6293:  eor     #$ff
         tay
@L6296:  lda     #$08
         sta     $f5
         lda     ($eb),y
@L629C:  pha
         eor     $2f        ;toggle?
         bpl     @L62A8
         bit     SPKR
         eor     $2f
         sta     $2f
@L62A8:  pla
         asl     A
         ldx     #$03
@L62AC:  dex
         bne     @L62AC
         dec     $f5
         bne     @L629C
         iny
         bne     @L6296
         lda     #$01
         sta     $e9
         ldy     $ee
         rts

@L62BD:  eor     #$ff
         sta     $e8
         ldy     $ff
@L62C3:  lda     #$08
         sta     $f5
         lda     ($eb),y
@L62C9:  pha
         eor     $2f        ;toggle?
         bpl     @L62D5
         bit     SPKR
         eor     $2f
         sta     $2f
@L62D5:  pla
         asl     A
         ldx     #$03
@L62D9:  dex
         bne     @L62D9
         dec     $f5
         bne     @L62C9
         iny
         inc     $e8
         bne     @L62C3
         lda     #$01
         sta     $e9
         sty     $ff
         ldy     $ee
         rts

L62EE:   lda     #$01
         sta     $ed
         bne     L62F8

L62F4:   lda     #$ff
         sta     $ed
L62F8:   stx     $ee
         txa
         sec
         sbc     #$1e
         bcs     @L6302
         lda     #$00
@L6302:  tax
@L6303:  lda     L4E00,x
         cmp     #$7f
         bne     @L630E
         inx
         jmp     @L6303

@L630E:  clc
         adc     $ed
         sta     $e8
         sta     L4E00,x
@L6316:  inx
         cpx     $ee
         beq     @L6327
         lda     L4E00,x
         cmp     #$ff
         beq     @L6316
         lda     $e8
         jmp     @L630E

@L6327:  jmp     L5FFF

Index14: .byte   $80
         .byte   $a0
         .byte   $70
         .byte   $70
         .byte   $70

L632F:   ldx     #$ff
         stx     $f3
         inx
         stx     $f4
         stx     $ff
@L6338:  ldx     $ff
         ldy     InputTemp1,x
         cpy     #$ff
         bne     @L6342
         rts

@L6342:  clc
         lda     $f4
         adc     InputTemp2,x
         sta     $f4
         cmp     #$e8
         bcc     @L6351
         jmp     @L637A

@L6351:  lda     Index08,y
         and     #$01
         beq     @L636F
         inx
         stx     $f6
         lda     #$00
         sta     $f4
         sta     $f7
         lda     #$fe
         sta     $f9
         jsr     L4644
         inc     $ff
         inc     $ff
         jmp     @L6338

@L636F:  cpy     #$00
         bne     @L6375
         stx     $f3
@L6375:  inc     $ff
         jmp     @L6338

@L637A:  ldx     $f3
         cmp     #$ff
         bne     @L6385
         pla
         pla
         jmp     ErrorBell

@L6385:  lda     #$1f
         sta     InputTemp1,x
         lda     #$04
         sta     InputTemp2,x
         lda     #$00
         sta     Index03,x
         inx
         stx     $f6
         lda     #$fe
         sta     $f9
         lda     #$00
         sta     $f4
         sta     $f7
         jsr     L4644
         inx
         stx     $ff
         jmp     @L6338

         .byte   $ea        ;NOP?
L63AB:   .byte   $2b

L63AC:   lda     #$00
         tax
         tay
@L63B0:  lda     InputTemp1,x
         cmp     #$ff
         bne     @L63C0
         lda     #$ff
         sta     Index09,y
         jsr     L5FD6
         rts

@L63C0:  cmp     #$fe
         bne     @L63D8
         inx
         stx     L63AB
         lda     #$ff
         sta     Index09,y
         jsr     L5FD6
         ldx     L63AB
         ldy     #$00
         jmp     @L63B0

@L63D8:  cmp     #$00
         bne     @L63E0
         inx
         jmp     @L63B0

@L63E0:  sta     Index09,y
         lda     InputTemp2,x
         sta     Index11,y
         lda     Index03,x
         sta     Index10,y
         inx
         iny
         jmp     @L63B0

L63F4:   ldx     #$00
@L63F6:  ldy     InputTemp1,x
         cpy     #$ff
         bne     @L6400
@L63FD:  jmp     @L6442

@L6400:  lda     Index08,y
         and     #$01
         bne     @L640B
         inx
         jmp     @L63F6

@L640B:  stx     $ff
@L640D:  dex
         beq     @L63FD
         ldy     InputTemp1,x
         lda     Index07,y
         and     #$80
         beq     @L640D
@L641A:  ldy     InputTemp1,x
         lda     Index08,y
         and     #$20
         beq     @L642B
         lda     Index07,y
         and     #$04
         beq     @L6439
@L642B:  lda     InputTemp2,x
         sta     $f5
         lsr     A
         clc
         adc     $f5
         adc     #$01
         sta     InputTemp2,x
@L6439:  inx
         cpx     $ff
         bne     @L641A
         inx
         jmp     @L63F6

@L6442:  ldx     #$00
         stx     $ff
@L6446:  ldx     $ff
         ldy     InputTemp1,x
         cpy     #$ff
         bne     @L6450
         rts

@L6450:  lda     Index07,y
         and     #$80
         bne     @L645A
         jmp     @L64BE

@L645A:  inx
         ldy     InputTemp1,x
         lda     Index07,y
         sta     $f5
         and     #$40
         beq     @L649A
         lda     $f5
         and     #$04
         beq     @L6480
         dex
         lda     InputTemp2,x
         sta     $f5
         lsr     A
         lsr     A
         clc
         adc     $f5
         adc     #$01
         sta     InputTemp2,x
@L647D:  jmp     @L652A

@L6480:  lda     $f5
         and     #$01
         beq     @L647D
         dex
         lda     InputTemp2,x
         tay
         lsr     A
         lsr     A
         lsr     A
         sta     $f5
         sec
         tya
         sbc     $f5
         sta     InputTemp2,x
         jmp     @L652A

@L649A:  cpy     #$12
         beq     @L64A5
         cpy     #$13
         beq     @L64A5
@L64A2:  jmp     @L652A

@L64A5:  inx
         ldy     InputTemp1,x
         lda     Index07,y
         and     #$40
         beq     @L64A2
         ldx     $ff
         lda     InputTemp2,x
         sec
         sbc     #$01
         sta     InputTemp2,x
         jmp     @L652A

@L64BE:  lda     Index08,y
         and     #$08
         beq     @L64E1
         inx
         ldy     InputTemp1,x
         lda     Index07,y
         and     #$02
         bne     @L64D3
@L64D0:  jmp     @L652A

@L64D3:  lda     #$06
         sta     InputTemp2,x
         dex
         lda     #$05
         sta     InputTemp2,x
         jmp     @L652A

@L64E1:  lda     Index07,y
         and     #$02
         beq     @L650E
@L64E8:  inx
         ldy     InputTemp1,x
         beq     @L64E8
         lda     Index07,y
         and     #$02
         beq     @L64D0
         lda     InputTemp2,x
         lsr     A
         clc
         adc     #$01
         sta     InputTemp2,x
         ldx     $ff
         lda     InputTemp2,x
         lsr     A
         clc
         adc     #$01
         sta     InputTemp2,x
@L650B:  jmp     @L652A

@L650E:  lda     Index08,y
         and     #$10
         beq     @L650B
         dex
         ldy     InputTemp1,x
         lda     Index07,y
         and     #$02
         beq     @L650B
         inx
         lda     InputTemp2,x
         sec
         sbc     #$02
         sta     InputTemp2,x
@L652A:  inc     $ff
         jmp     @L6446

ErrorBell:
         jsr     MON_BELL1
         jmp     MON_BELL1

Index15: .byte   "4=710, 5=1200, 6=2400, ",$0d,$0a,"7=4800 AND 8=9600 Baud.",$0d
         .byte   $0a,$0a,"Enter value: "
         .byte   $00,$cd,$9c,$38,$fe,$09,$d2,$56,$4b,$4b,$05,$01,$cd,$45,$3b,$c3
         .byte   $c9,$35,$cd,$9b,$3b,$c2,$85,$3b,$cd,$ab,$1c
         .byte   "Rate for the S mode time-to-send message is set to "
         .byte   $00,$c3,$98,$3b,$cd,$ab,$1c
         .byte   "Modem speed is "
         .byte   $00,$c3,$3f,$22,$3a,$09,$01,$47,$3a,$03,$01,$b0,$c9,$3a,$0d,$01
         .byte   $b7,$ca,$56,$37,$3a,$0c,$01,$2f,$32,$0c,$01,$cd,$b8,$3b,$c3,$c9
         .byte   $35,$b7,$c2,$cf,$3b,$cd,$ab,$1c
         .byte   "CRC mode set",$0d,$0a
         .byte   $00,$c9,$cd,$ab,$1c
         .byte   "Checksum mode set",$0d,$0a
         .byte   $00
         .byte   $c9,$3a,$0f,$01,$b7,$ca,$56,$37,$3a,$0e,$01,$2f,$32
         .byte   "COPYRIGHT 1982 DON'T ASK"
Index16: .res    33,$00
         .res    6,$02
         .byte   $82
         .byte   $00
         .byte   $00
         .res    6,$02
         .res    10,$03
         .res    7,$02
         .byte   $c0,$a8,$b0,$ac,$c0,$a0,$b8,$a0,$c0,$bc,$a0,$ac,$a8,$ac,$c0,$a0
         .byte   $a0,$ac,$b4,$a4,$c0,$a8,$a8,$b0,$c0,$bc,$00,$00,$00,$02,$00

TextMode:
         jsr     BackupZP
         lda     #$20
         sta     Index15
         ldx     #$01
         ldy     #$00
@L66B9:  lda     InputBuf,y
         and     #$7f
         cmp     #$70
         bcc     @L66C7
         and     #$5f
         jmp     @L66CD

@L66C7:  cmp     #$60
         bcc     @L66CD
         and     #$4f
@L66CD:  sta     Index15,x
         inx
         iny
         cpy     #$ff
         bne     @L66B9
         ldx     #$ff
         lda     #$0d
         sta     Index15,x
         jsr     L66E4
L66E0:   jsr     PlayPhenome ;Jumps to phenome mode here
         rts

L66E4:   lda     #$ff
         sta     $fa
L66E8:   lda     #$ff
         sta     $f5
L66EC:   inc     $fa
         ldx     $fa
         lda     Index15,x
         sta     $fd
         cmp     #$0d
         bne     @L6703
         inc     $f5
         ldx     $f5
         lda     #$0d
         sta     InputBuf,x
         rts

@L6703:  cmp     #$2e
         bne     @L671F
         inx
         lda     Index15,x
         tay
         lda     Index16,y
         and     #$01
         bne     @L671F
         inc     $f5
         ldx     $f5
         lda     #$2e
         sta     InputBuf,x
         jmp     L66EC

@L671F:  lda     $fd
         tay
         lda     Index16,y
         sta     $f6
         and     #$02
         beq     @L6736
         lda     #$da
         sta     $fb
         lda     #$6a
         sta     $fc
         jmp     L677C

@L6736:  lda     $f6
         bne     L6765
         lda     #$20
         sta     Index15,x
         inc     $f5
         ldx     $f5
         cpx     #$78
         bcs     L674E
         sta     InputBuf,x
         jmp     L66EC

FA_Store:
         .byte   $00

L674E:   lda     #$0d
         sta     InputBuf,x
         lda     $fa
         sta     FA_Store
         sta     $cd        ;This is never read again
         jsr     L66E0
         lda     FA_Store
         sta     $fa
         jmp     L66E8

L6765:   lda     $f6
         and     #$80
         bne     @L676C     ;always?
         brk

@L676C:  lda     $fd
         sec
         sbc     #$41
         tax
         lda     Index17,x
         sta     $fb
         lda     Rules,x
         sta     $fc
L677C:   ldy     #$00
@L677E:  clc
         lda     $fb
         adc     #$01
         sta     $fb
         lda     $fc
         adc     #$00
         sta     $fc
         lda     ($fb),y
         bpl     @L677E
         iny
@L6790:  lda     ($fb),y
         cmp     #$28
         beq     @L679A
         iny
         jmp     @L6790

@L679A:  sty     $ff
@L679C:  iny
         lda     ($fb),y
         cmp     #$29
         bne     @L679C
         sty     $fe
@L67A5:  iny
         lda     ($fb),y
         and     #$7f
         cmp     #$3d
         bne     @L67A5
         sty     $fd
         ldx     $fa
         stx     $f9
         ldy     $ff
         iny
@L67B7:  lda     Index15,x
         sta     $f6
         lda     ($fb),y
         cmp     $f6
         beq     @L67C5
         jmp     L677C

@L67C5:  iny
         cpy     $fe
         bne     @L67CD
         jmp     @L67D3

@L67CD:  inx
         stx     $f9
         jmp     @L67B7

@L67D3:  lda     $fa
         sta     $f8
@L67D7:  ldy     $ff
         dey
         sty     $ff
         lda     ($fb),y
         sta     $f6
         bpl     @L67E5
         jmp     @L695C

@L67E5:  and     #$7f
         tax
         lda     Index16,x
         and     #$80
         beq     @L6801
         ldx     $f8
         dex
         lda     Index15,x
         cmp     $f6
         beq     @L67FC
         jmp     L677C

@L67FC:  stx     $f8
         jmp     @L67D7

@L6801:  lda     $f6
         cmp     #$20
         bne     @L680A
         jmp     @L683F

@L680A:  cmp     #$23
         bne     @L6811
         jmp     @L684E

@L6811:  cmp     #$2e
         bne     @L6818
         jmp     @L6858

@L6818:  cmp     #$26
         bne     @L681F
         jmp     @L6867

@L681F:  cmp     #$40
         bne     @L6826
         jmp     @L6887

@L6826:  cmp     #$5e
         bne     @L682D
         jmp     @L68AC

@L682D:  cmp     #$2b
         bne     @L6834
         jmp     @L68BB

@L6834:  cmp     #$3a
         bne     @L683B
         jmp     @L68D0

@L683B:  jsr     ErrorBell
         brk

@L683F:  jsr     @L68DF
         and     #$80
         beq     @L6849
         jmp     L677C

@L6849:  stx     $f8
         jmp     @L67D7

@L684E:  jsr     @L68DF
         and     #$40
         bne     @L6849
         jmp     L677C

@L6858:  jsr     @L68DF
         and     #$08
         bne     @L6862
         jmp     L677C

@L6862:  stx     $f8
         jmp     @L67D7

@L6867:  jsr     @L68DF
         and     #$10
         bne     @L6862
         lda     Index15,x
         cmp     #$48
         beq     @L6878
         jmp     L677C

@L6878:  dex
         lda     Index15,x
         cmp     #$43
         beq     @L6862
         cmp     #$53
         beq     @L6862
         jmp     L677C

@L6887:  jsr     @L68DF
         and     #$04
         bne     @L6862
         lda     Index15,x
         cmp     #$48
         beq     @L6898
         jmp     L677C

@L6898:  cmp     #$54
         beq     @L68A7
         cmp     #$43
         beq     @L68A7
         cmp     #$53
         beq     @L68A7
         jmp     L677C

@L68A7:  stx     $f8
         jmp     @L67D7

@L68AC:  jsr     @L68DF
         and     #$20
         bne     @L68B6
         jmp     L677C

@L68B6:  stx     $f8
         jmp     @L67D7

@L68BB:  ldx     $f8
         dex
         lda     Index15,x
         cmp     #$45
         beq     @L68B6
         cmp     #$49
         beq     @L68B6
         cmp     #$59
         beq     @L68B6
         jmp     L677C

@L68D0:  jsr     @L68DF
         and     #$20
         bne     @L68DA
         jmp     @L67D7

@L68DA:  stx     $f8
         jmp     @L68D0

@L68DF:  ldx     $f8
         dex
         lda     Index15,x
         tay
         lda     Index16,y
         rts

@L68EA:  ldx     $f7
         inx
         lda     Index15,x
         tay
         lda     Index16,y
         rts

@L68F5:  ldx     $f7
         inx
         lda     Index15,x
         cmp     #$45
         bne     @L6945
         inx
         lda     Index15,x
         tay
         dex
         lda     Index16,y
         and     #$80
         beq     @L6914
         inx
         lda     Index15,x
         cmp     #$52
         bne     @L6919
@L6914:  stx     $f7
         jmp     @L6960

@L6919:  cmp     #$53
         beq     @L6914
         cmp     #$44
         beq     @L6914
         cmp     #$4c
         bne     @L692F
         inx
         lda     Index15,x
         cmp     #$59
         bne     @L6959
         beq     @L6914

@L692F:  cmp     #$46
         bne     @L6959
         inx
         lda     Index15,x
         cmp     #$55
         bne     @L6959
         inx
         lda     Index15,x
         cmp     #$4c
         beq     @L6914
         bne     @L6959

@L6945:  cmp     #$49
         bne     @L6959
         inx
         lda     Index15,x
         cmp     #$4e
         bne     @L6959
         inx
         lda     Index15,x
         cmp     #$47
         beq     @L6914
@L6959:  jmp     L677C

@L695C:  lda     $f9
         sta     $f7
@L6960:  ldy     $fe
         iny
         cpy     $fd
         bne     @L696A
         jmp     @L6A6F

@L696A:  sty     $fe
         lda     ($fb),y
         sta     $f6
         tax
         lda     Index16,x
         and     #$80
         beq     @L698A
         ldx     $f7
         inx
         lda     Index15,x
         cmp     $f6
         beq     @L6985
         jmp     L677C

@L6985:  stx     $f7
         jmp     @L6960

@L698A:  lda     $f6
         cmp     #$20
         bne     @L6993
         jmp     @L69CF

@L6993:  cmp     #$23
         bne     @L699A
         jmp     @L69DE

@L699A:  cmp     #$2e
         bne     @L69A1
         jmp     @L69E8

@L69A1:  cmp     #$26
         bne     @L69A8
         jmp     @L69F7

@L69A8:  cmp     #$40
         bne     @L69AF
         jmp     @L6A17

@L69AF:  cmp     #$5e
         bne     @L69B6
         jmp     @L6A3C

@L69B6:  cmp     #$2b
         bne     @L69BD
         jmp     @L6A4B

@L69BD:  cmp     #$3a
         bne     @L69C4
         jmp     @L6A60

@L69C4:  cmp     #$25
         bne     @L69CB
         jmp     @L68F5

@L69CB:  jsr     ErrorBell
         brk

@L69CF:  jsr     @L68EA
         and     #$80
         beq     @L69D9
         jmp     L677C

@L69D9:  stx     $f7
         jmp     @L6960

@L69DE:  jsr     @L68EA
         and     #$40
         bne     @L69D9
         jmp     L677C

@L69E8:  jsr     @L68EA
         and     #$08
         bne     @L69F2
         jmp     L677C

@L69F2:  stx     $f7
         jmp     @L6960

@L69F7:  jsr     @L68EA
         and     #$10
         bne     @L69F2
         lda     Index15,x
         cmp     #$48
         beq     @L6A08
         jmp     L677C

@L6A08:  inx
         lda     Index15,x
         cmp     #$43
         beq     @L69F2
         cmp     #$53
         beq     @L69F2
         jmp     L677C

@L6A17:  jsr     @L68EA
         and     #$04
         bne     @L69F2
         lda     Index15,x
         cmp     #$48
         beq     @L6A28
         jmp     L677C

@L6A28:  cmp     #$54
         beq     @L6A37
         cmp     #$43
         beq     @L6A37
         cmp     #$53
         beq     @L6A37
         jmp     L677C

@L6A37:  stx     $f7
         jmp     @L6960

@L6A3C:  jsr     @L68EA
         and     #$20
         bne     @L6A46
         jmp     L677C

@L6A46:  stx     $f7
         jmp     @L6960

@L6A4B:  ldx     $f7
         inx
         lda     Index15,x
         cmp     #$45
         beq     @L6A46
         cmp     #$49
         beq     @L6A46
         cmp     #$59
         beq     @L6A46
         jmp     L677C

@L6A60:  jsr     @L68EA
         and     #$20
         bne     @L6A6A
         jmp     @L6960

@L6A6A:  stx     $f7
         jmp     @L6A60

@L6A6F:  ldy     $fd
         lda     $f9
         sta     $fa
@Loop:   lda     ($fb),y
         sta     $f6
         and     #$7f
         cmp     #$3d
         beq     @L6A86
         inc     $f5
         ldx     $f5
         sta     InputBuf,x
@L6A86:  bit     $f6
         bpl     @L6A8D
         jmp     L66EC

@L6A8D:  iny
         jmp     @Loop

Index17: .byte   $82,$17,$79,$0d,$aa,$30,$71,$e9,$32,$91,$a2,$b9,$fc,$5c,$c0,$0e
         .byte   $6e,$94,$b5,$9e,$19,$a8,$c5,$a0,$b9,$4d
Rules:   .byte   $6c,$6e,$6e,$6f,$6f,$71,$71,$71,$72,$73,$73,$73,$73,$74,$74,$77 ;Text Mode Lookup Table?
         .byte   $77,$77,$77,$78,$7a,$7a,$7a,$7b,$7b,$7c,$a9,$bc,$8d,$e7,$02,$8d
         .byte   $64,$08,$a9,$5c,$8d,$e8,$02,$8d,$69,$08,$a9,$00,$85,$08,$60
         .byte   "(A)",$bd  ;Text to Phenome conversion
         .byte   "(!)=",$ae
         .byte   "(",$22,") =-AH5NKWOWT",$ad
         .byte   "(",$22,")=KWOW4T",$ad
         .byte   "(#)= NAH4MBE",$d2
         .byte   "($)= DAA4LE",$d2
         .byte   "(%)= PERSEH4N",$d4
         .byte   "(&)= AEN",$c4
         .byte   "(')",$bd
         .byte   "(*)= AE4STERIHS",$cb
         .byte   "(+)= PLAH4",$d3
         .byte   "(,)=",$ac
         .byte   " (-) =",$ad
         .byte   "(-)",$bd
         .byte   "(.)= POYN",$d4
         .byte   "(/)= SLAE4S",$c8
         .byte   "(0)= ZIY4RO",$d7
         .byte   " (1ST)=FER4S",$d4
         .byte   " (10TH)=TEH4NT",$c8
         .byte   "(1)= WAH4",$ce
         .byte   " (2ND)=SEH4KUN",$c4
         .byte   "(2)= TUW",$b4
         .byte   " (3RD)=THER4",$c4
         .byte   "(3)= THRIY",$b4
         .byte   "(4)= FOH4",$d2
         .byte   " (5TH)=FIH4FT",$c8
         .byte   "(5)= FAY4",$d6
         .byte   "(6)= SIH4K",$d3
         .byte   "(7)= SEH4VU",$ce
         .byte   " (8TH)=EY4T",$c8
         .byte   "(8)= EY4",$d4
         .byte   "(9)= NAY4",$ce
         .byte   "(:)=",$ae
         .byte   "(;)=",$ae
         .byte   "(<)= LEH4S DHAE",$ce
         .byte   "(=)= IY4KWUL",$da
         .byte   "(>)= GREY4TER DHAE",$ce
         .byte   "(?)=",$ae
         .byte   "(@)= AE6",$d4
         .byte   "(^)= KAE4RIX",$d4
         .byte   "]",$c1
         .byte   " (A.)=EH4Y.",$a0
         .byte   "(A) =A",$c8
         .byte   " (ARE) =AA",$d2
         .byte   " (AR)O=AX",$d2
         .byte   "(AR)#=EH4",$d2
         .byte   " ^(AS)#=EY4",$d3
         .byte   "(A)WA=A",$d8
         .byte   "(AW)=AO",$b5
         .byte   " :(ANY)=EH4NI",$d9
         .byte   "(A)^+#=EY",$b5
         .byte   "#:(ALLY)=ULI",$d9
         .byte   " (AL)#=U",$cc
         .byte   "(AGAIN)=AXGEH4",$ce
         .byte   "#:(AG)E=IH",$ca
         .byte   "(A)^%=E",$d9
         .byte   "(A)^+:#=A",$c5
         .byte   " :(A)^+ =EY",$b4
         .byte   " (ARR)=AX",$d2
         .byte   "(ARR)=AE4",$d2
         .byte   " ^(AR) =AA5",$d2
         .byte   "(AR)=AA5",$d2
         .byte   "(AIR)=EH4",$d2
         .byte   "(AI)=EY",$b4
         .byte   "(AY)=EY",$b5
         .byte   "(AU)=AO",$b4
         .byte   "#:(AL) =U",$cc
         .byte   "#:(ALS) =UL",$da
         .byte   "(ALK)=AO4",$cb
         .byte   "(AL)^=AO",$cc
         .byte   " :(ABLE)=EY4BU",$cc
         .byte   "(ABLE)=AXBU",$cc
         .byte   "(A)VO=EY",$b4
         .byte   "(ANG)+=EY4N",$ca
         .byte   "(ATARI)=AHTAA4RI",$d9
         .byte   "(A)TOM=A",$c5
         .byte   "(A)TTI=A",$c5
         .byte   " (AT) =AE",$d4
         .byte   " (A)T=A",$c8
         .byte   "(A)=A",$c5
         .byte   "]",$c2
         .byte   " (B) =BIY",$b4
         .byte   " (BE)^#=BI",$c8
         .byte   "(BEING)=BIY4IHN",$d8
         .byte   " (BOTH) =BOW4T",$c8
         .byte   " (BUS)#=BIH4",$da
         .byte   "(BREAK)=BREY5",$cb
         .byte   "(BUIL)=BIH4",$cc
         .byte   "(B)=",$c2
         .byte   "]",$c3
         .byte   " (C) =SIY",$b4
         .byte   " (CH)^=",$cb
         .byte   "^E(CH)=",$cb
         .byte   "(CHA)R#=KEH",$b5
         .byte   "(CH)=C",$c8
         .byte   " S(CI)#=SAY",$b4
         .byte   "(CI)A=S",$c8
         .byte   "(CI)O=S",$c8
         .byte   "(CI)EN=S",$c8
         .byte   "(CITY)=SIHTI",$d9
         .byte   "(C)+=",$d3
         .byte   "(CK)=",$cb
         .byte   "(COM)=KAH",$cd
         .byte   "(CUIT)=KIH",$d4
         .byte   "(CREA)=KRIYE",$d9
         .byte   "(C)=",$cb
         .byte   "]",$c4
         .byte   " (D) =DIY",$b4
         .byte   " (DR.) =DAA4KTE",$d2
         .byte   "#:(DED) =DIH",$c4
         .byte   ".E(D) =",$c4
         .byte   "#:^E(D) =",$d4
         .byte   " (DE)^#=DI",$c8
         .byte   " (DO) =DU",$d7
         .byte   " (DOES)=DAH",$da
         .byte   "(DONE) =DAH5",$ce
         .byte   "(DOING)=DUW4IHN",$d8
         .byte   " (DOW)=DA",$d7
         .byte   "#(DU)A=JU",$d7
         .byte   "#(DU)^#=JA",$d8
         .byte   "(D)=",$c4
         .byte   "]",$c5
         .byte   " (E) =IYIY",$b4
         .byte   "#:(E) ",$bd
         .byte   "':^(E) ",$bd
         .byte   " :(E) =I",$d9
         .byte   "#(ED) =",$c4
         .byte   "#:(E)D ",$bd
         .byte   "(EV)ER=EH4",$d6
         .byte   "(E)^%=IY",$b4
         .byte   "(ERI)#=IY4RI",$d9
         .byte   "(ERI)=EH4RI",$c8
         .byte   "#:(ER)#=E",$d2
         .byte   "(ERROR)=EH4ROH",$d2
         .byte   "(ERASE)=IHREY5",$d3
         .byte   "(ER)#=EH",$d2
         .byte   "(ER)=E",$d2
         .byte   " (EVEN)=IYVEH",$ce
         .byte   "#:(E)W",$bd
         .byte   "@(EW)=U",$d7
         .byte   "(EW)=YU",$d7
         .byte   "(E)O=I",$d9
         .byte   "#:&(ES) =IH",$da
         .byte   "#:(E)S ",$bd
         .byte   "#:(ELY) =LI",$d9
         .byte   "#:(EMENT)=MEHN",$d4
         .byte   "(EFUL)=FUH",$cc
         .byte   "(EE)=IY",$b4
         .byte   "(EARN)=ER5",$ce
         .byte   " (EAR)^=ER",$b5
         .byte   "(EAD)=EH",$c4
         .byte   "#:(EA) =IYA",$d8
         .byte   "(EA)SU=EH",$b5
         .byte   "(EA)=IY",$b5
         .byte   "(EIGH)=EY",$b4
         .byte   "(EI)=IY",$b4
         .byte   " (EYE)=AY",$b4
         .byte   "(EY)=I",$d9
         .byte   "(EU)=YUW",$b5
         .byte   "(EQUAL)=IY4KWU",$cc
         .byte   "(E)=E",$c8
         .byte   "]",$c6
         .byte   " (F) =EH4",$c6
         .byte   "(FUL)=FUH",$cc
         .byte   "(FRIEND)=FREH5N",$c4
         .byte   "(FATHER)=FAA4DHE",$d2
         .byte   "(F)F",$bd
         .byte   "(F)=",$c6
         .byte   "]",$c7
         .byte   " (G) =JIY",$b4
         .byte   "(GIV)=GIH5",$d6
         .byte   " (G)I^=",$c7
         .byte   "(GE)T=GEH",$b5
         .byte   "SU(GGES)=GJEH4",$d3
         .byte   "(GG)=",$c7
         .byte   " B#(G)=",$c7
         .byte   "(G)+=",$ca
         .byte   "(GREAT)=GREY4",$d4
         .byte   "(GON)E=GAO5",$ce
         .byte   "#(GH)",$bd
         .byte   " (GN)=",$ce
         .byte   "(G)=",$c7
         .byte   "]",$c8
         .byte   " (H) =EY4C",$c8
         .byte   " (HAV)=/HAE6",$d6
         .byte   " (HERE)=/HIY",$d2
         .byte   " (HOUR)=AW5E",$d2
         .byte   "(HOW)=/HA",$d7
         .byte   "(H)#=/",$c8
         .byte   "(H)",$bd
         .byte   "]",$c9
         .byte   " (IN)=IH",$ce
         .byte   " (I) =AY",$b4
         .byte   "(I) =A",$d9
         .byte   "(IN)D=AY5",$ce
         .byte   "SEM(I)=I",$d9
         .byte   " ANT(I)=A",$d9
         .byte   "(IER)=IYE",$d2
         .byte   "#:R(IED) =IY",$c4
         .byte   "(IED) =AY5",$c4
         .byte   "(IEN)=IYEH",$ce
         .byte   "(IE)T=AY4E",$c8
         .byte   "(I')=AY",$b5
         .byte   " :(I)^%=AY",$b5
         .byte   " :(IE) =AY",$b4
         .byte   "(I)%=I",$d9
         .byte   "(IE)=IY",$b4
         .byte   " (IDEA)=AYDIY5A",$c8
         .byte   "(I)^+:#=I",$c8
         .byte   "(IR)#=AY",$d2
         .byte   "(IZ)%=AY",$da
         .byte   "(IS)%=AY",$da
         .byte   "I^(I)^#=I",$c8
         .byte   "+^(I)^+=A",$d9
         .byte   "#:^(I)^+=I",$c8
         .byte   "(I)^+=A",$d9
         .byte   "(IR)=E",$d2
         .byte   "(IGH)=AY",$b4
         .byte   "(ILD)=AY5L",$c4
         .byte   " (IGN)=IHG",$ce
         .byte   "(IGN) =AY4",$ce
         .byte   "(IGN)^=AY4",$ce
         .byte   "(IGN)%=AY4",$ce
         .byte   "(ICRO)=AY4KRO",$c8
         .byte   "(IQUE)=IY4",$cb
         .byte   "(I)=I",$c8
         .byte   "]",$ca
         .byte   " (J) =JEY",$b4
         .byte   "(J)=",$ca
         .byte   "]",$cb
         .byte   " (K) =KEY",$b4
         .byte   " (K)N",$bd
         .byte   "(K)=",$cb
         .byte   "]",$cc
         .byte   " (L) =EH4",$cc
         .byte   "(LO)C#=LO",$d7
         .byte   "L(L)",$bd
         .byte   "#:^(L)%=U",$cc
         .byte   "(LEAD)=LIY",$c4
         .byte   " (LAUGH)=LAE4",$c6
         .byte   "(L)=",$cc
         .byte   "]",$cd
         .byte   " (M) =EH4",$cd
         .byte   " (MR.) =MIH4STE",$d2
         .byte   " (MS.)=MIH5",$da
         .byte   " (MRS.) =MIH4SIX",$da
         .byte   "(MOV)=MUW4",$d6
         .byte   "(MACHIN)=MAHSHIY5",$ce
         .byte   "M(M)",$bd
         .byte   "(M)=",$cd
         .byte   "]",$ce
         .byte   " (N) =EH4",$ce
         .byte   "E(NG)+=N",$ca
         .byte   "(NG)R=NX",$c7
         .byte   "(NG)#=NX",$c7
         .byte   "(NGL)%=NXGU",$cc
         .byte   "(NG)=N",$d8
         .byte   "(NK)=NX",$cb
         .byte   " (NOW) =NAW",$b4
         .byte   "N(N)",$bd
         .byte   "(NON)E=NAH4",$ce
         .byte   "(N)=",$ce
         .byte   "]",$cf
         .byte   " (O) =OH4",$d7
         .byte   "(OF) =AH",$d6
         .byte   " (OH) =OW",$b5
         .byte   "(OROUGH)=ER4O",$d7
         .byte   "#:(OR) =E",$d2
         .byte   "#:(ORS) =ER",$da
         .byte   "(OR)=AO",$d2
         .byte   " (ONE)=WAH",$ce
         .byte   "#(ONE) =WAH",$ce
         .byte   "(OW)=O",$d7
         .byte   " (OVER)=OW5VE",$d2
         .byte   "PR(O)V=UW",$b4
         .byte   "(OV)=AH4",$d6
         .byte   "(O)^%=OW",$b5
         .byte   "(O)^EN=O",$d7
         .byte   "(O)^I#=OW",$b5
         .byte   "(OL)D=OW4",$cc
         .byte   "(OUGHT)=AO5",$d4
         .byte   "(OUGH)=AH5",$c6
         .byte   " (OU)=A",$d7
         .byte   "H(OU)S#=AW",$b4
         .byte   "(OUS)=AX",$d3
         .byte   "(OUR)=OH",$d2
         .byte   "(OULD)=UH5",$c4
         .byte   "(OU)^L=AH",$b5
         .byte   "(OUP)=UW5",$d0
         .byte   "(OU)=A",$d7
         .byte   "(OY)=O",$d9
         .byte   "(OING)=OW4IHN",$d8
         .byte   "(OI)=OY",$b5
         .byte   "(OOR)=OH5",$d2
         .byte   "(OOK)=UH5",$cb
         .byte   "F(OOD)=UW5",$c4
         .byte   "L(OOD)=AH5",$c4
         .byte   "M(OOD)=UW5",$c4
         .byte   "(OOD)=UH5",$c4
         .byte   "F(OOT)=UH5",$d4
         .byte   "(OO)=UW",$b5
         .byte   "(O')=O",$c8
         .byte   "(O)E=O",$d7
         .byte   "(O) =O",$d7
         .byte   "(OA)=OW",$b4
         .byte   " (ONLY)=OW4NLI",$d9
         .byte   " (ONCE)=WAH4N",$d3
         .byte   "(ON'T)=OW4N",$d4
         .byte   "C(O)N=A",$c1
         .byte   "(O)NG=A",$cf
         .byte   " :^(O)N=A",$c8
         .byte   "I(ON)=U",$ce
         .byte   "#:(ON) =U",$ce
         .byte   "#^(ON)=U",$ce
         .byte   "(O)ST =O",$d7
         .byte   "(OF)^=AO4",$c6
         .byte   "(OTHER)=AH5DHE",$d2
         .byte   "R(O)B=RA",$c1
         .byte   "^R(O):#=OW",$b5
         .byte   "(OSS) =AO5",$d3
         .byte   "#:^(OM)=AH",$cd
         .byte   "(O)=A",$c1
         .byte   "]",$d0
         .byte   " (P) =PIY",$b4
         .byte   "(PH)=",$c6
         .byte   "(PEOPL)=PIY5PU",$cc
         .byte   "(POW)=PAW",$b4
         .byte   "(PUT) =PUH",$d4
         .byte   "(P)P",$bd
         .byte   " (P)S",$bd
         .byte   " (P)N",$bd
         .byte   " (PROF.)=PROHFEH4SE",$d2
         .byte   "(P)=",$d0
         .byte   "]",$d1
         .byte   " (Q) =KYUW",$b4
         .byte   "(QUAR)=KWOH5",$d2
         .byte   "(QU)=K",$d7
         .byte   "(Q)=",$cb
         .byte   "]",$d2
         .byte   " (R) =AA5",$d2
         .byte   " (RE)^#=RI",$d9
         .byte   "(R)R",$bd
         .byte   "(R)=",$d2
         .byte   "]",$d3
         .byte   " (S) =EH4",$d3
         .byte   "(SH)=S",$c8
         .byte   "#(SION)=ZHU",$ce
         .byte   "(SOME)=SAH",$cd
         .byte   "#(SUR)#=ZHE",$d2
         .byte   "(SUR)#=SHE",$d2
         .byte   "#(SU)#=ZHU",$d7
         .byte   "#(SSU)#=SHU",$d7
         .byte   "#(SED) =Z",$c4
         .byte   "#(S)#=",$da
         .byte   "(SAID)=SEH",$c4
         .byte   "^(SION)=SHU",$ce
         .byte   "(S)S",$bd
         .byte   ".(S) =",$da
         .byte   "#:.E(S) =",$da
         .byte   "#:^#(S) =",$d3
         .byte   "U(S) =",$d3
         .byte   " :#(S) =",$da
         .byte   "##(S) =",$da
         .byte   " (SCH)=S",$cb
         .byte   "(S)C+",$bd
         .byte   "#(SM)=ZU",$cd
         .byte   "#(SN)'=ZU",$ce
         .byte   "(STLE)=SU",$cc
         .byte   "(S)=",$d3
         .byte   "]",$d4
         .byte   " (T) =TIY",$b4
         .byte   " (THE) #=DHI",$d9
         .byte   " (THE) =DHA",$d8
         .byte   "(TO) =TU",$d8
         .byte   " (THAT)=DHAE",$d4
         .byte   " (THIS) =DHIH",$d3
         .byte   " (THEY)=DHE",$d9
         .byte   " (THERE)=DHEH",$d2
         .byte   "(THER)=DHE",$d2
         .byte   "(THEIR)=DHEH",$d2
         .byte   " (THAN) =DHAE",$ce
         .byte   " (THEM) =DHEH",$cd
         .byte   "(THESE) =DHIY",$da
         .byte   " (THEN)=DHEH",$ce
         .byte   "(THROUGH)=THRUW",$b4
         .byte   "(THOSE)=DHOH",$da
         .byte   "(THOUGH) =DHO",$d7
         .byte   "(TODAY)=TUXDE",$d9
         .byte   "(TOMO)RROW=TUMAA",$b5
         .byte   "(TO)TAL=TOW",$b5
         .byte   " (THUS)=DHAH4",$d3
         .byte   "(TH)=T",$c8
         .byte   "#:(TED) =TIX",$c4
         .byte   "S(TI)#N=C",$c8
         .byte   "(TI)O=S",$c8
         .byte   "(TI)A=S",$c8
         .byte   "(TIEN)=SHU",$ce
         .byte   "(TUR)#=CHE",$d2
         .byte   "(TU)A=CHU",$d7
         .byte   " (TWO)=TU",$d7
         .byte   "&(T)EN ",$bd
         .byte   "(T)=",$d4
         .byte   "]",$d5
         .byte   " (U) =YUW",$b4
         .byte   " (UN)I=YUW",$ce
         .byte   " (UN)=AH",$ce
         .byte   " (UPON)=AXPAO",$ce
         .byte   "@(UR)#=UH4",$d2
         .byte   "(UR)#=YUH4",$d2
         .byte   "(UR)=E",$d2
         .byte   "(U)^ =A",$c8
         .byte   "(U)^^=AH",$b5
         .byte   "(UY)=AY",$b5
         .byte   " G(U)#",$bd
         .byte   "G(U)%",$bd
         .byte   "G(U)#=",$d7
         .byte   "#N(U)=YU",$d7
         .byte   "@(U)=U",$d7
         .byte   "(U)=YU",$d7
         .byte   "]",$d6
         .byte   " (V) =VIY",$b4
         .byte   "(VIEW)=VYUW",$b5
         .byte   "(V)=",$d6
         .byte   "]",$d7
         .byte   " (W) =DAH4BULYU",$d7
         .byte   " (WERE)=WE",$d2
         .byte   "(WA)SH=WA",$c1
         .byte   "(WA)ST=WE",$d9
         .byte   "(WA)S=WA",$c8
         .byte   "(WA)T=WA",$c1
         .byte   "(WHERE)=WHEH",$d2
         .byte   "(WHAT)=WHAH",$d4
         .byte   "(WHOL)=/HOW",$cc
         .byte   "(WHO)=/HU",$d7
         .byte   "(WH)=W",$c8
         .byte   "(WAR)#=WEH",$d2
         .byte   "(WAR)=WAO",$d2
         .byte   "(WOR)^=WE",$d2
         .byte   "(WR)=",$d2
         .byte   "(WOM)A=WUH",$cd
         .byte   "(WOM)E=WIH",$cd
         .byte   "(WEA)R=WE",$c8
         .byte   "(WANT)=WAA5N",$d4
         .byte   "ANS(WER)=E",$d2
         .byte   "(W)=",$d7
         .byte   "]",$d8
         .byte   " (X) =EH4K",$d3
         .byte   " (X)=",$da
         .byte   "(X)=K",$d3
         .byte   "]",$d9
         .byte   " (Y) =WAY",$b4
         .byte   "(YOUNG)=YAHN",$d8
         .byte   " (YOUR)=YOH",$d2
         .byte   " (YOU)=YU",$d7
         .byte   " (YES)=YEH",$d3
         .byte   " (Y)=",$d9
         .byte   "F(Y)=A",$d9
         .byte   "PS(YCH)=AY",$cb
         .byte   "#:^(Y) =I",$d9
         .byte   "#:^(Y)I=I",$d9
         .byte   " :(Y) =A",$d9
         .byte   " :(Y)#=A",$d9
         .byte   " :(Y)^+:#=I",$c8
         .byte   " :(Y)^#=A",$d9
         .byte   "(Y)=I",$c8
         .byte   "]",$da
         .byte   " (Z) =ZIY",$b4
         .byte   "(Z)=",$da
         .byte   " (YOU)=YU",$d7
         .byte   " (YES)=YEH",$d3
         .byte   " (Y)=",$d9
         .byte   "F(Y)=A",$d9
         .byte   "ive/user no. (specify drive/user)",$0d,$0a,"      and reset di"
         .byte   "sks.  e.g. LOG A0, LOG B (user # unchanged)",$0d,$0a,"SPD - Se"
         .byte   "t sp*123456789 .?,-IIEAAAAUAIEUORLWYWRLWYMNNDQSSFT//ZZVDC*J***"
         .byte   "EAOAOUB**D**G**G**P**T**K**K**UUU*****YHHEAHOHXXRXHXXXXH******"
         .byte   "XX**H*HHX*H*HH"
         .byte   $84,$84,$2a,$2a,$2a,$59,$59,$59,$57,$57,$57,$2a,$2a,$2a,$2a,$2a
         .byte   $2a,$2a,$2a,$2a,$58,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a
         .byte   $58,$2a,$2a,$4c,$4d,$4e,$00,$00,$00,$00,$00,$a4,$a4,$a4,$a4,$a4
         .byte   $a4,$84,$84,$a4,$a4,$84,$84,$84,$84,$84,$84,$84,$44,$44,$44,$44
         .byte   $44,$4c,$4c,$4c,$48,$4c,$40,$40,$40,$40,$40,$40,$44,$44,$44,$44
         .byte   $48,$40,$4c,$44,$00,$00,$b4,$b4,$b4,$94,$94,$94,$4e,$4e,$4e,$4e
         .byte   $4e,$4e,$4e,$4e,$4e,$4e,$4e,$4e,$4b,$4b,$4b,$4b,$4b,$4b,$4b,$4b
         .byte   $4b,$4b,$4b,$4b,$80,$c1,$c1,$c1,$c1,$00,$00,$00,$00,$00,$00,$00
         .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$10,$10,$10,$10,$08
         .byte   $0c,$08,$04,$40,$24,$20,$20,$24,$00,$00,$24,$20,$20,$24,$20,$20
         .byte   $00,$20,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$04
         .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$04,$00,$00,$00,$00
         .byte   $00,$00,$85,$fc,$86,$fb,$84,$fa,$60,$a5,$fc,$a6,$fb,$a4,$fa,$60
         .byte   $20,$36,$46,$a2,$ff,$a0,$00,$ca,$88,$bd,$ee,$41,$99,$ee,$41,$bd
         .byte   $ee,$42,$99,$ee,$42,$bd,$ee,$43,$99,$ee,$43,$e4,$f6,$d0,$e8,$a5
         .byte   $f9,$9d,$ee,$41,$a5,$f8,$9d,$ee,$42,$a5,$f7,$9d,$ee,$43,$20,$3d
         .byte   $46,$85,$85,$00,$8a,$a8,$85,$ff,$99,$ee,$43,$c8,$c0,$ff,$d0,$f8
         .byte   $bd,$10,$40,$c9,$0d,$f0,$6e,$85,$fe,$e8,$bd,$10,$40,$85,$fd,$a0
         .byte   $00,$b9,$f8,$44,$c5,$fe,$d0,$0b,$b9,$49,$45,$c9,$2a,$f0,$04,$c5
         .byte   $fd,$f0,$07,$c8,$c0,$51,$d0,$e9,$f0,$0c,$98,$a4,$ff,$99,$ee,$41
         .byte   $e6,$ff,$e8,$4c,$84,$46,$a0,$00,$b9,$49,$45,$c9,$2a,$d0,$07,$b9
         .byte   $f8,$44,$c5,$fe,$f0,$07,$c8,$c0,$51,$d0,$ed,$f0,$0b,$98,$a4,$ff
         .byte   $99,$ee,$41,$e6,$ff,$4c,$84,$46,$a5,$fe,$a0,$08,$d9,$ee,$44,$f0
         .byte   $0a,$88,$d0,$f8,$8e,$0b,$40,$20,$2f,$65,$60,$98,$a4,$ff,$88,$99
         .byte   $ee,$43,$4c,$84,$46,$a9,$ff,$a4,$ff,$99,$ee,$41,$60,$a0,$00,$b9
         .byte   $ee,$41,$c9,$ff,$f0,$1b,$aa,$b9,$ee,$43,$f0,$0b,$30,$09,$bd,$e0
         .byte   $57,$99,$ee,$42,$4c,$21,$47,$bd,$30,$58,$99,$ee,$42,$c8,$4c,$03
         .byte   $47,$60,$a9,$00,$85,$ff,$a6,$ff,$bd,$ee,$41,$c9,$ff,$d0,$01,$60
         .byte   $85,$f9,$a8,$b9,$9a,$45,$a8,$29,$02,$d0,$05,$e6,$ff,$4c,$2a,$47
         .byte   $98,$29,$01,$d0,$2c,$e6,$f9,$a4,$f9,$bd,$ee,$43,$85,$f7,$b9,$30
         .byte   $58,$85,$f8,$e8,$86,$f6,$20,$44,$46,$e6,$f9,$a4,$f9,$b9,$30,$58
         .byte   $85,$f8,$e8,$86,$f6,$20,$44,$46,$e6,$ff,$e6,$ff,$e6,$ff,$4c,$2a
         .byte   $47,$e8,$86,$86,$41,$f0,$fa,$85,$f5,$c9,$ff,$d0,$03,$4c,$96,$47
         .byte   $a8,$b9,$9a,$45,$29,$08,$d0,$32,$a5,$f5,$c9,$24,$f0,$2c,$c9,$25
         .byte   $f0,$28,$a6,$ff,$bd,$ee,$43,$85,$f7,$e8,$86,$f6,$a6,$f9,$e8,$86
         .byte   $f9,$bd,$30,$58,$85,$f8,$20,$44,$46,$e6,$f6,$e8,$86,$f9,$bd,$30
         .byte   $58,$85,$f8,$20,$44,$46,$e6,$ff,$e6,$ff,$e6,$ff,$4c,$2a,$47,$a9
         .byte   $00,$85,$ff,$a6,$ff,$bd,$ee,$41,$d0,$05,$e6,$ff,$4c,$c7,$47,$c9
         .byte   $ff,$d0,$01,$60,$a8,$b9,$9a,$45,$29,$10,$f0,$1f,$bd,$ee,$43,$85
         .byte   $f7,$e8,$86,$f6,$b9,$9a,$45,$29,$20,$f0,$0c,$a9,$15,$85,$f9,$20
         .byte   $44,$46,$a6,$ff,$4c,$23,$49,$a9,$14,$d0,$f2,$bd

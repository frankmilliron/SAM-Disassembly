; Target assembler: Merlin 32 v1.0.0 []
; 6502bench SourceGen v1.8.3
MON_CSWL equ   $36        ;character output hook (lo)
MON_CSWH equ   $37        ;character output hook (hi)
SPKR     equ   $c030      ;RW toggle speaker
MON_BELL1 equ  $fbdd      ;sound bell regardless of output device
MON_COUT1 equ  $fdf0      ;print Acc to screen

         org   $4000
         jmp   Setup      ;CALL 16384

         jmp   PhenomeMode ;CALL 16387

         jmp   TextMode   ;CALL 16390

Speed    dfb   $46        ;$4009/16393: Speed Setting (Default value $3C/60)
Pitch    dfb   $f0        ;$400A/16394: Pitch Setting (Default value $48/72)
Error    dfb   $ff        ;$400B/16395: Error
Echo     dfb   $00        ;$400C/16396: $00=no echo to screen, $FF=echo char to screen
Mode     dfb   $00        ;$400D/16397: $00=phenome mode, $ff=text mode
BufPos   dfb   $2a        ;Current input buffer position
AStore   dfb   $8d        ;Accumulator storage
InputBuf asc   'BAH7T, AH4DHER TAYMZ AY TAO5K VEH4RIY LOW.' ;SAM input buffer ($100 bytes)
         dfb   $0d
         asc   'TIXN WER7DZ.'
         dfb   $0d
         asc   'THAHSAYZER-AA5N AH DIH2SK.'
         dfb   $0d
         hex   4a1fcd0611c3bc1bfe3bc2721fcd0a20cd06113a8501fe04c2521f3a8901fe0a
         hex   cabc1bfe1aca8b1ffe21cabc1bc3521ffe21cabc1bfe1aca8b1f3e53cd1802c3
         hex   521f7b956f7a9c67c921cf017e34b7caa71bcd0611cda620211101360d210d01
         hex   cd12022acb01eb2ad401cd841fe52acd01eb2ad401cd841f5c1600e1cd6918eb
         hex   cda92021110111d61f1ab7cae41f772313c3cb1f482055534520464143544f52
         hex   0d00210e01cd12022aed2022d0

Setup    lda   #<AddChar  ;Change output hooks to point to SAM input parser
         sta   MON_CSWL
         lda   #>AddChar
         sta   MON_CSWH
Setup1   lda   #$00
         sta   Echo       ;Turn echo off
         sta   BufPos     ;Reset current buffer position
         lda   #$ff
         sta   Mode       ;Set text entry mode
         rts

AddChar  sta   AStore     ;Add character to input buffer
         txa
         pha
         tya
         pha
         lda   AStore
         and   #$7f       ;High ASCII
         cmp   #$20       ;Do we have a control character?
         bcc   Control1
         ldy   BufPos
         sta   InputBuf,y ;Add character to SAM input buffer
         inc   BufPos
         bit   Echo
         bpl   Done
         ora   #$80
         jsr   MON_COUT1  ;Echo output to screen
Done     pla              ;Done adding characters to buffer
         tay
         pla
         tax
         lda   AStore
         rts

Control1 cmp   #$05       ;ENQ  Enquiry
         bne   Control2
         lda   #$ff
         sta   Echo       ;Turn echo on
         bne   Done

Control2 cmp   #$0e       ;SO  Shift Out
         bne   Control3
         lda   #$00
         sta   Echo       ;Turn echo off (Default in Setup)
         beq   Done

Control3 cmp   #$14       ;DC4  Device Control 4
         bne   Control4
         lda   #$ff       ;Set text entry mode (Default in Setup)
         sta   Mode
         bne   Done

Control4 cmp   #$10       ;DLE  Data Link Escape
         bne   Control5
         lda   #$00       ;Set phenome entry mode
         sta   Mode
         beq   Done

Control5 cmp   #$0d       ;CR  Carriage Return
         bne   Done
         ldy   BufPos
         sta   InputBuf,y ;Add last character
         bit   Echo
         beq   No_LF
         lda   #$8d       ;High-ASCII return character
         jsr   MON_COUT1  ;Line Feed to screen
No_LF    bit   Mode       ;Which playback mode?
         bne   DoTextMode
         jsr   PhenomeMode
         jmp   Done

DoTextMode
         jsr   TextMode
         jmp   Done

PhenomeMode
         jsr   BackupZP   ;Parse buffer for phenome entry
PlayPhenome
         lda   #$ff       ;Jumps here once text converted to phenomes
         sta   Error
         jsr   L4676
         lda   Error
         cmp   #$ff
         bne   Exit
         jsr   L47C3
         jsr   L49A9
         jsr   L4701
         jsr   L63F4
         jsr   L4726
         lda   Speed
         sta   L621B+1
         lda   Pitch
         sta   L603E+1
:Loop    lda   InputTemp1,x
         cmp   #$50
         bcs   :L41DB
         inx
         bne   :Loop
         beq   :L41E0

:L41DB   lda   #$ff
         sta   InputTemp1,x
:L41E0   jsr   L632F
         lda   #$ff
         sta   DoneFlag   ;(Was already #$FF?)
         jsr   L63AC
Exit     jmp   RestoreZP

InputTemp1
         hex   3637380a45464703fe000a290f0045464731151b26003115004546470b4b4c4d
         hex   00280712050018341401feff15002832152001feff2000200f1e0e1c1ffe190f
         hex   393a3b2601feff37381707210a1c1cff00081b000a000020363738052a2b0020
         hex   061c230a203115260f04fe091c000a00393a3b06203f404101feff
         asc   ' KAEN NAW4 OW4N YOHR OW3N KAA4PIY AHV SAE5M. YOH4R KUMPYUW3TER'
         asc   ' IHZ REH4DIY TUX TAOK."',0d0a,'490 GOSUB 5',0d0a,'500 END',0d0a
         dfb   $1a
         asc   'CS 2:SETCOLOR 2,0,0:?'
DoneFlag dfb   $ff
         dfb   $23        ;Part of Index02?
InputTemp2
         hex   0801020f0702021204000e060b000402020c090706000c07000602020e060104
         hex   00080b0a0800060e0d12040f0800080f0d0212040b0200020e0207070401081c
         hex   0801010a120106010205080208070506000b0700060000020801020b06020002
         hex   0c070206020c090611080213070006000701010e020a01021202
         asc   ' options followed by the speed e.g., 300, 1>>0.',0d0a0a,'     '
         asc   '       EXAMPLE:  SBO1T.600 will set the modem',0d0a,'         '
         asc   '             to run at '
Index03  ds    3,$08
         dfb   $07
         ds    6
         dfb   $04
         ds    14
         ds    3,$06
         dfb   $05
         ds    4
         dfb   $05
         dfb   $04
         ds    221
StressInputTable
         asc   '*123456789'
Index05  asc   ' .?,-IIEAAAAUAIEUORLWYWRLWYMNNDQSSFT//ZZVDC*J***EAOAOUB**D**G*'
         asc   '*G**P**T**K**K**UUU'
Index06  asc   '*****YHHEAHOHXXRXHXXXXH******XX**H*HHX*H*HH*****YYYWWW********'
         asc   '*X***********X**LMN'
Index07  ds    5
         dfb   $a4
         ds    5,$a4
         ds    2,$84
         ds    2,$a4
         ds    7,$84
         ds    5,$44
         ds    3,$4c
         dfb   $48
         dfb   $4c
         ds    6,$40
         ds    4,$44
         dfb   $48
         dfb   $40
         dfb   $4c
         dfb   $44
         ds    2
         ds    3,$b4
         ds    3,$94
         ds    12,$4e
         ds    12,$4b
Index08  dfb   $80
         ds    4,$c1
         ds    18
         ds    4,$10
         dfb   $08
         dfb   $0c
         dfb   $08
         dfb   $04
         dfb   $40
         dfb   $24
         ds    2,$20
         dfb   $24
         ds    2
         dfb   $24
         ds    2,$20
         dfb   $24
         ds    2,$20
         dfb   $00
         dfb   $20
         ds    11
         ds    3,$04
         ds    9
         ds    3,$04
         ds    6

SaveReg  sta   $fc        ;save registers
         stx   $fb
         sty   $fa
         rts

RestReg  lda   $fc        ;restore registers
         ldx   $fb
         ldy   $fa
         rts

L4644    jsr   SaveReg
         ldx   #$ff
         ldy   #$00
:Loop    dex
         dey
         lda   InputTemp1,x
         sta   InputTemp1,y
         lda   InputTemp2,x
         sta   InputTemp2,y
         lda   Index03,x
         sta   Index03,y
         cpx   $f6
         bne   :Loop
         lda   $f9
         sta   InputTemp1,x
         lda   $f8
         sta   InputTemp2,x
         lda   $f7
         sta   Index03,x
         jsr   RestReg
         rts

L4676    ldx   #$00
         txa
         tay
         sta   $ff
:Loop    sta   Index03,y
         iny
         cpy   #$ff
         bne   :Loop
L4684    lda   InputBuf,x
         cmp   #$0d
         beq   FoundReturn
         sta   $fe
         inx
         lda   InputBuf,x
         sta   $fd
         ldy   #$00
:Loop    lda   Index05,y
         cmp   $fe
         bne   :L46A7
         lda   Index06,y
         cmp   #$2a
         beq   :L46A7
         cmp   $fd
         beq   :L46AE
:L46A7   iny
         cpy   #$51
         bne   :Loop
         beq   :L46BA

:L46AE   tya
         ldy   $ff
         sta   InputTemp1,y
         inc   $ff
         inx
         jmp   L4684

:L46BA   ldy   #$00
:Loop1   lda   Index06,y
         cmp   #$2a
         bne   :L46CA
         lda   Index05,y
         cmp   $fe
         beq   :L46D1
:L46CA   iny
         cpy   #$51
         bne   :Loop1
         beq   :L46DC

:L46D1   tya
         ldy   $ff
         sta   InputTemp1,y
         inc   $ff
         jmp   L4684

:L46DC   lda   $fe
         ldy   #$08
:Loop2   cmp   StressInputTable,y
         beq   SetStress
         dey
         bne   :Loop2
         stx   Error
         jsr   ErrorBell
         rts

SetStress
         tya
         ldy   $ff
         dey
         sta   Index03,y
         jmp   L4684

FoundReturn
         lda   #$ff
         ldy   $ff
         sta   InputTemp1,y
         rts

L4701    ldy   #$00
:Loop    lda   InputTemp1,y
         cmp   #$ff
         beq   :Exit
         tax
         lda   Index03,y
         beq   :L471B
         bmi   :L471B
         lda   L57E0,x
         sta   InputTemp2,y
         jmp   :L4721

:L471B   lda   L5830,x
         sta   InputTemp2,y
:L4721   iny
         jmp   :Loop

:Exit    rts

L4726    lda   #$00
         sta   $ff
:L472A   ldx   $ff
         lda   InputTemp1,x
         cmp   #$ff
         bne   :L4734
         rts

:L4734   sta   $f9
         tay
         lda   Index07,y
         tay
         and   #$02
         bne   :L4744
         inc   $ff
         jmp   :L472A

:L4744   tya
         and   #$01
         bne   :L4775
         inc   $f9
         ldy   $f9
         lda   Index03,x
         sta   $f7
         lda   L5830,y
         sta   $f8
         inx
         stx   $f6
         jsr   L4644
         inc   $f9
         ldy   $f9
         lda   L5830,y
         sta   $f8
         inx
         stx   $f6
         jsr   L4644
         inc   $ff
         inc   $ff
         inc   $ff
         jmp   :L472A

:L4775   inx
         lda   InputTemp1,x
         beq   :L4775
         sta   $f5
         cmp   #$ff
         bne   :L4784
         jmp   :L4796

:L4784   tay
         lda   Index07,y
         and   #$08
         bne   :L47BE
         lda   $f5
         cmp   #$24
         beq   :L47BE
         cmp   #$25
         beq   :L47BE
:L4796   ldx   $ff
         lda   Index03,x
         sta   $f7
         inx
         stx   $f6
         ldx   $f9
         inx
         stx   $f9
         lda   L5830,x
         sta   $f8
         jsr   L4644
         inc   $f6
         inx
         stx   $f9
         lda   L5830,x
         sta   $f8
         jsr   L4644
         inc   $ff
         inc   $ff
:L47BE   inc   $ff
         jmp   :L472A

L47C3    lda   #$00
         sta   $ff
:L47C7   ldx   $ff
         lda   InputTemp1,x
         bne   :L47D3
         inc   $ff
         jmp   :L47C7

:L47D3   cmp   #$ff
         bne   :L47D8
         rts

:L47D8   tay
         lda   Index07,y
         and   #$10
         beq   :L47FF
         lda   Index03,x
         sta   $f7
         inx
         stx   $f6
         lda   Index07,y
         and   #$20
         beq   :L47FB
         lda   #$15
:L47F1   sta   $f9
         jsr   L4644
         ldx   $ff
         jmp   :L4923

:L47FB   lda   #$14
         bne   :L47F1

:L47FF   lda   InputTemp1,x
         cmp   #$4e
         bne   :L481D
         lda   #$18
:L4808   sta   $f9
         lda   Index03,x
         sta   $f7
         lda   #$0d
         sta   InputTemp1,x
         inx
         stx   $f6
         jsr   L4644
         jmp   :L49A4

:L481D   cmp   #$4f
         bne   :L4825
         lda   #$1b
         bne   :L4808

:L4825   cmp   #$50
         bne   :L482D
         lda   #$1c
         bne   :L4808

:L482D   tay
         lda   Index07,y
         and   #$80
         beq   :L4860
         lda   Index03,x
         beq   :L4860
         inx
         lda   InputTemp1,x
         bne   :L4860
         inx
         ldy   InputTemp1,x
         lda   Index07,y
         and   #$80
         beq   :L4860
         lda   Index03,x
         beq   :L4860
         stx   $f6
         lda   #$00
         sta   $f7
         lda   #$1f
         sta   $f9
         jsr   L4644
         jmp   :L49A4

:L4860   ldx   $ff
         lda   InputTemp1,x
         cmp   #$17
         bne   :L4899
         dex
         lda   InputTemp1,x
         cmp   #$45
         bne   :L4879
         lda   #$2a
         sta   InputTemp1,x
         jmp   :L4941

:L4879   cmp   #$39
         bne   :L4885
         lda   #$2c
         sta   InputTemp1,x
         jmp   :L494A

:L4885   tay
         inx
         lda   Index07,y
         and   #$80
         bne   :L4891
         jmp   :L49A4

:L4891   lda   #$12
         sta   InputTemp1,x
         jmp   :L49A4

:L4899   cmp   #$18
         bne   :L48B4
         dex
         ldy   InputTemp1,x
         inx
         lda   Index07,y
         and   #$80
         bne   :L48AC
         jmp   :L49A4

:L48AC   lda   #$13
         sta   InputTemp1,x
         jmp   :L49A4

:L48B4   cmp   #$20
         bne   :L48CC
         dex
         lda   InputTemp1,x
         cmp   #$3c
         beq   :L48C3
         jmp   :L49A4

:L48C3   inx
         lda   #$26
         sta   InputTemp1,x
         jmp   :L49A4

:L48CC   cmp   #$48
         bne   :L48E7
         inx
         ldy   InputTemp1,x
         dex
         lda   Index07,y
         and   #$20
         beq   :L48DF
         jmp   :L4902

:L48DF   lda   #$4b
         sta   InputTemp1,x
         jmp   :L4902

:L48E7   cmp   #$3c
         bne   :L4902
         inx
         ldy   InputTemp1,x
         dex
         lda   Index07,y
         and   #$20
         beq   :L48FA
         jmp   :L49A4

:L48FA   lda   #$3f
         sta   InputTemp1,x
         jmp   :L49A4

:L4902   ldy   InputTemp1,x
         lda   Index07,y
         and   #$01
         beq   :L4923
         dex
         lda   InputTemp1,x
         inx
         cmp   #$20
         beq   :L4919
         tya
         jmp   :L4962

:L4919   sec
         tya
         sbc   #$0c
         sta   InputTemp1,x
         jmp   :L49A4

:L4923   lda   InputTemp1,x
         cmp   #$35
         bne   :L4941
         dex
         ldy   InputTemp1,x
         inx
         lda   Index08,y
         and   #$04
         bne   :L4939
         jmp   :L49A4

:L4939   lda   #$10
         sta   InputTemp1,x
         jmp   :L49A4

:L4941   cmp   #$2a
         bne   :L494A
:L4945   tay
         iny
         jmp   :L4951

:L494A   cmp   #$2c
         beq   :L4945
         jmp   :L4962

:L4951   sty   $f9
         inx
         stx   $f6
         dex
         lda   Index03,x
         sta   $f7
         jsr   L4644
         jmp   :L49A4

:L4962   cmp   #$45
         bne   :L4968
         beq   :L496F

:L4968   cmp   #$39
         beq   :L496F
         jmp   :L49A4

:L496F   dex
         ldy   InputTemp1,x
         inx
         lda   Index07,y
         and   #$80
         beq   :L49A4
         inx
         lda   InputTemp1,x
         beq   :L4998
         tay
         lda   Index07,y
         and   #$80
         beq   :L49A4
         lda   Index03,x
         bne   :L49A4
:L498E   ldx   $ff
         lda   #$1e
         sta   InputTemp1,x
         jmp   :L49A4

:L4998   inx
         lda   InputTemp1,x
         tay
         lda   Index07,y
         and   #$80
         bne   :L498E
:L49A4   inc   $ff
         jmp   :L47C7

L49A9    lda   #$00
         sta   $ff
:L49AD   ldx   $ff
         ldy   InputTemp1,x
         cpy   #$ff
         bne   :L49B7
         rts

:L49B7   lda   Index07,y
         and   #$40
         beq   :L49D6
         inx
         ldy   InputTemp1,x
         lda   Index07,y
         and   #$80
         beq   :L49D6
         ldy   Index03,x
         beq   :L49D6
         bmi   :L49D6
         iny
         dex
         tya
         sta   Index03,x
:L49D6   inc   $ff
         jmp   :L49AD

ZPbackup hex   4f80000015ab05abf2bc22bd5abdb6bd0c0100004c0b2201f194000000000080 ;Could be zeroed out?
         asc   'COPYRIGHT 1982 DON',27,'T ASK - ALL RIGHTS l buffer to disk, X'
         asc   'ON sent to resume.'
         hex   0d0a0a003a1e01cd9c1c20202d2054724545736665722041534349492066696c
         hex   6520746f2072656d6f74650d0a0a003a1401b73a2001c29235cd9c1c20202d20
         hex   53656e64206c6f63616c20636f6e74726f6c2063686172616374657220746f20
         hex   72656d6f74650d0a0a00c3c935cd9c1c20202d204e6578742063686172616374
         hex   65722077696c6c206265207573656420666f72206c6f63616c20636f6e74726f
         hex   6c0d0a00cdab1c0d0a44656661756c7420447269766520000e19
L4B00    ds    3
         ds    6,$10
         ds    6,$20
         ds    7,$30
         ds    7,$40
         ds    8,$50
         ds    12,$60
         ds    31,$70
         ds    12,$60
         ds    8,$50
         ds    7,$40
         ds    7,$30
         ds    6,$20
         ds    6,$10
         ds    5
         ds    6,$f0
         ds    6,$e0
         ds    7,$d0
         ds    7,$c0
         ds    8,$b0
         ds    12,$a0
         ds    31,$90
         ds    12,$a0
         ds    8,$b0
         ds    7,$c0
         ds    7,$d0
         ds    6,$e0
         ds    6,$f0
         ds    2
L4C00    ds    128,$90
         ds    128,$70
L4D00    ds    18
         ds    2,$01
         ds    2,$02
         ds    2,$03
         ds    2,$04
         ds    2,$05
         ds    2,$06
         ds    2,$07
         hex   000102030405060708090a0b0c0d0e0f000103040607090a0c0d0f1012131516
         hex   00020406080a0c0e10121416181a1c1e000205070a0c0f111416191b1e202325
         hex   000306090c0f1215181b1e2124272a2d0003070a0e1115181c1f23262a2d3134
         hex   00fcf8f4f0ece8e4e0dcd8d4d0ccc8c400fcf9f5f2eeebe7e4e0ddd9d6d2cfcb
         hex   00fdfaf7f4f1eeebe8e5e2dfdcd9d6d300fdfbf8f6f3f1eeece9e7e4e2dfddda
         hex   00fefcfaf8f6f4f2f0eeeceae8e6e4e200fefdfbfaf8f7f5f4f2f1efeeecebe9
         hex   00fffefdfcfbfaf9f8f7f6f5f4f3f2f100fffffefefdfdfcfcfbfbfafaf9f9f8
L4E00    hex   d8d8d8d8d8d8d8d8d9dadbdddee1e5e8e9ebebebeae9e7e7e7e7e7e7e7e7e9ea
         hex   ecededededededeae6e3e3e3e3e3e3e3e3e4e5e6e6e7e8e9e9e9e9e9ebededed
         hex   ededededececececeae8e7e5e3e3e3e3e3e3e3e4e5e6e6e7e8e9e9eaebeceded
         hex   ededededededebe7e4e3e2e1e0dfdfe0e1e1e3e5e6e9ebedededededededeceb
         hex   eae9e7e5e5e4e2e1dfdddcdbdadadbdcdddfe0e1e3e4e5e7e7e7e8e8e9e9eaea
         hex   ebebebebeaeae9eaebecededeeeeeff0f1f2f3f4f5f6f8f9fafcfdfe00010203
         hex   0200fefdfaf7f6f3f1f0eeecebe9e7e7e7e7e7e7e7e7e714120f0d0b08080808
         hex   0808080808b91a20a0ad178bca98196d52cb1d90fb3d613a56507e8a52f637b2
L4F00    hex   17171717171717171717171717130f0a0a0a0a0a0c0f12121212121212120f0c
         hex   090606060606060d141b1b1b1b1b1b1b1a1817151412110f0f0f0f0f0b060606
         hex   06060607090909090c1013171b1b1b1b1b1b1a1817151412110f0f0d0b090606
         hex   0606060606060b101515151515151515151513100e0b09060606060606060606
         hex   0707080808080a0c0e101313131313131313131313121212121211100f0e0d0c
         hex   0a0a0a0b0c0d0e0e0e0e0f10111212121212121212121111100f0f0e0d0d0d0d
         hex   0d0d0d0d0e101113131313131313131313131313131313131313131313131313
         hex   13131313136e64206d6573736167652c0d0a776865726520303d3131302c2031
L5000    hex   2c2c2c2c2c2c2c2c2c2c2c2c2c2d2e2f2f2f2f2f2f3031313131313131313539
         hex   3d4242424242423930272727272727272a2e3236393d4145454545453a2e2e2e
         hex   2e2e2e3033333333312f2c2a2727272727272a2e3236393d4145454544434242
         hex   424242424242372b1f1f1f1f1f1f1f1f1f1f273039424b545454545454544c43
         hex   3a31282828282d32383d4343434343413f3d3a38363333333333373c41454a4f
         hex   54544a3f34291e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1d1d1d1d
         hex   1d1d1d1d26303943434343434343434343434343434343434343434343434343
         hex   43434343436f6465207365740d0a00c9cdab1c
         asc   'Checksum mode'
L5100    hex   57575757575757575757575757595b5d5d5d5d5d53493e3e3e3e3e3e3e3e4c5b
         hex   6a7979797979796e63585858585858585859595a5b5b5c5d5d5d5d5d57515151
         hex   515151575d5d5d5d5c5b5a595858585858585859595a5b5b5c5d5d646b727979
         hex   7979797979796e6358585858585858585858595a5b5c5d5e5e5e5e5e5e5e5b57
         hex   54504c4c4c4c4f5255585b5b5b5b5b57534f4b47433e3e3e3e3e444b52596067
         hex   6e6e6e6e6e6e6e6e6e6a66615d58585858585858585756555453525150505050
         hex   505050505255585b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b
         hex   5b5b5b5b5bc2cf3ccdab1c4e4f542000cdab1c
         asc   'sent after <C'
L5200    hex   0f0f0f0f0f0f0f0f0f0f0f0f0f0d0b0808080808080809090909090909090503
         hex   0200000000000003060f0f0f0f0f0f0f0f0f0f0f0f0f0f0d0d0d0d0d0b090909
         hex   090909090808080808090b0d0f0f0f0f0f0f0f0f0f0f0f0f0f0d0d0804020000
         hex   00000000000003060f0f0f0f0f0f0f0f0f0f0b06040302000000000000000202
         hex   0304080808080809090b0d0d0d0d0d0d0d0d0d0d0d0b0b0b0b0b0b0b0b0b0b0b
         hex   0b0b0b0b0b0b0b0b0b0b0b0d0d0f0f0f0f0f0f0f0f0f0f0f0d0d0d0d0b0b0b0b
         hex   0b0b0b0b06040200000000000000000000000000000000000000000000000000
         hex   0000000000a40202aa500202500202020002029d00009d000200e002019d0002
L5300    hex   0909090909090909090909090906040202020202030408080808080808080503
         hex   0200000000000002040b0b0b0b0b0b0b0b0b0b0b0b0b0b090909090904020202
         hex   0202020202020202030405080b0b0b0b0b0b0b0b0b0b0b0b0b09090503020000
         hex   0000000000000204090909090909090909090604030202000000060000000001
         hex   010202020202030405080b0b0b0b0b0b0b0b0b0b0b0909090909090909080808
         hex   0606060605050404040405060809090909090909090908080606050504040404
         hex   0404040403020200000000000000000000000000000000000000000000000000
         hex   0000000000024f0002aa0202020202aa02020200020002020200000202020002
L5400    hex   0101010101010101010101010101010000000000010203030303030303030202
         hex   0200000000000000000101010101010101020202020303040404040402000000
         hex   0000000000000000000000000101010101010102020202030304040302020000
         hex   0000000000000000000000000000000000000000000000000000030000000000
         hex   0000000000000102020304040404040404040404040303030303030303040404
         hex   0404040302020101010101010100000000000000000000000000000000000000
         hex   0000000000000000000000000000000000000000000000000000000000000000
         hex   00000000009d0000024f02a402a4a40202aa00020202a4a4020250500202024f
L5500    ds    14
         ds    6,$03
         ds    15
         ds    2,$19
         ds    30
         ds    6,$01
         ds    25
         ds    2,$19
         ds    27
         ds    8,$03
         ds    94
         hex   12022acb01eb2ad401cd841fe52acd01eb2ad401cd841f5c1600e1
L5600    hex   00131313130a0e13181b171510140e120e1212100d0f0b120e0b090606060611
         hex   060606060e10090a080a060606050600131b151b120d06060606060606060606
         hex   0606060606060606060a0a0606062c13
L5650    hex   00434343435449433f282c1f252d4931241e33251d4518321e18532e36563643
         hex   494f1a4249253342282f4f4f424f6e0048271f2b1e221a1a1a4242426e6e6e54
         hex   54541a1a1a4242426d566d5454547f7f
L56A0    hex   005b5b5b5b6e5d5b5859575852595d3e52583e6e505d5a3c6e5a6e517965795b
         hex   636a51795d525d674c5d6565796579005a5858585852515151797979706e6e5e
         hex   5e5e5151517979796565705e5e5e0801
L56F0    hex   00000000000d0d0e0f0f0f0f0f0c0d0c0f0f0d0d0d0e0d0c0d0d0d0c09090000
         hex   0000000000000b0b0b0b0000010b00020e0f0f0f0f0d02040002040001040001
         hex   0400000000000000000c000000000f0f
L5740    hex   00000000000a0b0d0e0d0c0c0b090b0b0c0c0c08080c080a08080a0309060000
         hex   00000000000003050304000000050a020e0d0c0d0c0800010000010000010000
         hex   0100000000000000000a00000a000000
L5790    hex   0000000000080708080101000100070501000601000700050100080000030000
         hex   00000000000000010000000000010e0109010001000000000000000000000000
         hex   00000000000000000007000005001310
L57E0    hex   00121212080b090b0e0f0b100c06060e0c0e0c0b08080b0a0908080808080305
         hex   020202020202060608060602090402010e0f0f0f0e0e08020207020107020207
         hex   02020802020602020702040701040505
L5830    hex   0012121208080808080b060c0a05050b0a0a0a09080709070608060707070205
         hex   0202020202020606070606020803011e0d0c0c0c0e0906010205010106010206
         hex   0102080202040202060104060104c7ff
L5880    hex   0002020202040404040404040404040404040302040402020202020101010101
         hex   0101010101010202020100010001000505050505040402000102000102000102
         hex   0001020002020001030002030002a0a0
L58D0    hex   0002020202040404040404040404040404040303040403030303030102030201
         hex   0303030301010303030202030203000005050505040402000202000302000402
         hex   0003020002020002030003030003b0a0
L5920    hex   001f1f1f1f0202020202020202020505020a020805050b0a090808a00808171f
         hex   121212121e1e1414141417171a1a1d1d0202020202021a1d1b1a1d1b1a1d1b1a
         hex   1d1b171d17171d17171d17171d171717
L5970    ds    32
         hex   f1e2d3bb7c950102030300720002
         ds    21
         dfb   $1b
         ds    2
         dfb   $19
         ds    9
         hex   38846b19c66318867398c6b11cca318cc73188c23098463118c6350cca310cc6
         hex   2110246912c23114c471084a2249ab6aa8ac495132d55288936c94221554d225
         hex   96d450a5462108856b18c46310ce6b188c71198c63350cc63399cc6cb54ea299
         hex   46212882952ee3309cc5309ca2b19c67318866592c5318846750cae30aacab30
         hex   ac62308c63109462b18c8228963398d6b54c6229a54ab59cc63114d6389c4bb4
         hex   866518ae671ca66319962319841308a652acca22896eab198c6234c462198663
         hex   18c42358d6a35042544aad4a25116b64894a63398a23312aeaa2a944c512cd42
         hex   348c62188c63114866319d44331d46319cc6b10ccd3288c47318867308d66358
         hex   0781e0f03c0787903c7c0fc7c0c0f07c1e078080001c7870f1c71fc00cfe1c1f
         hex   1f0e0a7ac071f2838f030f0f0c0079f861e0430f83e718f9c113dae9638f0f83
         hex   8387c31f3c70f0e1e1e387b8710e20e38d48781c938730e1c1c1e478218383c3
         hex   870639e5c387070e1c1c70f4719c603632c31e3cf38f0e3c70e3c78f0f0f0e3c
         hex   78f0e38706f0e307c199870f18787070fcf310b18c8c317c70e1863c646cb0e1
         hex   e30f238f0f1e3e383c387b8f070e3cf4171e3c78f29e7249e32536385839e2de
         hex   3c7878e1c761e1e1b0f0f0c3c70e38c0f0ce73731834b0e1c78e1c3cf838f0e1
         hex   c18b868f1c7870f078acb18f3931db3861c30e0e387873171e391e3864e1f1c1
         hex   4e0f40a202c58f81a1fc120864e03c22e045078e0c3290f01f2049e0f80c60f0
         hex   171a41aaa4d08d12821e1e03f83e030c73807044260324e13e044e041cc109cc
         hex   9e902107904364c00fc6909cc15b03e21d81e05e1d0384b82c0f80b183e03041
         hex   1e43898350fc242e1383f17c4c2cc90d83b0b582e4e8069c07a0991d073e828f
         hex   70307440ca10e4e80f92143f06f8848843810a343941c6e31c4703b0b8130ac2
         hex   64f818f960b3c0652060a68cc3812030261e1c38d301b02640f40bc3421f8532
         hex   266040c9cb01ec112840fa0434e0704c8c1d07690316c80423e8c69a0b1a03e0
         hex   760605cf1ebc5831716600f83f04fc0c74278a8071c23a2606c01f050f9840ae
         hex   017fc007ff000efe0003df8003ef801bf1c200e7e018fce021fc803cfc400e7e
         hex   003f3e000ffe001fff003ef007fc007e103fff003f380e7c01870cfcc7003e04
         hex   0f3e1f0f0f1f0f028387cf03870f3fc0079e603fc003fe003fe077e1c0fee0c3
         hex   e001dff80307007e70007c3818fe0c1e781c7c3e0e1f1e1e3e007f8307db8783
         hex   07c7071071ff003fe201e0c1c3e1007fc005f020f8f070fe7879f8023f0c8f03
         hex   0f9fe0c1c78703c3c3b0e1e1c1e3e071f000fc707c0c3e380e1c70c3c70381c1
         hex   c7e7000fc7871909efc433e0c1fcf870f078f8f061c7001ff8017cf8f078703c
         hex   7cce0e2183cf08078f08c1878f80c7e30007f8e0ef0039f7800ef8e1e3f8219f
         hex   c0ff03f807c01ff8c404fcc4c1bc87f00fc07f05e025ecc03e8447f08e03f803
         hex   fbc019f8079c0c17f807e01fa1fc0ffc01f03f00fe03f01f00fd00ff880df901
         hex   ff007007c03e42f30dc47f80fc07f05ec03f00783f81ff01f801c3e80ce4648f
         hex   e40ff007f0c21f007fc06f807e03f807f03fc0780f8207fe227770027603fe00
         hex   fe67007cc7f18ec63be03f84f319d80399fc09b80ff8009d2461f90d00fd03f0
         hex   1f903f01f81fd00ff83701f807f00fc03f00fe03f80fc03f00fa03f00f80ff01
         hex   b807f001fc01bc80131e007fe1407fa07fb0003fc01fc0380ff01f80ff01fc03
         hex   f17e01fe01f0ff007fc01d07f00fc07e06e007e00ff806c1fe01fc03e00f00fc
Index09  hex   0a290f45464731151b2631154546470b4b4c4d2807120518341401ff2001ffe8
         hex   bcee41b99a452980f00dbcee43f0083006c8ca989dee43e6ff4cad49
Index10  hex   0400000000000000000000000606060500000005040000000000000500002069
         asc   'COPYRIGHT 1982 DON',27,'T ASK - A'
Index11  hex   0e060b0402020c0907060c070602020e060104080b0a08060e0d120d0212
         asc   'N sent to resume.',0d0a0a
         hex   003a1e01cd9c1c20202d
Index12  hex   000102020203030404050608090b0d0f
Index13  hex   0000e0e6ecf3f900060c06

L5F8F    ldy   #$00
         bit   $f2
         bpl   :L5F9E
         sec
         lda   #$00
         sbc   $f2
         sta   $f2
         ldy   #$80
:L5F9E   sty   $ef
         lda   #$00
         ldx   #$08
:L5FA4   asl   $f2
         rol   A
         cmp   $f1
         bcc   :L5FAF
         sbc   $f1
         inc   $f2
:L5FAF   dex
         bne   :L5FA4
         sta   $f0
         bit   $ef
         bpl   :Exit
         sec
         lda   #$00
         sbc   $f2
         sta   $f2
:Exit    rts

BackupZP ldx   #$1f
:Loop    lda   $e0,x
         sta   ZPbackup,x
         dex
         bne   :Loop
         rts

RestoreZP
         ldx   #$1f
:Loop    lda   ZPbackup,x
         sta   $e0,x
         dex
         bne   :Loop
         rts

L5FD6    lda   Index09
         cmp   #$ff
         bne   :L5FDE
         rts

:L5FDE   lda   #$00
         tax
         sta   $e9
L5FE3    ldy   $e9
         lda   Index09,y
         sta   $f5
         cmp   #$ff
         bne   :L5FF1
         jmp   L604E

:L5FF1   cmp   #$01
         bne   :L5FF8
         jmp   L62EE

:L5FF8   cmp   #$02
         bne   L5FFF
         jmp   L62F4

L5FFF    lda   Index10,y
         sta   $e8
         lda   Index11,y
         sta   $e7
         ldy   $e8
         iny
         lda   Index13,y
         sta   $e8
         ldy   $f5
L6013    lda   L5600,y
         sta   L4F00,x
         lda   L5650,y
         sta   L5000,x
         lda   L56A0,y
         sta   L5100,x
         lda   L56F0,y
         sta   L5200,x
         lda   L5740,y
         sta   L5300,x
         lda   L5790,y
         sta   L5400,x
         lda   L5970,y
         sta   L5500,x
         clc
L603E    lda   #$f0
         adc   $e8
         sta   L4E00,x
         inx
         dec   $e7
         bne   L6013
         inc   $e9
         bne   L5FE3
L604E    lda   #$00
         sta   $e9
         sta   $ee
         tax
:L6055   ldy   Index09,x
         inx
         lda   Index09,x
         cmp   #$ff
         bne   :L6063
         jmp   :L6162

:L6063   tax
         lda   L5920,x
         sta   $f5
         lda   L5920,y
         cmp   $f5
         beq   :L608C
         bcc   :L607F
         lda   L5880,y
         sta   $e8
         lda   L58D0,y
         sta   $e7
         jmp   :L6096

:L607F   lda   L58D0,x
         sta   $e8
         lda   L5880,x
         sta   $e7
         jmp   :L6096

:L608C   lda   L5880,y
         sta   $e8
         lda   L5880,x
         sta   $e7
:L6096   clc
         lda   $ee
         ldy   $e9
         adc   Index11,y
         sta   $ee
         adc   $e7
         sta   $ea
         lda   #$00
         sta   $eb
         lda   #$4e
         sta   $ec
         sec
         lda   $ee
         sbc   $e8
         sta   $e6
         clc
         lda   $e8
         adc   $e7
         sta   $e3
         tax
         dex
         dex
         bpl   :L60C2
         jmp   :L615B

:L60C2   lda   $e3
         sta   $e5
         lda   $ec
         cmp   #$4e
         bne   :L6109
         ldy   $e9
         lda   Index11,y
         lsr   A
         sta   $e1
         iny
         lda   Index11,y
         lsr   A
         sta   $e2
         clc
         lda   $e1
         adc   $e2
         sta   $e5
         clc
         lda   $ee
         adc   $e2
         sta   $e2
         sec
         lda   $ee
         sbc   $e1
         sta   $e1
         ldy   $e2
         lda   ($eb),y
         sec
         ldy   $e1
         sbc   ($eb),y
         sta   $f2
         lda   $e5
         sta   $f1
         jsr   L5F8F
         ldx   $e5
         ldy   $e1
         jmp   :L611F

:L6109   ldy   $ea
         sec
         lda   ($eb),y
         ldy   $e6
         sbc   ($eb),y
         sta   $f2
         lda   $e5
         sta   $f1
         jsr   L5F8F
         ldx   $e5
         ldy   $e6
:L611F   lda   #$00
         sta   $f5
         clc
:L6124   lda   ($eb),y
         adc   $f2
         sta   $ed
         iny
         dex
         beq   :L6150
         clc
         lda   $f5
         adc   $f0
         sta   $f5
         cmp   $e5
         bcc   :L6149
         lda   $f5
         sbc   $e5
         sta   $f5
         bit   $ef
         bmi   :L6147
         inc   $ed
         bne   :L6149
:L6147   dec   $ed
:L6149   lda   $ed
         sta   ($eb),y
         clc
         bcc   :L6124

:L6150   inc   $ec
         lda   $ec
         cmp   #$55
         beq   :L615B
         jmp   :L60C2

:L615B   inc   $e9
         ldx   $e9
         jmp   :L6055

:L6162   lda   $ee
         clc
         ldy   $e9
         adc   Index11,y
         sta   $ed
         ldx   #$00
:Loop    lda   L4F00,x
         lsr   A
         sta   $f5
         sec
         lda   L4E00,x
         sbc   $f5
         sta   L4E00,x
         dex
         bne   :Loop
         lda   #$00
         sta   $e8
         sta   $e7
         sta   $e6
         sta   $ee
         lda   #$48
         sta   $ea
         lda   #$03
         sta   $f5
         lda   #$00
         sta   $eb
         lda   #$52
         sta   $ec
:L619A   ldy   #$00
:L619C   lda   ($eb),y
         tax
         lda   Index12,x
         sta   ($eb),y
         dey
         bne   :L619C
         inc   $ec
         dec   $f5
         bne   :L619A
         ldy   #$00
         lda   L4E00,y
         sta   $e9
         tax
         lsr   A
         lsr   A
         sta   $f5
         sec
         txa
         sbc   $f5
         sta   $e3
         jmp   L61CE

L61C2    jsr   L6267
         iny
         iny
         dec   $ed
         dec   $ed
         jmp   L6218

L61CE    lda   L5500,y
         sta   $e4
         and   #$f8
         bne   L61C2
         ldx   $e8
         clc
         lda   L4B00,x
         ora   L5200,y
         tax
         lda   L4D00,x
         sta   $f5
         ldx   $e7
         lda   L4B00,x
         ora   L5300,y
         tax
         lda   L4D00,x
         adc   $f5
         sta   $f5
         ldx   $e6
         lda   L4C00,x
         ora   L5400,y
         tax
         lda   L4D00,x
         adc   $f5
         adc   #$88
         eor   $2f
         bpl   :L6211
         bit   SPKR
         eor   $2f
         sta   $2f
:L6211   dec   $ea
         bne   L621F
         iny
         dec   $ed
L6218    bne   L621B
         rts

L621B    lda   #$46
         sta   $ea
L621F    dec   $e9
         bne   :L623E
:L6223   lda   L4E00,y
         sta   $e9
         tax
         lsr   A
         lsr   A
         sta   $f5
         sec
         txa
         sbc   $f5
         sta   $e3
         lda   #$00
         sta   $e8
         sta   $e7
         sta   $e6
         jmp   L61CE

:L623E   dec   $e3
         bne   :L624C
         lda   $e4
         beq   :L624C
         jsr   L6267
         jmp   :L6223

:L624C   clc
         lda   $e8
         adc   L4F00,y
         sta   $e8
         clc
         lda   $e7
         adc   L5000,y
         sta   $e7
         clc
         lda   $e6
         adc   L5100,y
         sta   $e6
         jmp   L61CE

L6267    sty   $ee
         lda   $e4
         tay
         and   #$07
         tax
         dex
         stx   $f5
         lda   Index14,x
         sta   $f2
         clc
         lda   #$59
         adc   $f5
         sta   $ec
         lda   #$c0
         sta   $eb
         tya
         and   #$f8
         bne   :L6293
         ldy   $ee
         lda   L4E00,y
         lsr   A
         lsr   A
         lsr   A
         lsr   A
         jmp   :L62BD

:L6293   eor   #$ff
         tay
:L6296   lda   #$08
         sta   $f5
         lda   ($eb),y
:L629C   pha
         eor   $2f        ;toggle?
         bpl   :L62A8
         bit   SPKR
         eor   $2f
         sta   $2f
:L62A8   pla
         asl   A
         ldx   #$03
:L62AC   dex
         bne   :L62AC
         dec   $f5
         bne   :L629C
         iny
         bne   :L6296
         lda   #$01
         sta   $e9
         ldy   $ee
         rts

:L62BD   eor   #$ff
         sta   $e8
         ldy   $ff
:L62C3   lda   #$08
         sta   $f5
         lda   ($eb),y
:L62C9   pha
         eor   $2f        ;toggle?
         bpl   :L62D5
         bit   SPKR
         eor   $2f
         sta   $2f
:L62D5   pla
         asl   A
         ldx   #$03
:L62D9   dex
         bne   :L62D9
         dec   $f5
         bne   :L62C9
         iny
         inc   $e8
         bne   :L62C3
         lda   #$01
         sta   $e9
         sty   $ff
         ldy   $ee
         rts

L62EE    lda   #$01
         sta   $ed
         bne   L62F8

L62F4    lda   #$ff
         sta   $ed
L62F8    stx   $ee
         txa
         sec
         sbc   #$1e
         bcs   :L6302
         lda   #$00
:L6302   tax
:L6303   lda   L4E00,x
         cmp   #$7f
         bne   :L630E
         inx
         jmp   :L6303

:L630E   clc
         adc   $ed
         sta   $e8
         sta   L4E00,x
:L6316   inx
         cpx   $ee
         beq   :L6327
         lda   L4E00,x
         cmp   #$ff
         beq   :L6316
         lda   $e8
         jmp   :L630E

:L6327   jmp   L5FFF

Index14  dfb   $80
         dfb   $a0
         dfb   $70
         dfb   $70
         dfb   $70

L632F    ldx   #$ff
         stx   $f3
         inx
         stx   $f4
         stx   $ff
:L6338   ldx   $ff
         ldy   InputTemp1,x
         cpy   #$ff
         bne   :L6342
         rts

:L6342   clc
         lda   $f4
         adc   InputTemp2,x
         sta   $f4
         cmp   #$e8
         bcc   :L6351
         jmp   :L637A

:L6351   lda   Index08,y
         and   #$01
         beq   :L636F
         inx
         stx   $f6
         lda   #$00
         sta   $f4
         sta   $f7
         lda   #$fe
         sta   $f9
         jsr   L4644
         inc   $ff
         inc   $ff
         jmp   :L6338

:L636F   cpy   #$00
         bne   :L6375
         stx   $f3
:L6375   inc   $ff
         jmp   :L6338

:L637A   ldx   $f3
         cmp   #$ff
         bne   :L6385
         pla
         pla
         jmp   ErrorBell

:L6385   lda   #$1f
         sta   InputTemp1,x
         lda   #$04
         sta   InputTemp2,x
         lda   #$00
         sta   Index03,x
         inx
         stx   $f6
         lda   #$fe
         sta   $f9
         lda   #$00
         sta   $f4
         sta   $f7
         jsr   L4644
         inx
         stx   $ff
         jmp   :L6338

         dfb   $ea        ;NOP?
L63AB    dfb   $2b

L63AC    lda   #$00
         tax
         tay
:L63B0   lda   InputTemp1,x
         cmp   #$ff
         bne   :L63C0
         lda   #$ff
         sta   Index09,y
         jsr   L5FD6
         rts

:L63C0   cmp   #$fe
         bne   :L63D8
         inx
         stx   L63AB
         lda   #$ff
         sta   Index09,y
         jsr   L5FD6
         ldx   L63AB
         ldy   #$00
         jmp   :L63B0

:L63D8   cmp   #$00
         bne   :L63E0
         inx
         jmp   :L63B0

:L63E0   sta   Index09,y
         lda   InputTemp2,x
         sta   Index11,y
         lda   Index03,x
         sta   Index10,y
         inx
         iny
         jmp   :L63B0

L63F4    ldx   #$00
:L63F6   ldy   InputTemp1,x
         cpy   #$ff
         bne   :L6400
:L63FD   jmp   :L6442

:L6400   lda   Index08,y
         and   #$01
         bne   :L640B
         inx
         jmp   :L63F6

:L640B   stx   $ff
:L640D   dex
         beq   :L63FD
         ldy   InputTemp1,x
         lda   Index07,y
         and   #$80
         beq   :L640D
:L641A   ldy   InputTemp1,x
         lda   Index08,y
         and   #$20
         beq   :L642B
         lda   Index07,y
         and   #$04
         beq   :L6439
:L642B   lda   InputTemp2,x
         sta   $f5
         lsr   A
         clc
         adc   $f5
         adc   #$01
         sta   InputTemp2,x
:L6439   inx
         cpx   $ff
         bne   :L641A
         inx
         jmp   :L63F6

:L6442   ldx   #$00
         stx   $ff
:L6446   ldx   $ff
         ldy   InputTemp1,x
         cpy   #$ff
         bne   :L6450
         rts

:L6450   lda   Index07,y
         and   #$80
         bne   :L645A
         jmp   :L64BE

:L645A   inx
         ldy   InputTemp1,x
         lda   Index07,y
         sta   $f5
         and   #$40
         beq   :L649A
         lda   $f5
         and   #$04
         beq   :L6480
         dex
         lda   InputTemp2,x
         sta   $f5
         lsr   A
         lsr   A
         clc
         adc   $f5
         adc   #$01
         sta   InputTemp2,x
:L647D   jmp   :L652A

:L6480   lda   $f5
         and   #$01
         beq   :L647D
         dex
         lda   InputTemp2,x
         tay
         lsr   A
         lsr   A
         lsr   A
         sta   $f5
         sec
         tya
         sbc   $f5
         sta   InputTemp2,x
         jmp   :L652A

:L649A   cpy   #$12
         beq   :L64A5
         cpy   #$13
         beq   :L64A5
:L64A2   jmp   :L652A

:L64A5   inx
         ldy   InputTemp1,x
         lda   Index07,y
         and   #$40
         beq   :L64A2
         ldx   $ff
         lda   InputTemp2,x
         sec
         sbc   #$01
         sta   InputTemp2,x
         jmp   :L652A

:L64BE   lda   Index08,y
         and   #$08
         beq   :L64E1
         inx
         ldy   InputTemp1,x
         lda   Index07,y
         and   #$02
         bne   :L64D3
:L64D0   jmp   :L652A

:L64D3   lda   #$06
         sta   InputTemp2,x
         dex
         lda   #$05
         sta   InputTemp2,x
         jmp   :L652A

:L64E1   lda   Index07,y
         and   #$02
         beq   :L650E
:L64E8   inx
         ldy   InputTemp1,x
         beq   :L64E8
         lda   Index07,y
         and   #$02
         beq   :L64D0
         lda   InputTemp2,x
         lsr   A
         clc
         adc   #$01
         sta   InputTemp2,x
         ldx   $ff
         lda   InputTemp2,x
         lsr   A
         clc
         adc   #$01
         sta   InputTemp2,x
:L650B   jmp   :L652A

:L650E   lda   Index08,y
         and   #$10
         beq   :L650B
         dex
         ldy   InputTemp1,x
         lda   Index07,y
         and   #$02
         beq   :L650B
         inx
         lda   InputTemp2,x
         sec
         sbc   #$02
         sta   InputTemp2,x
:L652A   inc   $ff
         jmp   :L6446

ErrorBell
         jsr   MON_BELL1
         jmp   MON_BELL1

Index15  asc   '4=710, 5=1200, 6=2400, ',0d0a,'7=4800 AND 8=9600 Baud.',0d0a0a
         asc   'Enter value: '
         hex   00cd9c38fe09d2564b4b0501cd453bc3c935cd9b3bc2853bcdab1c
         asc   'Rate for the S mode time-to-send message is set to '
         hex   00c3983bcdab1c
         asc   'Modem speed is '
         hex   00c33f223a0901473a0301b0c93a0d01b7ca56373a0c012f320c01cdb83bc3c9
         hex   35b7c2cf3bcdab1c
         asc   'CRC mode set',0d0a
         hex   00c9cdab1c
         asc   'Checksum mode set',0d0a
         dfb   $00
         hex   c93a0f01b7ca56373a0e012f32
         asc   'COPYRIGHT 1982 DON',27,'T ASK'
Index16  ds    33
         ds    6,$02
         dfb   $82
         dfb   $00
         dfb   $00
         ds    6,$02
         ds    10,$03
         ds    7,$02
         hex   c0a8b0acc0a0b8a0c0bca0aca8acc0a0a0acb4a4c0a8a8b0c0bc0000000200

TextMode jsr   BackupZP
         lda   #$20
         sta   Index15
         ldx   #$01
         ldy   #$00
:L66B9   lda   InputBuf,y
         and   #$7f
         cmp   #$70
         bcc   :L66C7
         and   #$5f
         jmp   :L66CD

:L66C7   cmp   #$60
         bcc   :L66CD
         and   #$4f
:L66CD   sta   Index15,x
         inx
         iny
         cpy   #$ff
         bne   :L66B9
         ldx   #$ff
         lda   #$0d
         sta   Index15,x
         jsr   L66E4
L66E0    jsr   PlayPhenome ;Jumps to phenome mode here
         rts

L66E4    lda   #$ff
         sta   $fa
L66E8    lda   #$ff
         sta   $f5
L66EC    inc   $fa
         ldx   $fa
         lda   Index15,x
         sta   $fd
         cmp   #$0d
         bne   :L6703
         inc   $f5
         ldx   $f5
         lda   #$0d
         sta   InputBuf,x
         rts

:L6703   cmp   #$2e
         bne   :L671F
         inx
         lda   Index15,x
         tay
         lda   Index16,y
         and   #$01
         bne   :L671F
         inc   $f5
         ldx   $f5
         lda   #$2e
         sta   InputBuf,x
         jmp   L66EC

:L671F   lda   $fd
         tay
         lda   Index16,y
         sta   $f6
         and   #$02
         beq   :L6736
         lda   #$da
         sta   $fb
         lda   #$6a
         sta   $fc
         jmp   L677C

:L6736   lda   $f6
         bne   L6765
         lda   #$20
         sta   Index15,x
         inc   $f5
         ldx   $f5
         cpx   #$78
         bcs   L674E
         sta   InputBuf,x
         jmp   L66EC

FA_Store dfb   $00

L674E    lda   #$0d
         sta   InputBuf,x
         lda   $fa
         sta   FA_Store
         sta   $cd        ;This is never read again
         jsr   L66E0
         lda   FA_Store
         sta   $fa
         jmp   L66E8

L6765    lda   $f6
         and   #$80
         bne   :L676C     ;always?
         brk

:L676C   lda   $fd
         sec
         sbc   #$41
         tax
         lda   Index17,x
         sta   $fb
         lda   Rules,x
         sta   $fc
L677C    ldy   #$00
:L677E   clc
         lda   $fb
         adc   #$01
         sta   $fb
         lda   $fc
         adc   #$00
         sta   $fc
         lda   ($fb),y
         bpl   :L677E
         iny
:L6790   lda   ($fb),y
         cmp   #$28
         beq   :L679A
         iny
         jmp   :L6790

:L679A   sty   $ff
:L679C   iny
         lda   ($fb),y
         cmp   #$29
         bne   :L679C
         sty   $fe
:L67A5   iny
         lda   ($fb),y
         and   #$7f
         cmp   #$3d
         bne   :L67A5
         sty   $fd
         ldx   $fa
         stx   $f9
         ldy   $ff
         iny
:L67B7   lda   Index15,x
         sta   $f6
         lda   ($fb),y
         cmp   $f6
         beq   :L67C5
         jmp   L677C

:L67C5   iny
         cpy   $fe
         bne   :L67CD
         jmp   :L67D3

:L67CD   inx
         stx   $f9
         jmp   :L67B7

:L67D3   lda   $fa
         sta   $f8
:L67D7   ldy   $ff
         dey
         sty   $ff
         lda   ($fb),y
         sta   $f6
         bpl   :L67E5
         jmp   :L695C

:L67E5   and   #$7f
         tax
         lda   Index16,x
         and   #$80
         beq   :L6801
         ldx   $f8
         dex
         lda   Index15,x
         cmp   $f6
         beq   :L67FC
         jmp   L677C

:L67FC   stx   $f8
         jmp   :L67D7

:L6801   lda   $f6
         cmp   #$20
         bne   :L680A
         jmp   :L683F

:L680A   cmp   #$23
         bne   :L6811
         jmp   :L684E

:L6811   cmp   #$2e
         bne   :L6818
         jmp   :L6858

:L6818   cmp   #$26
         bne   :L681F
         jmp   :L6867

:L681F   cmp   #$40
         bne   :L6826
         jmp   :L6887

:L6826   cmp   #$5e
         bne   :L682D
         jmp   :L68AC

:L682D   cmp   #$2b
         bne   :L6834
         jmp   :L68BB

:L6834   cmp   #$3a
         bne   :L683B
         jmp   :L68D0

:L683B   jsr   ErrorBell
         brk

:L683F   jsr   :L68DF
         and   #$80
         beq   :L6849
         jmp   L677C

:L6849   stx   $f8
         jmp   :L67D7

:L684E   jsr   :L68DF
         and   #$40
         bne   :L6849
         jmp   L677C

:L6858   jsr   :L68DF
         and   #$08
         bne   :L6862
         jmp   L677C

:L6862   stx   $f8
         jmp   :L67D7

:L6867   jsr   :L68DF
         and   #$10
         bne   :L6862
         lda   Index15,x
         cmp   #$48
         beq   :L6878
         jmp   L677C

:L6878   dex
         lda   Index15,x
         cmp   #$43
         beq   :L6862
         cmp   #$53
         beq   :L6862
         jmp   L677C

:L6887   jsr   :L68DF
         and   #$04
         bne   :L6862
         lda   Index15,x
         cmp   #$48
         beq   :L6898
         jmp   L677C

:L6898   cmp   #$54
         beq   :L68A7
         cmp   #$43
         beq   :L68A7
         cmp   #$53
         beq   :L68A7
         jmp   L677C

:L68A7   stx   $f8
         jmp   :L67D7

:L68AC   jsr   :L68DF
         and   #$20
         bne   :L68B6
         jmp   L677C

:L68B6   stx   $f8
         jmp   :L67D7

:L68BB   ldx   $f8
         dex
         lda   Index15,x
         cmp   #$45
         beq   :L68B6
         cmp   #$49
         beq   :L68B6
         cmp   #$59
         beq   :L68B6
         jmp   L677C

:L68D0   jsr   :L68DF
         and   #$20
         bne   :L68DA
         jmp   :L67D7

:L68DA   stx   $f8
         jmp   :L68D0

:L68DF   ldx   $f8
         dex
         lda   Index15,x
         tay
         lda   Index16,y
         rts

:L68EA   ldx   $f7
         inx
         lda   Index15,x
         tay
         lda   Index16,y
         rts

:L68F5   ldx   $f7
         inx
         lda   Index15,x
         cmp   #$45
         bne   :L6945
         inx
         lda   Index15,x
         tay
         dex
         lda   Index16,y
         and   #$80
         beq   :L6914
         inx
         lda   Index15,x
         cmp   #$52
         bne   :L6919
:L6914   stx   $f7
         jmp   :L6960

:L6919   cmp   #$53
         beq   :L6914
         cmp   #$44
         beq   :L6914
         cmp   #$4c
         bne   :L692F
         inx
         lda   Index15,x
         cmp   #$59
         bne   :L6959
         beq   :L6914

:L692F   cmp   #$46
         bne   :L6959
         inx
         lda   Index15,x
         cmp   #$55
         bne   :L6959
         inx
         lda   Index15,x
         cmp   #$4c
         beq   :L6914
         bne   :L6959

:L6945   cmp   #$49
         bne   :L6959
         inx
         lda   Index15,x
         cmp   #$4e
         bne   :L6959
         inx
         lda   Index15,x
         cmp   #$47
         beq   :L6914
:L6959   jmp   L677C

:L695C   lda   $f9
         sta   $f7
:L6960   ldy   $fe
         iny
         cpy   $fd
         bne   :L696A
         jmp   :L6A6F

:L696A   sty   $fe
         lda   ($fb),y
         sta   $f6
         tax
         lda   Index16,x
         and   #$80
         beq   :L698A
         ldx   $f7
         inx
         lda   Index15,x
         cmp   $f6
         beq   :L6985
         jmp   L677C

:L6985   stx   $f7
         jmp   :L6960

:L698A   lda   $f6
         cmp   #$20
         bne   :L6993
         jmp   :L69CF

:L6993   cmp   #$23
         bne   :L699A
         jmp   :L69DE

:L699A   cmp   #$2e
         bne   :L69A1
         jmp   :L69E8

:L69A1   cmp   #$26
         bne   :L69A8
         jmp   :L69F7

:L69A8   cmp   #$40
         bne   :L69AF
         jmp   :L6A17

:L69AF   cmp   #$5e
         bne   :L69B6
         jmp   :L6A3C

:L69B6   cmp   #$2b
         bne   :L69BD
         jmp   :L6A4B

:L69BD   cmp   #$3a
         bne   :L69C4
         jmp   :L6A60

:L69C4   cmp   #$25
         bne   :L69CB
         jmp   :L68F5

:L69CB   jsr   ErrorBell
         brk

:L69CF   jsr   :L68EA
         and   #$80
         beq   :L69D9
         jmp   L677C

:L69D9   stx   $f7
         jmp   :L6960

:L69DE   jsr   :L68EA
         and   #$40
         bne   :L69D9
         jmp   L677C

:L69E8   jsr   :L68EA
         and   #$08
         bne   :L69F2
         jmp   L677C

:L69F2   stx   $f7
         jmp   :L6960

:L69F7   jsr   :L68EA
         and   #$10
         bne   :L69F2
         lda   Index15,x
         cmp   #$48
         beq   :L6A08
         jmp   L677C

:L6A08   inx
         lda   Index15,x
         cmp   #$43
         beq   :L69F2
         cmp   #$53
         beq   :L69F2
         jmp   L677C

:L6A17   jsr   :L68EA
         and   #$04
         bne   :L69F2
         lda   Index15,x
         cmp   #$48
         beq   :L6A28
         jmp   L677C

:L6A28   cmp   #$54
         beq   :L6A37
         cmp   #$43
         beq   :L6A37
         cmp   #$53
         beq   :L6A37
         jmp   L677C

:L6A37   stx   $f7
         jmp   :L6960

:L6A3C   jsr   :L68EA
         and   #$20
         bne   :L6A46
         jmp   L677C

:L6A46   stx   $f7
         jmp   :L6960

:L6A4B   ldx   $f7
         inx
         lda   Index15,x
         cmp   #$45
         beq   :L6A46
         cmp   #$49
         beq   :L6A46
         cmp   #$59
         beq   :L6A46
         jmp   L677C

:L6A60   jsr   :L68EA
         and   #$20
         bne   :L6A6A
         jmp   :L6960

:L6A6A   stx   $f7
         jmp   :L6A60

:L6A6F   ldy   $fd
         lda   $f9
         sta   $fa
:Loop    lda   ($fb),y
         sta   $f6
         and   #$7f
         cmp   #$3d
         beq   :L6A86
         inc   $f5
         ldx   $f5
         sta   InputBuf,x
:L6A86   bit   $f6
         bpl   :L6A8D
         jmp   L66EC

:L6A8D   iny
         jmp   :Loop

Index17  hex   8217790daa3071e93291a2b9fc5cc00e6e94b59e19a8c5a0b94d
Rules    hex   6c6e6e6f6f7171717273737373747477777777787a7a7a7b7b7ca9bc8de7028d ;Text Mode Lookup Table?
         hex   6408a95c8de8028d6908a900850860
         dci   '(A)='     ;Text to Phenome conversion
         dci   '(!)=.'
         dci   '(") =-AH5NKWOWT-'
         dci   '(")=KWOW4T-'
         dci   '(#)= NAH4MBER'
         dci   '($)= DAA4LER'
         dci   '(%)= PERSEH4NT'
         dci   '(&)= AEND'
         dci   '(',27,')='
         dci   '(*)= AE4STERIHSK'
         dci   '(+)= PLAH4S'
         dci   '(,)=,'
         dci   ' (-) =-'
         dci   '(-)='
         dci   '(.)= POYNT'
         dci   '(/)= SLAE4SH'
         dci   '(0)= ZIY4ROW'
         dci   ' (1ST)=FER4ST'
         dci   ' (10TH)=TEH4NTH'
         dci   '(1)= WAH4N'
         dci   ' (2ND)=SEH4KUND'
         dci   '(2)= TUW4'
         dci   ' (3RD)=THER4D'
         dci   '(3)= THRIY4'
         dci   '(4)= FOH4R'
         dci   ' (5TH)=FIH4FTH'
         dci   '(5)= FAY4V'
         dci   '(6)= SIH4KS'
         dci   '(7)= SEH4VUN'
         dci   ' (8TH)=EY4TH'
         dci   '(8)= EY4T'
         dci   '(9)= NAY4N'
         dci   '(:)=.'
         dci   '(;)=.'
         dci   '(<)= LEH4S DHAEN'
         dci   '(=)= IY4KWULZ'
         dci   '(>)= GREY4TER DHAEN'
         dci   '(?)=.'
         dci   '(@)= AE6T'
         dci   '(^)= KAE4RIXT'
         dci   ']A'
         dci   ' (A.)=EH4Y. '
         dci   '(A) =AH'
         dci   ' (ARE) =AAR'
         dci   ' (AR)O=AXR'
         dci   '(AR)#=EH4R'
         dci   ' ^(AS)#=EY4S'
         dci   '(A)WA=AX'
         dci   '(AW)=AO5'
         dci   ' :(ANY)=EH4NIY'
         dci   '(A)^+#=EY5'
         dci   '#:(ALLY)=ULIY'
         dci   ' (AL)#=UL'
         dci   '(AGAIN)=AXGEH4N'
         dci   '#:(AG)E=IHJ'
         dci   '(A)^%=EY'
         dci   '(A)^+:#=AE'
         dci   ' :(A)^+ =EY4'
         dci   ' (ARR)=AXR'
         dci   '(ARR)=AE4R'
         dci   ' ^(AR) =AA5R'
         dci   '(AR)=AA5R'
         dci   '(AIR)=EH4R'
         dci   '(AI)=EY4'
         dci   '(AY)=EY5'
         dci   '(AU)=AO4'
         dci   '#:(AL) =UL'
         dci   '#:(ALS) =ULZ'
         dci   '(ALK)=AO4K'
         dci   '(AL)^=AOL'
         dci   ' :(ABLE)=EY4BUL'
         dci   '(ABLE)=AXBUL'
         dci   '(A)VO=EY4'
         dci   '(ANG)+=EY4NJ'
         dci   '(ATARI)=AHTAA4RIY'
         dci   '(A)TOM=AE'
         dci   '(A)TTI=AE'
         dci   ' (AT) =AET'
         dci   ' (A)T=AH'
         dci   '(A)=AE'
         dci   ']B'
         dci   ' (B) =BIY4'
         dci   ' (BE)^#=BIH'
         dci   '(BEING)=BIY4IHNX'
         dci   ' (BOTH) =BOW4TH'
         dci   ' (BUS)#=BIH4Z'
         dci   '(BREAK)=BREY5K'
         dci   '(BUIL)=BIH4L'
         dci   '(B)=B'
         dci   ']C'
         dci   ' (C) =SIY4'
         dci   ' (CH)^=K'
         dci   '^E(CH)=K'
         dci   '(CHA)R#=KEH5'
         dci   '(CH)=CH'
         dci   ' S(CI)#=SAY4'
         dci   '(CI)A=SH'
         dci   '(CI)O=SH'
         dci   '(CI)EN=SH'
         dci   '(CITY)=SIHTIY'
         dci   '(C)+=S'
         dci   '(CK)=K'
         dci   '(COM)=KAHM'
         dci   '(CUIT)=KIHT'
         dci   '(CREA)=KRIYEY'
         dci   '(C)=K'
         dci   ']D'
         dci   ' (D) =DIY4'
         dci   ' (DR.) =DAA4KTER'
         dci   '#:(DED) =DIHD'
         dci   '.E(D) =D'
         dci   '#:^E(D) =T'
         dci   ' (DE)^#=DIH'
         dci   ' (DO) =DUW'
         dci   ' (DOES)=DAHZ'
         dci   '(DONE) =DAH5N'
         dci   '(DOING)=DUW4IHNX'
         dci   ' (DOW)=DAW'
         dci   '#(DU)A=JUW'
         dci   '#(DU)^#=JAX'
         dci   '(D)=D'
         dci   ']E'
         dci   ' (E) =IYIY4'
         dci   '#:(E) ='
         dci   27,':^(E) ='
         dci   ' :(E) =IY'
         dci   '#(ED) =D'
         dci   '#:(E)D ='
         dci   '(EV)ER=EH4V'
         dci   '(E)^%=IY4'
         dci   '(ERI)#=IY4RIY'
         dci   '(ERI)=EH4RIH'
         dci   '#:(ER)#=ER'
         dci   '(ERROR)=EH4ROHR'
         dci   '(ERASE)=IHREY5S'
         dci   '(ER)#=EHR'
         dci   '(ER)=ER'
         dci   ' (EVEN)=IYVEHN'
         dci   '#:(E)W='
         dci   '@(EW)=UW'
         dci   '(EW)=YUW'
         dci   '(E)O=IY'
         dci   '#:&(ES) =IHZ'
         dci   '#:(E)S ='
         dci   '#:(ELY) =LIY'
         dci   '#:(EMENT)=MEHNT'
         dci   '(EFUL)=FUHL'
         dci   '(EE)=IY4'
         dci   '(EARN)=ER5N'
         dci   ' (EAR)^=ER5'
         dci   '(EAD)=EHD'
         dci   '#:(EA) =IYAX'
         dci   '(EA)SU=EH5'
         dci   '(EA)=IY5'
         dci   '(EIGH)=EY4'
         dci   '(EI)=IY4'
         dci   ' (EYE)=AY4'
         dci   '(EY)=IY'
         dci   '(EU)=YUW5'
         dci   '(EQUAL)=IY4KWUL'
         dci   '(E)=EH'
         dci   ']F'
         dci   ' (F) =EH4F'
         dci   '(FUL)=FUHL'
         dci   '(FRIEND)=FREH5ND'
         dci   '(FATHER)=FAA4DHER'
         dci   '(F)F='
         dci   '(F)=F'
         dci   ']G'
         dci   ' (G) =JIY4'
         dci   '(GIV)=GIH5V'
         dci   ' (G)I^=G'
         dci   '(GE)T=GEH5'
         dci   'SU(GGES)=GJEH4S'
         dci   '(GG)=G'
         dci   ' B#(G)=G'
         dci   '(G)+=J'
         dci   '(GREAT)=GREY4T'
         dci   '(GON)E=GAO5N'
         dci   '#(GH)='
         dci   ' (GN)=N'
         dci   '(G)=G'
         dci   ']H'
         dci   ' (H) =EY4CH'
         dci   ' (HAV)=/HAE6V'
         dci   ' (HERE)=/HIYR'
         dci   ' (HOUR)=AW5ER'
         dci   '(HOW)=/HAW'
         dci   '(H)#=/H'
         dci   '(H)='
         dci   ']I'
         dci   ' (IN)=IHN'
         dci   ' (I) =AY4'
         dci   '(I) =AY'
         dci   '(IN)D=AY5N'
         dci   'SEM(I)=IY'
         dci   ' ANT(I)=AY'
         dci   '(IER)=IYER'
         dci   '#:R(IED) =IYD'
         dci   '(IED) =AY5D'
         dci   '(IEN)=IYEHN'
         dci   '(IE)T=AY4EH'
         dci   '(I',27,')=AY5'
         dci   ' :(I)^%=AY5'
         dci   ' :(IE) =AY4'
         dci   '(I)%=IY'
         dci   '(IE)=IY4'
         dci   ' (IDEA)=AYDIY5AH'
         dci   '(I)^+:#=IH'
         dci   '(IR)#=AYR'
         dci   '(IZ)%=AYZ'
         dci   '(IS)%=AYZ'
         dci   'I^(I)^#=IH'
         dci   '+^(I)^+=AY'
         dci   '#:^(I)^+=IH'
         dci   '(I)^+=AY'
         dci   '(IR)=ER'
         dci   '(IGH)=AY4'
         dci   '(ILD)=AY5LD'
         dci   ' (IGN)=IHGN'
         dci   '(IGN) =AY4N'
         dci   '(IGN)^=AY4N'
         dci   '(IGN)%=AY4N'
         dci   '(ICRO)=AY4KROH'
         dci   '(IQUE)=IY4K'
         dci   '(I)=IH'
         dci   ']J'
         dci   ' (J) =JEY4'
         dci   '(J)=J'
         dci   ']K'
         dci   ' (K) =KEY4'
         dci   ' (K)N='
         dci   '(K)=K'
         dci   ']L'
         dci   ' (L) =EH4L'
         dci   '(LO)C#=LOW'
         dci   'L(L)='
         dci   '#:^(L)%=UL'
         dci   '(LEAD)=LIYD'
         dci   ' (LAUGH)=LAE4F'
         dci   '(L)=L'
         dci   ']M'
         dci   ' (M) =EH4M'
         dci   ' (MR.) =MIH4STER'
         dci   ' (MS.)=MIH5Z'
         dci   ' (MRS.) =MIH4SIXZ'
         dci   '(MOV)=MUW4V'
         dci   '(MACHIN)=MAHSHIY5N'
         dci   'M(M)='
         dci   '(M)=M'
         dci   ']N'
         dci   ' (N) =EH4N'
         dci   'E(NG)+=NJ'
         dci   '(NG)R=NXG'
         dci   '(NG)#=NXG'
         dci   '(NGL)%=NXGUL'
         dci   '(NG)=NX'
         dci   '(NK)=NXK'
         dci   ' (NOW) =NAW4'
         dci   'N(N)='
         dci   '(NON)E=NAH4N'
         dci   '(N)=N'
         dci   ']O'
         dci   ' (O) =OH4W'
         dci   '(OF) =AHV'
         dci   ' (OH) =OW5'
         dci   '(OROUGH)=ER4OW'
         dci   '#:(OR) =ER'
         dci   '#:(ORS) =ERZ'
         dci   '(OR)=AOR'
         dci   ' (ONE)=WAHN'
         dci   '#(ONE) =WAHN'
         dci   '(OW)=OW'
         dci   ' (OVER)=OW5VER'
         dci   'PR(O)V=UW4'
         dci   '(OV)=AH4V'
         dci   '(O)^%=OW5'
         dci   '(O)^EN=OW'
         dci   '(O)^I#=OW5'
         dci   '(OL)D=OW4L'
         dci   '(OUGHT)=AO5T'
         dci   '(OUGH)=AH5F'
         dci   ' (OU)=AW'
         dci   'H(OU)S#=AW4'
         dci   '(OUS)=AXS'
         dci   '(OUR)=OHR'
         dci   '(OULD)=UH5D'
         dci   '(OU)^L=AH5'
         dci   '(OUP)=UW5P'
         dci   '(OU)=AW'
         dci   '(OY)=OY'
         dci   '(OING)=OW4IHNX'
         dci   '(OI)=OY5'
         dci   '(OOR)=OH5R'
         dci   '(OOK)=UH5K'
         dci   'F(OOD)=UW5D'
         dci   'L(OOD)=AH5D'
         dci   'M(OOD)=UW5D'
         dci   '(OOD)=UH5D'
         dci   'F(OOT)=UH5T'
         dci   '(OO)=UW5'
         dci   '(O',27,')=OH'
         dci   '(O)E=OW'
         dci   '(O) =OW'
         dci   '(OA)=OW4'
         dci   ' (ONLY)=OW4NLIY'
         dci   ' (ONCE)=WAH4NS'
         dci   '(ON',27,'T)=OW4NT'
         dci   'C(O)N=AA'
         dci   '(O)NG=AO'
         dci   ' :^(O)N=AH'
         dci   'I(ON)=UN'
         dci   '#:(ON) =UN'
         dci   '#^(ON)=UN'
         dci   '(O)ST =OW'
         dci   '(OF)^=AO4F'
         dci   '(OTHER)=AH5DHER'
         dci   'R(O)B=RAA'
         dci   '^R(O):#=OW5'
         dci   '(OSS) =AO5S'
         dci   '#:^(OM)=AHM'
         dci   '(O)=AA'
         dci   ']P'
         dci   ' (P) =PIY4'
         dci   '(PH)=F'
         dci   '(PEOPL)=PIY5PUL'
         dci   '(POW)=PAW4'
         dci   '(PUT) =PUHT'
         dci   '(P)P='
         dci   ' (P)S='
         dci   ' (P)N='
         dci   ' (PROF.)=PROHFEH4SER'
         dci   '(P)=P'
         dci   ']Q'
         dci   ' (Q) =KYUW4'
         dci   '(QUAR)=KWOH5R'
         dci   '(QU)=KW'
         dci   '(Q)=K'
         dci   ']R'
         dci   ' (R) =AA5R'
         dci   ' (RE)^#=RIY'
         dci   '(R)R='
         dci   '(R)=R'
         dci   ']S'
         dci   ' (S) =EH4S'
         dci   '(SH)=SH'
         dci   '#(SION)=ZHUN'
         dci   '(SOME)=SAHM'
         dci   '#(SUR)#=ZHER'
         dci   '(SUR)#=SHER'
         dci   '#(SU)#=ZHUW'
         dci   '#(SSU)#=SHUW'
         dci   '#(SED) =ZD'
         dci   '#(S)#=Z'
         dci   '(SAID)=SEHD'
         dci   '^(SION)=SHUN'
         dci   '(S)S='
         dci   '.(S) =Z'
         dci   '#:.E(S) =Z'
         dci   '#:^#(S) =S'
         dci   'U(S) =S'
         dci   ' :#(S) =Z'
         dci   '##(S) =Z'
         dci   ' (SCH)=SK'
         dci   '(S)C+='
         dci   '#(SM)=ZUM'
         dci   '#(SN)',27,'=ZUN'
         dci   '(STLE)=SUL'
         dci   '(S)=S'
         dci   ']T'
         dci   ' (T) =TIY4'
         dci   ' (THE) #=DHIY'
         dci   ' (THE) =DHAX'
         dci   '(TO) =TUX'
         dci   ' (THAT)=DHAET'
         dci   ' (THIS) =DHIHS'
         dci   ' (THEY)=DHEY'
         dci   ' (THERE)=DHEHR'
         dci   '(THER)=DHER'
         dci   '(THEIR)=DHEHR'
         dci   ' (THAN) =DHAEN'
         dci   ' (THEM) =DHEHM'
         dci   '(THESE) =DHIYZ'
         dci   ' (THEN)=DHEHN'
         dci   '(THROUGH)=THRUW4'
         dci   '(THOSE)=DHOHZ'
         dci   '(THOUGH) =DHOW'
         dci   '(TODAY)=TUXDEY'
         dci   '(TOMO)RROW=TUMAA5'
         dci   '(TO)TAL=TOW5'
         dci   ' (THUS)=DHAH4S'
         dci   '(TH)=TH'
         dci   '#:(TED) =TIXD'
         dci   'S(TI)#N=CH'
         dci   '(TI)O=SH'
         dci   '(TI)A=SH'
         dci   '(TIEN)=SHUN'
         dci   '(TUR)#=CHER'
         dci   '(TU)A=CHUW'
         dci   ' (TWO)=TUW'
         dci   '&(T)EN ='
         dci   '(T)=T'
         dci   ']U'
         dci   ' (U) =YUW4'
         dci   ' (UN)I=YUWN'
         dci   ' (UN)=AHN'
         dci   ' (UPON)=AXPAON'
         dci   '@(UR)#=UH4R'
         dci   '(UR)#=YUH4R'
         dci   '(UR)=ER'
         dci   '(U)^ =AH'
         dci   '(U)^^=AH5'
         dci   '(UY)=AY5'
         dci   ' G(U)#='
         dci   'G(U)%='
         dci   'G(U)#=W'
         dci   '#N(U)=YUW'
         dci   '@(U)=UW'
         dci   '(U)=YUW'
         dci   ']V'
         dci   ' (V) =VIY4'
         dci   '(VIEW)=VYUW5'
         dci   '(V)=V'
         dci   ']W'
         dci   ' (W) =DAH4BULYUW'
         dci   ' (WERE)=WER'
         dci   '(WA)SH=WAA'
         dci   '(WA)ST=WEY'
         dci   '(WA)S=WAH'
         dci   '(WA)T=WAA'
         dci   '(WHERE)=WHEHR'
         dci   '(WHAT)=WHAHT'
         dci   '(WHOL)=/HOWL'
         dci   '(WHO)=/HUW'
         dci   '(WH)=WH'
         dci   '(WAR)#=WEHR'
         dci   '(WAR)=WAOR'
         dci   '(WOR)^=WER'
         dci   '(WR)=R'
         dci   '(WOM)A=WUHM'
         dci   '(WOM)E=WIHM'
         dci   '(WEA)R=WEH'
         dci   '(WANT)=WAA5NT'
         dci   'ANS(WER)=ER'
         dci   '(W)=W'
         dci   ']X'
         dci   ' (X) =EH4KS'
         dci   ' (X)=Z'
         dci   '(X)=KS'
         dci   ']Y'
         dci   ' (Y) =WAY4'
         dci   '(YOUNG)=YAHNX'
         dci   ' (YOUR)=YOHR'
         dci   ' (YOU)=YUW'
         dci   ' (YES)=YEHS'
         dci   ' (Y)=Y'
         dci   'F(Y)=AY'
         dci   'PS(YCH)=AYK'
         dci   '#:^(Y) =IY'
         dci   '#:^(Y)I=IY'
         dci   ' :(Y) =AY'
         dci   ' :(Y)#=AY'
         dci   ' :(Y)^+:#=IH'
         dci   ' :(Y)^#=AY'
         dci   '(Y)=IH'
         dci   ']Z'
         dci   ' (Z) =ZIY4'
         dci   '(Z)=Z'
         dci   ' (YOU)=YUW'
         dci   ' (YES)=YEHS'
         dci   ' (Y)=Y'
         dci   'F(Y)=AY'
         asc   'ive/user no. (specify drive/user)',0d0a,'      and reset disks'
         asc   '.  e.g. LOG A0, LOG B (user # unchanged)',0d0a,'SPD - Set sp*1'
         asc   '23456789 .?,-IIEAAAAUAIEUORLWYWRLWYMNNDQSSFT//ZZVDC*J***EAOAOU'
         asc   'B**D**G**G**P**T**K**K**UUU*****YHHEAHOHXXRXHXXXXH******XX**H*'
         asc   'HHX*H*HH'
         hex   84842a2a2a5959595757572a2a2a2a2a2a2a2a2a582a2a2a2a2a2a2a2a2a2a2a
         hex   582a2a4c4d4e0000000000a4a4a4a4a4a48484a4a48484848484848444444444
         hex   444c4c4c484c4040404040404444444448404c440000b4b4b49494944e4e4e4e
         hex   4e4e4e4e4e4e4e4e4b4b4b4b4b4b4b4b4b4b4b4b80c1c1c1c100000000000000
         hex   000000000000000000000010101010080c080440242020240000242020242020
         hex   0020000000000000000000000004040400000000000000000004040400000000
         hex   000085fc86fb84fa60a5fca6fba4fa60203646a2ffa000ca88bdee4199ee41bd
         hex   ee4299ee42bdee4399ee43e4f6d0e8a5f99dee41a5f89dee42a5f79dee43203d
         hex   468585008aa885ff99ee43c8c0ffd0f8bd1040c90df06e85fee8bd104085fda0
         hex   00b9f844c5fed00bb94945c92af004c5fdf007c8c051d0e9f00c98a4ff99ee41
         hex   e6ffe84c8446a000b94945c92ad007b9f844c5fef007c8c051d0edf00b98a4ff
         hex   99ee41e6ff4c8446a5fea008d9ee44f00a88d0f88e0b40202f656098a4ff8899
         hex   ee434c8446a9ffa4ff99ee4160a000b9ee41c9fff01baab9ee43f00b3009bde0
         hex   5799ee424c2147bd305899ee42c84c034760a90085ffa6ffbdee41c9ffd00160
         hex   85f9a8b99a45a82902d005e6ff4c2a47982901d02ce6f9a4f9bdee4385f7b930
         hex   5885f8e886f6204446e6f9a4f9b9305885f8e886f6204446e6ffe6ffe6ff4c2a
         hex   47e8868641f0fa85f5c9ffd0034c9647a8b99a452908d032a5f5c924f02cc925
         hex   f028a6ffbdee4385f7e886f6a6f9e886f9bd305885f8204446e6f6e886f9bd30
         hex   5885f8204446e6ffe6ffe6ff4c2a47a90085ffa6ffbdee41d005e6ff4cc747c9
         hex   ffd00160a8b99a452910f01fbdee4385f7e886f6b99a452920f00ca91585f920
         hex   4446a6ff4c2349a914d0f2bd

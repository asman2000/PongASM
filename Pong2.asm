����          
f                            ;--------------------------------------------------------------
;######   #####  #### ##  #####
;### ### ### ### #### ## ### ###
;### ### ### ### #### ## ###
;######  ### ### ####### ### ###   by Pawel Tukatsch
;###     ### ### ## #### ### ###   in Asm68k
;###     ### ### ## #### ### ###
;###      #####  ## ####  #####



;--------------------------------------------------------------
Start:		movem.l d0-d7/a0-a6,-(a7)
		bsr OsStore
		;bsr SystemBackup
		move.l #FakeCopper,$dff080
		bsr Init_Colors
		bsr Init_Screens
		move.l #Copper,$dff080

;--------------------------------------------------------------
Mainloop:	bsr VBlank
		move.b #$0,Players
		bsr Keyboard
		bsr Joystick
		bsr Controls
		cmp.w #$ffff,Players
		bne Mainloop
		
		;bsr SystemRestore
		bsr OsRestore
		movem.l (a7)+,d0-d7/a0-a6
		moveq #0,d0
		rts	; WYJSCIE Z PROGRAMU
;--------------------------------------------------------------
OsStore:
	;open graphics library
		move.l 4.w,a6
		lea gfxName(pc),a1
		jsr -408(a6)	;exec OldOpenLibrary(a1 - lib name)
		move.l d0,gfxBase
		beq Quit

	;save old view
		move.l d0,a6	;a6 - gfx base
		move.l $22(a6),osOldView

	;reset
		sub.l a1,a1
		jsr -222(a6)	;gfx LoadView(a1 - view)
		jsr -270(a6)	;gfx WaitTOF()
		jsr -270(a6)	;gfx WaitTOF()

	;get dma
		move.w $dff002,d0	;DMACONR
		or.w #$8000,d0
		move.w d0,osOldDma

Quit:		rts
;--------------------------------------------------------------
OsRestore:
	;restore dma
		move.w osOldDma,$dff096	;DMACON

	;load old view
		move.l gfxBase,a6
		move.l osOldView,a1
		jsr -222(a6)	;gfxLoadView(a1)
		jsr -270(a6)	;gfx WaitTOF()
		jsr -270(a6)	;gfx WaitTOF()

	;powrot do sytemowej copperlisty
		move.l $26(a6),$dff080

	;close graphics library
		move.l 4.w,a6
		move.l gfxBase,a1
		jsr -414(a6)

		moveq #0,d0
		rts
;--------------------------------------------------------------
SystemBackup:
		move.l 4.w,a6
		jsr -132(a6)
		move.w $dff01c,d0
		or.w #$8000,d0
		move.w d0,SystemIntena

		move.l 156(a6),a1
		move.l 38(a1),SystemCopper
		rts
;--------------------------------------------------------------
SystemRestore:
		move.l SystemCopper,$dff080

		move.w SystemIntena,$dff09a
		move.l 4.w,a6
		jsr -138(a6)
		rts
;--------------------------------------------------------------
Keyboard:	move.b $bfec01,d0
		ror.b #1,d0
		eor.b #$ff,d0
		
		cmp.b #$4c,d0
		beq P2u
		cmp.b #$4d,d0
		beq P2d
		cmp.b #$45,d0
		beq koniec
		rts
P2u:		bset #2,Players
		rts
P2d:		bset #3,Players
		rts
koniec:		move.w #$ffff,Players
		rts		
;--------------------------------------------------------------
Joystick:	move.w $dff00c,d0
		move.w d0,d1
		lsr.w #1,d0
		eor.w d0,d1

		btst #0,d1
		bne Joyup
		btst #8,d1
		bne Joydown
		rts

Joyup:		bset #0,Players
		rts
Joydown:	bset #1,Players
		rts
;--------------------------------------------------------------
Controls:	btst #0,Players
		bne Red
		btst #1,Players
		bne Green
		btst #2,Players
		bne Yellow
		btst #3,Players
		bne Purple
		rts
Red:		move.w #$f00,$dff180
		rts
Green:		move.w #$f0,$dff180
		rts
Yellow:		move.w #$ff0,$dff180
		rts
Purple:		move.w #$f0f,$dff180
		rts



;--------------------------------------------------------------
VBlank:		lea $dff004,a0
rast1:		lsr (a0)
		bcc rast1
rast2:		lsr (a0)
		bcs rast2
		rts
;--------------------------------------------------------------
Init_Colors:	lea Colors,a0
		lea Cop1palette,a1
		moveq #1,d7
Col_Nt:		move.w (a0)+,2(a1)
		adda.l #4,a1
		dbf d7,Col_Nt
		rts
;--------------------------------------------------------------
Init_Screens:	lea Planes,a0
		move.l #Bitmap,d0
		move.w d0,6(a0)
		swap d0
		move.w d0,2(a0)
		rts






;--------------------------------------------------------------
Players:	dc.w $0
Player1:	dc.l $0
Player2:	dc.l $0
Ball:		dc.l $0
;--------------------------------------------------------------
SystemCopper:	dc.l 0
SystemIntena:	dc.w 0
gfxName:	dc.b "graphics.library",0

	EVEN
gfxBase:	dc.l 0
osOldView:	dc.l 0
osOldDma:	dc.w 0



	Section CHIPRAM,DATA_C
	even	

FakeCopper:	dc.l $fffffffe



Copper:		dc.l $008e2c81,$00902cc1; DIWSTRT,DIWSTOP
		dc.l $00920038,$009400d0; DDFSTRT,DDFSTOP
		dc.l $0096000f		; kanaly DMA
		dc.l $01020000,$01040000; kasowanie BPLCON1 i BPLCON2
		dc.l $01080000,$010a0000; modulo 0
		
Cop1palette:	dc.l $01800000,$01820000; rejestry kolorow coppera
		dc.l $01840000,$01860000
		dc.l $01880000,$018a0000
		dc.l $018c0000,$018e0000
		dc.l $01900000,$01920000
		dc.l $01940000,$01960000
		dc.l $01980000,$019a0000
		dc.l $019c0000,$019e0000
		dc.l $01a00000,$01a20000
		dc.l $01a40000,$01a60000
		dc.l $01a80000,$01aa0000
		dc.l $01ac0000,$01ae0000
		dc.l $01b00000,$01b20000
		dc.l $01b40000,$01b60000
		dc.l $01b80000,$01ba0000
		dc.l $01bc0000,$01be0000
		
Planes:		dc.l $00e00000,$00e20000; adresy bitplanow
		dc.l $01001200		; BPLCON0 1 bitplan + A1000 zgodnosc
		dc.l $01060c00		; BPLCON3
		dc.l $01fc0000		; FMODE 0
		dc.l $fffffffe		; koniec copperlisty
		
Colors:		dc.w $0000,$0cde	; paleta kolorow

Bitmap:		incbin "DHC:PONG.RAW"

Shape:		dc.w %0111111111111000
		dc.w %1111111111111100
		dc.w %1111111111111100
		dc.w %1111111111111100
		dc.w %1111100001111100
		dc.w %1111000000111100
		dc.w %1111000000111100
		dc.w %1111000000111100
		dc.w %1111000000111100
		dc.w %1111000000111100
		dc.w %1111000000111100
		dc.w %1111000000111100
		dc.w %1111000000111100
		dc.w %1111000000111100
		dc.w %1111000000111100
		dc.w %1111000000111100
		dc.w %1111000000111100
		dc.w %1111000000111100
		dc.w %1111000000111100
		dc.w %1111000000111100
		dc.w %1111000000111100
		dc.w %1111000000111100
		dc.w %1111000000111100
		dc.w %1111000000111100
		dc.w %1111000000111100
		dc.w %1111000000111100
		dc.w %1111000000111100
		dc.w %1111100001111100
		dc.w %1111111111111100
		dc.w %1111111111111100
		dc.w %1111111111111100
		dc.w %0111111111111000

		dc.w %0000001100000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000011110000000
		dc.w %0000001100000000

		dc.w %0111111111111000
		dc.w %1111111111111100
		dc.w %1111111111111100
		dc.w %0111111111111100
		dc.w %0000000001111100
		dc.w %0000000000111100		
		dc.w %0000000000111100
		dc.w %0000000000111100
		dc.w %0000000000111100
		dc.w %0000000000111100
		dc.w %0000000000111100
		dc.w %0000000000111100
		dc.w %0000000000111100
		dc.w %0000000001111100
		dc.w %0111111111111100
		dc.w %1111111111111100
		dc.w %1111111111111100
		dc.w %1111111111111000
		dc.w %1111100000000000
		dc.w %1111000000000000
		dc.w %1111000000000000
		dc.w %1111000000000000
		dc.w %1111000000000000
		dc.w %1111000000000000
		dc.w %1111000000000000
		dc.w %1111000000000000
		dc.w %1111000000000000
		dc.w %1111100000000000
		dc.w %1111111111111000
		dc.w %1111111111111100
		dc.w %1111111111111100
		dc.w %0111111111111000

		dc.w %0111111111111000
		dc.w %1111111111111100
		dc.w %1111111111111100
		dc.w %0111111111111100
		dc.w %0000000001111100
		dc.w %0000000000111100
		dc.w %0000000000111100
		dc.w %0000000000111100
		dc.w %0000000000111100
		dc.w %0000000000111100
		dc.w %0000000000111100
		dc.w %0000000000111100
		dc.w %0000000000111100
		dc.w %0000000001111100
		dc.w %0111111111111100
		dc.w %1111111111111100
		dc.w %1111111111111100
		dc.w %0111111111111100
		dc.w %0000000001111100
		dc.w %0000000000111100
		dc.w %0000000000111100
		dc.w %0000000000111100
		dc.w %0000000000111100
		dc.w %0000000000111100
		dc.w %0000000000111100
		dc.w %0000000000111100
		dc.w %0000000000111100
		dc.w %0000000001111100
		dc.w %0111111111111100
		dc.w %1111111111111100
		dc.w %1111111111111100
		dc.w %0111111111111000

		dc.w %0110000000000000
		dc.w %1111000000000000
		dc.w %1111000000000000
		dc.w %1111000000000000
		dc.w %1111000000000000
		dc.w %1111000000000000
		dc.w %1111000000000000
		dc.w %1111000000000000
		dc.w %1111000000000000
		dc.w %1111000000000000
		dc.w %1111000000000000
		dc.w %1111000000000000
		dc.w %1111000000000000
		dc.w %1111100000000000
		dc.w %1111111111000000
		dc.w %1111111111100000
		dc.w %1111111111100000
		dc.w %0111111111100000
		dc.w %0000001111100000
		dc.w %0000000111100000
		dc.w %0000000111100000
		dc.w %0000000111100000
		dc.w %0000000111100000
		dc.w %0000000111100000
		dc.w %0000000111100000
		dc.w %0000000111100000
		dc.w %0000000111100000
		dc.w %0000000111100000
		dc.w %0000000111100000
		dc.w %0000000111100000
		dc.w %0000000111100000
		dc.w %0000000011000000

		dc.w %0111111111111000
		dc.w %1111111111111100
		dc.w %1111111111111100
		dc.w %1111111111111000
		dc.w %1111100000000000
		

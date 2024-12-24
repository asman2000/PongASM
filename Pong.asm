;--------------------------------------------------------------
;######   #####  #### ##  #####
;### ### ### ### #### ## ### ###
;### ### ### ### #### ## ###
;######  ### ### ####### ### ###   by Pawel Tukatsch
;###     ### ### ## #### ### ###   in Asm68k
;###     ### ### ## #### ### ###
;###      #####  ## ####  #####

;--------------------------------------------------------------
Start:
		bsr	OsStore

		bsr	Init_Colors
		bsr	SpritesSetFake
		bsr	Init_Screens
		bsr	Punktacja
		move.l	#Copper,$dff080
		move.w	d0,$dff088

		bsr	CopperSetSprite0
		bsr	WaitFire
Mainloop:
		bsr	VBlank
		move.b	#$0,Players

		bsr	FizykaPilki

		moveq	#0,d0		;pozycja x
		move.l	d0,d1
		move.w	Player1+2,d1	;pozycja y
		moveq	#32,d2		;wysokosc sprajta
		lea	Paletka,a0
		bsr	SpriteSet

		move.l	#300,d0
		move.w	Player2+2,d1
		moveq	#32,d2
		lea	Paletka2,a0
		bsr	SpriteSet

		move.w	Ball,d0
		move.w	Ball+2,d1
		moveq	#16,d2
		lea	Pilka,a0
		bsr 	SpriteSet

		bsr	Keyboard
		bsr	Joystick
		bsr	Controls
		cmp.w	#$ffff,Players
		bne	Mainloop
		
		bsr	OsRestore
		moveq	#0,d0
		rts

;--------------------------------------------------------------

Keyboard:	moveq	#0,d0
		move.b	$bfec01,d0
		ror.b	#1,d0
		eor.b	#$ff,d0
		
		cmp.b	#$4c,d0
		beq	P2u
		cmp.b	#$4d,d0
		beq	P2d
		cmp.b	#$45,d0
		beq	koniec
		rts
P2u:		bset	#2,Players
		rts
P2d:		bset	#3,Players
		rts
koniec:		move.w	#$ffff,Players
		rts

;--------------------------------------------------------------

Joystick:	move.w	$dff00c,d0
		move.w	d0,d1
		lsr.w	#1,d0
		eor.w	d0,d1

		btst	#0,d1
		bne	Joyup
		btst	#8,d1
		bne	Joydown
		rts

Joyup:		bset	#0,Players
		rts
Joydown:	bset	#1,Players
		rts

;--------------------------------------------------------------

Controls:	btst	#0,Players
		beq	.Green
		cmp.w	#183,Player2+2
		bge	.Green
		addq.w	#3,Player2+2

.Green:
		btst	#1,Players
		beq	.Yellow
		cmp.w	#33,Player2+2
		ble	.Yellow
		subq.w	#3,Player2+2

.Yellow:		
		btst	#2,Players
		beq	.Purple
		cmp.w	#33,Player1+2
		ble	.Purple
		subq.w	#3,Player1+2

.Purple:
		btst	#3,Players
		beq	.No
		cmp.w	#183,Player1+2
		bge	.No
		addq.w	#3,Player1+2
.No
		rts

;--------------------------------------------------------------

FizykaPilki:
		move.w	BallSpeed,d0
		move.w	BallSpeed+2,d1
		add.w	d0,Ball
		add.w	d1,Ball+2

.LewaGranica:
		cmp.w	#-16,Ball
		bge	.PrawaGranica
		add.w	#1,Player2
		move.w	#140,Ball
		move.w	#100,Ball+2
		bsr	Punktacja
		bsr	WaitFire
.PrawaGranica	cmp.w	#320,Ball
		ble	.GornaGranica
		add.w	#1,Player1
		move.w	#140,Ball
		move.w	#100,Ball+2
		bsr	Punktacja
		bsr	WaitFire
.GornaGranica
		cmp.w	#33,Ball+2
		bge	.DolnaGranica
		neg.w	BallSpeed+2
.DolnaGranica	
		cmp.w	#198,Ball+2
		ble	.Kolizje
		neg.w	BallSpeed+2

.Kolizje
		move.w	Ball+2,d0	;D0 drugi word to Y pileczki
		swap	d0
		move.w	Ball,d0		;D0 pierwszy word to X pileczki
		move.l	d0,d1		;D1 jako baza do dalszych obliczen
		move.w	Player2+2,d2	;D2 drugi word to Y prawej paletki
		swap	d2
		move.w	Player1+2,d2	;D2 pierwszy word to Y lewej paletki
		move.l	d2,d3		;D3 jako baza do dalszych obliczen

.LewaGorna
		cmp.w	#15,d0		;pozycja pozioma
		bgt	.LewaDolna
		swap	d0
		
		add.w	#15,d0
		cmp.w	d0,d2
		bgt	.LewaDolna

		sub.w	#8,d0
		add.w	#15,d2
		cmp.w	d0,d2
		blt	.LewaDolna
		move.w	#2,BallSpeed
		subq.w	#2,BallSpeed+2

.LewaDolna
		move.l	d1,d0
		move.l	d3,d2
		cmp.w	#15,d0
		bgt	.PrawaGorna
		swap	d0

		add.w	#31,d2
		cmp.w	d0,d2
		blt	.PrawaGorna
		sub.w	#15,d2
		add.w	#8,d0
		cmp.w	d0,d2
		bgt	.PrawaGorna
		move.w	#2,BallSpeed
		addq.w	#2,BallSpeed+2

.PrawaGorna

		rts
;--------------------------------------------------------------

WaitFire:	moveq	#0,d0
		move.b	$bfec01,d0
		ror.b	#1,d0
		eor.b	#$ff,d0

.Esc		cmp.b	#$45,d0
		bne	.Space
 		move.w	#$ffff,Players
 		rts
.Space		cmp.b	#$40,d0
		bne	.Fire
		bra	.UstawKierunek
.Fire		btst	#7,$bfe001
 		bne	WaitFire

.UstawKierunek
		cmp.w	#160,Ball
		bge	.RuchWPrawo
.RuchWLewo:	move.w	#-3,BallSpeed
		rts
.RuchWPrawo	move.w	#3,BallSpeed

		rts
		
;--------------------------------------------------------------
Punktacja:	
		cmp.w	#9,Player1
		bgt	.ResetujPunkty
		cmp.w	#9,Player2
		bgt	.ResetujPunkty
		
		move.w	Player1,d0
		moveq	#14,d1
		bsr	Punkty

		move.w	Player2,d0
		moveq	#24,d1
		bsr	Punkty
		rts

.ResetujPunkty
		move.w	#0,Player1
		move.w	#0,Player2
		move.w	#0,BallSpeed+2
		bra	Punktacja
		rts

;--------------------------------------------------------------

VBlank:		lea	$dff004,a0
rast1:		lsr	(a0)
		bcc	rast1
rast2:		lsr	(a0)
		bcs	rast2
		rts

;--------------------------------------------------------------

Init_Colors:	lea	Colors,a0
		lea	Cop1palette,a1
		moveq	#1,d7
Col_Nt:		move.w	(a0)+,2(a1)
		adda.l	#4,a1
		dbf	d7,Col_Nt
		move.w	#$abc,$dff1a2 ; kolor 17
		move.w	#$f00,$dff1aa ; kolor 21
		rts

;--------------------------------------------------------------

Init_Screens:	lea	Planes,a0
		move.l	#Bitmap,d0
		move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)
		rts

;--------------------------------------------------------------

Punkty:		; D0 - punkty | D1 - pozycja X blitu

		and.l #$ff,d0
		lsl.l #6,d0
		add.l #Shape,d0

		add.w #2000,d1
		add.l #Bitmap,d1
		
		btst #14-8,$dff002
BlitWait:	btst #14-8,$dff002
		bne BlitWait

		move.w #0,$dff064		; Modulo A(BLTAMOD) bajty
		move.w #39,$dff066		; Modulo D(BLTBMOD) bajty
		move.l #$09f00000,$dff040	; D=A
		move.l #$ffffffff,$dff044	; maska
		move.l d0,$dff050		; adres grafiki
		
		move.l d1,$dff054		; adres bitplanu

		move.w #64*32+1,$dff058 	; start blitu
		rts

;--------------------------------------------------------------

SpritesSetFake:
		moveq #8-1,d0
		lea Sprite00,a0
		move.l #SpriteFake,d1

.loop		swap d1
		move.w d1,(a0)
		swap d1
		move.w d1,4(a0)
		addq.l #8,a0
		dbf d0,.loop
		rts

;--------------------------------------------------------------

CopperSetSprite0:
		lea	Sprite00,a0
		move.l	#Paletka,d0

		move.w	d0,4(a0)
		swap	d0
		move.w	d0,(a0)

;Sprite1
		lea	Sprite01,a0
		move.l	#Paletka2,d0
		move.w	d0,4(a0)
		swap	d0
		move.w	d0,(a0)

;Sprite2
 		lea	Sprite02,a0
 		move.l	#Pilka,d0
 		move.w	d0,4(a0)
 		swap	d0
 		move.w	d0,(a0)

		rts

;--------------------------------------------------------------

SpriteSet:
	; adjust coordinates
		add.w	#$80,d0
		add.w	#$2c,d1

	; calculateo position bits for SPRPOS and SPRCTL
		add.w	d1,d2
		lsl.w	#7,d2
		lsl.w	#8,d1
		roxl.w	#1,d2
		roxl.b	#1,d2
		lsr.w	#1,d0
		roxl.b	#1,d2
		move.b	d0,d1

	; write SPRPOS and SPRCTL words
		move.w	d1,(a0)
		move.w	d2,2(a0)
		rts

;--------------------------------------------------------------

OsStore:
	;open graphics library
		move.l	4.w,a6
		lea	gfxName(pc),a1
		jsr	-408(a6)	;exec OldOpenLibrary(a1 - lib name)
		move.l	d0,gfxBase

	;save old view
		move.l	d0,a6	;a6 - gfx base
		move.l	$22(a6),osOldView

	;takeover blitter
		jsr	-456(a6)	;gfx OwnBlitter()
		jsr	-228(a6)	;gfx WaitBlit()

	;reset
		sub.l	a1,a1
		jsr	-222(a6)	;gfx LoadView(a1 - view)
		jsr	-270(a6)	;gfx WaitTOF()
		jsr	-270(a6)	;gfx WaitTOF()

	;get dma
		move.w	$dff002,d0	;DMACONR
		or.w	#$8000,d0
		move.w	d0,osOldDma
		rts

;--------------------------------------------------------------

OsRestore:
		move.l	#CopperSimple,$dff080
		move.w	d0,$dff088
		bsr	VBlank

	;restore dma
		move.w	osOldDma,$dff096	;DMACON

	;blitter back to os
		move.l	gfxBase,a6
		jsr	-228(a6)	;gfx WaitBlit()
		jsr	-462(a6)	;gfx DisownBlitter()

	;load old view
		move.l	osOldView,a1
		jsr	-222(a6)	;gfxLoadView(a1)
		jsr	-270(a6)	;gfx WaitTOF()
		jsr	-270(a6)	;gfx WaitTOF()

	;back to os copperlist
		move.l	$26(a6),$dff080

	;close graphics library
		move.l	4.w,a6
		move.l	gfxBase,a1
		jsr	-414(a6)
		rts

;--------------------------------------------------------------
Players:	dc.w $0,$0	; %0000 pl2d pl2u pl1d pl1u ($ffff - wyjscie)
Player1:	dc.w $0,100-15	; punkty , Y
Player2:	dc.w $0,$33	; punkty , Y
Ball:		dc.w 140,100	; X , Y
BallSpeed:	dc.w 0,0	; XS,YS
;--------------------------------------------------------------
gfxName:	dc.b "graphics.library",0
	EVEN

gfxBase:	dc.l 0
osOldView:	dc.l 0
osOldDma:	dc.w 0


;=============================================================================
	Section CHIPRAM,DATA_C

CopperSimple:	dc.w	$0180,0
		dc.w	$0100,0
		dc.w	$ffff,$fffe


Copper:		dc.l $008e2c81,$00902cc1; DIWSTRT,DIWSTOP
		dc.l $00920038,$009400d0; DDFSTRT,DDFSTOP
		dc.l $0096000f		; kanaly DMA
		dc.l $01020000,$01040000; kasowanie BPLCON1 i BPLCON2
		dc.l $01080000,$010a0000; modulo 0
		
Cop1palette:	dc.l $01800000,$01820000; rejestry kolorow coppera
		
Planes:		dc.l $00e00000,$00e20000; adresy bitplanow
		dc.l $01001200		; BPLCON0 1 bitplan + A1000 zgodnosc
		dc.l $01060c00		; BPLCON3
		dc.l $01fc0000		; FMODE 0

		dc.l $1007fffe		; czekamy na 10 linie

		dc.w	$0120
Sprite00:	dc.w	0,$0122,0

		dc.w	$0124
Sprite01:	dc.w	0,$0126,0

		dc.w	$0128		
Sprite02:	dc.w	$0,$012a,0

		dc.l	$012c0000,$012e0000
		dc.l	$01300000,$01320000
		dc.l	$01340000,$01360000
		dc.l	$01380000,$013a0000
		dc.l	$013c0000,$013e0000
		dc.l	$fffffffe		; koniec copperlisty
		
Colors:		dc.w $0000,$0cde	; paleta kolorow

Bitmap:		incbin "pong.raw"

Shape:		incbin	"digits.bin"

SpriteFake:	dc.l 0,0,0,0

Paletka:	dc.w	0,0
		dc.w %0111111111111110,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w %0111111111111110,$0
		dc.l 0

Paletka2:	dc.w 0,0
		dc.w %0111111111111110,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w $ffff,$0
		dc.w %0111111111111110,$0
		dc.l 0

;jeśli chcesz żeby to był sprajt to muszą być najpierw dwa słowa albo jeden long 
Pilka:		dc.l	0
		dc.w %0000001111000000,$0
		dc.w %0000111111110000,$0
		dc.w %0001111111111000,$0
		dc.w %0011111111111100,$0
		dc.w %0111111111111110,$0
		dc.w %0111111111111110,$0
		dc.w %1111111111111111,$0
		dc.w %1111111111111111,$0
		dc.w %1111111111111111,$0
		dc.w %1111111111111111,$0
		dc.w %0111111111111110,$0
		dc.w %0111111111111110,$0
		dc.w %0011111111111100,$0
		dc.w %0001111111111000,$0
		dc.w %0000111111110000,$0
		dc.w %0000001111000000,$0
		dc.l 0

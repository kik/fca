#include "nes.h"

	SECTION_FAST
	ALIGN

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ パレットの変換
@@@ 
@@@ パレットは読み書きできるので，読むときにそなえてコピーを
@@@ とっておかなければならない。
@@@ それと同時にGBAのパレットRAMにも書き込む。
@@@ 

	SECTION_FAST
	ALIGN
bg_palette:
	.fill	0x16, 1, 0
spr_palette:	
	.fill	0x16, 1, 0
	
	ALIGN

@@@ 
@@@ $2007経由でパレットを読む
@@@ 
@@@ r1	=> VRAMアドレス 
@@@ r0	<= 結果
	.globl	read_palette

read_palette:	
	and	r1, r1, #0x1F
	adr	r0, bg_palette
	ldrb	r0, [r0, r1]
	mov	pc, lr

@@@ 
@@@ $2007経由でパレットに書く
@@@ 
@@@ r0	=> 書くバイト
@@@ r1	=> VRAMアドレス
@@@ 
@@@ GBAのパレットは0500_0000にあり
@@@ BGのパレットが256エントリ
@@@ SPRのパレットが256エントリある
@@@ 
@@@ NESのパレットは4*4で
@@@ GBAのパレットは16*16
@@@ 
	.globl	write_palette

write_palette:	
	@@ とりあえずコピーをとる
	and	r0, r0, #0x3F
	and	r1, r1, #0x1F
	adr	r2, bg_palette
	strb	r0, [r2, r1]
	@@ パレット0はミラーされている
	tst	r1, #0xF
	eoreq	r1, r1, #0x10
	streqb	r0, [r2, r1]
	biceq	r1, r1, #0x10

	@@ 色を変換する
	adr	r2, nes_palette
	ldr	r0, [r2, r0, lsl #2]

	@@ パレット位置を変換する
	adr	r2, palette_map
	ldr	r1, [r2, r1, lsl #2]
	strh	r0, [r1]

	mov	pc, lr

	ALIGN

palette_map:	
#define P(n)	0x05000000 + n
	.long	P(0x00),  P(0x02), P(0x04), P(0x06)
	.long	P(0x20),  P(0x22), P(0x24), P(0x26)
	.long	P(0x40),  P(0x42), P(0x44), P(0x46)
	.long	P(0x60),  P(0x62), P(0x64), P(0x66)
#undef P
#define P(n)	0x05000000 + n + 512
	.long	P(0x00),  P(0x02), P(0x04), P(0x06)
	.long	P(0x20),  P(0x22), P(0x24), P(0x26)
	.long	P(0x40),  P(0x42), P(0x44), P(0x46)
	.long	P(0x60),  P(0x62), P(0x64), P(0x66)
#undef P
	
	ALIGN

#include "palette.S"


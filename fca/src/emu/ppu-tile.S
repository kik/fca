#include "nes.h"
#include "gba-regs.h"
#include "struct.h"

	SECTION_FAST
	ALIGN

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ タイルの変換
@@@ 
@@@ NESのタイルはPPUの$0000-$1000と$1000-2000に置かれている
@@@ これはBGとSPRで共通に使われるので，GBAのBG用タイルとSPR用
@@@ タイルの両方にコピーしなければならない。
@@@ 
@@@ BGのタイルは
@@@ 0600_0000-0600_2000
@@@ 0600_4000-0600_6000
@@@ 0600_8000-0600_A000
@@@ 0600_C000-0600_E000
@@@ に置く
@@@ 
@@@ SPRのタイルは
@@@ 0601_0000-0601_2000
@@@ 0601_4000-0601_6000
@@@ に置く

@@@ 
@@@ VROMスイッチングを行う多くのゲームは画面の更新中に
@@@ VROMを切り替える。
@@@ これを完全にサポートすることはできないが，
@@@ 少しだけサポートする
@@@ BGのタイルは4箇所にコピーできるので，切り替えがあった場合は
@@@ 4つのうちのまだ使われてないところにコピーすることにする
@@@ 

@@@ 
@@@ タイル用のRAM
@@@ FF3などのゲームはCHR-ROMを持たず，かわりにこれを使う
@@@ これらのゲームは簡単である。
@@@ 画面更新中にVRAMに書き込むことはできないため
@@@ 描画開始時に一度だけ更新すればよい
@@@ 
	SECTION_SLOW
	ALIGN
tile_ram:
	.fill	0x2000, 1, 0

	SECTION_FAST
	ALIGN

@@@ 
@@@ VROMの変更を行う
@@@ 
@@@ 

chr_rom_start:	.long	0

@@@ r0 => アドレス
@@@ r1 => 4バイトのキー(アドレスの比較に用いる)
@@@ r2 => 4バイトのキー(アドレスの比較に用いる)

	.globl	set_vram_bank_0to7
set_vram_bank_0to7:	
	ldr	r1, chr_rom_start
	add	r1, r1, r0, lsl #10

	str	r1, tile_map + 0x00;	add	r1, r1, #0x400
	str	r1, tile_map + 0x04;	add	r1, r1, #0x400
	str	r1, tile_map + 0x08;	add	r1, r1, #0x400
	str	r1, tile_map + 0x0C;	add	r1, r1, #0x400
	str	r1, tile_map + 0x10;	add	r1, r1, #0x400
	str	r1, tile_map + 0x14;	add	r1, r1, #0x400
	str	r1, tile_map + 0x18;	add	r1, r1, #0x400
	str	r1, tile_map + 0x1C;	@add	r1, r1, #0x400

	strb	r0, tile_map_key + 0;	add	r0, r0, #1
	strb	r0, tile_map_key + 1;	add	r0, r0, #1
	strb	r0, tile_map_key + 2;	add	r0, r0, #1
	strb	r0, tile_map_key + 3;	add	r0, r0, #1
	strb	r0, tile_map_key + 4;	add	r0, r0, #1
	strb	r0, tile_map_key + 5;	add	r0, r0, #1
	strb	r0, tile_map_key + 6;	add	r0, r0, #1
	strb	r0, tile_map_key + 7;	@add	r0, r0, #1
	
	mov	pc, lr

@@@ r0 => アドレス
@@@ r1 => 4バイトのキー(アドレスの比較に用いる)

	.globl	set_vram_bank_0to3
set_vram_bank_0to3:	
	ldr	r1, chr_rom_start
	add	r1, r1, r0, lsl #10

	str	r1, tile_map + 0x00;	add	r1, r1, #0x400
	str	r1, tile_map + 0x04;	add	r1, r1, #0x400
	str	r1, tile_map + 0x08;	add	r1, r1, #0x400
	str	r1, tile_map + 0x0C;	@add	r1, r1, #0x400

	strb	r0, tile_map_key + 0;	add	r0, r0, #1
	strb	r0, tile_map_key + 1;	add	r0, r0, #1
	strb	r0, tile_map_key + 2;	add	r0, r0, #1
	strb	r0, tile_map_key + 3;	@add	r0, r0, #1
	
	mov	pc, lr
	
	.globl	set_vram_bank_4to7
set_vram_bank_4to7:	
	ldr	r1, chr_rom_start
	add	r1, r1, r0, lsl #10

	str	r1, tile_map + 0x10;	add	r1, r1, #0x400
	str	r1, tile_map + 0x14;	add	r1, r1, #0x400
	str	r1, tile_map + 0x18;	add	r1, r1, #0x400
	str	r1, tile_map + 0x1C;	@add	r1, r1, #0x400

	strb	r0, tile_map_key + 4;	add	r0, r0, #1
	strb	r0, tile_map_key + 5;	add	r0, r0, #1
	strb	r0, tile_map_key + 6;	add	r0, r0, #1
	strb	r0, tile_map_key + 7;	@add	r0, r0, #1
	
	mov	pc, lr

@@@ r0 => アドレス
@@@ r1 => 1バイトのキー(アドレスの比較に用いる)

.macro	set_vram_bank_x	n
	ldr	r1, chr_rom_start
	add	r1, r1, r0, lsl #10
	str	r1, tile_map + 0x04 * \n
	strb	r0, tile_map_key + \n
	mov	pc, lr
.endm

	.globl	set_vram_bank_0
	.globl	set_vram_bank_1
	.globl	set_vram_bank_2
	.globl	set_vram_bank_3
	.globl	set_vram_bank_4
	.globl	set_vram_bank_5
	.globl	set_vram_bank_6
	.globl	set_vram_bank_7
set_vram_bank_0:	set_vram_bank_x	0
set_vram_bank_1:	set_vram_bank_x	1
set_vram_bank_2:	set_vram_bank_x	2
set_vram_bank_3:	set_vram_bank_x	3
set_vram_bank_4:	set_vram_bank_x	4
set_vram_bank_5:	set_vram_bank_x	5
set_vram_bank_6:	set_vram_bank_x	6
set_vram_bank_7:	set_vram_bank_x	7


@@@ r0 => アドレス
@@@ r1 => 2バイトのキー(アドレスの比較に用いる)

.macro	set_vram_bank_xx	n
	ldr	r1, chr_rom_start
	add	r1, r1, r0, lsl #10
	str	r1, tile_map + 0x04 * \n
	add	r1, r1, #0x400
	str	r1, tile_map + 0x04 * \n + 4
	strb	r0, tile_map_key + \n
	add	r0, r0, #1
	strb	r0, tile_map_key + \n + 1
	mov	pc, lr
.endm

	.globl	set_vram_bank_0to1
	.globl	set_vram_bank_2to3
	.globl	set_vram_bank_4to5
	.globl	set_vram_bank_6to7
set_vram_bank_0to1:	set_vram_bank_xx	0
set_vram_bank_2to3:	set_vram_bank_xx	2
set_vram_bank_4to5:	set_vram_bank_xx	4
set_vram_bank_6to7:	set_vram_bank_xx	6

@@@ 
@@@ 0000-2000を8つにわける
@@@ ひとつは0x400つまり64個
@@@ 
	.globl	tile_map

tile_map:
	.long	tile_ram + 0x0000, tile_ram + 0x0400
	.long	tile_ram + 0x0800, tile_ram + 0x0C00
	.long	tile_ram + 0x1000, tile_ram + 0x1400
	.long	tile_ram + 0x1800, tile_ram + 0x1C00

tile_cp_map:	
	.long	0x06000000, 0x06000800, 0x06001000, 0x06001800
	.long	0x06004000, 0x06004800, 0x06005000, 0x06005800
	.long	0x06008000, 0x06008800, 0x06009000, 0x06009800
	.long	0x0600C000, 0x0600C800, 0x0600D000, 0x0600D800

@@@ 
@@@ タイルマップを一度で比較できるようにするキー
@@@ 1バンクごとに1バイトの値を使う
@@@ 
tile_map_key:		.long	0x03020100, 0x07060504
tile_map_bg_key:	.long	-1, -1, -1, -1
tile_map_spr_key:	.long	-1, -1


@@@ 
@@@ RAMの場合は変更されたかどうか
@@@ 
tile_ram_dirty:		.long	0

@@@ 
@@@ 4つのテーブルのうちどれを使用したか
@@@ 
tile_alloc_flags:	.long	0

@@@ 
@@@ BG_CRのスクリーンの大きさの設定値
@@@ 
screen_size:		.long	0

	.globl set_screen_size
set_screen_size:	
	str	r0, screen_size
	mov	pc, lr


.macro	UP_SPR	n, mask
	tst	r11, #(\mask)
	ldrne	r0, tile_map + (\n) * 4
	ldrne	r1, tile_cp_map + (\n) * 4
	addne	r1, r1, #0x10000
	blne	trans_tile_64
.endm

.macro	UP_BG	n, m, mask
	tst	r11, #(\mask)
	ldrne	r0, tile_map + (\n) * 4
	ldrne	r1, tile_cp_map + (\m) * 4
	blne	trans_tile_64
.endm

.macro	UP_RAM	n, mask
	tst	r11, #(\mask)
	ldrne	r0, tile_map + (\n) * 4
	ldrne	r1, tile_cp_map + (\n) * 4
	blne	trans_tile_64_bg_spr
.endm


@@@ 
@@@ タイルのデータを更新する
@@@ 
@@@ 画面の更新の最初に呼ばれる。
@@@ タイルがRAMに置かれていて，RAMに書き込みがあった場合は
@@@ ここでSPRとBGのタイルを変換する。
@@@ ROMの場合はSPRだけを変換する。画面の更新中にROMが変更されても
@@@ SPRには反映されない。
@@@ 
	.globl	update_tile

update_tile:	
	tst	REG_P_REST, #P_REST_HAS_VRAM
	bne	update_tile_ram

	mov	r0, #0
	str	r0, tile_alloc_flags

	stmfd	sp!, {r4-r11, lr}
	@@ SPRを変換する
	ldr	r11, tile_map_key
	ldr	r0,  tile_map_spr_key
	str	r11, tile_map_spr_key
	eors	r11, r0, r11
	beq	2f
	UP_SPR	0, 0x000000FF
	UP_SPR	1, 0x0000FF00
	UP_SPR	2, 0x00FF0000
	UP_SPR	3, 0xFF000000
2:	
	ldr	r11, tile_map_key + 4
	ldr	r0,  tile_map_spr_key + 4
	str	r11, tile_map_spr_key + 4
	eors	r11, r0, r11
	ldmeqfd	sp!, {r4-r11, pc}
	UP_SPR	4, 0x000000FF
	UP_SPR	5, 0x0000FF00
	UP_SPR	6, 0x00FF0000
	UP_SPR	7, 0xFF000000
	ldmfd	sp!, {r4-r11, pc}

update_tile_ram:	
	ldr	r0, tile_ram_dirty
	teq	r0, #0
	moveq	pc, lr
	mov	r1, #0
	str	r1, tile_ram_dirty

	stmfd	sp!, {r4-r11, lr}
	mov	r11, r0
	@@ SPR, BG両方変換する
	UP_RAM	0, 0x01
	UP_RAM	1, 0x02
	UP_RAM	2, 0x04
	UP_RAM	3, 0x08
	UP_RAM	4, 0x10
	UP_RAM	5, 0x20
	UP_RAM	6, 0x40
	UP_RAM	7, 0x80
	ldmfd	sp!, {r4-r11, pc}

@@@ 
@@@ 描画途中でVROMの変更を反映する
@@@ 反映できるのはBGだけであるが，それだけで十分である
@@@ 
@@@ r0にBG_CRの値を返す

	.globl	update_tile_per_line

update_tile_per_line:	
	ldr	r0, screen_size
	orr	r0, r0, #GBA_BG_CR_MAP_ADDR(0x4)
	tst	REG_P_REST, #P_REST_HAS_VRAM
	beq	1f

	tst	REG_P_REST, #P_REST_BG_ADR
	orrne	r0, r0, #GBA_BG_CR_TILE_ADDR(1)	
	mov	pc, lr
1:	
	tst	REG_P_REST, #P_REST_BG_ADR
	ldreq	r1, tile_map_key
	ldrne	r1, tile_map_key + 4
	ldr	r3, tile_alloc_flags

	@@ 
	@@ まず，同じ設定のものがあるか調べる
	@@ あった場合はそれを使う
	@@ 

	ldr	r2, tile_map_bg_key + 0
	teq	r1, r2
	orreq	r3, r3, #0x01
	streq	r3, tile_alloc_flags
	moveq	pc, lr
	
	ldr	r2, tile_map_bg_key + 4
	teq	r1, r2
	orreq	r3, r3, #0x02
	streq	r3, tile_alloc_flags
	orreq	r0, r0, #GBA_BG_CR_TILE_ADDR(1)
	moveq	pc, lr

	ldr	r2, tile_map_bg_key + 8
	teq	r1, r2
	orreq	r3, r3, #0x04
	streq	r3, tile_alloc_flags
	orreq	r0, r0, #GBA_BG_CR_TILE_ADDR(2)
	moveq	pc, lr

	ldr	r2, tile_map_bg_key + 12
	teq	r1, r2
	orreq	r3, r3, #0x08
	streq	r3, tile_alloc_flags
	orreq	r0, r0, #GBA_BG_CR_TILE_ADDR(3)
	moveq	pc, lr
	
	@@ VROMが変更されていて同じ配置が残っていない
	@@ そこで新しくVRAMを確保してそこにコピーする

	tst	REG_P_REST, #P_REST_BG_ADR
	adreq	r2, 1f
	adrne	r2, 2f
	ldr	pc, [r2, r3, lsl #2]
1:	
	@@          0000      0001      0010      0011
	.word	alloc_L0, alloc_L1, alloc_L0, alloc_L2
	@@          0100      0101      0110      0111
	.word	alloc_L0, alloc_L1, alloc_L0, alloc_L3
	@@          1000      1001      1010      1011
	.word	alloc_L0, alloc_L1, alloc_L0, alloc_L2
	@@          1100      1101      1110      1111
	.word	alloc_L0, alloc_L1, alloc_L0, alloc_imp
2:	
	@@          0000      0001      0010      0011
	.word	alloc_H0, alloc_H1, alloc_H0, alloc_H2
	@@          0100      0101      0110      0111
	.word	alloc_H0, alloc_H1, alloc_H0, alloc_H3
	@@          1000      1001      1010      1011
	.word	alloc_H0, alloc_H1, alloc_H0, alloc_H2
	@@          1100      1101      1110      1111
	.word	alloc_H0, alloc_H1, alloc_H0, alloc_imp

.macro	ALLOC_VRAM_LO	n
	orr	r3, r3, #1 << \n
	str	r3, tile_alloc_flags
	stmfd	sp!, {r0, r4-r11, lr}

	ldr	r11, tile_map_bg_key + 4 * \n
	str	r1,  tile_map_bg_key + 4 * \n
	eor	r11, r11, r1

	UP_BG	0, \n * 4 + 0, 0x000000FF
	UP_BG	1, \n * 4 + 1, 0x0000FF00
	UP_BG	2, \n * 4 + 2, 0x00FF0000
	UP_BG	3, \n * 4 + 3, 0xFF000000

	ldmfd	sp!, {r0, r4-r11, pc}
.endm

.macro	ALLOC_VRAM_HI	n
	orr	r3, r3, #1 << \n
	str	r3, tile_alloc_flags
	stmfd	sp!, {r0, r4-r11, lr}

	ldr	r11, tile_map_bg_key + 4 * \n
	str	r1,  tile_map_bg_key + 4 * \n
	eor	r11, r11, r1

	UP_BG	4, \n * 4 + 0, 0x000000FF
	UP_BG	5, \n * 4 + 1, 0x0000FF00
	UP_BG	6, \n * 4 + 2, 0x00FF0000
	UP_BG	7, \n * 4 + 3, 0xFF000000

	ldmfd	sp!, {r0, r4-r11, pc}
.endm

alloc_L0:	
	orr	r0, r0, #GBA_BG_CR_TILE_ADDR(0)
	ALLOC_VRAM_LO	0
alloc_L1:	
	orr	r0, r0, #GBA_BG_CR_TILE_ADDR(1)
	ALLOC_VRAM_LO	1
alloc_L2:	
	orr	r0, r0, #GBA_BG_CR_TILE_ADDR(2)
	ALLOC_VRAM_LO	2
alloc_L3:	
	orr	r0, r0, #GBA_BG_CR_TILE_ADDR(3)
	ALLOC_VRAM_LO	3

alloc_H0:	
	orr	r0, r0, #GBA_BG_CR_TILE_ADDR(0)
	ALLOC_VRAM_HI	0
alloc_H1:	
	orr	r0, r0, #GBA_BG_CR_TILE_ADDR(1)
	ALLOC_VRAM_HI	1
alloc_H2:	
	orr	r0, r0, #GBA_BG_CR_TILE_ADDR(2)
	ALLOC_VRAM_HI	2
alloc_H3:	
	orr	r0, r0, #GBA_BG_CR_TILE_ADDR(3)
	ALLOC_VRAM_HI	3

alloc_imp:	
	mov	pc, lr


@@@ 
@@@ $2007経由でタイルを読む
@@@ 
@@@ r1	=> アドレス
@@@ r0	<= *r3 = read_2007_buffer
@@@ *r3 <= 結果
	.globl	read_tile

read_tile:
	mov	r2, r1, lsr #10
	adrl	r0, tile_map
	ldr	r0, [r0, r2, lsl #2]
	bic	r1, r1, #0xFC00
	ldrb	r0, [r0, r1]
	swpb	r0, r0, [r3]
	mov	pc, lr

@@@ 
@@@ $2007経由でタイルに書く
@@@ 
	.globl	write_tile

write_tile:
	tst	REG_P_REST, #P_REST_HAS_VRAM
	moveq	pc, lr

	mov	r2, r1, lsr #10
	adrl	r3, tile_map
	ldr	r3, [r3, r2, lsl #2]
	bic	r1, r1, #0xFC00
	strb	r0, [r3, r1]

	ldr	r0, tile_ram_dirty
	mov	r1, #1
	orr	r0, r0, r1, lsl r2
	str	r0, tile_ram_dirty
	mov	pc, lr

	.globl	get_tile_map
get_tile_map:	
	adrl	r0, tile_map
	mov	pc, lr

@@@ 
@@@ タイルを64個変換する
@@@ 
@@@ r0	=> SRC
@@@ r1	=> DST
@@@ 
@@@ r3-r10 を壊す
@@@ 
.macro	TRANS_LINE_BG_SPR	reg1, reg2, mask, shift
	and	r8, \reg1, #\mask
	ldr	r9, [r3, r8, \shift]
	and	r8, \reg2, #\mask
	ldr	r8, [r3, r8, \shift]
	orr	r8, r9, r8, lsl #1
	str	r8, [r1], #4
	str	r8, [r2], #4
.endm

.macro	TRANS_LINE		reg1, reg2, mask, shift
	and	r8, \reg1, #\mask
	ldr	r9, [r3, r8, \shift]
	and	r8, \reg2, #\mask
	ldr	r8, [r3, r8, \shift]
	orr	r8, r9, r8, lsl #1
	str	r8, [r1], #4
.endm

trans_tile_64_bg_spr:	
	adr	r3, tile_translate_table
	add	r2, r1, #0x10000

	mov	r10, #64
1:	
	@@ タイルをひとつロード
	@@ ROMからのロードはLDMを使ってシーケンシャルに
	@@ やると速い
	ldmia	r0!, {r4-r7}

	TRANS_LINE_BG_SPR	r4, r6, 0x000000FF, lsl #2
	TRANS_LINE_BG_SPR	r4, r6, 0x0000FF00, lsr #6
	TRANS_LINE_BG_SPR	r4, r6, 0x00FF0000, lsr #14
	TRANS_LINE_BG_SPR	r4, r6, 0xFF000000, lsr #22

	TRANS_LINE_BG_SPR	r5, r7, 0x000000FF, lsl #2
	TRANS_LINE_BG_SPR	r5, r7, 0x0000FF00, lsr #6
	TRANS_LINE_BG_SPR	r5, r7, 0x00FF0000, lsr #14
	TRANS_LINE_BG_SPR	r5, r7, 0xFF000000, lsr #22

	subs	r10, r10, #1
	bne	1b

	mov	pc, lr

trans_tile_64:	
	adr	r3, tile_translate_table

	mov	r10, #64
1:	
	@@ タイルをひとつロード
	@@ ROMからのロードはLDMを使ってシーケンシャルに
	@@ やると速い
	ldmia	r0!, {r4-r7}

	TRANS_LINE	r4, r6, 0x000000FF, lsl #2
	TRANS_LINE	r4, r6, 0x0000FF00, lsr #6
	TRANS_LINE	r4, r6, 0x00FF0000, lsr #14
	TRANS_LINE	r4, r6, 0xFF000000, lsr #22

	TRANS_LINE	r5, r7, 0x000000FF, lsl #2
	TRANS_LINE	r5, r7, 0x0000FF00, lsr #6
	TRANS_LINE	r5, r7, 0x00FF0000, lsr #14
	TRANS_LINE	r5, r7, 0xFF000000, lsr #22

	subs	r10, r10, #1
	bne	1b

	mov	pc, lr



	ALIGN
tile_translate_table:	
	.fill	256, 4, 0

	SECTION_SLOW
	ALIGN

@@@ 
@@@ タイルの変換はテーブルを使う
@@@ 
@@@    NES   =>  GBA
@@@ ABCDEFGH => 000H 000G 000F 000E 000D 000C 000B 000A
@@@ を行うテーブル(byte → word)を作っておく
@@@ 
	.globl	init_tile_trans_table

init_tile_trans_table:	
	@@ 
	@@ タイルの変換テーブルを初期化する
	@@ 
	ldr	r1, =tile_translate_table
	mov	r2, #0
1:	
	mov	r3, #0

	tst	r2, #0x80;  orrne	r3, r3, #0x00000001
	tst	r2, #0x40;  orrne	r3, r3, #0x00000010
	tst	r2, #0x20;  orrne	r3, r3, #0x00000100
	tst	r2, #0x10;  orrne	r3, r3, #0x00001000
	tst	r2, #0x08;  orrne	r3, r3, #0x00010000
	tst	r2, #0x04;  orrne	r3, r3, #0x00100000
	tst	r2, #0x02;  orrne	r3, r3, #0x01000000
	tst	r2, #0x01;  orrne	r3, r3, #0x10000000

	str	r3, [r1], #4
	add	r2, r2, #1
	teq	r2, #256
	bne	1b

	ldopt	r0, EMU_OPT_chr_rom_start
	ldr	r1, = chr_rom_start
	str	r0, [r1]

	mov	pc, lr

	.pool

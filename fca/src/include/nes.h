#ifndef NES_H
#define NES_H

#define SECTION_FAST .section emu.fast, "awx"
#define SECTION_SLOW .section emu.slow, "awx"
#define SECTION_HEAD .section emu.head, "awx"

#define ALIGN .align 2

#define FOUR_SCREEN 3
#define VERTICAL_SCREEN 2
#define HORIZONTAL_SCREEN 1

/*
 * 6502 のレジスタ
 *
 * A は常に 24 ビットシフトしておく
 * P は2つに分ける。
 * NZはほとんどの命令が変更するので，NZの元になる値を保存
 * 残りは他の場所に置く
 *
 * S は24ビットシフトしておく
 * これで余って下のビットに P の残りを置く(VBDI)
 * さらに余ってるところには割り込みに関するフラグを置く
 *
 * PC はROM内のアドレスに変換しておく
 * この場合は境界チェックをしたほうがいいのだが，簡単ではない
 * 本当の PC を得るためには現在のバンクの先頭アドレスを引けばよい
 */
#define REG_A  r4
#define REG_X  r5
#define REG_Y  r6
#define REG_PC r7
#define REG_S  r8
#define REG_NZ  r9
#define REG_P_REST REG_S

#if 0
/*
 * REG_P で使うフラグ
 */
#define ARM_N_FLAG 0x80000000
#define ARM_Z_FLAG 0x40000000
#define ARM_C_FLAG 0x20000000
#define ARM_V_FLAG 0x10000000
#endif

/*
 * REG_P_REST には各種フラグを置く
 *
 * 0
 * FEDCBA98 76543210
 * |||||||| |||||||+---C キャリーまたはボローなし
 * |||||||| ||||||+---NMIの発生
 * |||||||| |||||+---I 割り込み許可
 * |||||||| ||||+---D 十進モード
 * |||||||| |||+---B
 * |||||||| ||+---IRQの発生
 * |||||||| |+---V オーバーフロー
 * |||||||| +---$2005/$2006 トグルフラグ
 * ||||||||
 * |||||||+---$2000[2] 32インクリメント
 * ||||||+---$2000[3] スプライトアドレス選択
 * |||||+---$2000[4] バックグラウンドアドレス選択
 * ||||+---$2000[5] スプライトサイズ
 * |||+---未使用
 * ||+---$2000[7] NMI許可
 * |+---$2001[3] バックグラウンドを描画
 * +---$2001[4] スプライトを描画
 *
 * 1
 * FEDCBA9876543210
 * |||||||||||||||+---$2002[4] VRAMに書き込み可？
 * ||||||||||||||+---$2002[5] スプライトが多すぎ
 * |||||||||||||+---$2002[6] スプライトヒット(実装できるのか？)
 * ||||||||||||+---$2002[7] VBL
 * |||||||||||+---DMC割り込み発生
 * ||||||||+++---未使用
 * ++++++++---S スタックポインタ
 *
 */


/*
 * REG_P_REST で使うフラグ。基本的にPと同じ位置にある
 */
#define P_REST_V_FLAG 0x40
#define P_REST_B_FLAG 0x10
#define P_REST_D_FLAG 0x08
#define P_REST_I_FLAG 0x04
#define P_REST_C_FLAG 0x01
#define P_REST_FLAGS  0x5D

/*
 * 割り込みが発生するとセットされる
 */
#define P_REST_INT_PENDING 0x20
#define P_REST_NMI_PENDING 0x02

#define ASSERT_NMI	orr	REG_P_REST, REG_P_REST, #P_REST_NMI_PENDING
#define ASSERT_INT	orr	REG_P_REST, REG_P_REST, #P_REST_INT_PENDING

/*
 * 2005/2006のトグル
 */
#define P_REST_PPU_TOGGLE 0x80

/*
 * レジスタ$2000はP_REST[8-13]におく
 */
#define P_REST_PPU_32     0x0100
#define P_REST_SPR_ADR    0x0200
#define P_REST_BG_ADR     0x0400
#define P_REST_SPR_SZ     0x0800
#define P_REST_ENB_NMI    0x2000
#define P_REST_2000       0x3F00

/*
 * レジスタ$2001はP_REST[14-15]に以下のふたつを置く
 */
#define P_REST_DRAW_BG    0x4000
#define P_REST_DRAW_SPR   0x8000
#define P_REST_2001       0xC000

/*
 * レジスタ$2002はP_REST[16-19]に以下をおく
 */
#define P_REST_VRAM_WR    0x10000
#define P_REST_SPR_COUNT  0x20000
#define P_REST_SPR_HIT    0x40000
#define P_REST_IN_VBL     0x80000
#define P_REST_2002       0xF0000

#define P_REST_DMC_IRQ    0x100000

/*
 * 6502 の本当のフラグ
 */
#define P_N_FLAG 0x80
#define P_V_FLAG 0x40
#define P_R_FLAG 0x20
#define P_B_FLAG 0x10
#define P_D_FLAG 0x08
#define P_I_FLAG 0x04
#define P_Z_FLAG 0x02
#define P_C_FLAG 0x01

#define NMI_VECTOR   6
#define RESET_VECTOR 4
#define IRQ_VECTOR   2

/*
 * 生成されたアドレス
 */
#define REG_ADDR r10

/*
 * 残りサイクル
 */
#define REG_CYCLE r11

/*
 * 命令のジャンプテーブル
 */
#define REG_OP_TABLE r12

#endif

#ifndef VRAM_H
#define VRAM_H

#define VRAM_BASE_ADDR  0x06000000

#ifndef __ASSEMBLY__

#define VRAM_BASE       ((short *)VRAM_BASE_ADDR)

#define VRAM_FONT_BASE  ((short *)(VRAM_BASE_ADDR + 0x8000))
#define VRAM_TEXT_BASE  ((short *)(VRAM_BASE_ADDR + 0xF800))

#endif

#define FONT_TOFU_TR  0xF100 // ∆©Ã¿§ ∆¶…Â
#define FONT_TOFU_B   0xF101 // πı§§∆¶…Â
#define FONT_TOFU_W   0xF102 // «Ú§§∆¶…Â

#define FONT_LINE_U   0xF103
#define FONT_LINE_D   0xF903
#define FONT_LINE_L   0xF104
#define FONT_LINE_R   0xF504

#define FONT_LINE_UL  0xF105
#define FONT_LINE_UR  0xF505
#define FONT_LINE_DL  0xF905
#define FONT_LINE_DR  0xFD05

#define FONT_CUR_U    0xF107
#define FONT_CUR_D    0xF907
#define FONT_CUR_L    0xF106
#define FONT_CUR_R    0xF506

#endif

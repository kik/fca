#ifndef GBA_H
#define GBA_H

extern long _etext;
extern long _sdata;
extern long _edata;
extern long _load_start;
extern long _load_end;
extern long __bss_start;
extern long __bss_end;
extern long _stack;
extern long _stack_usr;
extern long _stack_irq;
extern long _stack_svc;

extern long _rom_end;

extern long _interrupt_vector;

extern unsigned short _vram[0xC000];
#define VRAM_TILE_SET(n)  (&_vram[(n) << 13])
#define VRAM_MAP_TABLE(n) (&_vram[(n) << 10])

extern unsigned short _palette[0x200];
extern unsigned short _sprite[0x200];

extern volatile unsigned short _ioreg[0x181];

#define RGB(r, g, b) ((b) << 10 | (g) << 5 | (r))

extern inline void
write_palette(int n, short c)
{
  _palette[n] = c;
}

#endif

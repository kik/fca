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

#define RGB(r, g, b) ((b) << 10 | (g) << 5 | (r))

extern inline void
write_palette(int n, short c)
{
  short *p = (short *)0x05000000;
  p[n] = c;
}

#endif

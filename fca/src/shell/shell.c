#include "gba.h"
#include "file.h"
#include "text.h"
#include "load.h"

int
start_shell(void)
{
  int i;
  int *p;

  init_file_system();
  init_text_console(0, 2, 0x1C);

  _ioreg[0] = 0x0140;
  _ioreg[5] = 0x0704;
  _ioreg[0x102] = 0x4004;
  for (i = 0; i < 32 * 32; i++)
    _vram[0x2000 + i] = i;

#define RGB(r, g, b) ((b) << 10 | (g) << 5 | (r))
  _palette[0xCF] = RGB(31, 0, 0);
  _palette[0xDF] = RGB(0, 31, 0);
  _palette[0xEF] = RGB(0, 0, 31);
  _palette[0xFF] = RGB(31, 31, 31);
#if 0
  p = find_file("test.nes", 0);
  printf("test.nes found at %x\n", p);
#endif

  //test();
  
  while ((p = select_nes_file(0)) == 0)
    ;

  printf("rom %x\n", p);
  load_emulator(p);
  load_mapper(p);
  enter_emulator(p);

  printf("emulation end\n");
  while (1);
}


void
panic(int op, int pc, unsigned char *sp, void *p)
{
  int i;

  _ioreg[0x104] = 0;
  _ioreg[0xBA / 2] = 0;
  _ioreg[0xC6 / 2] = 0;
  init_text_console(0, 2, 0x1C);

  _ioreg[0] = 0x0140;
  _ioreg[8] = 0;
  _ioreg[9] = 0;
  _ioreg[5] = 0x0704;
  _ioreg[0x102] = 0x4004;
  for (i = 0; i < 32 * 32; i++)
    _vram[0x2000 + i] = i;

  printf("PANIC!!!\n");
  printf("OP: %x\n", op);
  printf("PC: %x(%x)\n", pc, p);
  printf("stack dump:\n");
  
  sp -= 32;
  for (i = 0; i < 4; i++, sp += 8)
    printf("%x %x %x %x %x %x %x %x\n", sp[0], sp[1], sp[2], sp[3],
	   sp[4], sp[5], sp[6], sp[7]);

  printf("---SP---\n");

  for (i = 0; i < 4; i++, sp += 8)
    printf("%x %x %x %x %x %x %x %x\n", sp[0], sp[1], sp[2], sp[3],
	   sp[4], sp[5], sp[6], sp[7]);

  while (1)
    ;
}

void
panic_from_int()
{
  int i;
  int *p = (int *)0x03000000;

  _ioreg[0xBA / 2] = 0;
  _ioreg[0xC6 / 2] = 0;

  init_text_console(0, 2, 0x1C);

  _ioreg[0] = 0x0140;
  _ioreg[8] = 0;
  _ioreg[9] = 0;
  //_ioreg[4] = 0x1C08;
  //_ioreg[0x102] = 0x4004;
#if 0
  for (i = 0; i < 32 * 32; i++)
    _vram[0x2000 + i] = i;
#endif
  //printf("\n\n\n\n\n");
  printf("PANIC from int!!!\n");
  for (i = 0; i < 9; i++, p += 2)
    printf("%x %x\n", p[0], p[1]);

  while (1)
    ;
}


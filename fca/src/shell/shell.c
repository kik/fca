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

  init_text_console(0, 2, 0x1C);

  _ioreg[0] = 0x0140;
  _ioreg[5] = 0x0704;
  _ioreg[0x102] = 0x4004;
  for (i = 0; i < 32 * 32; i++)
    _vram[0x2000 + i] = i;

  printf("PANIC!!!\n");
  printf("OP: %x\n", op);
  printf("PC: %x(%x)\n", pc, p);
  printf("stack dump:\n");
  for (i = 0; i < 8; i++, sp += 4)
    printf("%x %x %x %x\n", sp[0], sp[1], sp[2], sp[3]);

  while (1)
    ;
}


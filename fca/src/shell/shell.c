#include "gba.h"
#include "file.h"
#include "text.h"
#include "load.h"

#if 0
static const char test_a[] = "ABCDEFGH";
static char test_b[] = "ABCDEFGH";

static void 
test()
{
  int *ip;
  short *hp;
  int v[4];
  int *testx = (int *)0x03000000;
  char *test0 = testx;

  testx[0] = 0x01234567;
  testx[1] = 0x89ABCDEF;

  printf("test1 %x\n", test0);
  ip = test0;
  v[0] = *ip;
  ip = test0 + 1;
  v[1] = *ip;
  ip = test0 + 2;
  v[2] = *ip;
  ip = test0 + 3;
  v[3] = *ip;
  printf("result %x %x %x %x\n", v[0], v[1], v[2], v[3]);
  printf("test1 %x\n", test0);
  hp = test0;
  v[0] = *hp;
  hp = test0 + 1;
  v[1] = *hp;
  hp = test0 + 2;
  v[2] = *hp;
  hp = test0 + 3;
  v[3] = *hp;
  printf("result %x %x %x %x\n", v[0], v[1], v[2], v[3]);
}
#endif

int
start_shell(void)
{
  int i;
  int *p;

  init_file_system();
  init_text_console(0, 2, 0x1C);

  _ioreg[0] = 0x0140;
  _ioreg[5] = 0x0704;
  _ioreg[0x102] = 0x4000;
  for (i = 0; i < 32 * 32; i++)
    _vram[0x2000 + i] = i;

#define RGB(r, g, b) ((b) << 10 | (g) << 5 | (r))
  _palette[0x00] = RGB(0, 0, 0);
  _palette[0x01] = RGB(0, 31, 0);
  _palette[0x02] = RGB(31, 0, 0);
  _palette[0x03] = RGB(0, 0, 31);

  _palette[0xCF] = RGB(31, 0, 0);
  _palette[0xDF] = RGB(0, 31, 0);
  _palette[0xEF] = RGB(0, 0, 31);

  for (i = 0; i < 256; i += 16) {
    _palette[0x0 | i] = RGB(0, 0, 0);
    _palette[0x1 | i] = RGB(0, 0, 15);
    _palette[0x2 | i] = RGB(0, 15, 0);
    _palette[0x3 | i] = RGB(0, 15, 15);
    _palette[0x4 | i] = RGB(15, 0, 0);
    _palette[0x5 | i] = RGB(15, 0, 15);
    _palette[0x6 | i] = RGB(15, 15, 0);
    _palette[0x7 | i] = RGB(15, 15, 15);
    _palette[0x8 | i] = RGB(0, 0, 0);
    _palette[0x9 | i] = RGB(0, 0, 31);
    _palette[0xA | i] = RGB(0, 31, 0);
    _palette[0xB | i] = RGB(0, 31, 31);
    _palette[0xC | i] = RGB(31, 0, 0);
    _palette[0xD | i] = RGB(31, 0, 31);
    _palette[0xE | i] = RGB(31, 31, 0);
    _palette[0xF | i] = RGB(31, 31, 31);
  }
  //test(); while(1);

  p = find_file("smb1.nes", 0);
  printf("smb1.nes found at %x\n", p);

  load_emulator(p);
  enter_emulator(p);

  printf("emulation end\n");
  while (1);
}

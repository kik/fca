#include "gba.h"
#include "file.h"
#include "text.h"
#include "load.h"

#define SGCNT0L		*(unsigned short*)0x04000080	// Final sound control register addresses
#define SGCNT0H		*(unsigned short*)0x04000082
#define SGCNT1		*(unsigned short*)0x04000084

#define SG30L	*(unsigned short*)0x04000070	// Addresses to sound 3 registers
#define SG30H	*(unsigned short*)0x04000072
#define SG31	*(unsigned short*)0x04000074

#define SGWRAM	((unsigned short*)0x04000090)	// Address of sound 3 wave RAM (16 bytes 4bit/step)

static void test()
{
  SGCNT0L = 0xFFFF;
  //SGCNT0H = 0xFFFF;
  SGCNT1 = 0x08;

  SG30L = 0x0040;
  SGWRAM[0] = 0x0000;
  SGWRAM[1] = 0x0000;
  SGWRAM[2] = 0x0000;
  SGWRAM[3] = 0x0000;
  SGWRAM[4] = 0xFFFF;
  SGWRAM[5] = 0xFFFF;
  SGWRAM[6] = 0xFFFF;
  SGWRAM[7] = 0xFFFF;
  SG30L = 0x0000;
  SG30H = 0x2000;
  SG31 = 0x5AC;
  SG30L |= 0x0080;
  SG31 |= 0x8000;

  printf("sound test\n");

  while (1) {
    int *key = (int *)0x04000130;
    while (*key & 1)
      ;
    while (!(*key & 1))
      ;
    printf("sound test\n");
    _ioreg[0x30] = 0;
    _ioreg[0x31] = 0xF000;
    _ioreg[0x32] = 0xC5AC;
  }
}

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


#include "gba.h"
#include "file.h"
#include "text.h"
#include "load.h"
#include "nes-header.h"

extern long _emu_start;
extern long _emu_end;
extern long _emu_slow_start;
extern long _emu_slow_end;
extern void emulator_entry(void *nes_file);

void
show_nes_header(struct nes_header *h)
{
  if (memcmp(h->header, NES_ROM_HEADER, 4) != 0) {
    printf("No NES ROM Header\n");
    return;
  }
  printf("%x PRG ROM\n", h->n_prg_rom);
  printf("%x CHR ROM\n", h->n_chr_rom);
  if (h->rom_ctl_1 & NES_ROM_FOUR_SCREEN) {
    printf("Four screen\n");
  } else if (h->rom_ctl_1 & NES_ROM_VERTICAL_MIRRORING) {
    printf("Vertical mirroring\n");
  } else {
    printf("horizontal mirroring\n");
  }
  if (h->rom_ctl_1 & NES_ROM_HAS_TRAINER)
    printf("ROM has trainer\n");
  printf("Mapper #%x\n",
	 (h->rom_ctl_2 & NES_ROM_MAPPER_HEIGH) |
	 ((h->rom_ctl_1 & NES_ROM_MAPPER_LOW) >> 4));
}

void
load_emulator(void *nes_file)
{
  long *p;
  struct file f;

  show_nes_header(nes_file);
  p = find_file("emu.bin", &f);
  if (!p) {
    printf("can't find emu.bin\n");
    return;
  }
  printf("load emu.bin\n %x -> %x\n", p, &_emu_start);
  memcpy(&_emu_start, p, f.length);

  p = find_file("emuslow.bin", &f);
  if (!p) {
    printf("can't find emuslow.bin\n");
    return;
  }
  printf("load emuslow.bin\n %x -> %x\n", p, &_emu_slow_start);
  memcpy(&_emu_slow_start, p, f.length);
}

void
enter_emulator(void *nes_file)
{
  /* こうすると
   * ldr pc, =nes_start
   * にしてくれる。
   */
  void (*start)(void *nes_file) = emulator_entry;
  printf("call %x\n", start);
  start(nes_file);
}

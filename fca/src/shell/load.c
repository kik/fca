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

#if 0
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
#endif

void
load_emulator(void *nes_file)
{
  long *p;
  struct file f;

  //show_nes_header(nes_file);
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


extern int n_prg_rom;
extern int n_chr_rom;
extern int mapper_num;
extern int scroll_type;
extern int has_sram;
extern void *prg_rom_start;
extern void *chr_rom_start;

extern int _start_mapper;

struct mapper {
  int n;
  char *file;
};

static struct mapper mapper_list[] = {
  {0, "mapper0.bin"},
  {2, "mapper2.bin"},
  {3, "mapper3.bin"},
  {4, "mapper4.bin"},
  {0, 0}
};

void
load_mapper(void *nes_file)
{
  struct file mapper_file;
  struct nes_header *h = nes_file;
  char *p = nes_file;
  void *q;
  int i;

  if (memcmp(h->header, NES_ROM_HEADER, 4) != 0) {
    printf("No NES ROM Header\n");
    return;
  }

  n_prg_rom = h->n_prg_rom;
  n_chr_rom = h->n_chr_rom;
  printf("%x PRG ROM\n", h->n_prg_rom);
  printf("%x CHR ROM\n", h->n_chr_rom);

  if (h->rom_ctl_1 & NES_ROM_FOUR_SCREEN) {
    printf("Four screen\n");
    scroll_type = 2;
  } else if (h->rom_ctl_1 & NES_ROM_VERTICAL_MIRRORING) {
    printf("Vertical mirroring\n");
    scroll_type = 0;
  } else {
    printf("horizontal mirroring\n");
    scroll_type = 1;
  }

  if (h->rom_ctl_1 & NES_ROM_HAS_TRAINER) {
    printf("ROM has trainer\n");
    p += 512 + 16;
  } else {
    p += 16;
  }

  mapper_num = (h->rom_ctl_2 & NES_ROM_MAPPER_HEIGH) |
    ((h->rom_ctl_1 & NES_ROM_MAPPER_LOW) >> 4);

  printf("Mapper #%x\n", mapper_num);

  for (i = 0; mapper_list[i].file; i++)
    if (mapper_num == mapper_list[i].n)
      break;

  if (!mapper_list[i].file) {
    printf("mapper is not supported\n");
    while (1);
  }

  q = find_file(mapper_list[i].file, &mapper_file);
  if (!q) {
    printf("%s: not found\n", mapper_list[i].file);
    while (1);
  }
  printf("%s: found\n", mapper_list[i].file);
  memcpy(&_start_mapper, q, mapper_file.length);

  prg_rom_start = p;
  p += 16 * 1024 * n_prg_rom;
  chr_rom_start = p;
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

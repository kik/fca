#include "gba.h"
#include "file.h"
#include "text.h"
#include "load.h"
#include "window.h"
#include "struct.h"
#include "lib.h"

extern long _emu_start;
extern long _emu_end;
extern long _emu_slow_start;
extern long _emu_slow_end;
extern long _start_mapper;
extern void emulator_entry();


int
verify_nes_file(struct nes_header *p)
{
  if (memcmp(p->header, "NES\x1A", 4) != 0)
    return 0;
  if (p->rom_ctl_2 & 0xF)
    return 0;
  //if (memcmp(p->pad, "\0\0\0\0\0\0\0\0", 8) != 0)
  //  return 0;
  return 1;
}

int
nes_scroll_type(struct nes_header *p)
{
  if (p->rom_ctl_1 & 0x08)
    return 2;
  else if (p->rom_ctl_1 & 0x01)
    return 0;
  else
    return 1;
}

int
nes_has_save_ram(struct nes_header *p)
{
  if (p->rom_ctl_1 & 0x02)
    return 1;
  else
    return 0;
}

int
nes_has_trainer(struct nes_header *p)
{
  if (p->rom_ctl_1 & 0x04)
    return 1;
  else
    return 0;
}

int
nes_mapper(struct nes_header *p)
{
  return (p->rom_ctl_1 >> 4) | (p->rom_ctl_2 & 0xF0);
}

static int
load_emulator()
{
  struct file f;
  void *p;

  p = open_file("emu", "bin", &f);
  if (!p)
    return 0;
  memcpy(&_emu_start, p, f.length);

  p = open_file("emuslow", "bin", &f);
  if (!p)
    return 0;
  memcpy(&_emu_slow_start, p, f.length);

  return 1;
}

struct mapper {
  int n;
  char *file;
};

static struct mapper mapper_list[] = {
  {0, "mapper0"},
  {1, "mapper1"},
  {2, "mapper2"},
  {3, "mapper3"},
  {4, "mapper4"},
  {0, 0}
};

static int
load_mapper(int num)
{
  struct file f;
  void *p;
  int i;

  for (i = 0; mapper_list[i].file; i++)
    if (num == mapper_list[i].n)
      break;

  if (!mapper_list[i].file)
    return 0;

  p = open_file(mapper_list[i].file, "bin", &f);
  if (!p)
    return 0;

  memcpy(&_start_mapper, p, f.length);

  return 1;
}

int
run_emulator(struct nes_header *p, 
	     struct file *save_w, struct file *save_r)
{
  struct emulator_opt *opt = &emulator_opt;
  if (!verify_nes_file(p)) {
    warn(ERROR "NESファイルヘッダがまちがっています。");
    return 0;
  }

  if (!load_emulator()) {
    warn(ERROR "ひつようなファイルをひらけません。");
    return 0;
  }
  if (!load_mapper(opt->mapper_num = nes_mapper(p))) {
    warn(ERROR "マッパーをサポートしていません。");
    return 0;
  }
  
  opt->n_prg_rom = p->n_prg_rom;
  opt->n_chr_rom = p->n_chr_rom;
  opt->scroll_type = nes_scroll_type(p);

  if (nes_has_trainer(p))
    opt->prg_rom_start = p->data + 512;
  else
    opt->prg_rom_start = p->data;

  opt->chr_rom_start = opt->prg_rom_start + 16 * 1024 * opt->n_prg_rom;

  if (save_w)
    opt->save_file_write = save_w->start;
  if (save_r)
    opt->save_file_read = save_r->start;

  {
    /* こうすると
     * ldr pc, =nes_start
     * にしてくれる。
     */
    void (* volatile start)() = emulator_entry;
    start();
  }
  return 1;
}


#ifndef LOAD_H
#define LOAD_H

struct nes_header {
  char header[4];
  unsigned char n_prg_rom;
  unsigned char n_chr_rom;
  unsigned char rom_ctl_1;
  unsigned char rom_ctl_2;
  char pad[8];
  char data[0]; // GNU ext.
};



int run_emulator(struct nes_header *nes_file,
		 struct file *save_w, struct file *save_r);

int verify_nes_file(struct nes_header *nes_file);
int nes_scroll_type(struct nes_header *nes_file);
int nes_has_save_ram(struct nes_header *nes_file);
int nes_has_trainer(struct nes_header *nes_file);
int nes_mapper(struct nes_header *nes_file);

#endif

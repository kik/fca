#ifndef NES_HEADER_H
#define NES_HEADER_H

struct nes_header {
  char header[4];
  unsigned char n_prg_rom;
  unsigned char n_chr_rom;
  unsigned char rom_ctl_1;
  unsigned char rom_ctl_2;
  char pad[8];
};

#define NES_ROM_HEADER "NES\x1A"
#define NES_ROM_VERTICAL_MIRRORING 0x01
#define NES_ROM_SRAM_ENABLED       0x02
#define NES_ROM_HAS_TRAINER        0x04
#define NES_ROM_FOUR_SCREEN         0x08
#define NES_ROM_MAPPER_LOW         0xF0
#define NES_ROM_MAPPER_HEIGH       0xF0

#endif


CROSS_COMPILE = arm-elf-

CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy

HOSTCC = gcc

CFLAGS = -Iinlcude

OBJ = shell/crt0.o shell/shell.o shell/text.o shell/lib.o shell/file.o \
      shell/load.o shell/disass.o \
      emu/main.o emu/cpu.o emu/mapper.o emu/ppu.o emu/pad.o

all: shell.gba

shell.elf: subdir
	$(LD) -o $@ $(OBJ) -T shell.lds -Map shell.map

shell.bin: shell.elf
	$(OBJCOPY) -O binary $< $@ -j .text -j .rodata -j .data

emu.bin: shell.elf
	$(OBJCOPY) -O binary $< $@ -j emu

emuslow.bin: shell.elf
	$(OBJCOPY) -O binary $< $@ -j emu.slow

shell.gba: shell.bin emu.bin emuslow.bin
	cp shell.bin shell.gba
	./tool/addfile emu.bin		emu.bin		>>shell.gba
	./tool/addfile emuslow.bin	emuslow.bin	>>shell.gba
	./tool/addfile data/font.dat	font.dat	>>shell.gba
#	./tool/addfile data/test.nes	test.nes	>>shell.gba
	./tool/addfile data/smb1.nes	smb1.nes	>>shell.gba
	./tool/endfile >>shell.gba

subdir:
	$(MAKE) -C shell
	$(MAKE) -C emu
	$(MAKE) -C tool
clean:
	rm -f *.o
	$(MAKE) -C shell clean
	$(MAKE) -C emu clean
	$(MAKE) -C tool clean



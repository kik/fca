
CROSS_COMPILE = arm-elf-

CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy

HOSTCC = gcc

CFLAGS = -Iinlcude

OBJ = shell/shells.o emu/emu.o emu/mapper/mapper0.o

MAPPER = mapper0.bin mapper1.bin mapper2.bin mapper3.bin mapper4.bin

all: shell.gba

font: subdir
	./tool/selfont <data/font.dat.src >data/font.dat

shell.elf: subdir
	$(LD) -o $@ $(OBJ) -T shell.lds -Map shell.map

bin/shell.bin: shell.elf
	$(OBJCOPY) -O binary $< $@ -j .text -j .rodata -j .data

bin/emu.bin: shell.elf
	$(OBJCOPY) -O binary $< $@ -j emu

bin/emuslow.bin: shell.elf
	$(OBJCOPY) -O binary $< $@ -j emu.slow

$(MAPPER:%=bin/%): shell.elf
	$(OBJCOPY) -O binary $< $@ -j $(@:bin/%.bin=%)

shell.gba: bin/shell.bin bin/emu.bin bin/emuslow.bin $(MAPPER:%=bin/%) font
	cp bin/shell.bin shell.gba
	./tool/addfile bin/emu.bin	emu.bin		>>shell.gba
	./tool/addfile bin/emuslow.bin	emuslow.bin	>>shell.gba

	for i in $(MAPPER); do \
	  ./tool/addfile bin/$$i	$$i		>>shell.gba; \
	done

	./tool/addfile data/font.dat	font.dat	>>shell.gba

	if [ -f data/test.nes ]; then \
	./tool/addfile data/test.nes	test.nes	>>shell.gba; \
	fi
	if [ -f data/test.sav ]; then \
	./tool/addfile data/test.sav	test.sav	>>shell.gba; \
	fi
#	./tool/addfile data/smb1.nes	smb1.nes	>>shell.gba
#	./tool/addfile data/SMB_E.NES	smb_e.nes	>>shell.gba
#	./tool/addfile data/Dkong.nes	dkong.nes	>>shell.gba
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



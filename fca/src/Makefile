
CROSS_COMPILE = arm-elf-

CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy

HOSTCC = gcc

export HOSTCC CROSS_COMPILE CC AS LD OBJCOPY

CFLAGS = -Iinlcude

OBJ = shell/shells.o emu/emu.o emu/mapper/mappers.o

#MAPPER = mapper0.bin mapper1.bin mapper2.bin mapper3.bin mapper4.bin \
#	mapper9.bin mapper10.bin mapper21.bin mapper66.bin

MAPPER = 0 1 2 3 4 9 10 21 66

BIN = shell.bin emu.bin emuslow.bin $(MAPPER:%=mapper%.bin)

all: fca.gba

fca.gba: bindir
	./tool/fca-mkfs -c -b bin/shell.bin $@ \
	  bin/emu*.bin bin/mapper*.bin bin/*.dat

#font: subdir
#	./tool/selfont <data/font.dat.src >data/font.dat

#bindir: bin/shell.bin bin/emu.bin bin/emuslow.bin $(MAPPER:%=bin/%)

bindir: $(BIN:%=bin/%)

bin/fca.elf: subdir
	$(LD) -o $@ $(OBJ) -T shell.lds -Map fca.map

bin/shell.bin: bin/fca.elf
	$(OBJCOPY) -O binary $< $@ -j .text -j .rodata -j .data

bin/emu.bin: bin/fca.elf
	$(OBJCOPY) -O binary $< $@ -j emu

bin/emuslow.bin: bin/fca.elf
	$(OBJCOPY) -O binary $< $@ -j emu.slow

$(MAPPER:%=bin/mapper%.bin): bin/fca.elf
	$(OBJCOPY) -O binary $< $@ -j $(@:bin/%.bin=%)

subdir:
	$(MAKE) -C shell
	$(MAKE) -C emu
	$(MAKE) -C tool

# mapper-list:
# 	rm -f mapper.lds
# 	for i in $(MAPPER); do \
# 	  echo "	mapper$$i { *(mapper$$i) }" >>mapper.lds; \
# 	done

clean:
	rm -f $(BIN:%=bin/%) bin/fca.elf fca.map fca.gba
	$(MAKE) -C shell clean
	$(MAKE) -C emu clean
	$(MAKE) -C tool clean




CROSS_COMPILE = arm-elf-

CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy

#CFLAGS = -Iinclude

CPPFLAGS = -I../include -D__ASSEMBLY__

SRC = main.S cpu.S mapper.S ppu.S pad.S
OBJ = $(SRC:.S=.o)

all: $(OBJ)

clean:
	rm -f *.o

depend:
	makedepend $(CPPFLAGS) $(SRC)
# DO NOT DELETE

main.o: ../include/nes.h
cpu.o: ../include/nes.h
mapper.o: ../include/nes.h
ppu.o: ../include/nes.h palette.S
pad.o: ../include/nes.h

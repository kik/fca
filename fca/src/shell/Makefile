
CROSS_COMPILE = arm-elf-

CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy

HOSTCC = gcc

CFLAGS = -I../include -ffreestanding -O2
CPPFLAGS = -I../include

OBJ = crt0.o shell.o lib.o file.o load.o font.o window.o
SRC = crt0.S shell.c lib.c file.c load.c font.c window.c

all: shells.o

shells.o: $(OBJ)
	$(LD) -r -o $@ $^

clean:
	rm -f *.o

depend:
	makedepend -Y -- -I../include -- $(SRC)


# DO NOT DELETE

crt0.o: ../include/gba-arm.h
shell.o: ../include/gba.h ../include/file.h ../include/text.h
shell.o: ../include/load.h
text.o: ../include/gba.h ../include/text.h ../include/file.h
lib.o: ../include/gba.h ../include/lib.h
file.o: ../include/gba.h ../include/file.h ../include/text.h
load.o: ../include/gba.h ../include/file.h ../include/text.h
load.o: ../include/load.h ../include/nes-header.h
disass.o: ../include/gba.h ../include/text.h
font.o: ../include/gba.h ../include/file.h ../include/vram.h
font.o: ../include/window.h
window.o: ../include/gba.h ../include/gba-regs.h ../include/vram.h
window.o: ../include/window.h


CROSS_COMPILE = arm-elf-

CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy

HOSTCC = gcc

CFLAGS = -I../include -ffreestanding -O2 -Wall
CPPFLAGS = -I../include

OBJ = crt0.o shell.o lib.o file.o load.o text.o window.o
SRC = crt0.S shell.c lib.c file.c load.c text.c window.c

all: shells.o

shells.o: $(OBJ)
	$(LD) -r -o $@ $^

clean:
	rm -f *.o

depend:
	makedepend -Y -- -I../include -- $(SRC)


# DO NOT DELETE

crt0.o: ../include/gba-arm.h
shell.o: ../include/gba.h ../include/gba-regs.h ../include/file.h
shell.o: ../include/load.h ../include/window.h ../include/text.h
shell.o: ../include/struct.h ../include/lib.h
lib.o: ../include/gba.h ../include/lib.h ../include/file.h
file.o: ../include/gba.h ../include/file.h ../include/text.h
file.o: ../include/window.h ../include/lib.h
load.o: ../include/gba.h ../include/file.h ../include/text.h
load.o: ../include/load.h ../include/window.h ../include/struct.h
load.o: ../include/lib.h
text.o: ../include/gba.h ../include/gba-regs.h ../include/file.h
text.o: ../include/text.h ../include/window.h
window.o: ../include/gba.h ../include/gba-regs.h ../include/text.h
window.o: ../include/window.h ../include/file.h ../include/lib.h

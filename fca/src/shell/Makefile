
CROSS_COMPILE = arm-elf-

CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy

HOSTCC = gcc

CFLAGS = -I../include -ffreestanding -O2
CPPFLAGS = -I../include

OBJ = crt0.o shell.o text.o lib.o file.o load.o disass.o
SRC = crt0.S shell.c text.c lib.c file.c load.c disass.c

all: $(OBJ)

clean:
	rm -f *.o

depend:
	makedepend -Y -- -I../include -- $(SRC)


# DO NOT DELETE

crt0.o: ../include/gba-arm.h
shell.o: ../include/gba.h ../include/file.h ../include/text.h
shell.o: ../include/load.h
text.o: ../include/gba.h ../include/text.h
lib.o: ../include/gba.h ../include/lib.h
file.o: ../include/gba.h ../include/file.h ../include/text.h
load.o: ../include/gba.h ../include/file.h ../include/text.h
load.o: ../include/load.h

CROSS_COMPILE = arm-elf-

CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy

#CFLAGS = -Iinclude

CPPFLAGS = -I../../include -D__ASSEMBLY__

SRC = mapper0.S
OBJ = $(SRC:.S=.o)

all: $(OBJ)

clean:
	rm -f *.o

depend:
	makedepend $(CPPFLAGS) $(SRC)
# DO NOT DELETE

mapper0.o: ../../include/nes.h

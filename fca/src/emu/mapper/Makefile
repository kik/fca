CROSS_COMPILE = arm-elf-

CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy

#CFLAGS = -Iinclude

CPPFLAGS = -I../../include -D__ASSEMBLY__

SRC = mapper0.S mapper1.S mapper2.S mapper3.S mapper4.S \
	mapper9.S mapper10.S mapper21.S mapper66.S

OBJ = $(SRC:.S=.o)

all: mappers.o

mappers.o: $(OBJ)
	$(LD) -r -o $@ $^

clean:
	rm -f *.o

depend:
	makedepend $(CPPFLAGS) $(SRC)
# DO NOT DELETE

mapper0.o: ../../include/nes.h

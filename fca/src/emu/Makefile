
CPPFLAGS = -I../include -D__ASSEMBLY__

SRC = main.S cpu.S mapper.S ppu.S ppu-map.S ppu-palette.S \
      ppu-spr.S ppu-tile.S pad.S apu.S

OBJ = $(SRC:.S=.o)

SUBDIR = mapper

all: emu.o $(SUBDIR)

emu.o: $(OBJ)
	$(LD) -r -o $@ $^

.PHONY: $(SUBDIR)

$(SUBDIR):
	$(MAKE) -C $@

clean:
	rm -f *.o

depend:
	makedepend $(CPPFLAGS) $(SRC)

cpu.o: cpu-test.S

# DO NOT DELETE

main.o: ../include/nes.h
cpu.o: ../include/nes.h
mapper.o: ../include/nes.h
ppu.o: ../include/nes.h palette.S
pad.o: ../include/nes.h

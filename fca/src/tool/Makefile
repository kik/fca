CFLAGS = -I../include

all: addfile endfile fca-mkfs #nes-dasm selfont

addfile: addfile.c
	$(HOSTCC) -o $@ $< -I../include

endfile: endfile.c
	$(HOSTCC) -o $@ $< -I../include

fca-mkfs: fca-mkfs.c
	$(HOSTCC) -o $@ $< -I../include

clean:
	rm -f addfile endfile fca-mkfs


CC = gcc
CFLAGS = -I../include

all: addfile endfile fca-mkfs #nes-dasm selfont

addfile: addfile.c
	$(CC) -o $@ $< -I../include

endfile: endfile.c
	$(CC) -o $@ $< -I../include

clean:
	rm -f addfile endfile

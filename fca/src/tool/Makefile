
CC = gcc

all: addfile endfile

addfile: addfile.c
	$(CC) -o $@ $< -I../include

endfile: endfile.c
	$(CC) -o $@ $< -I../include

clean:
	rm -f addfile endfile

#include <stdio.h>
#include <string.h>
#include <sys/stat.h>

#include "file.h"

int
main(int argc, char **argv)
{
  struct file file;
  char *in_file;
  struct stat st;
  FILE *in;
  int c;

  if (argc != 3) {
    printf("usage: addfile filename fs-filename\n");
    return 1;
  }
  if (strlen(argv[2]) >= 16) {
    printf("filename < 16\n");
    return 1;
  }
  memset(file.name, 0, sizeof file.name);
  strcpy(file.name, argv[2]);
  if (stat(argv[1], &st) < 0) {
    perror(argv[1]);
  }
  file.length = st.st_size;
  in = fopen(argv[1], "rb");
  if (!in) {
    perror(argv[1]);
    return 1;
  }
  fwrite(&file, sizeof file, 1, stdout);
  while ((c = fgetc(in)) != EOF)
    putchar(c);

  switch (file.length & 3) {
  case 1: putchar(0);
  case 2: putchar(0);
  case 3: putchar(0);
  }
  if (ferror(stdout) || ferror(in)) {
    perror("I/O error\n");
    return 1;
  }
  return 0;
}

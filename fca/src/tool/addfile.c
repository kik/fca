#include <stdio.h>
#include <string.h>
#include <sys/stat.h>

#include "file.h"

int
addfile(FILE *out, char *in, char *name, char *ext)
{
  struct file_header file;
  FILE *f;
  struct stat st;
  int c;

  memset(&file, 0, sizeof file);

  file.magic = FILE_MAGIC;
  strncpy(file.name, name, MAX_NAME_LEN);
  strncpy(file.ext, ext, MAX_EXT_LEN);

  if (stat(in, &st) < 0) {
    return 1;
  }

  file.length = st.st_size;
  f = fopen(in, "rb");
  if (!f)
    return 1;

  fwrite(&file, sizeof file, 1, out);
  while ((c = fgetc(f)) != EOF)
    fputc(c, out);

  switch (file.length & 3) {
  case 1: fputc(0, f);
  case 2: fputc(0, f);
  case 3: fputc(0, f);
  }

  fclose(f);
  return 0;
}

int
main(int argc, char **argv)
{
  char *name, *ext;

  if (argc != 3) {
    printf("usage: addfile filename name\n");
    return 1;
  }

  name = argv[2];
  ext = strchr(argv[2], '.');
  if (ext)
    *ext++ = '\0';
  else
    ext = "???";

  if (addfile(stdout, argv[1], name, ext)) {
    perror(argv[1]);
    exit(1);
  }

  return 0;
}

#include <stdio.h>

#include "file.h"

int
main(int argc, char **argv)
{
  struct file_header file;

  memset(&file, 0, sizeof file);
  file.magic = FILE_END_MAGIC;
  fwrite(&file, sizeof file, 1, stdout);
  return 0;
}

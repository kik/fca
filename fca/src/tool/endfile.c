#include <stdio.h>

#include "file.h"

int
main(int argc, char **argv)
{
  struct file file;

  memset(&file, 0, sizeof file);
  fwrite(&file, sizeof file, 1, stdout);
  return 0;
}

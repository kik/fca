#include "gba.h"
#include "file.h"
#include "text.h"

void
init_file_system()
{
}


void *
find_file(char *name, struct file *f)
{
  struct file *p = (struct file *)&_rom_end;

  while (p->length) {
    if (strcmp(p->name, name) == 0) {
      if (f)
	*f = *p;
      return p + 1;
    }
    p = (struct file *)((char *)(p + 1) + ((p->length + 3) & ~3));
  }
}

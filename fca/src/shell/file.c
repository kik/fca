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
  return 0;
}

void *
select_nes_file(struct file *f)
{
  struct file *p = (struct file *)&_rom_end;
  volatile int *key = (int *)0x04000130;

  while (p->length) {
    char *q;

    q = strchr(p->name, '.');
    if (q && strcmp(q, ".nes") == 0) {
      printf("%s?", p->name);
      for (;;) {
	int k = *key;
	if (!(k & 1)) {
	  if (f) *f = *p;
	  return p + 1;
	} else if (!(k & 2)) {
	  while (! (*key & 2))
	    ;
	  printf("\n");
	  break;
	}
      }
    }
    p = (struct file *)((char *)(p + 1) + ((p->length + 3) & ~3));
  }
  return 0;
}

#include "gba.h"
#include "file.h"
#include "text.h"

static struct file_header *first_file;

static struct file_header *
next(struct file_header *p)
{
  int addr = (int)&p[1];
  int len = (p->length + 3) & ~3;
  
  p = (struct file_header *)(addr + len);

  if (p->magic == FILE_END_MAGIC)
    return 0;
  if (p->magic == FILE_MAGIC)
    return p;
  else
    preinit_error();
}

void
init_file_system()
{
  struct file_header *p;

  first_file = (struct file_header *)&_rom_end;
  if (first_file->magic != FILE_MAGIC)
    preinit_error();

  // check fs
  for (p = first_file; p; p = next(p))
    ;
}

static void
make_file(struct file *f, struct file_header *p, int fileno)
{
  f->fileno = fileno;
  memcpy(f->name, p->name, MAX_NAME_LEN);
  memcpy(f->ext,  p->ext,  MAX_EXT_LEN);
  f->start = &p[1];
  f->length = p->length;
  f->header = p;
}

void *
open_file(char *name, char *ext, struct file *f)
{
  struct file ff;
  void *start;

  for (start = next_file(&ff, 0); start; start = next_file(&ff, &ff)) {
    if (namecmp(&ff, name) && extcmp(&ff, ext)) {
      if (f) *f = ff;
      return start;
    }
  }
  return 0;
}

void *
open_fileno(int fileno, struct file *f)
{
  struct file ff;
  void *start;

  for (start = next_file(&ff, 0); start; start = next_file(&ff, &ff)) {
    if (ff.fileno == fileno) {
      if (f) *f = ff;
      return start;
    }
  }
  return 0;
}

void *
next_file(struct file *f, struct file *prev)
{
  struct file_header *p;
  int fno;

  fno = prev? prev->fileno + 1: 0;
  p = prev? next(prev->header): first_file;
  if (!p)
    return 0;

  make_file(f, p, fno);
  return f->start;
}

int
namecmp(struct file *f, char *name)
{
  //return strcmp(f->name, name) == 0;
  return strncasecmp(f->name, name, MAX_NAME_LEN) == 0;
}

int
extcmp(struct file *f, char *ext)
{
  //return strcmp(f->ext, ext) == 0;
  return strncasecmp(f->ext, ext, MAX_EXT_LEN) == 0;
}

struct save_file_super save_file_super;

int
init_save_file_system()
{
  int i;
  int sum, *pp;

  memcpy8(&save_file_super, (void *)0x0E000000, sizeof save_file_super);

  if (save_file_super.magic != SAVE_SUPER_MAGIC)
    return -1;

  // 和のようには見えないが，てきとー
  sum = 0;
  pp = (int *)&save_file_super;
  for (i = 0; i < (sizeof save_file_super) / 4; i++)
    sum ^= pp[i];

  if (sum)
    return -1;
  
  for (i = 0; i < MAX_SAVE_FILE; i++) {
    long m = save_file_super.header[i].magic;
    if (m != FILE_MAGIC && m != FILE_END_MAGIC)
      return -1;
  }

  return 0;
}

void
format_save_file_system()
{
  int i;
  int sum, *p;

  memset(save_file_super, 0, sizeof save_file_super);
  save_file_super.magic = SAVE_SUPER_MAGIC;
  for (i = 0; i < MAX_SAVE_FILE; i++)
    save_file_super.header[i].magic = FILE_END_MAGIC;
  
  sum = 0;
  p = (int *)&save_file_super;
  for (i = 0; i < (sizeof save_file_super) / 4; i++)
    sum ^= p[i];

  save_file_super.sum = sum;
  memcpy8((void *)0x0E000000, &save_file_super, sizeof save_file_super);
}

void *
open_save_file(int n, struct file *f)
{
  void *start;
  struct save_file_header *p;

  if (n <0 || n >= MAX_SAVE_FILE)
    return 0;

  p = &save_file_super.header[n];
  if (p->magic == FILE_END_MAGIC)
    return 0;

  start = (void *)(0x0E000000 + (n + 1) * SAVE_FILE_LEN);
  if (f) {
    f->fileno = n;
    memcpy(f->name, p->name, MAX_NAME_LEN);
    memcpy(f->ext,  p->ext, MAX_EXT_LEN);
    f->start = start;
    f->length = SAVE_FILE_LEN;
    f->header = 0;
  }
  return start;
}

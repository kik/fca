#ifndef FILE_H
#define FILE_H

struct file {
  char name[16];
  int length;
};

void init_file_system();

void *find_file(char *name, struct file *f);

#endif

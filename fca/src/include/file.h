#ifndef FILE_H
#define FILE_H

#define FILE_MAGIC     0x04174170
#define FILE_END_MAGIC 0x41700417
#define MAX_NAME_LEN 32
#define MAX_EXT_LEN   4

#define SAVE_SUPER_MAGIC 0xA838861A
#define SAVE_FILE_LEN  0x2000
/* 64KBまで保存できる
 * ひとつ8KBなので7つまで。
 */
#define MAX_SAVE_FILE  7

struct file_header {
  long magic;
  char name[MAX_NAME_LEN];
  char ext[MAX_EXT_LEN];
  long length;
};

struct save_file_header {
  long magic;
  char name[MAX_NAME_LEN];
  char ext[MAX_EXT_LEN];
};

struct save_file_super {
  long magic;
  struct save_file_header header[MAX_SAVE_FILE];
  long sum;
};

#define DEV_ROM  1
#define DEV_RAM  2

struct file {
  int dev;
  int fileno;
  char name[MAX_NAME_LEN];
  char ext[MAX_EXT_LEN];
  void *start;
  int length;
  
  struct file_header *header;
};

void init_file_system();

int  init_save_file_system();

void format_save_file_system();

void *open_file(char *name, char *ext, struct file *f);

void *open_fileno(int fileno, struct file *f);

void *next_file(struct file *f, struct file *prev);

void *open_save_file(int n, struct file *f);

int write_save_file(char *name, char *ext, int n);

int namecmp(struct file *f, char *name);

int extcmp(struct file *f, char *ext);

#endif

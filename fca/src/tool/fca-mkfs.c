/*
 * ファミコンアドバンス
 * ファイルシステム作成プログラム
 *
 * このソースは一応動くが非常にてきとう。
 *
 * 使用上の注意
 * ***リトルエンディアン***でないと動かない。
 *
 * カレントディレクトリに配布したファイルを置いて使うこと。
 */
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define FILE_MAGIC     0x04174170
#define FILE_END_MAGIC 0x41700417
#define MAX_NAME_LEN 32
#define MAX_EXT_LEN   4

struct file_header {
  long magic;
  char name[MAX_NAME_LEN];
  char ext[MAX_EXT_LEN];
  long length;
};

void
copy_file(FILE *out, char *in_file)
{
  int c;
  FILE *in = fopen(in_file, "rb");

  if (!in) {
    perror(in_file);
    exit(1);
  }

  while ((c = fgetc(in)) != EOF)
    fputc(c, out);

  fclose(in);
}

int
file_length(char *file)
{
  struct stat st;

  if (stat(file, &st) < 0) {
    perror(file);
    exit(1);
  }
  return st.st_size;
}

void
add_file(FILE *out, char *in, char *name, char *ext)
{
  struct file_header file;

  printf("%s %s %s\n", in, name, ext);
  memset(&file, 0, sizeof file);

  file.magic = FILE_MAGIC;
  strncpy(file.name, name, MAX_NAME_LEN - 1);
  strncpy(file.ext, ext, MAX_EXT_LEN - 1);
  file.length = file_length(in);

  fwrite(&file, sizeof file, 1, out);
  copy_file(out, in);

  // 4バイトにアラインすること
  switch (file.length & 3) {
  case 1: fputc(0, out);
  case 2: fputc(0, out);
  case 3: fputc(0, out);
  }
}

void
end(FILE *out)
{
  struct file_header file;

  memset(&file, 0, sizeof file);
  file.magic = FILE_END_MAGIC;
  fwrite(&file, sizeof file, 1, out);
}

char *system_files[] = {
  "emu.bin",     "emu",     "bin",
  "emuslow.bin", "emuslow", "bin",
  "font.dat",    "font",    "dat",
  "mapper0.bin", "mapper0", "bin",
  "mapper1.bin", "mapper1", "bin",
  "mapper2.bin", "mapper2", "bin",
  "mapper3.bin", "mapper3", "bin",
  "mapper4.bin", "mapper4", "bin",
  0
};

int
main(int argc, char **argv)
{
  FILE *out;
  int i;

  if (argc < 3) {
    printf("usage: fca-mkfs out-file file1 file2  ...\n");
    exit(1);
  }

  out = fopen(argv[1], "wb");
  if (!out) {
    perror(argv[1]);
    exit(1);
  }
  
  copy_file(out, "shell.bin");
  for (i = 0; system_files[i]; i += 3)
    add_file(out, system_files[i], system_files[i + 1], system_files[i + 2]);

  for (i = 2; i < argc; i++) {
    char *s = strdup(argv[i]);
    char *t, *u;
    
    t = basename(s);
    u = strrchr(s, '.');
    if (u) *u++ = 0;
    else u = "???";

    add_file(out, argv[i], t, u);
    free(s);
  }

  end(out);

  fclose(out);
  return 0;
}


/*
 * ファミコンアドバンス
 * ファイルシステム作成プログラム
 *
 * このソースは一応動くが非常にてきとう。
 *
 * 使用上の注意
 * ***リトルエンディアン***でないと動かない。
 *
 */
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <getopt.h>

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

void
usage()
{
  printf("usage: fca-mkfs [-c] [-b base-file] out-file file1 file2 ...\n");
  exit(1);
}

int
main(int argc, char **argv)
{
  FILE *out;
  int c;
  char *base_file = "shell.bin";
  int  dont_close = 0;

  while ((c = getopt(argc, argv, "cb:")) >= 0) {
    switch (c) {
    case 'c': dont_close = 1; break;
    case 'b': base_file = optarg; break;
    default:
      usage();
    }
  }

  if (optind >= argc)
    usage();

  out = fopen(argv[optind], "wb");
  if (!out) {
    perror(argv[optind]);
    exit(1);
  }
  
  copy_file(out, base_file);

  for (optind++; optind < argc; optind++) {
    char *s = strdup(argv[optind]);
    char *t, *u;
    
    t = basename(s);
    u = strrchr(s, '.');
    if (u) *u++ = 0;
    else u = "???";

    add_file(out, argv[optind], t, u);
    free(s);
  }

  if (!dont_close)
    end(out);

  fclose(out);
  return 0;
}


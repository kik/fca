#include <stdarg.h>
#include "gba.h"
#include "text.h"
#include "file.h"

#if 0
#define NO_TEXT
#endif

static unsigned short *text_tile_table;
static unsigned char *font_data;
static int cur_x, cur_y;

int
init_text_console(int bkg, int tile, int map)
{
  int i;
  unsigned short *p;

  font_data = find_file("font.dat", 0);
  if (! font_data) {
    return -1;
  }

  _ioreg[4 + bkg] = (map << 8) | (tile << 2);
  
  p = VRAM_MAP_TABLE(map);
#if 1
  for (i = 0; i < 32 * 32; i++) {
    p[i] = 0xF000 | i;
#if 0
    p[i + 0x400] = 0xE000 | i;
    p[i + 0x800] = 0xD000 | i;
    p[i + 0xC00] = 0xC000 | i;
#endif
  }
#else
  for (i = 0; i < 32 * 32; i++)
    p[i] = i + 512;
#endif
  text_tile_table = p = VRAM_TILE_SET(tile);
  for (i = 0; i < 32 * 32 * 8; i++)
    p[i] = 0;

  cur_x = cur_y = 0;
  return 0;
}

void
scroll()
{
#ifndef NO_TEXT
  short *p;
  int i, j;

  p = text_tile_table;

  for (i = 0; i < 32 * 19 * 16; i++)
    p[i] = p[i + 32 * 16];
  for (j = 0; j < 32 * 16; j++, i++)
    p[i] = 0;
#endif
}

int
putcharxy(char *c, int x, int y)
{
#ifndef NO_TEXT
  short *p;
  short *dst;
  int pos;
  int i;

  if (*c & 0x80) {
    pos = (c[0] - 0xA0) * 0x60 + c[1] - 0xA0;
  } else {
    pos = c[0] - 0x20;
  }
  p = (short *) &font_data[pos * 32];
  dst = text_tile_table + (x + y * 32) * 16;
  for (i = 0; i < 16; i++)
    dst[i] = p[i];

#endif
  if (*c & 0x80)
    return 2;
  else
    return 1;
}

int
putchar(char *c)
{
  if (c[0] == '\n') {
    if (cur_y == 19)
      scroll();
    else
      cur_y++;
    cur_x = 0;
    return 1;
  } else {
    return putcharxy(c, cur_x++, cur_y);
  }
}

void
putsxy(char *s, int x, int y)
{
  while (*s) {
    if (s[0] == '\n') {
      y++;
      x = 0;
      if (y == 20)
	y = 0;
    } else {
      s += putcharxy(s, x, y);
      x++;
    }
  }
}

void
puts(char *s)
{
  while (*s) {
    s += putchar(s);
  }
  putchar("\n");
}

void
puthex(int x)
{
  char n = '0';
  char a = 'A';

  if (x < 10) {
    n += x;
    putchar(&n);
  } else {
    a += x - 10;
    putchar(&a);
  }
}

void
printf(char *fmt, ...)
{
  va_list va;

  va_start(va, fmt);
  while (*fmt) {
    if (*fmt != '%') {
      fmt += putchar(fmt);
    } else {
      fmt++;
      switch (*fmt) {
      default:
      case '%':
	putchar("%");
	break;
      case 'x':
	{
	  int v = va_arg(va, int);
	  int nonzero = 0;
	  int s = 28;
	  int i;

	  for (i = 0; i < 8; i++) {
	    if (nonzero || ((v >> s) & 0xF)) {
	      puthex((v >> s) & 0xF);
	      nonzero = 1;
	    }
	    s -= 4;
	  }
	  if (!nonzero)
	    putchar("0");
	}
	break;
      case 's':
	{
	  char *s = va_arg(va, char *);

	  while (*s) {
	    s += putchar(s);
	  }
	}
      }
      fmt++;
    }
  }
  va_end(va);
}

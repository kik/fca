#include <stdarg.h>
#include "gba.h"
#include "gba-regs.h"
#include "file.h"
#include "vram.h"
#include "window.h"

static const unsigned char *ch_table_src[] = {
  "¢£", "¢£", "¢£", "¢£", "¢£", "¢£", "¢£", "¢£", // 00
  "¢£", "¢£", "¢£", "¢£", "¢£", "¢£", "¢£", "¢£", // 08
  "¢£", "¢£", "¢£", "¢£", "¢£", "¢£", "¢£", "¢£", // 10
  "¢£", "¢£", "¢£", "¢£", "¢£", "¢£", "¢£", "¢£", // 18
  "°°", "°™", "°…", "°Ù", "°", "°Û", "°ı", "°«", // 20
  "° ", "°À", "°ˆ", "°‹", "°§", "°›", "°•", "°ø", // 28
  "£∞", "£±", "£≤", "£≥", "£¥", "£µ", "£∂", "£∑", // 30
  "£∏", "£π", "°ß", "°®", "°„", "°·", "°‰", "°©", // 38
  "°˜", "£¡", "£¬", "£√", "£ƒ", "£≈", "£∆", "£«", // 40
  "£»", "£…", "£ ", "£À", "£Ã", "£Õ", "£Œ", "£œ", // 48
  "£–", "£—", "£“", "£”", "£‘", "£’", "£÷", "£◊", // 50
  "£ÿ", "£Ÿ", "£⁄", "°Œ", "°¿", "°œ", "°∞", "°≤", // 58
  "°∆", "£·", "£‚", "£„", "£‰", "£Â", "£Ê", "£Á", // 60
  "£Ë", "£È", "£Í", "£Î", "£Ï", "£Ì", "£Ó", "£Ô", // 68
  "£", "£Ò", "£Ú", "£Û", "£Ù", "£ı", "£ˆ", "£˜", // 70
  "£¯", "£˘", "£˙", "°–", "°√", "°—", "°¡", "¢£", // 78
};

static short ch_table[128];

static short text_screen[20][32];

static short
cc(unsigned char **s)
{
  unsigned char *p = *s;
  unsigned short r;

  if (p[0] >= 128) {
    r = (p[0] << 7) + p[1] - (0xA2 << 7) + 0xF000;
    *s += 2;
  } else {
    r = ch_table[p[0]];
    (*s)++;
  }
  return r;
}

static short
hex(int v)
{
  short v0 = 0xF100 + '0';
  short vA = 0xF100 + 'A';

  if (v < 10)
    return v0 + v;
  else
    return vA + v - 10;
}

void
init_font()
{
  int *p;
  int *dst = (int *)0x06008000;
  int i;

  p = open_file("font", "dat", 0);
  if (!p) return;

  for (i = 0; i < 0x80 * 5 * 8; i++)
    dst[i] = p[i];

  for (i = 0; i < 128; i++) {
    unsigned char *s;

    s = (unsigned char *)ch_table_src[i];
    ch_table[i] = cc(&s);
  }

  writeh(GBA_DISP_CR, GBA_DISP_CR_MODE(0) | GBA_DISP_CR_ENB_BG0);
  writeh(GBA_BGn_CR(0), GBA_BG_CR_MAP_ADDR(0x1F) | GBA_BG_CR_TILE_ADDR(2));

  write_palette(0xF1, RGB(0, 0, 0));
  write_palette(0xFF, RGB(31, 31, 31));
}

void
refresh_screen()
{
  short *dst = (short *)0x0600F800;
  short *src = &text_screen[0][0];
  int i;

  for (i = 0; i < 32 * 20; i++)
    dst[i] = src[i];
}

void
putcxy(short c, int x, int y)
{
  text_screen[y][x] = c;
}

void
putsxy(unsigned char *s, int x, int y)
{
  int dx = 0;

  while (*s) {
    if (*s == '\n') {
      dx = 0;
      y++; s++;
    } else {
      putcxy(cc(&s), x + dx, y);
      dx++;
    }
  }
}

void
printfxy(int x, int y, unsigned char *s, ...)
{
  va_list va;
  int dx = 0;

  va_start(va, s);
  while (*s) {
    if (*s == '\n') {
      dx = 0;
      y++; s++;
    } else if (*s == '%') {
      switch (s[1]) {
      case '%':
	putcxy(cc(&s), x + dx, y);
	s++;
	dx++;
	break;
      default:
	putcxy(cc(&s), x + dx, y);
	dx++;
	break;
      case 's':
	{
	  unsigned char *ss;
	  ss = va_arg(va, char *);
	  while (*ss) {
	    if (*ss == '\n') {
	      dx = 0;
	      y++; ss++;
	    } else {
	      putcxy(cc(&ss), x + dx, y);
	      dx++;
	    }
	  }
	}
	s += 2;
	break;
      case 'x':
	{
	  int v = va_arg(va, int);
	  int nonzero = 0;
	  int s = 28;
	  int i;
	  
	  for (i = 0; i < 8; i++) {
	    if (nonzero || ((v >> s) & 0xF)) {
	      putcxy(hex((v >> s) & 0xF), x + dx, y);
	      dx++;
	      nonzero = 1;
	    }
	    s -= 4;
	  }
	  if (!nonzero) {
	    putcxy(hex(0), x + dx, y);
	    dx++;
	  }
	}
	s += 2;
	break;
      case 'd':
	{
	  int v = va_arg(va, int);
	  int neg;
	  int n;
	  int i;
	  
	  if (v >= 100000) {
	    putsxy(" §ø§Ø§µ§Û", x + dx, y);
	    dx += 5;
	    goto end_d;
	  } else if (v <= -10000) {
	    putsxy("-§ø§Ø§µ§Û", x + dx, y);
	    dx += 5;
	    goto end_d;
	  }
	  for (i = 0; i < 5; i++)
	    putsxy(" ", x + dx + i, y);

	  neg = 0;
	  if (v < 0) {
	    v = -v;
	    neg = 1;
	  }
	  for (i = 0; i < 5; i++) {
	    n = v % 10; v = v / 10;
	    putcxy(hex(n), x + dx + 4 - i, y);
	    if (!v) {
	      if (neg) putsxy("-", x + dx + 3 - i, y);
	      break;
	    }
	  }
	  dx += 5;
	}
      end_d:
	s += 2;
	break;
      }
    } else {
      putcxy(cc(&s), x + dx, y);
      dx++;
    }
  }
  va_end(va);
}

void
draw_rect(int x, int y, int w, int h)
{
  int i, j;

  putcxy(FONT_LINE_UL, x, y);
  for (i = 1; i < w - 1; i++)
    putcxy(FONT_LINE_U, x + i, y);
  putcxy(FONT_LINE_UR, x + i, y);

  for (j = 1; j < h - 1; j++) {
    putcxy(FONT_LINE_L, x, y + j);
    for (i = 1; i < w - 1; i++)
      putcxy(FONT_TOFU_B, x + i, y + j);
    putcxy(FONT_LINE_R, x + i, y + j);
  }

  putcxy(FONT_LINE_DL, x, y + j);
  for (i = 1; i < w - 1; i++)
    putcxy(FONT_LINE_D, x + i, y + j);
  putcxy(FONT_LINE_DR, x + i, y + j);
}

void
clear_screen()
{
  int i, j;
  
  for (i = 0; i < 20; i++)
    for (j = 0; j < 30; j++)
      putcxy(FONT_TOFU_TR, j, i);
}

static int test_n;

void
test_draw(struct window *wn)
{
  draw_rect(wn->x, wn->y, wn->w, wn->h);
  printfxy(wn->x + 1, wn->y + 1, "§€§≤°º§È\n\n§€§≤§€§≤\n\n%d", test_n);
}

static char *menu_items[] = {
  "§·§À§Â0", "§·§À§Â1", "§·§À§Â2", "§·§À§Â3",
  "§·§À§Â4", "§·§À§Â5", "§·§À§Â6", "§·§À§Â7",
  "§·§À§Â8", "§·§À§Â9", "§·§À§ÂA", "§·§À§ÂB",
  "§·§À§ÂC", "§·§À§ÂD", "§·§À§ÂE", "§·§À§ÂF",
};

static char *
test_menu_item(struct menu_window *menu, int n)
{
  return menu_items[n];
}

void
font_test()
{
  struct message_window mwn;

  push_message_window(&mwn);
  set_message_widow(&mwn, "§€§≤°º");

  for (;;) {
    int ev;
    int sel;
    struct menu_window menu;

    while ((ev = run_message_window(&mwn, 0)))
      if (ev == EV_NEXT_MSG)
	break;
    if (yes_or_no())
      set_message_widow(&mwn, "§€§≤§È°º");
    else
      set_message_widow(&mwn, "§ø§Ï§—§Û§¿°º");

    push_menu_window(&menu, 2, 2, 10, 7, 3);
    //menu.menu_item = test_menu_item;
    while ((ev = run_menu_window(&menu, &sel)))
      ;
    pop_window(&menu.wn);
    if (sel < 0)
      set_message_widow(&mwn, "§€§≤§€§≤°º");
    else
      set_message_widow(&mwn, menu_items[sel]);
  }

#if 0
  struct window wn;
  int ev;

  push_window(&wn, 1, 1, 10, 18);
  wn.draw = test_draw;
  while ((ev = run_window(&wn, 0))) {
    switch (ev) {
    case EV_KEY_PRESS:
      if (yes_or_no()) {
	test_n++;
	wn.ev = 1 << EV_DRAW;
      }
      break;
    }
  }
  //draw_rect(1, 1, 10, 18);

  //printfxy(2, 2, "§€§≤§È\n\n%d\n\n%d\n\n%d\n\n%d", 99999, -1024, 417, -0);
#endif
}

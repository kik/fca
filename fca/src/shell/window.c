#include "gba.h"
#include "gba-regs.h"

#include "vram.h"
#include "window.h"

/*
 * DQみたいなUI
 *
 * あまりこったことはしない
 */


struct window *bottom = 0;
struct window *top = 0;

static int redraw_all;
static int prev_key;
static int cursor_counter;
static int cursor_visible;

void
push_window(struct window *wn, char x, char y, char w, char h)
{
  if (top)
    top->next = wn;
  else
    bottom = wn;
  top = wn;
  wn->next = 0;

  wn->x = x;
  wn->y = y;
  wn->w = w;
  wn->h = h;

  wn->draw = 0;

  wn->ev = 1 << EV_DRAW;
}

void
pop_window()
{
  struct window *p;
  if (top == bottom)
    top = bottom = 0;
  else {
    for (p = bottom; p->next != top; p = p->next)
      ;
    top = p;
    top->next = 0;
  }
  redraw_all = 1;
}

void
quit_window(struct window *wn)
{
  wn->ev |= (1 << EV_QUIT);
}

void
redraw_window(struct window *wn)
{
  wn->ev |= (1 << EV_DRAW);
}

static void
draw_window(struct window *wn)
{
  draw_rect(wn->x, wn->y, wn->w, wn->h);
  if (wn->draw)
    wn->draw(wn);
}

static int
wait_vblank()
{
  while (readh(GBA_DISP_Y) != 160)
    ;
}

static int
repeat_counter(int n, int press)
{
  return 0;
}

int
run_window(struct window *wn, int *param)
{
  struct window *p;
  int key;
  int press;
  int need_refresh = 0;

  if (wn->ev & (1 << EV_QUIT))
    return EV_QUIT;

  if (redraw_all) {
    clear_screen();
    for (p = bottom; p; p = p->next)
      draw_window(p);
    redraw_all = 0;
    need_refresh = 1;
  } else if (top->ev & (1 << EV_DRAW)) {
    draw_window(top);
    need_refresh = 1;
    top->ev ^= EV_DRAW;
  }

  wait_vblank();
  if (need_refresh)
    refresh_screen();

  key = ~readh(GBA_KEY) & 0x03FF;
  press = prev_key ^ key;
  press &= key;
  prev_key = key;

  if (repeat_counter(0, key & GBA_KEY_A))     press |= GBA_KEY_A;
  if (repeat_counter(1, key & GBA_KEY_B))     press |= GBA_KEY_B;
  if (repeat_counter(2, key & GBA_KEY_RIGHT)) press |= GBA_KEY_RIGHT;
  if (repeat_counter(3, key & GBA_KEY_LEFT))  press |= GBA_KEY_LEFT;
  if (repeat_counter(4, key & GBA_KEY_UP))    press |= GBA_KEY_UP;
  if (repeat_counter(5, key & GBA_KEY_DOWN))  press |= GBA_KEY_DOWN;

  if (press) {
    if (param)
      *param = press;
    return EV_KEY_PRESS;
  }

  if (--cursor_counter < 0) {
    cursor_counter = 20;
    cursor_visible = !cursor_visible;
    return EV_CURSOR;
  }

  return EV_NONE;
}

static void
show_cursor()
{
  cursor_visible = 1;
  cursor_counter = 20;
}

static void
draw_cursor(int x, int y)
{
  if (cursor_visible)
    putcxy(FONT_CUR_R, x, y);
}


static int yes_or_no_flag;

static void
yes_or_no_draw(struct window *wn)
{
  printfxy(wn->x + 1, wn->y + 1, " はい\n\n いいえ");
  draw_cursor(wn->x + 1, wn->y + (yes_or_no_flag? 1: 3));
}

int
yes_or_no()
{
  struct window wn;
  int ev;
  int key;

  yes_or_no_flag = 1;
  push_window(&wn, 24, 10, 6, 5);
  wn.draw = yes_or_no_draw;

  while ((ev = run_window(&wn, &key))) {
    switch (ev) {
    case EV_KEY_PRESS:
      if (key & GBA_KEY_A) {
	quit_window(&wn);
      } else if (key & GBA_KEY_B) {
	yes_or_no_flag = 0;
	quit_window(&wn);
      } else if (key & GBA_KEY_DOWN) {
	yes_or_no_flag = 0;
	show_cursor();
	redraw_window(&wn);
      } else if (key & GBA_KEY_UP) {
	yes_or_no_flag = 1;
	show_cursor();
	redraw_window(&wn);
      }
      break;
    case EV_CURSOR:
      redraw_window(&wn);
      break;
    }
  }
  pop_window();
  return yes_or_no_flag;
}


static void
draw_message_window(struct window *wn)
{
  struct message_window *mwn = (struct message_window *)wn;

  putsxy(mwn->msg, wn->x + 1, wn->y + 1, wn->w, wn->h);
}

void
push_message_window(struct message_window *mwn)
{
  push_window(&mwn->wn, 4, 11, 22, 9);
  mwn->msg = "";
  mwn->wn.draw = draw_message_window;
}

int
run_message_window(struct message_window *mwn, int *param)
{
  int ev;
  int key;

  ev = run_window(&mwn->wn, &key);
  if (ev == EV_KEY_PRESS) {
    if ((key & GBA_KEY_A) || (key & GBA_KEY_B))
      ev = EV_NEXT_MSG;
  }
  if (param) *param = key;
  return ev;
}

void
set_message_widow(struct message_window *mwn, char *msg)
{
  mwn->msg = msg;
  redraw_window(&mwn->wn);
}


static void
draw_menu(struct window *wn)
{
  struct menu_window *menu = (struct menu_window *)wn;
  int i;
  
  for (i = 0; i < menu->n_vis; i++) {
    if (menu->draw_item)
      menu->draw_item(menu, menu->top + i,
		      wn->x + 2, wn->y + i * 2 + 1);
  }
  if (menu->top > 0)
    putcxy(FONT_CUR_U, wn->x, wn->y);
  if (menu->top + menu->n_vis < menu->n)
    putcxy(FONT_CUR_D, wn->x + wn->w - 1, wn->y + wn->h - 1);
  draw_cursor(wn->x + 1, wn->y + (menu->sel - menu->top) * 2 + 1);
}

void
push_menu_window(struct menu_window *menu, int x, int y,
		    int w, int n, int n_vis)
{
  if (n < n_vis) n_vis = n;
  push_window(&menu->wn, x, y, w, n_vis * 2 + 1);
  menu->n = n;
  menu->n_vis = n_vis;
  menu->top = 0;
  menu->sel = 0;
  menu->wn.draw = draw_menu;
}

int
run_menu_window(struct menu_window *menu, int *param)
{
  int ev, key;

  ev = run_window(&menu->wn, &key);
  if (ev == EV_QUIT) {
    if (param) *param = -1;
    return EV_QUIT;
  }
  if (ev == EV_KEY_PRESS) {
    if (key & GBA_KEY_A) {
      if (param) *param = menu->sel;
      return EV_QUIT;
    } else if (key & GBA_KEY_B) {
      if (param) *param = -1;
      return EV_QUIT;
    } else if (key & GBA_KEY_UP) {
      if (menu->sel > 0) {
	if (menu->sel == menu->top)
	  menu->top--;
	menu->sel--;
	show_cursor();
	redraw_window(&menu->wn);
      }
    } else if (key & GBA_KEY_DOWN) {
      if (menu->sel < menu->n - 1) {
	if (menu->sel == menu->top + menu->n_vis - 1)
	  menu->top++;
	menu->sel++;
	show_cursor();
	redraw_window(&menu->wn);
      }
    } else if (key & GBA_KEY_LEFT) {
      // scroll up one page
      if (menu->top > 0) {
	menu->top -= menu->n_vis;
	menu->sel -= menu->n_vis;
	if (menu->top < 0)
	  menu->top = 0;
	if (menu->sel < 0)
	  menu->sel = 0;
	show_cursor();
	redraw_window(&menu->wn);
      }
    } else if (key & GBA_KEY_RIGHT) {
      if (menu->top + menu->n_vis < menu->n) {
	menu->top += menu->n_vis;
	menu->sel += menu->n_vis;
	if (menu->top + menu->n_vis >= menu->n)
	  menu->top = menu->n - menu->n_vis;
	if (menu->sel >= menu->n)
	  menu->sel = menu->n - 1;
	show_cursor();
	redraw_window(&menu->wn);
      }
    }
  }
  if (ev == EV_CURSOR)
    redraw_window(&menu->wn);

  if (param) *param = key;
  return ev;
}


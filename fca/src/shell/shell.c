#include "gba.h"
#include "gba-regs.h"

#include "file.h"
#include "load.h"
#include "window.h"
#include "text.h"
#include "struct.h"
#include "lib.h"

static struct file loaded_file;

static void *
nes_file(int nth, struct file *f)
{
  struct file ff;
  int n = 0;

  next_file(&ff, 0);
  do {
    if (extcmp(&ff, "nes")) {
      if (n == nth) {
	if (f) *f = ff;
	return f->start;
      }
      n++;
    }
  } while (next_file(&ff, &ff));

  return 0;
}

static void *
save_file(int nth, struct file *f)
{
  struct file ff;
  int n = 0;
  int i;

  for (i = 0; i < MAX_SAVE_FILE; i++) {
    open_save_file(i, &ff);
    if (extcmp(&ff, "sav")) {
      if (n == nth) {
	if (f) *f = ff;
	return f->start;
      }
      n++;
    }
  }

  next_file(&ff, 0);
  do {
    if (extcmp(&ff, "sav")) {
      if (n == nth) {
	if (f) *f = ff;
	return f->start;
      }
      n++;
    }
  } while (next_file(&ff, &ff));

  return 0;
}

static void *
save_file_writable(int n, struct file *f)
{
  return open_save_file(n, f);
}

static void *
select_save_file(char *name, char *ext, struct file *f)
{
  int i;

  i = select_file("セーブするファイルのせんたく", 16, save_file_writable);
  if (i < 0)
    return 0;

  if (!write_save_file(name, ext, i))
    return 0;

  return open_save_file(i, f);
}

#ifdef KOMASAI
static void *
komasai_select_save_file(char *name, char *ext, struct file *f)
{
  int i;
  struct file ff;

  for (i = 0; i < MAX_SAVE_FILE; i++) {
    if (open_save_file(i, &ff) && namecmp(&ff, name) && extcmp(&ff, ext)) {
      *f = ff;
      return f->start;
    }
  }
  for (i = 0; i < MAX_SAVE_FILE; i++) {
    if (!open_save_file(i, &ff)) {
      write_save_file(name, ext, i);
      return open_save_file(i, f);
    }
  }
  return 0;
}
#endif

static void
load_file()
{
  int i;

  i = select_file("ゲームのせんたく", 10, nes_file);

  if (i >= 0) {
    struct file f;
    struct nes_header *p;
    p = nes_file(i, &f);

    loaded_file = f;
#ifndef KOMASAI
    if (nes_has_save_ram(p)) {
      struct file s;
      if (select_save_file(f.name, "sav", &s))
	run_emulator(p, &s, 0);
      else {
	warn(WARN "セーブデータはほぞんされません。\n\n"
	     "Lメニューからほぞんできます。");
	run_emulator(p, 0, 0);
      }
    } else {
      run_emulator(p, 0, 0);
    }
#else
#if 1
    if (nes_has_save_ram(p)) {
      struct file s;
      if (komasai_select_save_file(f.name, "sav", &s))
	run_emulator(p, &s, &s);
    } else
#endif
      run_emulator(p, 0, 0);
#endif
    init_font();
  }
}

static void
load_save_file()
{
  int i;

  i = select_file("ロードするファイルのせんたく", 16, save_file);

  if (i >= 0) {
    struct file f, n;
    void *p;

    save_file(i, &f);
    p = open_file(f.name, "nes", &n);
    loaded_file = n;
    if (!p)
      return;
    if (f.dev == DEV_RAM) {
      run_emulator(p, &f, &f);
    } else {
      run_emulator(p, 0 , &f);
    }
    init_font();
  }
}

static char *main_menu_item[] = {
  "つづきから",
  "はじめから",
};

static void
draw_main_menu(struct menu_window *menu, int n, int x, int y)
{
  printfxy(x, y, "%s", main_menu_item[n]);
}

static void
draw_version(struct window *wn)
{
  printfxy(wn->x + 1, wn->y + 1, "ファミコンアドバンス KOMASAI ヴァージョン");
}

static void
main_menu()
{
#ifdef KOMASAI
  struct window win;

  push_window(&win, 0, 17, 30, 3);
  win.draw = draw_version;

  while (run_window(&win, 0))
    load_file();
#else
  struct menu_window menu;

  for (;;) {
    int n;

    push_menu_window(&menu, 2, 2, 8, 2, 2);

    menu.draw_item = draw_main_menu;
    while (run_menu_window(&menu, &n))
      ;

    pop_window(&menu.wn);

    switch (n) {
    case 0:
      load_save_file();
      break;
    case 1:
      load_file();
      break;
    }
  }
#endif
}

static void
query_format()
{
  if (no_or_yes_message("セーブデータがこわれています。\n\n"
			"フォーマットしますか？")) {
    format_save_file_system();
  } else {
    warn(WARN "キャンセルしました。\n\n"
	 "バックアップをとるなりして\n\n"
	 "さいきどうしてください。");
  }
}

int
start_shell(void)
{
#if 0
  int i, j;
  struct file f;
#endif
  writeh(0x204, 0x4004);

  init_file_system();

  init_font();

  if (init_save_file_system() < 0)
    query_format();

#if 0
  i = j = 0;
  while (nes_file(i, &f)) {
    if (nes_has_save_ram(f.start)) {
      write_save_file(f.name, "sav", j);
      j++;
    }
    i++;
  }
#endif
  while (1)
    main_menu();
}


static char *L_menu_text[] = {
  "もどる",
  "リセット",
#ifndef KOMASAI
  "ほぞん",
#endif
  "しゅうりょう",
};

static void
draw_L_menu(struct menu_window *menu, int n, int x, int y)
{
  printfxy(x, y, "%s", L_menu_text[n]);
}

void
L_button_menu(struct L_menu *p)
{
  struct menu_window menu;

  init_font();

  memset(p, 0, sizeof *p);

  for (;;) {
    int n;

#ifdef KOMASAI
    push_menu_window(&menu, 2, 2, 9, 3, 3);
#else
    push_menu_window(&menu, 2, 2, 9, 4, 4);
#endif

    menu.draw_item = draw_L_menu;
    while (run_menu_window(&menu, &n))
      ;

    pop_window(&menu.wn);

    switch (n) {
    case 1:
      p->reset = 1;
      goto end;
    case 2:
#ifndef KOMASAI
      if (nes_has_save_ram(loaded_file.start)) {
	struct file f;
	
	if (select_save_file(loaded_file.name, "sav", &f)) {
	  p->save_file_write = f.start;
	  goto end;
	}
      }
      break;
    case 3:
#endif
      p->exit = 1;
      goto end;
    case 0:
    case -1:
      goto end;
    }
  }
 end:
  while ((readh(GBA_KEY) & (GBA_KEY_B | GBA_KEY_A)) != (GBA_KEY_A | GBA_KEY_B))
    ;
}

void
panic(int op, int pc, unsigned char *sp, void *p)
{
  while (1)
    ;
}

void
panic_from_int()
{
  while (1)
    ;
}

void
preinit_error()
{
  while (1)
    ;
}

void
printf(char *fmt, ...)
{
}

void
panic_no_such_file(char *name, char *ext)
{
  while (1)
    ;
}

void
cpu_test_ok()
{
  while (1)
    warn("cpu test ok");
}

void
cpu_test_fail(int n)
{
  while (1)
    warn("cpu test fail %d", n);
}

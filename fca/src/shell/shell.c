#include "gba.h"
#include "gba-regs.h"

#include "file.h"
#include "load.h"
#include "window.h"
#include "vram.h"

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

  i = select_file(save_file_writable);
  if (i < 0)
    return 0;

  if (!write_save_file(name, ext, i))
    return 0;

  return open_save_file(i, f);
}

static void
load_file()
{
  int i;

  i = select_file(nes_file);

  if (i >= 0) {
    struct file f;
    struct nes_header *p;
    p = nes_file(i, &f);

    if (nes_has_save_ram(p)) {
      struct file s;
      if (select_save_file(f.name, "sav", &s))
	run_emulator(p, &s, 0);
      else
	run_emulator(p, 0, 0);
    } else {
      run_emulator(p, 0, 0);
    }
  }
}

static void
load_save_file()
{
  int i;

  i = select_file(save_file);

  if (i >= 0) {
    struct file f;
    void *p;

    save_file(i, &f);
    p = open_file(f.name, "nes", 0);
    if (!p)
      return;
    if (f.dev == DEV_RAM) {
      run_emulator(p, &f, &f);
    } else {
      run_emulator(p, 0 , &f);
    }
  }
}

static char *main_menu_item[] = {
  "つづきから",
  "はじめから",
  "そのほか",
  "たれ", "ぎゃ", "あう"
};

static void
draw_main_menu(struct menu_window *menu, int n, int x, int y)
{
  printfxy(x, y, "%s", main_menu_item[n]);
}

static void
main_menu()
{
  struct menu_window menu;

  for (;;) {
    int n;

    push_menu_window(&menu, 2, 2, 15, 6, 6);

    menu.draw_item = draw_main_menu;
    while (run_menu_window(&menu, &n))
      ;
    switch (n) {
    case 0:
      load_save_file();
      break;
    case 1:
      load_file();
      break;
    }

    pop_window(&menu.wn);
  }
}

static void
query_format()
{
  struct message_window mes;
  int ev;

  push_message_window(&mes);
  set_message_widow(&mes,
		    "セーブデータがこわれています。\n\n"
		    "フォーマットしますか？");
  while ((ev = run_message_window(&mes, 0))) {
    if (ev == EV_NEXT_MSG) {
      if (yes_or_no()) {
	format_save_file_system();
	quit_window(&mes.wn);
      } else {
	set_message_widow(&mes,
			  "キャンセルしました。\n\n"
			  "バックアップをとるなりして\n\n"
			  "さいきどうしてください。");
	while (run_message_window(&mes, 0))
	  ;
      }
    }
  }
  pop_window(&mes.wn);
}

int
start_shell(void)
{
  writeh(0x204, 0x4004);

  init_file_system();

  init_font();

  if (init_save_file_system() < 0)
    query_format();

  while (1)
    main_menu();
}


void
panic(int op, int pc, unsigned char *sp, void *p)
{
#if 0
  int i;

  _ioreg[0x104] = 0;
  _ioreg[0xBA / 2] = 0;
  _ioreg[0xC6 / 2] = 0;
  init_text_console(0, 2, 0x1C);

  _ioreg[0] = 0x0140;
  _ioreg[8] = 0;
  _ioreg[9] = 0;
  _ioreg[5] = 0x0704;
  for (i = 0; i < 32 * 32; i++)
    _vram[0x2000 + i] = i;

  printf("PANIC!!!\n");
  printf("OP: %x\n", op);
  printf("PC: %x(%x)\n", pc, p);
  printf("stack dump:\n");
  
  sp -= 32;
  for (i = 0; i < 4; i++, sp += 8)
    printf("%x %x %x %x %x %x %x %x\n", sp[0], sp[1], sp[2], sp[3],
	   sp[4], sp[5], sp[6], sp[7]);

  printf("---SP---\n");

  for (i = 0; i < 4; i++, sp += 8)
    printf("%x %x %x %x %x %x %x %x\n", sp[0], sp[1], sp[2], sp[3],
	   sp[4], sp[5], sp[6], sp[7]);

  compare_memory();
#endif
  while (1)
    ;
}

void
panic_from_int()
{
#if 0
  int i;
  int *p = (int *)0x03000000;

  _ioreg[0xBA / 2] = 0;
  _ioreg[0xC6 / 2] = 0;

  init_text_console(0, 2, 0x1C);

  _ioreg[0] = 0x0140;
  _ioreg[8] = 0;
  _ioreg[9] = 0;
  //_ioreg[4] = 0x1C08;
#if 0
  for (i = 0; i < 32 * 32; i++)
    _vram[0x2000 + i] = i;
#endif
  //printf("\n\n\n\n\n");
  printf("PANIC from int!!!\n");
  for (i = 0; i < 9; i++, p += 2)
    printf("%x %x\n", p[0], p[1]);

  compare_memory();
#endif
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

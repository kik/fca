#ifndef TEXT_H
#define TEXT_H

int init_text_console(int bkg, int tile, int map);

void scroll();

int putcharxy(char *c, int x, int y);
int putchar(char *c);
void putsxy(char *s, int x, int y);
void puts(char *s);
void printf(char *fmt, ...);

#endif

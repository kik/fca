#ifndef LIB_H
#define LIB_H

#include <stdarg.h>

int strlen(char *s);
char *strcpy(char *d, char *s);
char *strchr(char *s, int c);
int strcmp(const char *p, const char *q); 
int strncasecmp(const char *p, const char *q, int n);
int toupper(int c);


int memcpy(void *d, const void *s, int n);
int memcpy8(void *d, const void *s, int n);

int memcmp(void *a, void *b, int n);

int memset(void *d, int c, int n);

void sprintf(char *buf, char *fmt, ...);
void vsprintf(char *buf, char *fmt, va_list va);


#endif

#ifndef LIB_H
#define LIB_H

char *strcpy(char *d, char *s);
int strcmp(const char *p, const char *q); 

int memcpy(void *d, const void *s, int n);
int memcpy8(void *d, const void *s, int n);

int memcmp(void *a, void *b, int n);

int memset(void *d, int c, int n);

#endif

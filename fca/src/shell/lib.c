#include "gba.h"
#include "lib.h"

char *
strcpy(char *d, char *s)
{
  char *p = d;
  while ((*p++ = *s++))
    ;
  return d;
}

char *
strchr(char *p, char c)
{
  while (*p && *p != c)
    p++;
  return *p? p: 0;
}

int
strcmp(const char *p, const char *q)
{
  while (*p && *p == *q)
    p++, q++;
  return *p - *q;
}

int
strncasecmp(const char *p, const char *q, int n)
{
  while (n > 0 && *p && toupper(*p) == toupper(*q))
    p++, q++, n--;
  if (n > 0)
    return toupper(*p) - toupper(*q);
  else
    return 0;
}

int
toupper(int c)
{
  if ('a' <= c && c <= 'z')
    return c + 'A' - 'a';
  return c;
}

int
memcpy(void *d, const void *s, int n)
{
  char *d1 = d;
  const char *s1 = s;

  int i;
  for (i = 0; i < n; i++)
    d1[i] = s1[i];
  return n;
}

int
memcpy8(void *d, const void *s, int n)
{
  return memcpy(d, s, n);
}

int
memcmp(void *a, void *b, int n)
{
  char *c = a;
  char *d = b;
  int i;

  for (i = 0; i < n; i++)
    if (c[i] != d[i])
      return c[i] - d[i];
  return 0;
}

int
memset(void *d, int c, int n)
{
  char *p = d;
  int i;

  for (i = 0; i < n; i++)
    p[i] = c;
  
  return n;
}

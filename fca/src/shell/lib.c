#include "gba.h"
#include "lib.h"

int
strcmp(const char *p, const char *q)
{
  while (*p && *p == *q)
    p++, q++;
  return *p - *q;
}

int
memcpy(void *d, const void *s, int n)
{
  char *d1 = d;
  const char *s1 = s;

  int i;
  for (i = 0; i < n; i++)
    d1[i] = s1[i];
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

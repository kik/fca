#include <stdarg.h>
#include "gba.h"
#include "lib.h"
#include "file.h"

int
strlen(char *s)
{
  int len = 0;
  while (*s++)
    len++;
  return len;
}

char *
strcpy(char *d, char *s)
{
  char *p = d;
  while ((*p++ = *s++))
    ;
  return d;
}

char *
strchr(char *p, int c)
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

/*
 * 簡単なsprintf
 *
 *
 *
 */
void
sprintf(char *buf, char *fmt, ...)
{
  va_list va;
  va_start(va, fmt);
  vsprintf(buf, fmt, va);
  va_end(va);
}

void
vsprintf(char *dst, char *fmt, va_list va)
{
  while (*fmt) {
    if (*fmt != '%')
      *dst++ = *fmt++;
    else {
      char flag = 0;
      int width = 0;
      int prec = 0;
      char format;

      char buf[256];
      int len = 0;
      int xtype;
      char *p = 0;
      int i;

      union {
	int n;
	char *s;
	struct file *f;
      } value;

      while (*++fmt) {
	switch (*fmt) {
	case '0': case '-': case ' ': case '+':
	  flag = *fmt;
	  break;
	default:
	  goto width;
	}
      }
    width:
      while (*fmt) {
	switch (*fmt) {
	case '0': case '1': case '2': case '3': case '4':
	case '5': case '6': case '7': case '8': case '9':
	  width += width * 10 + *fmt - '0';
	  break;
	default:
	  goto prec;
	}
	fmt++;
      } 
    prec:
      if (*fmt == '.') {
	while (*++fmt) {
	  switch (*fmt) {
	  case '0': case '1': case '2': case '3': case '4':
	  case '5': case '6': case '7': case '8': case '9':
	    prec += prec * 10 + *fmt - '0';
	  default:
	    goto conv;
	  }
	}
      }
    conv:
      if (!*fmt) goto end;
      switch (format = *fmt++) {
      case 'd': case 'i':
	{
	  int neg = 0;
	  value.n = va_arg(va, int);
	  if (value.n < 0)
	    value.n = -value.n;
	  len = 0;
	  buf[60] = 0;
	  do {
	    buf[60 - ++len] = value.n % 10 + '0';
	    value.n /= 10;
	  } while (value.n);
	  if (prec && prec > len) {
	    while (prec > len)
	      buf[60 - ++len] = '0';
	  }
	  p = &buf[60 - len];
	  if (neg) {
	    *--p = '-';
	    len++;
	  }
	  break;
	}
      case 'X':
	xtype = 'A';
	goto xdigit;
      case 'x':
	xtype = 'a';
      xdigit:
	value.n = va_arg(va, int);
	len = 0;
	buf[60] = 0;
	do {
	  if ((value.n & 0xF) < 10)
	    buf[60 - ++len] = (value.n & 0xF) + '0';
	  else
	    buf[60 - ++len] = (value.n & 0xF) + xtype - 10;
	  value.n >>= 4;
	} while (value.n);
	if (prec && prec > len) {
	    while (prec > len)
	      buf[60 - ++len] = '0';
	  }
	p = &buf[60 - len - 1];
	break;
      case 's':
	value.s = va_arg(va, char *);
	len = strlen(value.s);
	if (prec && len > prec)
	  len = prec;
	p = value.s;
	break;
      case '%':
	*dst++ = '%';
	goto end;
      case 'F': // struct file * ファイル名を書く
	value.f = va_arg(va, struct file *);
	p = value.f->name;
	for (len = 0; *p; len++)
	  buf[len] = toupper(*p++);
	buf[len++] = '.';
	p = value.f->ext;
	for (len = 0; *p; len++)
	  buf[len] = toupper(*p++);
	p = buf;
	if (prec && prec < len)
	  len = prec;
	break;
      default:
	goto end;
      }
      if (flag != '-' && width && width > len)
	while (width-- > len)
	  *dst++ = ' ';
      for (i = 0; i < len; i++)
	*dst++ = p[i];
      if (flag == '-' && width && width > len)
	while (width-- > len)
	  *dst++ = ' ';
    end:
      ;
    }
  }
  *dst = 0;
}

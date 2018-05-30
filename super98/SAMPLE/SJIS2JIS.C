/*
 *	sjis2jis.c
 */

#include <stdio.h>
#include "super98.h"

#define FALSE	0
#define TRUE	1

int main(void)
{
	int		inknj	= FALSE;
	int		c;
	unsigned int	knj;

	while ((c = fgetc(stdin)) != EOF) {
		if ((0x81 <= c && c <= 0x9f) || (0xe0 <= c && c <= 0xef)) {
			if (inknj == FALSE) {
				fputs("\x1b\x24\x40", stdout);
				inknj = TRUE;
			}
/*
			knj = ToJis((c << 8) | (fgetc(stdin) & 0xff));
*/
			knj = ToJisFast((c << 8) | (fgetc(stdin) & 0xff));
			fputc(knj >> 8, stdout);
			fputc(knj & 0xff, stdout);
		} else {
			if (inknj != FALSE) {
				fputs("\x1b\x28\x4A", stdout);
				inknj = FALSE;
			}
			fputc(c, stdout);
		}
	}

	return 0;
}

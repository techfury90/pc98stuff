/*
 *	jis2sjis.c
 */

#include <stdio.h>
#include "super98.h"

#define FALSE	0
#define TRUE	1

int main(void)
{
	int		inknj	= FALSE;
	int		c, c1, c2;
	unsigned int	knj;

	while ((c = fgetc(stdin)) != EOF) {
		if (c == 0x1B) {
			c1 = fgetc(stdin);
			c2 = fgetc(stdin);
			if (c1 == 0x24 && c2 == 0x40) {
				inknj = TRUE;
			} else if (c1 == 0x28 && c2 == 0x4A) {
				inknj = FALSE;
			} else {
				fputc(0x1B, stdout);
				fputc(c1, stdout);
				fputc(c2, stdout);
			}
		} else if (inknj == FALSE) {
			fputc(c, stdout);
		} else {
/*
			knj = ToSjis((c << 8) | (fgetc(stdin) & 0xff));
*/
			knj = ToSjisFast((c << 8) | (fgetc(stdin) & 0xff));
			fputc(knj >> 8, stdout);
			fputc(knj & 0xff, stdout);
		}
	}

	return 0;
}

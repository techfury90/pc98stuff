/*
 *	pal.c
 */

#include <stdio.h>
#include <stdlib.h>
#include "super98.h"

int main(int argc, char **argv)
{
	unsigned int	c_num;
	unsigned int	c_code;

	if (argc ==  1) {
		PaletteInit();
		return 0;
	} else if (argc != 3) {
		puts("Usage: pal [<ColorNumber> <ColorCode>]");
		return 1;
	}
	c_num = atoi(*++argv);
	c_code = atoi(*++argv);
	Palette(c_num, c_code);
	return 0;
}

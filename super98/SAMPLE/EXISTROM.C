/*
 * existrom.c
 */

#include <stdio.h>
#include <stdlib.h>
#include "super98.h"

int main(int argc, char **argv)
{
	unsigned int seg;

	argc--;
	argv++;
	if (argc == 0) {
		printf("usage: existrom <segment adrs>\n");
		return 0;
	}
	seg = (unsigned int)strtol(*argv, NULL, 16);
	printf("existrom: %04X %sexist\n", seg, ExistExtRom(seg) ? "" : "not ");
	return 0;
}

/* existrom.c */

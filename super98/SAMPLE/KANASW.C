/*
 * kanasw.c
 */

#include <stdio.h>
#include "super98.h"

int main(int argc, char **argv)
{
	argc--;
	argv++;
	if (argc == 0) {
		printf("usage: kanasw {on|off}\n");
		return 0;
	}
	if (!GetKbType()) {
		printf("kanasw: can't control this keyboard\n");
		return 1;
	}
	if (*++*argv == 'n') {
		KanaSwitch(1);
	} else {
		KanaSwitch(0);
	}
	return 0;
}

/* kanasw.c */
		

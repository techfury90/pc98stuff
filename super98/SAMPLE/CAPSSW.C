/*
 * capssw.c
 */

#include <stdio.h>
#include "super98.h"

int main(int argc, char **argv)
{
	argc--;
	argv++;
	if (argc == 0) {
		printf("usage: capssw {on|off}\n");
		return 0;
	}
	if (!GetKbType()) {
		printf("capssw: can't control this keyboard\n");
		return 1;
	}
	if (*++*argv == 'n') {
		CapsSwitch(1);
	} else {
		CapsSwitch(0);
	}
	return 0;
}

/* capssw.c */

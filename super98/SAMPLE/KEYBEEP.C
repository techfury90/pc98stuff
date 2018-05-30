/*
 * keybeep.c
 */

#include <stdio.h>
#include "super98.h"

int main(int argc, char **argv)
{
	argc--;
	argv++;
	if (argc == 0) {
		printf("keybeep: %s\n", GetKeyBeepMode() ? "off" : "on");
		return 0;
	}
	if (*++*argv == 'f') {
		KeyBeepOff();
	} else {
		KeyBeepOn();
	}
	return 0;
}

/* keybeep.c */

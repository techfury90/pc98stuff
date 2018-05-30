/*
 * keytouch.c
 */

#include <stdio.h>
#include <conio.h>
#include "super98.h"

void main(void)
{
	int i, j;
	unsigned char code;

	printf("\033[2J");
	for (;;) {
		printf("\033[H");
		printf("   0 1 2 3 4 5 6 7\n");
		printf("--+---------------\n");
		for (i = 0; i < 0x10; i++) {
			printf("%02X", i);
			code = KeyTouch(i);
			for (j = 0; j < 8; j++) {
				printf(" %c", code & 1 ? '1' : '0');
				code >>= 1;
			}
			printf("\n");
		}
		while (kbhit()) {
			getch();
		}
	}
}

/* keytouch.c */

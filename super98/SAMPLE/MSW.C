/*
 * msw.c
 */

#include <stdio.h>
#include "super98.h"

void setmemswitch(int num, int bit, int sw);
void printmemswitch(void);

int main(int argc, char **argv)
{
	int num, bit, sw;
	int err = 0;

	argc--;
	argv++;
	if (argc == 0) {
		printf("usage: msw s[1-8] b[0-7] {on|off}...\n");
		printmemswitch();
		return 0;
	}
	while (argc >= 3) {
		if (argv[0][0] != 's') {
			err = 1;
		} else {
			num = argv[0][1] - '0';
		}
		if (argv[1][0] != 'b') {
			err = 2;
		} else {
			bit = argv[1][1] - '0';
		}
		if (argv[2][0] != 'o') {
			err = 3;
		} else if (argv[2][1] == 'n') {
			sw = 1;
		} else if (argv[2][1] == 'f') {
			sw = 0;
		} else {
			err = 4;
		}
		if (err) {
			fprintf(stderr,
			"msw: %s %s %s: uh?\n", argv[0], argv[1], argv[2]);
			return 1;
		}
		setmemswitch(num, bit, sw);
		argc -= 3;
		argv += 3;
	}
	if (argc != 0) {
		fprintf(stderr, "msw: %s: missing argument\n", *argv);
		return 1;
	}
	return 0;
}

void setmemswitch(int num, int bit, int sw)
{
	unsigned char msw;
	unsigned char mask;

	mask = 1 << bit;
	msw = GetMemorySwitch(num);
	msw &= ~mask;
	if (sw) {
		msw |= mask;
	}
	SetMemorySwitch(num, msw);
}

void printmemswitch(void)
{
	int i, j;
	unsigned char msw;

	printf("sw b76543210\n");
	printf("---+--------\n");
	for (i = 1; i <= 8; i++) {
		msw = GetMemorySwitch(i);
		printf(" %d  ", i);
		for (j = 0; j < 8; j++) {
			if ((msw & 0x80) == 0x80) {
				printf("1");
			} else {
				printf("0");
			}
			msw <<= 1;
		}
		printf("\n");
	}
}

/* msw.c */

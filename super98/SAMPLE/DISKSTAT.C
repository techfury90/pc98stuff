/*
 * diskstat.c
 */

#include <stdio.h>
#include <ctype.h>
#include "super98.h"

int main(int argc, char **argv)
{
	unsigned char daua;

	argc--;
	argv++;
	if (argc == 0) {
		printf("usage: diskstat <drive>\n");
		return 0;
	}
	daua = DriveToDaua(toupper(**argv));
	if (daua == 0) {
		fprintf(stderr, "diskstat: %c: no such drive\n", **argv);
		return 1;
	}
	switch (daua / 16) {
	case 7:
		printf("Floppy Disk Drive (640K)\n");
		break;
	case 8:
		printf("Hard Disk Drive (SASI)\n");
		break;
	case 9:
		printf("Floppy Disk Drive (1M)\n");
		break;
	case 10:
		printf("Hard Disk Drive (SCSI)\n");
		break;
	default:
		printf("unknown device\n");
		return 0;
	}
	printf("unit number: %d\n", daua % 16);
	return 0;
}

/* diskstat.c */

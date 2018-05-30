/*
 * rsstat.c
 */

#include <stdio.h>
#include "super98.h"

#define BAUDNUM 10

void printstat(int stat);

int main(void)
{
	unsigned int tbl[BAUDNUM] = {
		75, 150, 300, 600, 1200, 2400, 4800, 9600, 19200, 38400U
	};

	printf("CD CS CI DR Speed\n");
	printf("--+--+--+--+-----\n");
	printstat(CheckCd());
	printstat(CheckCs());
	printstat(CheckCi());
	printstat(CheckDr());
	printf("%5u\n", tbl[GetSpeed()]);
	return 0;
}

void printstat(int stat)
{
	printf(" %c ", stat ? 'o' : '-');
}

/* rsstat.c */

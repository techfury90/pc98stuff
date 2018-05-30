/*
 * prnstat.c
 */

#include <stdio.h>
#include "super98.h"

int main(void)
{
	printf("prnstat: ");
	switch (GetPrnStat()) {
	case 0:
		printf("printer available.\n");
		break;
	case 1:
		printf("printer is busy.\n");
		break;
	case 2:
		printf("no response. time out...\n");
		break;
	case 3:
		printf("printer offline, not available.\n");
		break;
	case 4:
		printf("printer paper end.\n");
		break;
	case 5:
		printf("There is no printer\n");
		break;
	}
	return 0;
}

/* prnstat.c */

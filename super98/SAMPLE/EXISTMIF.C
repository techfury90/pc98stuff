/*
 * existmif.c
 */

#include <stdio.h>
#include "super98.h"

int main(void)
{
	printf("existmif: ");
	switch (ExistMouseIF()) {
	case 0:
		printf("Mouse I/F なし。\n");
		break;
	case 1:
		printf("Mouse I/F あり。割込周期設定機能なし。\n");
		break;
	case 2:
		printf("Mouse I/F あり。割込周期設定機能あり。\n");
		break;
	}
	return 0;
}

/* existmif.c */

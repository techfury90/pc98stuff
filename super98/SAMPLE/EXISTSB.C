/*
 * existsb.c
 */

#include <stdio.h>
#include "super98.h"

int main(void)
{
	printf("existsb: ");
	switch (ExistSoundBoard()) {
	case 0:
		printf("サウンド機能なし。\n");
		break;
	case 1:
		printf("サウンド機能あり。ROM なし(ハイレゾ含む)。\n");
		break;
	case 2:
		printf("サウンド機能あり。サウンド ROM あり。\n");
		break;
	}
	return 0;
}

/* existsb.c */

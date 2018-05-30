/*
 * keytype.c
 */

#include <stdio.h>
#include "super98.h"

int main(void)
{
	int i;
	unsigned int t;
	unsigned int mask;
	char *str[] = {
		"NFER",
		"HOME",
		"vf.1～5 バッククオート",
		"BS、DEL、HELP、ROLL UP、ROLL DOWN", 
		"CAPS、カナソフトウェア制御機能",
		"NUMソフトウェア制御機能"
	};
	char *yesno[] = {
		"なし", "あり"
	};

	t = GetKeyType();
	printf("vf.1～5→f.6～10変換: %s\n", t & 0x40 ? "必要" : "不要");
	mask = 0x20;
	for (i = 0; i < 6; i++) {
		printf("%s: %s\n", str[i], yesno[(t & mask) == mask]);
		mask >>= 1;
	}
	return 0;
}

/* keytype.c */

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
		"vf.1�`5 �o�b�N�N�I�[�g",
		"BS�ADEL�AHELP�AROLL UP�AROLL DOWN", 
		"CAPS�A�J�i�\�t�g�E�F�A����@�\",
		"NUM�\�t�g�E�F�A����@�\"
	};
	char *yesno[] = {
		"�Ȃ�", "����"
	};

	t = GetKeyType();
	printf("vf.1�`5��f.6�`10�ϊ�: %s\n", t & 0x40 ? "�K�v" : "�s�v");
	mask = 0x20;
	for (i = 0; i < 6; i++) {
		printf("%s: %s\n", str[i], yesno[(t & mask) == mask]);
		mask >>= 1;
	}
	return 0;
}

/* keytype.c */
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
		printf("�T�E���h�@�\�Ȃ��B\n");
		break;
	case 1:
		printf("�T�E���h�@�\����BROM �Ȃ�(�n�C���]�܂�)�B\n");
		break;
	case 2:
		printf("�T�E���h�@�\����B�T�E���h ROM ����B\n");
		break;
	}
	return 0;
}

/* existsb.c */
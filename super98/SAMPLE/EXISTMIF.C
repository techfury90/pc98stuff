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
		printf("Mouse I/F �Ȃ��B\n");
		break;
	case 1:
		printf("Mouse I/F ����B���������ݒ�@�\�Ȃ��B\n");
		break;
	case 2:
		printf("Mouse I/F ����B���������ݒ�@�\����B\n");
		break;
	}
	return 0;
}

/* existmif.c */
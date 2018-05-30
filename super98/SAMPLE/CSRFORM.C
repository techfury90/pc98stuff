/*
 *	csrform.c
 */

#include <stdio.h>
#include <stdlib.h>
#include "super98.h"

int main(int argc, char **argv)
{
	if (argc != 2) {
		puts("Usage: csrform <form>");
		puts("       form: 0 ... box");
		puts("             1 ... bold-line");
		puts("             2 ... line");
		return 1;
	} else {
		SetCursorForm(atoi(*++argv));
		return 0;
	}
}

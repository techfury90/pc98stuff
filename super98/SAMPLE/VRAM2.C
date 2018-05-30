/*
 *	vram2.c
 */

#include <stdio.h>
#include <string.h>
#include "super98.h"

int main(void)
{
	char	buffer[80];
	int	colum;
	int	line;

	puts("Input to line (max:80)");
	gets(buffer);
	GetGdcCursor(&colum, &line);
	PutStrVram(80 - strlen(buffer), line, buffer);

	return 0;
}

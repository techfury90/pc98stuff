/*
 *	vram1.c
 */

#include "super98.h"

int main(void)
{
	int		line;
	int		colum;
	int		n;
	unsigned int	buffer[80];

	for (line = 0; line < 25; line++) {
		for (colum = 0, n = 0; colum < 80; colum++, n++) {
			buffer[n] = GetVram(colum, line);
			if (buffer[n] & 0xFF00) {
				colum++;
			}
		}
		for (colum = 0, n = 0; colum < 80; colum++, n++) {
			if (buffer[n] & 0xFF00) {
				colum++;
			}
			PutVram(79 - colum, line, buffer[n]);
		}
	}

	return 0;
}

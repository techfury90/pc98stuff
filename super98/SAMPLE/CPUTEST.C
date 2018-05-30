/*
 *	cputest.c
 */

#include <stdio.h>
#include "super98.h"

int main(void)
{
	struct {
		int	cpu;
		char	*name;
	} cpukind[9] = {
			{ 0x00, "8086" },
			{ 0x01, "80186" },
			{ 0x02, "80286" },
			{ 0x03, "80386" },
			{ 0x04, "80486" },
			{ 0x11, "V30/V50" },
			{ 0x31, "V33" },
			{ 0x83, "80386 (V86)" },
			{ 0x84, "80486 (V86)" }
	};
	char	*clkkind[2] = { "5/10MHz", "8MHz" };
	int	cpu;
	int	clk;
	int	n;

	cpu = CpuKind();
	clk = GetSysClk();

	for (n = 0; n < 9; n++) {
		if (cpukind[n].cpu == cpu) {
			printf("CPU is %s\n", cpukind[n].name);
			printf("SYSTEM CLOCK is %s\n", clkkind[clk]);
			return 0;
		}
	}

	printf("unknown\n");
	return 1;
}

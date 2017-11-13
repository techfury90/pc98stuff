#include <stdio.h>
#include <dos.h>
#include <conio.h>

void wrvram(int, int);
void setpal(int, int, int, int);

void main(void)
{
	int i, x, y, addr, vdta;
	int dta[8]={0x1111, 0x0000, 0x1111, 0x4444, 0xaaaa, 0x0000, 0xaaaa, 0x5555};

	clrscr();
	outportb(0x6a, 1);
	outportb(0xa2, 0x4b);
	outportb(0xa0, 0);
	outportb(0x68, 8);
	setpal(0, 0, 0, 0);
	setpal(9, 0, 0, 15);
	outportb(0xa2, 0xd);
	for (i = 0; i < 4; i++) {
		for(y = 0; y < 100; y++) {
			for (x = 0; x < (640 / 8); x += 2) {
				addr = i * 100 * 80 + y * 80 + x;
				vdta = dta[i * 2 + (y % 2)];
				wrvram(addr, vdta);
			}
		}
	}
	printf("lol\n");

}
	
void wrvram(int vaddr, int vdta)
{
	poke(0xa800, vaddr, vdta);
	poke(0xb000, vaddr, 0);
	poke(0xb800, vaddr, 0);
	poke(0xe000, vaddr, vdta);
}

void setpal(int pnum, int gbr, int rbr, int bbr)
{
	outportb(0xa8, pnum);
	outportb(0xaa, gbr);
	outportb(0xac, rbr);
	outportb(0xae, bbr);
}
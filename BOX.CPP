#include <stdio.h>
#include <dos.h>
#include <conio.h>
#include <string.h>

#define GGDC_PAR 0xa0
#define GGDC_CMD 0xa2

/* #define 
#define BP_SIZE */

/* 	Pointers to graphics VRAM bitplanes 0-3. 
	You may notice that bitplane 3 is not contiguous with the first 2 
	bitplanes, this is because bitplane 3 was added by NEC at a
	later date (1985, PC-9801VM)
*/
volatile far void* GVRAM_BP0 = 0xa8000000;
volatile far void* GVRAM_BP1 = 0xb0000000;
volatile far void* GVRAM_BP2 = 0xb8000000;
volatile far void* GVRAM_BP3 = 0xe0000000;



void setpal(int, int, int, int);

pc98_grphinit()
{
	
	clrscr(); //clear the text display, as it overlays graphics on PC-98s
	outportb(0x6a, 1); //enable graphics VRAM bitplane 3
	
	outportb(0xa2, 0x4b); //G-GDC CCHAR command
	outportb(0xa0, 0x00); //G-GDC CCHAR parameter for graphics mode
	
	outportb(0x68, 0x08); //set display resoultion to 640x400
	outportb(0xa2, 0xd); //send G-GDC START command (activate graphics display)
}

pc98_grphstop()
{
	outportb(0xa2, 0x0d); //G-GDC STOP command
	outportb(0x6a, 0x00); //disable VRAM bitplane 3
	clrscr();
}

void main()
{
	
	

	pc98_grphinit();
	
	while ((inportb(0xa0) & 2) == 1); // wait for GDC FIFO to be empty
	outportb(0xa2, 0x33); //GDC WDAT (try 0x31 if it doesn't work)
	outportb(0xa0, 0x00); //dummy write (used to set BitBLT ROP register)

	outportb(0xa2, 0x78); //PRAM opcode, modify parameter memory from location 8
	outportb(0xa0, 0xff); //specify bitmap line fill pattern here
	outportb(0xa0, 0xff); //


	while ((inportb(0xa0) & 2) == 1); // wait for GDC FIFO to be empty
	outportb(0xa2, 0x49); //issue CURS opcode
	outportb(0xa0, 0x83); //
	outportb(0xa0, 0x80);
	outportb(0xa0, 0x00); //specify cursor position


	while ((inportb(0xa0) & 2) == 1); // wait for GDC FIFO to be empty
	outportb(0xa2, 0x4c); //FIGS opcode

	outportb(0xa0, 0x40);
	outportb(0xa0, 0x03); //DC = 3  (rectangle drawing mode)
	outportb(0xa0, 0x00); //

	outportb(0xa0, 0x40); //D = 64
	outportb(0xa0, 0x00); //

	outportb(0xa0, 0x20); //D2 = 32
	outportb(0xa0, 0x00); //

	outportb(0xa0, 0xff); //D1 = -1
	outportb(0xa0, 0xff); //

	outportb(0xa0, 0x40); //DM = 64 (same as D)
	outportb(0xa0, 0x00); //

	outportb(0xa2, 0x6c); //FIGD, start drawing!

	getch(); //wait for a key press
	
	pc98_grphstop(); //shut down PC-98 graphics 
	
}

void setpal(int pnum, int gbr, int rbr, int bbr)
{
	outportb(0xa8, pnum);
	outportb(0xaa, gbr);
	outportb(0xac, rbr);
	outportb(0xae, bbr);
}
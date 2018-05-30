/***************************************************************
PC-9821 Enhanced Graphics (256Color Packed Pixel)
VRAM Linear Access  Sample Program
                                   for Watcom C++ & DOS4GW
                                         2002/09/22 By DULL
****************************************************************/
#include <stdio.h>
#include <string.h>
#include <malloc.h>
#include <math.h>
#include <dos.h>
#include <conio.h>

#define _16MB_CHECK_ 1
#define _HSYNC_ 0

#define WIDTH 640
#define HEIGHT 400
#define VRAM_SIZE (WIDTH * HEIGHT)

typedef union X_{
	struct{
		unsigned short l;
		unsigned short h;
	}w;
	unsigned long x;
}X;

typedef struct DPMI_MEM_{
	unsigned int selecter;
	unsigned int p_address;		// Physical Address
	unsigned int p_size;		// Physical Address Size
	unsigned int l_address;		// Linear Address
}DPMI_MEM;

#if _HSYNC_
static int Hmode;
#endif


void setpal(int no,int red,int green,int blue)
{
	outp(0xa8,no);
	outp(0xaa,green);
	outp(0xac,red);
	outp(0xae,blue);
}

void pc9821_on(void)
{
#if _HSYNC_
	// HSYNC -> 31.47 KHz 
	if( (inp(0x09a8) & 0x01) == 0){
		outp(0x09a8,0x01);
		Hmode = 1;
	}
#endif

	// 256 color mode
	outp(0x6a,0x07);
	outp(0x6a,0x21);
	outp(0x6a,0x06);

	// Packed Pixel
	*((char *)0xe0100) = 0x00;

	// 16[MB] System Area -> VRAM ON
	*((char *)0xe0102) = 0x01;

	// Graphics Start
	outp(0xa2,0x0d);
}

void pc9821_off()
{
	// 16[MB] System Area -> VRAM OFF
	*((char *)0xe0102) = 0x00;

	// 16 Color (standard) mode
	outp(0x6a,0x07);
	outp(0x6a,0x20);
	outp(0x6a,0x06);

#if _HSYNC_
	// HSYNC -> 24.8? KHz
	if(Hmode==1)
		outp(0x09a8,0x00);
#endif

	// TEXT Start
	outp(0x62,0x0d);

}

void dpmi_vram_off(DPMI_MEM *dm)
{
	union REGS r;
	X tmp;

	if(dm->selecter != 0xFFFFFFFF){
		r.x.eax = 0x0001;		// DPMI Function
		r.x.ebx = dm->selecter;
		int386(0x31, &r, &r);
		if( r.x.cflag ){
			// Failed
			puts("ディスクリプタを開放できませんでした。");
		}
	}

	if(dm->l_address != 0xFFFFFFFF){
		r.x.eax = 0x0801;		// DPMI Function
		tmp.x = dm->l_address;	// BX:CX = メモリの物理アドレス
		r.x.ebx = tmp.w.h;
		r.x.ecx = tmp.w.l;

		int386(0x31, &r, &r);
		if( r.x.cflag ){
			// Failed
			puts("物理アドレスのマッピングの解除ができませんでした。");
		}
	}
}

int dpmi_vram_on(DPMI_MEM *dm)
{
	union REGS r;
	X tmp;

	// ・ディスクリプタの割り当て
	r.x.eax = 0x0000;		// DPMI Function
	r.x.ecx = 1;			// アロケートするディスクリプタの数
	int386(0x31, &r, &r);
	if( r.x.cflag ){
		// Failed
		puts("ディスクリプタをアロケートできませんでした。");
		return(0);
	}
	// アロケートされたセレクタ
	dm->selecter = r.x.eax;


	// ・物理アドレスのマッピング
	r.x.eax = 0x0800;		// DPMI Function
	tmp.x = dm->p_address;	// BX:CX = メモリの物理アドレス
	r.x.ebx = tmp.w.h;
	r.x.ecx = tmp.w.l;
	tmp.x = dm->p_size;		// SI:DI = マップする領域のバイト数
	r.x.esi = tmp.w.h;
	r.x.edi = tmp.w.l;
	int386(0x31, &r, &r);
	if( r.x.cflag ){
		// Failed
		puts("物理アドレスをマッピングできませんでした。");
		return(0);
	}
	// physical address mapping -> Linear Address
	tmp.w.h = r.x.ebx;
	tmp.w.l = r.x.ecx;
	dm->l_address = tmp.x;


	// ・セグメントのベースアドレスを設定
	r.x.eax = 0x0007;		// DPMI Function
	r.x.ebx = dm->selecter;		// セレクタ
	// CX:DX = セグメントに対する新しい32ビットリニアベースアドレス
	r.x.ecx = tmp.w.h;
	r.x.edx = tmp.w.l;
	int386(0x31, &r, &r);
	if( r.x.cflag ){
		// Failed
		puts("ベースアドレスを設定できませんでした。");
		return(0);
	}
/*
	// ・セグメントのリミットを設定
	r.x.eax = 0x0008;		// DPMI Function
	r.x.ebx = dm->selecter;		// セレクタ
	tmp.x = dm->p_size;		// リミットサイズ
	r.x.ecx = tmp.w.h;
	r.x.edx = tmp.w.l;
	int386(0x31, &r, &r);
	if( r.x.cflag ){
		// Failed
		puts("リミットを設定できませんでした。");
		return(0);
	}
*/
	return(1);
}

int get_ds(void)
{
#if 1
	unsigned short ds_sreg;

	_asm{
		mov ax,ds
		mov [ds_sreg],ax
	}
	return(ds_sreg);
#else
    struct SREGS sregs;

    segread( &sregs );
	return(sregs.ds);
#endif
}

/********************************************************************/

void main()
{
	unsigned char *VVRAM;
	int i,x,y,dat,my_ds;
	unsigned char tp1,tp2,tp3,tp4;
	unsigned char p1,p2,p3,p4;
	unsigned char WTable[256];
	float palk;
	int ret;
	DPMI_MEM dm;


#if _16MB_CHECK_
	if( (inp(0x043b)&0x04) ){
		puts("16MBシステム空間の設定を変更して下さい。");
		return;
	}
#endif

	memset(&dm,0,sizeof(DPMI_MEM));
	dm.selecter  = 0xFFFFFFFF;
	dm.p_address = 0x00F00000;	// 16[MB] System Area
	dm.p_size    = 0x00080000;	// VRAM 512[KB]
	dm.l_address = 0xFFFFFFFF;

	pc9821_on();
	ret = dpmi_vram_on(&dm);
	my_ds = get_ds();

	if( ret ){
		VVRAM = (unsigned char *)malloc(VRAM_SIZE);
		p1 = p2 = p3 = p4 = 0;

		// テーブルの作成 - 実行速度を上げるため最初に計算しておく。
		for(i=0;i<256;i++){
			palk=30.0*(1.0+sin(i*2.0*3.141592654/256.0));
			WTable[i]=(unsigned char)palk;
		}

		// パレットの設定
		for(i=0;i<256;i++)
			setpal(i,i,10,100-i/3);

//		while(kbhit()==0){
		for(i=0;i<100;i++){		// 100フレーム描画で終了。
			tp1 = p1;
			tp2 = p2;
			for(x=0;x<WIDTH;x++){
				tp3 = p3;
				tp4 = p4;
				for(y=0;y<HEIGHT;y++){
					dat = WTable[tp1]+WTable[tp2]+WTable[tp3]+WTable[tp4];
					VVRAM[x + y * WIDTH] = dat;
					tp3 += 1;
					tp4 += 3;
				}
				tp1 += 2;
				tp2 += 1;
			}
			p1 += 1;
			p2 -= 2;
			p3 += 3;
			p4 -= 4;
#if 0
			// gcc はこっちかな？
			movedata(my_ds,(unsigned int)VVRAM,
					dm.selecter,0,VRAM_SIZE);
#else
			// DOS4GW ではリニアアドレス直指定の転送も可能。
			memcpy((void *)dm.l_address,VVRAM,VRAM_SIZE);
#endif
		}

		// clear !!
		memset(VVRAM,0,640*400);
		memcpy((void *)dm.l_address,VVRAM,VRAM_SIZE);

		free(VVRAM);
	}

	dpmi_vram_off(&dm);
	pc9821_off();
}

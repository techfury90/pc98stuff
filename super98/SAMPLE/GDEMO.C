/*====================================================
	PC9801 Graphic Library - Demonstration Program
	GDEMO.C
	1992/02/17  by ZOBplus Neopara
    初期タイプのPC9801では動作しません
====================================================*/

#include <stdio.h>
#include <stdlib.h>
#include "super98.h"

#define FLAMEW		14		/* ウインドウの枠の幅 */
#define BOLDKANJI	0x10	/* KanjiGputc()で太字を指定するビット */

/*色の定数集合*/
enum {
	BLACK, GRAY1, GRAY2, GRAY3, BLUE1, BLUE2, RED1, RED2,
	GREEN1, GREEN2, CYAN1, CYAN2, YELLOW1, YELLOW2, BROWN, WHITE
};

/*カラーコードのテーブル*/
static unsigned int paltable[] = {
	0x000, 0xDCC, 0xA99, 0x555, 0x37D, 0x126, 0x4C0, 0x290,
	0xA45, 0x834, 0xA7F, 0x85D, 0xAD3, 0x8C1, 0x451, 0xFFF
};


/*---------------------------------------------------------------------
	パレットのフェードイン/フェードアウト
	- PaletteAll()を使用 -
	IN : unsigned int paltable[] カラーコードのテーブル(グローバル)
	     int vec 正ならフェードイン、そうででなければフェードアウト
---------------------------------------------------------------------*/

void SetUpPalette(int vec)
{
	unsigned int tmppal[16];
	unsigned int level, tone, col, b, r, g;

	for (level=0 ; level<=16 ; level++) {
		tone = (vec>0) ? level : 16-level;
		for (col=0 ; col<16 ; col++) {
			b = (paltable[col] & 0xF)*tone >> 4;
			r = ((paltable[col]>>4) & 0xF)*tone >> 4;
			g = ((paltable[col]>>8) & 0xF)*tone >> 4;
			tmppal[col] = (g<<8)|(r<<4)|b;  /* ある段階のカラーコードを得る */
		}
		PaletteAll(tmppal);
	}
}


/*----------------------------------------------------
	ウインドウ(モドキ)の表示
	- GdcLine(), GdcBox(), GraphicBoxf()を使用 -
	IN : unsigned int sx,sy ウインドウ左上端座標
	     unsigned int ex,ey ウインドウ右下端座標
	     unsigned int col 内部を塗りつぶす色の番号
----------------------------------------------------*/

void DrawWindow(unsigned int sx, unsigned int sy,
				unsigned int ex, unsigned int ey, unsigned int col)
{
	GdcBox(sx,sy,ex,ey,GRAY3);
	GraphicBoxf(sx+1,sy+1,ex-1,ey-1,WHITE);
	GraphicBoxf(sx+4,sy+4,ex-4,ey-4,GRAY1);
	GraphicBoxf(sx+FLAMEW,sy+FLAMEW,ex-FLAMEW,ey-FLAMEW,col);
	GdcLine(sx+1,ey-1,ex-1,ey-1,GRAY2);
	GdcLine(sx+2,ey-2,ex-2,ey-2,GRAY2);
	GdcLine(sx+3,ey-3,ex-3,ey-3,GRAY2);
	GdcLine(ex-1,sy+1,ex-1,ey-1,GRAY2);
	GdcLine(ex-2,sy+2,ex-2,ey-2,GRAY2);
	GdcLine(ex-3,sy+3,ex-3,ey-3,GRAY2);
	GdcLine(sx+(FLAMEW-1),ey-(FLAMEW-1),ex-(FLAMEW-1),ey-(FLAMEW-1),WHITE);
	GdcLine(ex-(FLAMEW-1),sy+(FLAMEW-1),ex-(FLAMEW-1),ey-(FLAMEW-1),WHITE);
	GdcLine(sx+(FLAMEW-1),sy+(FLAMEW-1),ex-(FLAMEW-1),sy+(FLAMEW-1),GRAY2);
	GdcLine(sx+(FLAMEW-1),sy+(FLAMEW-1),sx+(FLAMEW-1),ey-(FLAMEW-1),GRAY2);
}


/*-----------------------------------------------------------
	タイル状にウインドウを表示
	IN : unsigned int xp,yp 横/縦方向のウインドウの分割数
	     unsigned int col 内部を塗りつぶす色の番号
-----------------------------------------------------------*/

void DrawTilingWindows(unsigned int xp, unsigned int yp, unsigned int col)
{
	unsigned int winx, winy, x, y;
	unsigned int boxw = 640/xp;
	unsigned int boxh = 400/yp;

	for (winy=0 ; winy<yp ; winy++)
		for (winx=0 ; winx<xp ; winx++) {
			x = winx*boxw;
			y = winy*boxh;
			DrawWindow(x,y,x+boxw-1,y+boxh-1,col);
		}
}


/*---------------------------------------------------------
	レベルメータ風の表示
	- GraphicBoxf()を使用 -
	IN : unsigned int bars 横に列べるメータの数
	     unsigned int maxlvl 各メータの最大値(目盛の数)
	     unsigned int count 表示回数
---------------------------------------------------------*/

void LevelMeter(unsigned int bars, unsigned int maxlev, unsigned int count)
{
	int level[32], lev, vec;
	unsigned int bar, col, x, y;
	unsigned int i;

	unsigned int redlev = maxlev*9/10;
	unsigned int yellev = maxlev*7/10;
	unsigned int boxw = 640/bars*9/10-1;
	unsigned int boxh = 400/maxlev*9/10-1;

	for (bar=0 ; bar<bars ; bar++)
		level[bar] = 0;

	for (i=0 ; i<count ; i++) {
		do {
			bar = rand() % bars;
			vec = (rand() % 2)*2 - 1;  /* vec= -1 or +1 */
			lev = level[bar] + vec;
		} while (lev<0 || lev>maxlev);
		if (vec<0)
			col = BLUE2;
		else {
			level[bar]++;
			if (lev>=redlev)
				col = RED1;
			else if (lev>=yellev)
				col = YELLOW1;
			else
				col = CYAN1;
		}
		x = bar*640/bars;
		y = 400-level[bar]*400/maxlev;
		GraphicBoxf(x,y,x+boxw,y+boxh,col);
		if (vec<0)
			level[bar]--;
	}
}


/*--------------------------------------
	四角形と円の描画
	- GdcLine(), GdcCircle()を使用 -
	IN : unsigned int count 描画回数
--------------------------------------*/

#define MAXR 80  /* 図形の中心から端までの距離の最大値 */

void DrawSquaresAndCircles(unsigned int count)
{
	unsigned int x, y, r, col0, col;
	unsigned int i;

	for (i=0 ; i<count ; i++) {
		x = rand()%(320-FLAMEW*2-MAXR*2)+FLAMEW+MAXR;
		y = rand()%(400-FLAMEW*2-MAXR*2)+FLAMEW+MAXR;
		col0 = (rand()%6)*2+GRAY2;
		for (r = rand()%MAXR+1 ; r>0 ; r--) {
			col = col0+rand()%2;
			GdcLine(x+r,y,x,y-r,col);
			GdcLine(x,y-r,x-r,y,col);
			GdcLine(x-r,y,x,y+r,col);
			GdcLine(x,y+r,x+r,y,col);
			GdcCircle(x+320,y,r,col);
		}
	}
}


/*----------------------------------------------------
	グラフィック漢字文字列を表示
	- KanjiGputc()を使用 -
	IN : char *s 漢字文字列
	     unsigned int x,y 最初の文字の左上端の座標
	     unsigned int col 文字の色番号
----------------------------------------------------*/

void KanjiGputs(char *s, unsigned int x, unsigned int y, unsigned int col)
{
	unsigned int kanji;

	while (*s) {
		kanji = (*s) + ((*(s+1))<<8);  /*上位バイト・下位バイトを交換*/
		KanjiGputc(kanji,x,y,col);
		x += 16;
		s += 2;
	}
}


/*--------------------------------------------
	四字熟語(など)をグラフィック画面に表示
--------------------------------------------*/

void WriteKanji()
{
	unsigned int wc, wx, wy, col;
	static char *words[] = {
		"抱腹絶倒","商売繁盛","前後不覚","天下太平","完全無欠",
		"博学多才","清廉潔白","一攫千金","家内安全","人畜無害",
		"品行方正","才色兼備","焼肉定食","優柔不断","質実剛健",
		"神出鬼没","猪突猛進","狂気乱舞","酒池肉林","七転八倒",
		"千客万来","合格祈願","絶体絶命","満員御礼","大願成就"
	};

	wc = 0;
	for (wy=0 ; wy<5 ; wy++)
		for (wx=0 ; wx<5 ; wx++) {
			col = (wx*2+BLUE1) | ((wx+wy)%2 ? BOLDKANJI : 0);
			KanjiGputs(words[wc],wx*128+32,wy*80+31,BLACK);
			KanjiGputs(words[wc],wx*128+32,wy*80+32,col);
			wc++;
		}
}


/*---------------------------------------------------------------------
	15パズル風の矩形領域の移動と画面スクロール
	- GraphicMove(), GdcScroll()等を使用 -
	IN : unsigned int xp,yp 横/縦方向の領域の分割数
	     unsigned int *initx,*inity スペースの初期位置 (終了時更新される)
	     unsigned int col スペースの色番号
	     int scrl 画面全体をスクロールする時のライン数
	     unsigned int count スペースの移動回数
---------------------------------------------------------------------*/

void SlideRectangles(unsigned int xp, unsigned int yp,
					 unsigned int *initx, unsigned int *inity,
					 unsigned int col, int scrl, unsigned int count)
{
	unsigned int spacex, spacey, rects, steps, x, y, wx, wy;
	int dx, dy, newx, newy;
	unsigned int i;

	unsigned int boxw = 640/xp;
	unsigned int boxh = 400/yp;

	/* スペースを作る */
	for (spacey=0 ; spacey<yp ; spacey++)
		for (spacex=0 ; spacex<xp ; spacex++) {
			x = spacex*boxw;
			y = spacey*boxh;
			if (*initx==spacex && *inity==spacey)
				GraphicBoxf(x,y,x+boxw-1,y+boxh-1,col);
			else
				GdcBox(x,y,x+boxw-1,y+boxh-1,col);
		}
	spacex = *initx;
	spacey = *inity;

	/* 矩形領域の移動 */
	for (i=0 ; i<count ; i++) {
		/* スペースの移動先と、移動する領域の個数の決定 */
		do {
			dx = (rand()%2)*2-1;  /* dx  = -1 or +1 */
			if (i%2) {
				dy = 0;
				rects = rand()%(xp-1)+1;
				steps = boxw;
			} else {
				dy = dx;
				dx = 0;
				rects = rand()%(yp-1)+1;
				steps = boxh;
			}
			newx = spacex+dx*rects;
			newy = spacey+dy*rects;
		} while (newx<0 || newy<0 || newx>=xp || newy>=yp);
		/* 移動する領域全体の左上座標と大きさの計算 */
		x = (dx>0) ? (spacex+1)*boxw : newx*boxw;
		y = (dy>0) ? (spacey+1)*boxh : newy*boxh;
		wx = (0==dx) ? boxw : boxw*rects;
		wy = (0==dy) ? boxh : boxh*rects;
		/* 移動 */
		while (steps) {
			GraphicMove(x,y,x+wx-1,y+wy-1,x-dx,y-dy);
			if (scrl)
				GdcScroll(scrl);  /* 画面スクロール */
			x -= dx;
			y -= dy;
			steps--;
		}
		spacex = newx;
		spacey = newy;
	}

	/* スペースの位置を更新 */
	*initx = spacex;
	*inity = spacey;
}


/*--------------------
	メインルーチン
--------------------*/

void main(void)
{
	unsigned int spacex, spacey;
	char far *gr_work;

	GraphicInit(1,1);
	SetPen(0xFFFF,3); 
	GraphicCls(BLACK);
	SetUpPalette(-1);
	puts("\33[>1h\33[>5h\33*");  /* ファンクションキー/カーソル/画面消去 */

	GraphicCls(BLUE2);
	SetUpPalette(+1);
	LevelMeter(8,16,20000);
	GraphicCls(BLUE2);
	LevelMeter(32,50,60000U);
	SetUpPalette(-1);

	DrawTilingWindows(2,1,BROWN);
	SetUpPalette(+1);
	DrawSquaresAndCircles(200);
	SetUpPalette(-1);

	DrawTilingWindows(5,5,GRAY3);
	WriteKanji();
	SetUpPalette(+1);
	gr_work = (char far*)0x0000054D;	
	if (*gr_work & 0x40) { 
		spacex = spacey = 2;
		SlideRectangles(5,5,&spacex,&spacey,BROWN,0,30);
		SlideRectangles(5,5,&spacex,&spacey,BROWN,+1,6);
		SlideRectangles(5,5,&spacex,&spacey,BROWN,-1,6);
		spacex = spacey = 0;
		SlideRectangles(10,10,&spacex,&spacey,BLUE2,+5,20);
		SetUpPalette(-1);
	} else {
		puts("このマシンはEGCが搭載されていないので以下のデモを終了します\n");
	}
	
	GraphicCls(BLACK);
	PaletteInit();
	puts("\33[>1l\33[>5l");  /* ファンクションキー/カーソル表示 */
}

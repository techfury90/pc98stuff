/*
 *	super98.h
 */


#ifndef _SUPER98_

#define _SUPER98_


/* cpu */

int		CpuKind(void);
int		GetSysClk(void);

void		CpuReset(void);


/* text */

unsigned int	GetVram(int colum, int line);
void		PutVram(int colum, int line, unsigned int chr);
void		PutStrVram(int colum, int line, char *str);

void		GetGdcCursor(int *colum, int *line);
void		SetCursorForm(int form);

void		SetUcgBios(int chrcode, char *fontbuf, int num);
void		SetUcgIo(int chrcode, char *fontbuf, int num);

unsigned int	ToJis(unsigned int chr);
unsigned int	ToJisFast(unsigned int chr);
unsigned int	ToSjis(unsigned int chr);
unsigned int	ToSjisFast(unsigned int chr);


/* graph */

void		GraphicInit(int Lines, int ColorMode);

void		GraphicSystem(void);
extern char	_board16_set;
extern char	_gdc_clock;
extern char	_gc_set;
extern char	_egc_set;
extern char	_lines;
extern char	_alanog;

void		GraphicLineSet(int Lines);
void		GraphicColorMode(int ColorMode);
void		GraphicON(void);
void		GraphicOFF(void);
void		GraphicGdcON(void);
void		GraphicGdcOFF(void);

void		PaletteInit(void);
void		PaletteAll(unsigned int *ColorCode);
void		Palette(int ColorNo, int ColorCode);

void		VsyncStart(void);


/* gdc */

void		SetPen(int Pattern, int Writemode);

void		GdcLine(int X1, int Y1, int X2, int Y2, int Color);
void		GdcBox(int X1, int Y1, int X2, int Y2, int Color);
void		GdcCircle(int XC, int YC, int RR, int Color);
void		GdcScroll(int Line);

void		KanjiGputc(unsigned int Kanji, int XP, int YP, int Color);


/* grcg */

void		GrcgReset(void);
void		GrcgReadSet(void);
void		GrcgSet(void);
void		GrcgColor(int Color);

void		GraphicCls(int Color);
void		GraphicBoxf(int X1, int Y1, int X2, int Y2, int Color);


/* egc */

void		GraphicMove(int X1, int Y1, int X2, int Y2, int X3, int Y3);
void		EgcGraphicBoxf(int X1,int Y1,int X2,int Y2,int Color);
void		EgcKanjiGputc(unsigned int KANJI,int XP,int YP,int COLOR);


/* kdb */

unsigned int	GetKeyType(void);
unsigned int	GetKbType(void);

unsigned char	GetKeyBeepMode(void);
void		KeyBeepOn(void);
void		KeyBeepOff(void);

unsigned char	KeyTouch(int KeyCodeGroup);

void		CapsSwitch(unsigned int sw);
void		KanaSwitch(unsigned int sw);

/* rs232c */

void		RsOpen(int speed, int datalen, int parity, int stopbit, int flow);
void		RsReOpen(int datalen, int parity, int stopbit, int flow);
void		RsClose(void);

void		RsSendBreak(void);
void		RsBreakOn(void);
void		RsBreakOff(void);

void		SetErOn(void);
void		SetErOff(void);
void		SetRsOn(void);
void		SetRsOff(void);

int		CheckEr(void);
int		CheckRs(void);
int		CheckCd(void);
int		CheckCs(void);
int		CheckCi(void);
int		CheckDr(void);

int		ReceiveData(void);
int		ReceiveLength(void);
int		ReceiveSpace(void);

void		TransData(int txdata);
int		TransLength(void);
int		TransSpace(void);

int		GetSpeed(void);
int		SetSpeed(int num);


/* peri */

unsigned char	DriveToDaua(unsigned char drive);

unsigned int	ExistExtRom(unsigned int segment);

unsigned char	GetMemorySwitch(unsigned char number);
void		SetMemorySwitch(unsigned char number, unsigned char value);

int		ExistMouseIF(void);

unsigned int	GetPrnStat(void);
void		PrinterSelect(void);

unsigned int	ExistSoundBoard(void);


#endif

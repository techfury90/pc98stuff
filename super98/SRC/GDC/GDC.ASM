;=================================================
;	PC9801 GDC routines
;		      1991 10/1	ZOBplus	Hayami
;=================================================
		
		TITLE 	GDC routines

		.MODEL	small,C
		

		.DATA
		EXTRN	_gdc_clock  : BYTE
		EXTRN	_board16_set: BYTE
		EXTRN	_egc_set    : BYTE
		PUBLIC  _vram_offset
_vram_offset	dw	0		; VRAM オフセットアドレス
lx01		dw	?		; 開始座標ワーク
ly01		dw	?		;
lx02		dw	?		; 終点座標ワーク
ly02		dw	?		;
lndx		dw	?		; x 座標差
lndy		dw	?		; y 座標差
lrr		dw	?		; 半径 r
ead		dw	?		; GDC vram address
dad		db	?		; GDC vram bits
dir		db	?		; DIR register 格納	
dc_reg		dw	?		; DC registrer
d_reg		dw	?		; D  registrer
d2_reg		dw	?		; D2 registrer
d1_reg		dw	?		; D1 registrer
dm_reg		dw	?		; DM registrer
voff		dw	?		; GDC vram offset 格納
color_d		dw	?		; Color データ

sad1l		dw	0
sad1h		db	0		
sl1		dw	400
sad2l		dw	0
sad2h		db	0		
sl2		dw	0
		
		.CODE
		EXTRN  GrcgSet   : NEAR
		EXTRN  GrcgReset : NEAR
		EXTRN  GrcgColor  : NEAR
		EXTRN  VsyncCheck: NEAR	
	
		PUBLIC	SetPen,GdcLine,GdcBox,GdcCircle,GdcScroll
;---------------------------------------------------------
;  GDC ペンモードセット
;  void SetPen(int Pattern,int Writemode)
;  IN : int Pattern ラインパターン
;	int Writemode ドット修正モード
;           0:REPLACE, 1:COMPLEMENT, 2:CLEAR, 3:SET
;---------------------------------------------------------
SetPen		PROC Pattern:WORD,Writemode:WORD
		mov	al,78h		; TEXTW コマンド
		call	CommOut
		mov	ax,Pattern
		call	ParaOutWord
		mov	ax,Writemode
		or	al,20h
		call	CommOut		; WRITE コマンド
		ret
SetPen		ENDP		 		

;---------------------------------------------------------
;  GDCグラフィックライン描画 
;  void GdcLine(int X1,int Y1,int X2,int Y2,int Color)
;  IN : int X1,Y1 開始点座標
;       int X2,Y2 終点座標
;       int Color 色番号
;---------------------------------------------------------  
GdcLine		PROC X1:WORD,Y1:WORD,X2:WORD,Y2:WORD,Color:WORD
		push	si
		push	di

		mov	ax,Color
		mov	[color_d],ax
		mov	ax,X1
		mov	bx,X2
		mov	cx,Y1
		mov	dx,Y2
		call	PointAdjust
		call	DirSet
		call	GdcAdrSet
		call	VectwLineSet	
		cmp	[_egc_set],0
		jz	gline_1
		call	DrawLineGc
		jmp	SHORT gline_2
gline_1:	call	DrawLine
gline_2:	pop	di
		pop	si
		ret
GdcLine		ENDP

;---------------------------------------------------------
;  GDCグラフィックボックス描画 
;  void GdcBox(int X1,int Y1,int X2,int Y2,int Color)
;  IN : int X1,Y1 開始点座標
;       int X2,Y2 終点座標
;       int Color 色番号
;---------------------------------------------------------  
GdcBox		PROC X1:WORD,Y1:WORD,X2:WORD,Y2:WORD,Color:WORD
		push	si
		push	di
		mov	ax,Color
		mov	[color_d],ax
		mov	ax,X1
		mov	bx,X2
		mov	cx,Y1
		mov	dx,Y2
		call	PointAdjust
		mov	ax,X1
		cmp	ax,X2
		jz	line_entry
		mov	ax,Y1
		cmp	ax,Y2
		jz	line_entry
		mov	ax,[ly01]
		mov	dx,[ly02]
		cmp	ax,dx
		jbe	gbox_1
		mov	[ly01],dx
		mov	[ly02],ax
gbox_1:
		call	GdcAdrSet
		call	VectwBoxSet	
gbox_4:		
		cmp	[_egc_set],0
		jz	gbox_2
		call	DrawLineGc
		jmp	SHORT gbox_3
gbox_2:		call	DrawLine
gbox_3:		pop	di
		pop	si
		ret
line_entry:
		call	DirSet
		call	GdcAdrSet
		call	VectwLineSet	
		jmp	gbox_4
GdcBox		ENDP

;----------- ポイント調整

PointAdjust:
		cmp	ax,bx		; X1 > X2 なら X1<=>X2 , Y1<=>Y2       
		jb	padj_1
		jz	padj_3	
		xchg	ax,bx
		xchg	cx,dx
		jmp	SHORT padj_1
padj_3:
		cmp	cx,dx
		jbe	padj_1
		xchg	cx,dx
padj_1:
		mov	[lx01],ax
		mov	[lx02],bx
		mov	[ly01],cx
		mov	[ly02],dx
		sub	bx,ax
		mov	[lndx],bx	; abs(X2 - X1)
		sub	dx,cx
		jae	padj_2
		neg	dx
padj_2:		mov	[lndy],dx	; abs(Y2 - Y1)
		ret


;-----------   GDC vram アドレス設定

GdcAdrSet:	
		mov	cx,[ly01]
		mov	ax,40
		mul	cx
		mov	di,ax
		mov	ax,[lx01]
		mov	dx,ax
		mov	cl,4
		shr	ax,cl
		add	di,ax
		and	dx,000Fh
		mov	[ead],di
		mov	[dad],dl
		ret
;-----------   Direction 設定

DirSet:
		mov	ax,[ly01]
		mov	cx,[ly02]
		mov	si,[lndx]
		mov	di,[lndy]
		cmp	ax,cx
		jb	dirs_2
		mov	dl,2			; dir = 2
		cmp	si,di
		ja	dir_set
		inc	dl			; dir = 3
		jmp	SHORT dirch_set
dirs_2:
		mov	dl,1			; dir = 1
		cmp	si,di
		jae	dir_set
dirs_3:
		dec	dl			; dir = 0
dirch_set:		
		mov	[lndx],di		; △X←→△Y
		mov	[lndy],si
dir_set:	or	dl,08h			; LINE 描画設定
		mov	[dir],dl		; DIR セット
		ret

;---------- Vectw Line Parameter Set

VectwLineSet:
		mov	ax,[lndx]
		mov	[dc_reg],ax		; DC Register 設定
		mov	ax,[lndy]		; △X
		shl	ax,1			; △X * 2
		sub	ax,[lndx]
		mov	[d_reg],ax		; D Register 設定
		mov	ax,[lndy]		; △Y	
		sub	ax,[lndx]		; △X
		shl	ax,1			; 2 * (△Y-△X)
		mov	[d2_reg],ax		; D2 Register 設定
		mov	ax,[lndy]		; △Y
		shl	ax,1			; △Y * 2
		mov	[d1_reg],ax		; D1 Register 設定
		mov	[dm_reg],-1		; DM Register Dumy
		ret


;---------- Vectw Box Parameter Set

VectwBoxSet:
		mov	[dir],40h		; Box Command 設定
		mov	[dc_reg],3		; DC Register 設定
		mov	ax,[lndy]
		mov	[d_reg],ax		; D Register 設定
		mov	[dm_reg],ax		; DM Register 設定
		mov	ax,[lndx]
		mov	[d2_reg],ax		; D2 Register 設定
		mov	[d1_reg],-1		; D1 Register 設定
		ret

;-----------   Draw line by GRCG ライン描画

DrawLineGc:
		pushf	
		cli
		mov	[voff],4000h
		call	GrcgSet
		call	CsrCommand
		call	VectwCommand
		mov	ax,[color_d]
		push	ax
		call	GrcgColor
    		add	sp,2 
		mov	al,6ch
		call	CommOut			; VECTE 描画開始コマンド
		call	GdcBusy	
		call	GrcgReset
		popf
		ret

;-----------   Draw line normal ライン描画

DrawLine:
		pushf	
		cli
		mov	[voff],4000h
		mov	dx,[color_d]
		mov	cx,3
		add	cl,[_board16_set]
dline_1:		
		push	cx
		push	dx
		mov	ax,dx
		and	ax,1
		or	al,022h
		call	CommOut			; Write mode コマンド
		call	CsrCommand
		call	VectwCommand
		mov	al,6ch
		call	CommOut			; VCTE 描画開始コマンド
		add	[voff],4000h
		pop	dx
		pop	cx
		shr	dx,1
		loop	dline_1
		call	GdcBusy	
		popf
		ret


;---------------------------------------------------------
;  GDCグラフィックサークル描画 
;  void GdcCircle(int XC,int YC,int RR,int Color)
;  IN : int XC,YC 中心点座標
;       int RR    半径
;       int Color 色番号
;---------------------------------------------------------  

GdcCircle	PROC XC:WORD,YC:WORD,RR:WORD,Color:WORD
		push	si
		push	di
		mov	ax,Color
		mov	[color_d],ax
		mov	ax,RR
		mov	[lrr],ax
		mov	cx,XC
		mov	dx,YC
		cmp	[_egc_set],0
		jz	gcircle_1
		call	DrawCircleGc
		jmp	SHORT gcircle_2
gcircle_1:
		call	DrawCircle
gcircle_2:
		pop	di
		pop	si
		ret
GdcCircle	ENDP

;---------- Vectw Circle Parameter Set

VectwCircleSet:
		mov	ax,[lrr]
		mov	dx,14142
		mul	dx
		mov	cx,20000		; 半径 / sqrt(2)
		div	cx
		inc	ax
		mov	[dc_reg],ax		; DC Register 設定
		mov	ax,[lrr]
		dec	ax
		mov	[d_reg],ax		; D Register 設定
		shl	ax,1
		mov	[d2_reg],ax		; D2 Register 設定
		mov	[d1_reg],-1		; D1 Register 設定
		mov	[dm_reg],0		; DM Register 設定
		ret


;-----------   Draw Circle by GRCG サークル描画 

DrawCircleGc:
		pushf	
		cli
		sub	cx,[lrr]
		mov	[lx01],cx
		mov	[ly01],dx
		mov	[voff],4000h
		call	GrcgSet
		mov	ax,[color_d]
		push	ax
		call	GrcgColor
    		add	sp,2 
		call	GdcAdrSet
		call	VectwCircleSet	
		mov	[dir],20h		; dir = 0
		call	DCGsub
		mov	[dir],23h		; dir = 3
		call	DCGsub
		
		mov	ax,[lrr]
		add	[lx01],ax
		sub	[ly01],ax
		call	GdcAdrSet
		call	VectwCircleSet	
		mov	[dir],21h		; dir = 1
		call	DCGsub
		mov	[dir],26h		; dir = 6
		call	DCGsub
		
		mov	ax,[lrr]
		add	ax,ax
		add	[ly01],ax
		call	GdcAdrSet
		call	VectwCircleSet	
		mov	[dir],22h		; dir = 2
		call	DCGsub
		mov	[dir],25h		; dir = 5
		call	DCGsub
		
		mov	ax,[lrr]
		add	[lx01],ax
		sub	[ly01],ax
		call	GdcAdrSet
		call	VectwCircleSet	
		mov	[dir],24h		; dir = 4
		call	DCGsub
		mov	[dir],27h		; dir = 7
		call	DCGsub
		mov	cx,70			;
		loop	$
		call	GdcBusy	
		call	GrcgReset
		popf
		ret
		
DCGsub:		
		call	CsrCommand
		call	VectwCommand
		mov	al,6ch
		call	CommOut			; VCTE 描画開始コマンド
		ret


;-----------   Draw Circle Normal サークル描画 

DrawCircle:
		pushf	
		cli
		sub	cx,[lrr]
		mov	[lx01],cx
		mov	[ly01],dx
		call	GdcAdrSet
		call	VectwCircleSet	
		mov	[dir],20h		; dir = 0
		call	DCsub
		mov	[dir],23h		; dir = 3
		call	DCsub
		
		mov	ax,[lrr]
		add	[lx01],ax
		sub	[ly01],ax
		call	GdcAdrSet
		call	VectwCircleSet	
		mov	[dir],21h		; dir = 1
		call	DCsub
		mov	[dir],26h		; dir = 6
		call	DCsub
		
		mov	ax,[lrr]
		add	ax,ax
		add	[ly01],ax
		call	GdcAdrSet
		call	VectwCircleSet	
		mov	[dir],22h		; dir = 2
		call	DCsub
		mov	[dir],25h		; dir = 5
		call	DCsub
		
		mov	ax,[lrr]
		add	[lx01],ax
		sub	[ly01],ax
		call	GdcAdrSet
		call	VectwCircleSet	
		mov	[dir],24h		; dir = 4
		call	DCsub
		mov	[dir],27h		; dir = 7
		call	DCsub
		call	GdcBusy	
		popf
		ret
		
DCsub:		
		mov	[voff],4000h
		mov	dx,[color_d]
		mov	cx,3
		add	cl,[_board16_set]
dcircle_1:		
		push	cx
		push	dx
		mov	ax,dx
		and	ax,1
		or	al,022h
		call	CommOut			; Write mode コマンド
		call	CsrCommand
		call	VectwCommand
		mov	al,6ch
		call	CommOut			; VCTE 描画開始コマンド
		add	[voff],4000h
		pop	dx
		pop	cx
		shr	dx,1
		loop	dcircle_1
		ret
		
;-----------   Csrw command

CsrCommand:
		mov	al,49h			; CSRW コマンド
		call	CommOut
		mov	ax,[ead]
		add	ax,[voff]
		call	ParaOutWord
		mov	al,[dad]
		mov	cl,4
		shl	al,cl
		call	ParaOutByte
		ret

;-----------   Vectw command

VectwCommand:
		mov	al,4ch			; VECTW コマンド
		call	CommOut
		mov	al,[dir]
		call	ParaOutByte		; DIR register 設定
		mov	ax,[dc_reg]
		cmp	[_gdc_clock],0
		jz	vec_1
		or	ax,4000h
vec_1:		call	ParaOutWord		; DC register 設定
		mov	ax,[d_reg]
		call	ParaOutWord		; D register 設定
		mov	ax,[d2_reg]
		call	ParaOutWord		; D2 register 設定
		mov	ax,[d1_reg]
		call	ParaOutWord		; D1 register 設定
		mov	ax,[dm_reg]
		cmp	ax,-1
		jz	vec_2
		call	ParaOutWord		; DM register 設定
vec_2:		ret


;---------------------------------------------------------
;  GDCグラフィックスクロール 
;  void GdcScroll(int Line)
;  IN : int Line  スクロールするライン数
;---------------------------------------------------------  

GdcScroll	PROC	Line : WORD
		push	si
		call	VsyncCheck
		mov	ax,Line
		or	ax,ax
		js	scroll_down	
scroll_up:		
		push	ax
		mov	dx,40
		mul	dx
		add	[sad1l],ax
		pop	ax
		add	[sl2],ax
		sub	[sl1],ax
		ja	scroll_set
		sub	[sl2],400
		sub	[sad1l],400*40
		add	[sl1],400
		jmp	SHORT scroll_set
scroll_down:
		neg	ax
		push	ax
		mov	dx,40
		mul	dx
		sub	[sad1l],ax
		pop	ax
		add	[sl1],ax
		sub	[sl2],ax
		jae	scroll_set
		add	[sl2],400
		add	[sad1l],400*40
		sub	[sl1],400

scroll_set:
		mov	ax,[sad1l]
		shl	ax,1
		mov	[_vram_offset],ax
		call	ScrollDataSet
		pop	si	
		ret
GdcScroll	ENDP
		
ScrollDataSet:
		sub	bx,bx			; bx = 0
		mov	cx,4
		mov	si,offset DGROUP:sad1l
		lodsb
		call	SDSsub
		inc	bx
		lodsb
		call	SDSsub
		inc	bx
		lodsb
		mov	ah,al
		lodsb
		mov	dl,al
		shl	al,cl
		shr	dl,cl
		or	al,ah
		call	SDSsub
		inc	bx
		lodsb
		shl	al,cl
		or	al,dl
		cmp	[_gdc_clock],0
		jz	scf_0
		or	al,40h		;
scf_0:		call	SDSsub
		inc	bx
		lodsb
		call	SDSsub
		inc	bx
		lodsb
		call	SDSsub
		inc	bx
		lodsb
		mov	ah,al
		lodsb
		mov	dl,al
		shl	al,cl
		shr	dl,cl
		or	al,ah
		call	SDSsub
		inc	bx
		lodsb
		shl	al,cl
		or	al,dl
		cmp	[_gdc_clock],0
		jz	scf_1
		or	al,40h		;
scf_1:		call	SDSsub
		call	SDSsub
		ret				

SDSsub:
		push	ax
		mov	al,70h
		or	al,bl
		out	0A2h,al
		pop	ax
		out	0A0h,al
		ret		

;------------  Command out
;
CommOut:	push	ax
		call	FifoNotFull
		pop	ax
		out	0A2h,al
		ret

;------------  Parameter out byte
;
ParaOutByte:	push	ax
		call	FifoNotFull
		pop	ax
		out	0A0h,al
		ret

;------------  Parameter out word
;
ParaOutWord:	call	ParaOutByte
		xchg	ah,al
		call	ParaOutByte
		xchg	ah,al
		ret

FifoNotFull:
		jmp	$+2
		in	al,0A0h
		test	al,02h		; FIFO FULL 
		jmp	$+2	
		jmp	$+2	
		jne	FifoNotFull
		ret

GdcBusy:	
gbusy_0:		
		in	al,0A0h
		test	al,04h		; FIFO Empty
		jmp	$+2	
		jmp	$+2	
		jz	gbusy_0
		push	cx
		mov	cx,16
		loop	$
		pop	cx
gbusy_1:		
		in	al,0A0h		; GDC Busy
		xor	al,04h
		test	al,0Ch
		jmp	$+2
		jmp	$+2
		jnz	gbusy_1
		ret
		
		END

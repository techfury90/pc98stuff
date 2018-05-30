;=================================================
;	PC9801 Graphic Initialize routine
;		      1991 10/1	ZOBplus	Hayami
;=================================================


		TITLE Graphic Initialize

		.MODEL small,C		; スモールモデル

		.DATA
;-------------------------------------------------
;	グラフィック関連グローバル変数
;-------------------------------------------------
		PUBLIC	_gc_set,_egc_set,_board16_set,_gdc_clock
		PUBLIC	_analog,_lines

_gc_set		db	0		; GRCG グラフィックチャージャー
					; 0 = 無し, 1 =	有り
_egc_set	db	0		; EGC エンハンストGRCG
					; 0 = 無し, 1 =	有り
_board16_set	db	0		; 16色ボード
					; 0 = 無し, 1 =	有り
_gdc_clock	db	0		; GDC クロック
					; 0 = 2.5MHz, 1	= 5MHz
_analog		db	0		; アナログ表示
					; 0 = デジタル表示, 1 =	アナログ表示
_lines		db	0		; 縦ライン数
					; 0 = 200 lines	, 1 = 400 lines

		.CODE
		PUBLIC	GraphicInit
;-----------------------------------------------------
;  グラフィック画面初期化
;  void	GraphicInit(int Lines, int ColorMode)
;  IN  :int Lines      0 = 200 lines
;		       1 = 400 lines
;	int ColorMode  0 = デジタル表示（8色）
;		       1 = アナログ表示（16色／4096）
;  RET : Nothing
;-----------------------------------------------------
GraphicInit	PROC Lines:WORD,ColorMode:WORD
		pushf
		cli			; 割り込み禁止
		call	GraphicOFF	; グラフィック表示停止
		call	GraphicSystem	; グラフィックシステムチェック
		mov	ax,Lines
		mov	[_lines],al	; グローバル変数設定
		push	ax
		call	GraphicLineSet
		add	sp,2
		mov	ax,ColorMode	; デジタル、アナログ設定
		mov	[_analog],al	; グローバル変数設定
		push	ax
		call	GraphicColorMode
		add	sp,2
		call	GraphicON	; グラフィック表示開始
		popf
		ret
GraphicInit		ENDP

;---------- グラフィック画面表示ON
GraphicON	PROC
		mov	ah,40h
		int	18h
		ret
GraphicON	ENDP


;---------- グラフィック画面表示OFF
GraphicOFF	PROC
		mov	ah,41h
		int	18h
		ret
GraphicOFF	ENDP

;---------- GDCグラフィック画面表示ON
GraphicGdcON	PROC
		call	FifoReady		; FIFO FULL?
		mov	al,0Dh			; 表示ONコマンド
		out	0A2h,al
		push	es
		mov	ax,0
		mov	es,ax
		mov	al,80h
		or	es:[054Ch],al
		pop	es
		ret
GraphicGdcON	ENDP


;---------- GDCグラフィック画面表示OFF
GraphicGdcOFF	PROC
		call	FifoReady		; FIFO FULL?
		mov	al,0Ch			; 表示OFFコマンド
		out	0A2H,al
		push	es
		mov	ax,0
		mov	es,ax
		mov	al,7Fh
		and	es:[054Ch],al
		pop	es
		ret
GraphicGdcOFF	ENDP

;---------- GDC	FIFO が空くまでループ
FifoReady	PROC
fifo_full:	in	al,0A2h		; GDCステータスリード
		test	al,02h		; FIFOがFULL？
		jmp	$+2		; ウェイト
		jmp	$+2		; ウェイト
		jne	fifo_full
		ret
FifoReady	ENDP


;---------- グラフィック縦ライン設定
;    int Line :	0 = 200lines, 1	= 400lines

GraphicLineSet	PROC Line : WORD
		mov	ax,Line
		cmp	ax,0
		jz	lines200
		cmp	ax,1
		jz	lines400
		jmp	SHORT lines_exit

lines200:
		mov	ch,10000000b		; LOWER	COLOR BANK0
		jmp	SHORT lines_go
lines400:
		mov	ch,11000000b		; ALL	COLOR BANK0
lines_go:
		mov	ah,42h
		int	18h			; Graphic BIOS
lines_exit:
		ret
GraphicLineSet	ENDP


;---------- デジタル／アナログカラーモード設定
;    int ColorMode : 0 = Degital, 1 = Analog

GraphicColorMode PROC ColorMode : WORD
		mov	ax,ColorMode
		out	06Ah,al
		ret
GraphicColorMode ENDP

;---------------------------------------------------------------
;  VSYNCのスタート時点をチェック
;  void VsyncStart()
; VYSNC	が発生していない状態から、発生が始まった時までループする
;---------------------------------------------------------------

		PUBLIC	VsyncStart
VsyncStart	PROC
vsync_ing:
		jmp	$+2		; ウェイト
		jmp	$+2		; ウェイト
		in	al,0A0h		; GDCステータスリード
		test	al,020h		; VSYNC	Check
		jnz	vsync_ing	; VSYNCが発生していたらLoop
		pushf
vsync_not:
		cli
		in	al,0A0h		; GDCステータスリード
		test	al,20h		; VSYNC	Check
		jnz	vsync_go
		popf
		pushf
		jmp	vsync_not
vsync_go:
		pop	ax
		ret
VsyncStart	ENDP



;---------- 垂直同期信号（VSYNC）が発生するまでループ
		PUBLIC	VsyncCheck
VsyncCheck	PROC
not_vsync:	in	al,0A0h		; GDCステータスリード
		test	al,20h		; VSYNC	Check
		jmp	$+2		; ウェイト
		jmp	$+2		; ウェイト
		jz	not_vsync
		ret
VsyncCheck	ENDP

;---------- グラフィックシステムデータ格納
GraphicSystem	PROC
		sub	ax,ax		; ax = 0
		mov	es,ax		; es = 0
		mov	al,es:[054Ch]	; GRCG 有無
		and	al,02h
		shl	al,1
		mov	[_gc_set],al	; GRCG グラフィックチャージャー
					; 0 = 無し, 1 =	有り
		mov	al,es:[054Ch]	; 16色ボード 有無
		and	al,04h
		mov	cl,2
		shr	al,cl
		mov	[_board16_set],al
		mov	al,es:[054Dh]
		mov	dl,al
		and	al,40h		; EGC 有無
		mov	cl,6
		shr	al,cl
		mov	[_egc_set],al	; EGC エンハンストGRCG
					; 0 = 無し, 1 =	有り
		and	dl,04h
		mov	cl,2
		shr	dl,cl		; GDCクロックを得る
		mov	[_gdc_clock],dl	; GDC クロック
					; 0 = 2.5MHz, 1	= 5MHz
		ret
GraphicSystem	ENDP
		END

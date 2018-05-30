;=================================================
;	PC9801 Graphic Charger routine 
;			by ZOBplus Hayami
;			1991 10/25
;=================================================

		TITLE	GRCG
		
		.MODEL	small,C
		
		.186			; GRCG搭載マシンはすべて186拡張命令
					; が使用可能
		
		.CODE
		PUBLIC GrcgReadSet,GrcgSet
		PUBLIC GrcgReset,GrcgColor	
;-------------------------------------------------
;  グラフィックチャージャ TCR TDW モード設定
;  void GrcgReadSet(void)
;-------------------------------------------------
GrcgReadSet	PROC
		mov	al,080h		; Grcg TCR TDW mode
		jmp	SHORT GrcgMode
GrcgReadSet	ENDP

;-------------------------------------------------
;  グラフィックチャージャ RMW モード設定
;  void GrcgSet(void)
;-------------------------------------------------
GrcgSet	PROC	
		mov	al,0C0h		; Grcg RMW mode
GrcgSet	ENDP

;---------- GRCG Set subroutine
GrcgMode:
		push	es
		push	0
		pop	es
		pushf
		cli
		out	7Ch,al
		mov	es:[0495h],al	; GRCG mode データ格納
		popf
		pop	es
		ret

;-------------------------------------------------
;  グラフィックチャージャ リセット
;  void GrcgReset(void)
;-------------------------------------------------
GrcgReset	PROC
		mov	al,0		; Grcg mode off
		jmp	SHORT GrcgMode
GrcgReset	ENDP

		
;-------------------------------------------------
; グラフィックチャージャタイルレジスタ設定		
;  void GrcgColor(int Color)
;  IN  : int Color タイルレジスタに設定する色番号
;-------------------------------------------------

GrcgColor	PROC Color : WORD	; Color = 0～15
		pushf
		cld
		push	di
		push	es
		mov	di,0496h	; Grcg Tile register 格納アドレス
		sub	ax,ax		; ax = 0
		mov	es,ax		; es = 0
		mov	ax,Color
		pushf
		cli
	REPT 4
		ror	al,1
		cbw			; bit = 1 のとき ah = FFh
		xchg	ah,al		; bit = 0 のとき ah = 0 となる
		out	07Eh,al		; Tile register にデータセット
		stosb			; システムワークへデータ格納
		xchg	ah,al
	ENDM
		popf
		pop	es
		pop	di
		popf
		ret
GrcgColor	ENDP
		
;-----------------------------------------------------
;  グラフィック画面消去
;  void	GraphicCls(int Color)
;  IN  : int Color 画面を消去する色番号
;-----------------------------------------------------
		
		PUBLIC	GraphicCls
GraphicCls	PROC Color : WORD
		push	di
		cld
		call	GrcgReadSet 	; TDW モードセット
		mov	ax,Color
		push	ax
		call	GrcgColor
		add	sp,2
		sub	di,di		; di = 0
		mov	ax,0A800h	; Plane 0 セグメント
		mov	es,ax
		mov	cx,80 * 400 / 2	; Plane 0 VRAM のバイト数 / 2
	rep	stosw			; cx ワード画面に書き込む axは不定
		call	GrcgReset	; GRCG リセット
		pop	di
		ret
GraphicCls		ENDP

;---------------------------------------------------------
;  グラフィックボックスフィル
;  void GraphicBoxf(int X1,int Y1,int X2,int Y2,int Color)
;  IN  : int X1,Y1 ボックス左上端座標
;        int X2,Y2 ボックス右下端座標
;	 int Color 塗り潰す色番号
;----------------------------------------------------------
		.DATA
xpats		dw	?			; 左端ビットデータ
xpate		dw	?			; 右端ビットデータ
lndx		dw	?			; 横バイト数
		
		.CODE		
		PUBLIC GraphicBoxf
GraphicBoxf	PROC X1:WORD,Y1:WORD,X2:WORD,Y2:WORD,Color:WORD
		push	di
		cld
		call	GrcgSet		; RMW モード設定
		mov	ax,Color
		push	ax
		call	GrcgColor		; GRCG タイルレジスタ設定
		add	sp,2
		mov	bx,X1			; bx = x1
		mov	dx,X2			; dx = x2
		mov	ax,639
		cmp	bx,ax
		jbe	gboxf_1
		mov	bx,ax
gboxf_1:
		cmp	dx,ax
		jbe	gboxf_2
		mov	dx,ax
gboxf_2:
		cmp	bx,dx
		jbe	not_xchg
		xchg	bx,dx			; X1 > X2 ならX1,X2を入れ替える
not_xchg:
		mov	cx,bx
		and	cx,00Fh
		mov	ax,0FFFFh
		shr	ax,cl	
		xchg	ah,al
		mov	[xpats],ax		; 左端のビットデータ
		mov	cx,dx
		and	cx,000Fh	
		sub	cx,000Fh
		neg	cx
		mov	ax,0FFFFh
		shl	ax,cl
		xchg	ah,al
		mov	[xpate],ax		; 右端のビットデータ
		shr	bx,4			; bx = x1
		mov	di,bx
		shr	dx,4			; dx = x2
		sub	dx,di
		dec	dx
		mov	[lndx],dx
		shl	di,1
		mov	ax,Y1
		mov	cx,Y2
		mov	dx,399
		cmp	ax,dx
		jbe	gboxf_3
		mov	ax,dx
gboxf_3:
		cmp	cx,dx
		jbe	gboxf_4
		mov	cx,dx
gboxf_4:
		cmp	ax,cx
		jbe	not_ychg
		xchg	ax,cx			; Y1 > Y2 ならY1,Y2を入れ替える
not_ychg:
		sub	cx,ax
		inc	cx
		mov	dx,80
		mul	dx
		add	di,ax			; di = 先頭VRAMアドレス
		call	BoxFill
		call	GrcgReset		; GRCG リセット
		pop	di
		ret
GraphicBoxf	ENDP

;---------- ボックスフィルサブルーチン
;  IN : di = 先頭VRAM アドレス, cx = 縦ライン数

BoxFill		PROC
		mov	ax,0A800h
		mov	es,ax
		mov	ax,[lndx]
		or	ax,ax
		js	boxf_1			; 横幅1word
		jz	boxf_2			; 横幅2word
;---------- 横幅3word以上
boxf_0:		
		mov	bx,[xpats]	;
		mov	dx,[xpate]
		mov	ax,0FFFFh
boxf_01:		
		push	cx
		push	di
		mov	cx,[lndx]
		mov	es:[di],bx
		add	di,2
	rep	stosw
		mov	es:[di],dx
		pop	di
		add	di,80
		pop	cx
		loop	boxf_01
boxf_exit:		
		ret

;---------- 横幅1word
boxf_1:
		mov	ax,[xpats]
		and	ax,[xpate]
boxf_11:	mov	es:[di],ax
		add	di,80
		loop	boxf_11
		jmp	boxf_exit	

;---------- 横幅2word
boxf_2:
		mov	ax,[xpats]
		mov	dx,[xpate]
boxf_21:		
		stosw
		mov	es:[di],dx
		add	di,80 - 2
		loop	boxf_21
		jmp	boxf_exit	
BoxFill		ENDP
		
		END

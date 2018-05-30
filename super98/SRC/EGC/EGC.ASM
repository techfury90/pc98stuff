;================================================
;	EGC Graphic Block Move
;		   1991/11/1
;                         by ZOBplus Hayami
;================================================

		TITLE	EGC
		
		.186
		.MODEL	small,C

		.DATA
lx01		dw	?
ly01		dw	?
lx02		dw	?
ly02		dw	?		
lx03		dw	?
ly03		dw	?		
lndx		dw	?
lndy		dw	?
sbitad		dw	?
dbitad		dw	?		
		
		.CODE
		
;---------------------------------------------------
;  GraphicMove(int X1,int Y1,int X2,int Y2,int X3,int Y3)
;	int X1, Y1 : 移動元左上ドット座標
;	int X2, Y2 : 移動元右下ドット座標
;	int X3, Y3 : 移動先左上ドット座標
;---------------------------------------------------
		PUBLIC	GraphicMove
GraphicMove	PROC	X1:WORD,Y1:WORD,X2:WORD,Y2:WORD,X3:WORD,Y3:WORD
		push	si
		push	di
		cld
		call	EgcSet
		mov	dx,04A4h	;Compare read = 1
		mov	ax,29F0h	;Write data = Pattern data
		out 	dx,ax		;shift Input = VRAM data
					;Pattern Reg = Change
					;ROP P AND S
		mov	ax,X1
		mov	dx,X2
		cmp	ax,dx
		jbe	gb_1	
		xchg	ax,dx	
gb_1:
		mov	[lx01],ax
		mov	[lx02],dx
		mov	ax,Y1
		mov	dx,Y2
		cmp	ax,dx
		jbe	gb_2	
		xchg	ax,dx	
gb_2:
		mov	[ly01],ax
		mov	[ly02],dx
		mov	ax,X3
		mov	dx,Y3
		mov	[lx03],ax
		mov	[ly03],dx
		
		imul	si,[ly01],80
		mov	ax,[lx01]
		shr	ax,3
		and	ax,0FFFEh
		add	si,ax		;移動元 Vram address
		
		imul	di,[ly03],80
		mov	ax,[lx03]
		shr	ax,3
		and	ax,0FFFEh
		add	di,ax		;移動先 Vram address
		
		mov	dx,[lx02]
		sub	dx,[lx01]
		inc	dx
		mov	[lndx],dx	; 移動ブロック横ドット幅
		mov	cx,[ly02]
		sub	cx,[ly01]
		inc	cx
		mov	[lndy],cx
		cmp	si,di
		jb	gb_back
		call	normal_move
		jmp	SHORT gb_exit
gb_back:	call	back_move
gb_exit:
		call	EgcReset
		pop	di
		pop	si
		ret
GraphicMove	ENDP


		

normal_move	PROC
		mov	dx,04AEh	;bit length
		mov	ax,[lndx]
		dec	ax
		out	dx,ax
		call	egc_offset	;RET: cx=word_length
		mov	dx,cx
		mov	cx,[lndy]
		push	ds
		mov	ax,0A800h	; Plane 0 segment
		mov	ds,ax
		mov	es,ax
move_loop:		
		push	cx
		push	si
		push	di
		mov	cx,dx
	rep	movsw
		pop	di
		pop	si
		pop	cx
		add	si,80
		add	di,80
		loop	move_loop	
		pop	ds
		ret
normal_move	ENDP

back_move	PROC
		imul	si,[ly02],80
		mov	ax,[lx02]
		shr	ax,3
		and	ax,0FFFEh
		add	si,ax
		
		mov	ax,[ly03]
		add	ax,[lndy]
		dec	ax
		imul	di,ax,80
		mov	ax,[lx03]
		add	ax,[lndx]
		dec	ax
		shr	ax,3
		and	ax,0FFFEh
		add	di,ax		;Destnation Vram address	
		mov	dx,04AEh	;bit length
		mov	ax,[lndx]
		dec	ax
		out	dx,ax
		
		call	egc_offsetb
		mov	dx,cx
		mov	cx,[lndy]
		
		std
		push	ds
		mov	ax,0A800h	; Plane 0 segment
		mov	ds,ax
		mov	es,ax
back_loop:		
		push	cx
		push	si
		push	di
		mov	cx,dx
	rep	movsw
		pop	di
		pop	si
		pop	cx
		sub	si,80
		sub	di,80
		loop	back_loop	
		pop	ds
		cld
		ret
back_move	ENDP


EgcSet		PROC
		push	es
		push	0
		pop	es
		pushf
		cli
		mov	al,80h		;CG mode
		out	7Ch,al
		mov	es:[0495h],al	; GRCG mode データ格納
		popf
		pop	es
		mov	al,07h
		out	6Ah,al
		mov	al,05h		;Extend mode
		out	6Ah,al
		mov	al,06h
		out	6Ah,al
		mov	dx,04A0h
		mov	ax,0fff0h	;ALL PLANE ACTIVE
		out	dx,ax
		mov	dx,04A2h
		mov	ax,0ffh	
		out	dx,ax	
		mov	dx,04A8h	;Mask Reg
		mov	ax,0ffffh
		out	dx,ax
		mov	dx,04ACh	; dir , bit address
		sub	ax,ax		; ax = 0
		out	dx,ax
		mov	dx,04AEh	; bit length
		mov	ax,15
		out	dx,ax
		ret
EgcSet		ENDP

EgcReset	PROC
		mov	al,07h
		out	6Ah,al
		mov	al,04h		;Extend mode off
		out	6Ah,al	
		mov	al,06h
		out	6Ah,al
		push	es
		push	0
		pop	es
		pushf
		cli
		mov	al,0		;CG mode off
		out	7Ch,al
		mov	es:[0495h],al	; GRCG mode data set
		popf
		pop	es
		ret
EgcReset	ENDP

egc_offset	PROC
		mov	ax,[lx01]
		and	ax,000Fh
		mov	[sbitad],ax
		mov	ax,[lx03]
		and	ax,000Fh
		mov	[dbitad],ax
		
		mov	ax,[sbitad]
		mov	dx,[dbitad]
		shl	dx,4
		or	ax,dx

		mov	dx,04ACh
		out	dx,ax	

		mov	cx,[dbitad]
		add	cx,[lndx]
		add	cx,15
		shr	cx,4
		mov	ax,[sbitad]
		cmp	ax,[dbitad]
		ja	egcoff_1
		jz	egcoff_2
		add	ax,[lndx]
		add	ax,15
		shr	ax,4
		mov	dx,[dbitad]
		add	dx,[lndx]
		add	dx,15		;
		shr	dx,4
		cmp	ax,dx
		jbe	egcoff_2	;		
		inc	cx		
		sub	di,2
		jmp	SHORT egcoff_2
egcoff_1:
		add	ax,[lndx]
		add	ax,15		;
		shr	ax,4
		mov	dx,[dbitad]
		add	dx,[lndx]
		add	dx,15		;
		shr	dx,4
		inc	cx		
		sub	di,2
egcoff_2:		
		ret				
egc_offset	ENDP

egc_offsetb	PROC
		mov	ax,[lx02]
		inc	ax
		and	ax,000Fh
		sub	ax,16
		neg	ax
		and	ax,000Fh
		mov	[sbitad],ax
	
		mov	ax,[lx03]
		add	ax,[lndx]
		and	ax,000Fh
		sub	ax,16
		neg	ax
		and	ax,000Fh
		mov	[dbitad],ax
		mov	ax,[sbitad]
		mov	dx,[dbitad]
		
		shl	dx,4
		or	ax,dx
		or	ax,1000h
		mov	dx,04ACh
		out	dx,ax	

		mov	cx,[dbitad]		;
		add	cx,[lndx]
		add	cx,15
		shr	cx,4
		mov	ax,[sbitad]
		cmp	ax,[dbitad]
		ja	egcoffb_1	
		jz	egcoffb_2
		add	ax,[lndx]
		add	ax,15		;
		shr	ax,4
		mov	dx,[dbitad]
		add	dx,[lndx]
		add	dx,15		;
		shr	dx,4
		cmp	ax,dx
		jbe	egcoffb_2	;		
		inc	cx
		add	di,2
		jmp	SHORT egcoffb_2
egcoffb_1:
		add	ax,[lndx]
		add	ax,15		;
		shr	ax,4
		mov	dx,[dbitad]
		add	dx,[lndx]
		add	dx,15		;
		shr	dx,4
		add	di,2
		inc	cx		
egcoffb_2:		
		ret				
egc_offsetb	ENDP


;---------------------------------------------------------
;  EGCグラフィックボックスフィル
;  void EgcGraphicBoxf(int X1,int Y1,int X2,int Y2,int Color)
;  IN  : int X1,Y1 ボックス左上端座標
;        int X2,Y2 ボックス右下端座標
;	 int Color 塗り潰す色番号
;----------------------------------------------------------
		.DATA
xpats		dw	?			; 左端ビットデータ
xpate		dw	?			; 右端ビットデータ
		
		.CODE		
		PUBLIC EgcGraphicBoxf
EgcGraphicBoxf	PROC X1:WORD,Y1:WORD,X2:WORD,Y2:WORD,Color:WORD
		push	di
		cld
		call	EgcSet		; RMW モード設定
		mov	ax,040FFh	; FGC ON
		mov	dx,04A2h
		out	dx,ax
		mov	ax,Color
		mov	dx,04A6h	; Foreground Color
		out	dx,ax	
		mov	dx,04A4h	;Compare read = 1
		mov	ax,02CACh	;Write data = Pattern data
		out 	dx,ax		;shift Input = CPU data
					;Pattern Reg = not Change
					;ROP = P･S + ~S･D
		mov	bx,X1		; bx = x1
		mov	dx,X2		; dx = x2
		mov	ax,639
		cmp	bx,ax
		jbe	egboxf_1
		mov	bx,ax
egboxf_1:
		cmp	dx,ax
		jbe	egboxf_2
		mov	dx,ax
egboxf_2:
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
		jbe	egboxf_3
		mov	ax,dx
egboxf_3:
		cmp	cx,dx
		jbe	egboxf_4
		mov	cx,dx
egboxf_4:
		cmp	ax,cx
		jbe	not_ychg
		xchg	ax,cx			; Y1 > Y2 ならY1,Y2を入れ替える
not_ychg:
		sub	cx,ax
		inc	cx
		mov	dx,80
		mul	dx
		add	di,ax			; di = 先頭VRAMアドレス
		call	EBoxFill
		call	EgcReset		; GRCG リセット
		pop	di
		ret
EgcGraphicBoxf	ENDP

;---------- ボックスフィルサブルーチン
;  IN : di = 先頭VRAM アドレス, cx = 縦ライン数

EBoxFill		PROC
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
EBoxFill	ENDP

;-----------------------------------------------------------------
;  void EgcKanjiGputc(unsigned int KANJI,int XP,int YP,int COLOR)
;  unsigned int KANJI : 漢字シフトJISコード
;           int XP    : 表示 横座標 0～639-16
;           int YP    : 表示 縦座標 0～400-16
;           int COLOR : 表示カラー 
;                       bit8 = 0 :普通文字 
;                            = 1 :太文字 
;-----------------------------------------------------------------  
KANJI_H		equ	16
		
		.DATA
kanji_data	dw	KANJI_H dup (?)
	
		.CODE
		PUBLIC	EgcKanjiGputc
EgcKanjiGputc	PROC NEAR USES si di,KANJI:WORD,XP:WORD,YP:WORD,COLOR:WORD
		cld
		mov	al,0Bh		;ビットアクセスモード
		out	68h,al		;kanji access control
		mov	ax,KANJI
	        ;--- シフトJIS→JIS変換
	        xchg	ah,al
	        shl     ah,1
	        sub     al,1fh
      	  	js      kgput_1
        	cmp     al,061h
        	adc     al,0deh
kgput_1:
        	add     ax,1fa1h
        	and     ax,07f7fh
		sub	ah,20h
					; ax = Kanji JIS code
		out	0A1h,al
		xchg	ah,al
		out	0A3h,al
		mov	ax,ds
		mov	es,ax
		mov	di,OFFSET DGROUP:kanji_data
		push	ds
		mov	cx,16
		mov	ax,0A400h
		mov	ds,ax	
		sub	si,si		; si = 0	
	rep	movsw
		pop	ds
		
		mov	al,0Ah		; コードアクセスモード
		out	68h,al		;kanji access control
		test	COLOR,010h
		jnz	kgput_4
		jmp	kgput_3
		;--- 太文字データ処理
kgput_4:
		mov	si,OFFSET DGROUP:kanji_data
		mov	di,si
	REPT KANJI_H
		lodsw
		mov	dx,ax
		rol	dx,1
		or	ax,dx
		stosw	
	ENDM
kgput_3:
		mov	bx,XP
		mov	cx,YP
		mov	dx,COLOR
		and	dx,0Fh
		mov	si,OFFSET DGROUP:kanji_data
		call	EgcView16
		ret
EgcKanjiGputc	ENDP


EgcView16	PROC		
		push	dx
		imul	di,cx,80
		mov	ax,bx
		shr	ax,3
		add	di,ax
		call	EgcSet
		mov	ax,040FFh	; FGC ON
		mov	dx,04A2h
		out	dx,ax
		pop	ax
		mov	dx,04A6h	; Foreground Color
		out	dx,ax	
		mov	dx,04A4h	;Compare read = 1
		mov	ax,02CA0h	;Write data = Pattern data
		out 	dx,ax		;shift Input = CPU data
					;Pattern Reg = not Change
					;ROP = P･S
		mov	ax,0A800h
		mov	es,ax
		mov	cx,KANJI_H
		and	bx,7
		jz	not_shift
shift_data:
		push	cx
		sub	dx,dx
		lodsw
		xchg	ah,al
		mov	cx,bx
shift_loop:
		shr	ax,1
		rcr	dl,1
		loop	shift_loop
		mov	es:[di+2],dl
		xchg	ah,al
		mov	es:[di],ax
		add	di,80
		pop	cx
		loop	shift_data
		jmp	SHORT view16_exit
not_shift:
		lodsw
		mov	es:[di],ax
		add	di,80
		loop	not_shift
view16_exit:
		call	EgcReset
		ret
EgcView16	ENDP
		END

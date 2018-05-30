;=================================================
;	PC9801 Graphic Kanji Put routine 
;			by ZOBplus Hayami
;			1991 11/10
;=================================================

		TITLE	GPUTC
		
		.MODEL	small,C
		
		.186			; GRCG搭載マシンはすべて186拡張命令
					; が使用可能
		
		EXTRN	GrcgSet  : NEAR
		EXTRN	GrcgColor  : NEAR
		EXTRN	GrcgReset  : NEAR

KANJI_H		equ	16
		
		.DATA
kanji_data	dw	KANJI_H dup (?)
	
		.CODE
;-------------------------------------------------------------
;  void KanjiGputc(unsigned int KANJI,int XP,int YP,int COLOR)
;  unsigned int KANJI : 漢字シフトJISコード
;           int XP    : 表示 横座標 0～639-16
;           int YP    : 表示 縦座標 0～400-16
;           int COLOR : 表示カラー 
;                       bit8 = 0 :普通文字 
;                            = 1 :太文字 
;--------------------------------------------------------------  
		PUBLIC	KanjiGputc
KanjiGputc	PROC NEAR USES si di,KANJI:WORD,XP:WORD,YP:WORD,COLOR:WORD
		cld
		mov	al,0Bh		;ビットマップモード
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
		sub	ax,ax		; ax = 0
		mov	es,ax
		test	BYTE PTR es:[054Dh],01000000b
		mov	ax,ds
		mov	es,ax
		mov	di,OFFSET DGROUP:kanji_data
		jz	io_read	
cgw_read:
		push	ds
		mov	cx,16
		mov	ax,0A400h
		mov	ds,ax	
		sub	si,si		; si = 0	
	rep	movsw
		pop	ds
		jmp	SHORT kgput_2	
io_read:		
		mov	cx,0
ior_1:		
		mov	ax,cx
		or	al,020h	
		out	0A5h,al
		in	al,0A9h
		stosb
		mov	ax,cx
		out	0A5h,al
		in	al,0A9h
		stosb
		inc	cx
		cmp	cx,KANJI_H
		jnz	ior_1
kgput_2:
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
		call	View16
		ret
KanjiGputc	ENDP


View16		PROC		
		imul	di,cx,80
		mov	ax,bx
		shr	ax,3
		add	di,ax
		call	GrcgSet
		push	dx
		call	GrcgColor
		add	sp,2
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
		call	GrcgReset
		ret
View16		ENDP
		END

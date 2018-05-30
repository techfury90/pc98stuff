; 警告音発生プログラム

code	segment
	assume	cs:code,ds:code

	org	100h

p_start:
	jmp	p_entry

pro_id	db	'WARNING SOUND2',0	; 常駐チェック用ID

	even
iv_adr	label	dword
iv_ofs	dw	0		; オフセット保存用
iv_seg	dw	0		; セグメント保存用

count	db	0		; 持続時間カウンタ

; CRTVエントリ

v_intr	proc far
	push	ax
	push	bx
	mov     al,cs:count
	inc     cs:count
	cmp     al,55
	jnz     v_chk
	mov	cs:count,0

v_chk:
	cmp     al,0
	jz      b_on
	cmp     al,2
	jz      b_off
	cmp     al,5
	jz      b_on
	cmp     al,7
	jz      b_off
	cmp     al,10
	jz      b_on
	cmp     al,20
	jz      b_off
	jmp	short v_end

b_on:
	mov	al,06h
	out	37h,al		; beep ON
	jmp	short v_end

b_off:
	mov	al,07h
	out	37h,al		; beep OFF
	jmp	short v_end

v_end:
	out	64h,al		; 次回のCRTV割り込みの用意

	mov	al,20h
	out	00h,al		; 割り込みコントローラにEOIを発行
	pop	bx
	pop	ax
	iret
v_intr endp


p_entry proc
	mov	ax,cs
	mov	ds,ax
	mov	es,ax

	mov	ax,350ah
	int	21h		; INT-0AH ベクタ読み出し
	mov	iv_ofs,bx
	mov	iv_seg,es

	mov	di,offset pro_id
	mov	si,di
	mov	cx,15
	cld
	repe cmpsb		; 常駐チェック
	jz	remove		; 常駐解除

	pushf
	cli
	sub	ax,ax		; 割り込みベクタテーブルのセグメント:0000H
	mov	es,ax
	mov	ax,offset v_intr	; 自前のCRTV割り込み処理
	mov	es:[0028h],ax
	mov	es:[002ah],cs

	in	al,02h		; 割り込みコントローラのIMR
	and	al,11111011b	; CRTV割り込みを許可
	out	02h,al		; IMRを書き込む
	popf

	out	64h,al

	mov	es,word ptr cs:[002ch]	; 環境エリアのセグメント取得
	mov	ax,4900h
	int	21h		; 環境エリアを解放

	mov	dx,offset p_entry
	mov	cl,4
	shr	dx,cl
	inc	dx		; 常駐サイズ計算
	mov	ax,3100h
	int	21h		; 常駐終了

; 常駐解除の処理

remove:
	pushf
	cli
	in	al,02h		; 割り込みコントローラのIMR
	or	al,00000100b	; CRTV割り込みを禁止
	out	02h,al		; IMRを書き込む

	mov	al,07h
	out	37h,al		; beep OFF

	mov	es,iv_seg	; 常駐プログラムのセグメント
	mov	dx,es:iv_ofs	; 常駐プログラム内のINT-0AH元ベクタ
	mov	cx,es:iv_seg	; 常駐プログラム内のINT-0AH元ベクタ
	sub	ax,ax		; セグメント:0000H
	mov	es,ax
	mov	es:[0028h],dx
	mov	es:[002ah],cx
	popf

	mov	es,iv_seg	; 常駐プログラムのセグメント
	mov	ax,4900h
	int	21h		; 常駐部のコードエリアを解放

	mov	ax,4c00h
	int	21h		; 終了
p_entry endp

code	ends
	end	p_start

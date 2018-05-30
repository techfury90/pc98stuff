; キークリック音発生プログラム

code	segment
	assume	cs:code,ds:code

	org	100h

p_start:
	jmp	p_entry

pro_id	db	'KEY_CLICK3',0	; 常駐チェック用ID

	even
iv_adr	dd	8 dup (0)

entmask	db	0


iv_08h	proc far
	int	08h		; 本来の割り込み処理を起動
	iret
iv_08h	endp

iv_09h	proc far
	int	09h		; 本来のキーボード割り込み処理を起動

	push	ax
	in	al,43h		; ステータス
	test	al,02h		; 受信データがあるか
	pop	ax
	jnz	iv_end		; 受信データがあれば受信データは読まない
	push	ax
	in	al,41h		; キーボードからの受信データを読む
	test	al,80h		; 0:Make, 1:Break
	pop	ax
	jnz	iv_end

	cmp	cs:entmask,0	; 再入チェック
	jnz	iv_end
	mov	cs:entmask,1
	sti			; 割り込みを許可
	push	ax
	mov	al,06h		; ビープON
	out	37h,al
	mov	ax,1000
cloop:
	out	5fh,al		; ウェイトポート
	dec	ax
	jnz	cloop
	mov	al,07h		; ビープOFF
	out	37h,al
	pop	ax
	mov	cs:entmask,0
iv_end:
	iret
iv_09h	endp

iv_0ah	proc far
	int	0ah		; 本来の割り込み処理を起動
	iret
iv_0ah	endp

iv_0bh	proc far
	int	0bh		; 本来の割り込み処理を起動
	iret
iv_0bh	endp

iv_0ch	proc far
	int	0ch		; 本来の割り込み処理を起動
	iret
iv_0ch	endp

iv_0dh	proc far
	int	0dh		; 本来の割り込み処理を起動
	iret
iv_0dh	endp

iv_0eh	proc far
	int	0eh		; 本来の割り込み処理を起動
	iret
iv_0eh	endp

iv_0fh	proc far
	int	0fh		; 本来の割り込み処理を起動
	iret
iv_0fh	endp


p_entry proc
	mov	ax,cs
	mov	ds,ax
	mov	ax,3588h
	int	21h		; 常駐プログラムのベクタ読み出し
	mov	di,offset pro_id
	mov	si,di
	mov	cx,10
	cld
	repe cmpsb		; 常駐チェック
	jz	remove		; 常駐解除

	cli
	mov	di,offset iv_adr
	mov	al,88h		; INT-88H～INT-8FHを使用
	mov	cx,8
vr_loop:
	mov	ah,35h
	int	21h		; ベクタ読み出し
	mov	[di],bx
	add	di,2
	mov	[di],es
	add	di,2
	inc	al
	loop	vr_loop

	mov	si,offset iv_tbl
	mov	al,88h		; INT-88H～INT-8FHを使用
	mov	cx,8
vw_loop:
	mov	dx,[si]
	add	si,2
	mov	ah,25h
	int	21h		; ベクタ書き込み
	inc	al
	loop	vw_loop

	mov	al,11h
	out	00h,al		; ICW1を書き込む
	mov	al,88h		; 使用ベクタ番号88H～8FH
	out	02h,al		; ICW2を書き込む
	mov	al,80h
	out	02h,al		; ICW3を書き込む
	mov	al,1dh
	out	02h,al		; ICW4を書き込む
	sti

	mov	es,word ptr cs:[002ch]	; 環境エリアのセグメント取得
	mov	ax,4900h
	int	21h		; 環境エリアを解放

	mov	dx,offset p_entry
	mov	cl,4
	shr	dx,cl
	inc	dx		; 常駐サイズ計算
	mov	ax,3100h
	int	21h		; 常駐終了

iv_tbl	dw	iv_08h
	dw	iv_09h
	dw	iv_0ah
	dw	iv_0bh
	dw	iv_0ch
	dw	iv_0dh
	dw	iv_0eh
	dw	iv_0fh

; 常駐解除の処理

remove:
	cli
	mov	al,11h
	out	00h,al		; ICW1を書き込む
	mov	al,08h		; 使用ベクタ番号08H～0FH
	out	02h,al		; ICW2を書き込む
	mov	al,80h
	out	02h,al		; ICW3を書き込む
	mov	al,1dh
	out	02h,al		; ICW4を書き込む

	mov	ax,3588h
	int	21h		; 常駐プログラムのベクタ読み出し
	mov	si,offset iv_adr
	mov	al,88h		; INT-88H～INT-8FHを使用
	mov	cx,8
rm_loop:
	mov	dx,es:[si]
	add	si,2
	push	ds
	mov	ds,es:[si]
	add	si,2
	mov	ah,25h
	int	21h		; ベクタ書き込み
	pop	ds
	inc	al
	loop	rm_loop
	sti

	mov	ax,4900h
	int	21h		; 常駐部のコードエリアを解放
	mov	ax,4c00h
	int	21h		; 終了
p_entry endp

code	ends
	end	p_start

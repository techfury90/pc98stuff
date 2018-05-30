	.MODEL	small,c
	.CODE

; void SetUcgIo(int chrcode, char *fontbuf, int num)
; --------------------------------------------------
; ユーザ定義文字を設定する

SetUcgIo PROC chrcode:WORD, fontbuf:PTR WORD, num:WORD
	push	si
	cld
	mov	si,fontbuf
	mov	dx,chrcode
	mov	bx,0		; 設定回数カウンタ
	jmp	SHORT sync_main

sync_wait:
	or	bx,bx		; 回数カウンタが0か
	jz	sync_wait2
	dec	bx		; 回数カウンタを減らす
	jmp	SHORT ucg_set

sync_wait2:
	popf
	jmp	$+2		; リカバリータイム＆他の割り込み起動用
	jmp	$+2

sync_main:
	pushf
	cli
	in	al,60h		; GDCのステータスを読む
	test	al,20h		; V-SYNCか
	jz	sync_wait
	inc	bx		; 回数カウンタを増やす
ucg_set:
	mov	al,0bh
	out	68h,al		; KCGドットアクセス

	mov	ax,dx
	out	0a1h,al		; 文字コードの2バイト目
	mov	al,ah
	sub	al,20h		; KCG用にコードを変換する
	out	0a3h,al		; 文字コードの1バイト目

	mov	cl,0		; ラインカウンタ
set_loop:
	mov	al,cl
	or	al,20h		; 左右ビットを1（左）にする
	out	0a5h,al		; ラインカウンタ
	lodsw
	out	0a9h,al		; 左側のフォントを書き込む
	mov	al,cl		; 左右ビットは0（右）
	out	0a5h,al		; ラインカウンタ
	mov	al,ah
	out	0a9h,al		; 右側のフォントを書き込む
	inc	cl		; 次のラインにする
	cmp	cl,16
	jnz	set_loop	; 16ラインを繰り返す

	mov	al,0ah
	out	68h,al		; KCGコードアクセス
	popf

	inc	dl		; 次の登録コードへ
	cmp	dl,7fh		; 1区の終わりか
	jnz	skip
	mov	dl,21h
	inc	dh		; 1区上の登録コードへ
skip:
	dec	num
	jnz	sync_main	; 指定数だけ繰り返す

	pop	si
	ret
SetUcgIo ENDP

	END

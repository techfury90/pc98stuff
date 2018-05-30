	.MODEL	small,c
	.DATA
fbuf	db	2+32 dup (0)	; フォントバッファ

	.CODE

; void SetUcgBios(int chrcode, char *fontbuf, int num)
; ----------------------------------------------------
; ユーザ定義文字を設定する

	PUBLIC	SetUcgBios
SetUcgBios PROC chrcode:WORD, fontbuf:WORD, num:WORD
	push	si
	push	di
	call	vsync_wait	; 画面の乱れを防止するためV-SYNCを待つ
	mov	ah,0dh		; テキスト画面表示停止
	int	18h
;
	mov	ax,1b01h	; KCGドットアクセスモードにする
	int	18h
;
        mov	si,fontbuf
set_loop:
	mov	ax,ds
	mov	es,ax
	mov	di,OFFSET DGROUP:fbuf+2
	mov	cx,16
	cld
	rep movsw		; フォントデータを転送
;
	mov	bx,ds
	mov	cx,OFFSET DGROUP:fbuf
        mov	dx,chrcode
	mov	ah,1ah		; ユーザ定義文字の書き込み
	int	18h
;
	mov	ax,chrcode
	inc	al		; 次の登録コードへ
	cmp	al,7fh		; 不連続点か
	jnz	skip
	mov	al,21h
	inc	ah		; 1区上の登録コードへ
skip:
	mov	chrcode,ax
	dec	num
	jnz	set_loop	; 指定個の登録が終わるまで繰り返し
;
	mov	ax,1b00h	; KCGコードアクセスモードにする
	int	18h
;
	call	vsync_wait	; 画面の乱れを防止するためV-SYNCを待つ
	mov	ah,0ch		; テキスト画面表示開始
	int	18h
	pop	di
	pop	si
	ret
SetUcgBios ENDP


; V-SYNC待ち処理

vsync_wait:
	in	al,60h		; GDCのステータスを読み出す
	jmp	$+2		; リカバリータイム用
	jmp	$+2
	test	al,20h		; V-SYNC中か
	jz	vsync_wait
	ret

	END

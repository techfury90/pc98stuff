	.MODEL	small,c
	.CODE

; unsigned int GetVram(int colum, int line)
; -----------------------------------------
; 引数で指定された画面上の位置の文字を読み取り、その文字コードを返す。
; ハイレゾモードやPC-98HAなどには対応していない。

GetVram	PROC colum:WORD, line:WORD
	mov	ax,80		; 画面上の１行の文字数
	mul	WORD PTR line	; 指定行の行頭の位置を計算
	add	ax,colum	; 指定桁を取得し位置を計算
	add	ax,ax		; ２倍してＶＲＡＭ上のオフセットアドレスに変換
	mov	bx,ax
	mov	ax,0a000h	; ＶＲＡＭのセグメントアドレス
	mov	es,ax
	mov	ax,es:[bx]	; ＶＲＡＭの内容を読み出す
	or	ah,ah		; ANK文字かチェック
	jz	pend		; ANK文字なら終了へ
	xchg	ah,al		; 上位バイトと下位バイトを交換
	add	ah,20h		; ＪＩＳ漢字コードに変換
pend:
	ret
GetVram	ENDP

	END

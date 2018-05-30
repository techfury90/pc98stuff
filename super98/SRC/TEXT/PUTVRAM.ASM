	.MODEL	small,c
	.CODE

; void PutVram(int colum, int line, unsigned int chcode)
; ------------------------------------------------------
; 画面の指定位置に文字を表示する。
;
; colum:  画面上の桁位置(0～79)
; line:   画面上の行位置(0～現在の画面表示行数-1)
; chcode: 表示する文字コード。

CHRATR	equ	00e1h		; 文字の表示色
CLRCHR	equ	0020h		; 消去に使う文字

PutVram	PROC colum:WORD, line:WORD, chcode:WORD
	mov	cx,colum	; 指定桁を取得
	mov	ax,80		; 画面上の１行の文字数
	mul	WORD PTR line	; 指定行の行頭の位置を計算
	add	ax,cx		; 指定桁の位置を計算
	add	ax,ax		; 2倍してVRAM上のオフセットアドレスに変換
	mov	bx,ax
	mov	ax,0a000h	; テキストVRAMセグメントアドレス
	mov	es,ax
	jcxz	putmain		; 行頭ならputmainへ
	mov	ax,es:[bx]	; 書き込み位置の内容を読み出す
	or	ah,ah		; ANK文字かチェック
	jz	putmain		; ANK文字なら上書きなのでputmainへ
	test	al,80h		; 全角文字の右側か
	jz	putmain		; 全角文字の右側でなければputmainへ
	mov	ax,CLRCHR
	mov	es:[bx-2],ax	; 全角文字の左側を消す
putmain:
	mov	ax,chcode	; 文字コードを取得
	or	ah,ah		; ANK文字かどうかチェック
	jz	putank		; ANK文字ならputankへ
	xchg	ah,al		; 上位バイトと下位バイトを交換
	sub	al,20h		; オフセット調整
	cmp	al,09h		; 2バイト半角文字のチェック
	jb	putzen		; 全角文字ならputzenへ
	cmp	al,0ah		; 2バイト半角文字のチェック
	jbe	putank		; 半角文字ならputankへ
putzen:
	mov	es:[bx],ax	; 全角文字の左側を書く
	or	al,80h		; 全角右側のフラグを立てる
	mov	es:[bx+2],ax	; 全角文字の右側を書く
	mov	ax,CHRATR
	add	bh,20h		; アトリビュート部にする
	mov	es:[bx],ax	; 文字属性を書き込む
	add	bl,02h		; 文字の右側にする
	jmp	SHORT clrcheck
putank:
	mov	es:[bx],ax	; 文字を書き込む
	mov	ax,CHRATR
	add	bh,20h		; アトリビュート部にする
clrcheck:
	mov	es:[bx],ax	; 文字属性を書き込む
	sub	bh,20h		; アドレスをテキスト部に戻す
	mov	dx,es:[bx+2]	; 書き込み位置の次の内容を読み出す
	or	dh,dh		; ANK文字かチェックする
	jz	pend
	test	dl,80h		; 2バイト文字の右側か
	jz	pend
	mov	dx,CLRCHR
	mov	es:[bx+2],dx	; 全角文字の左側を消す
pend:
	ret
PutVram	ENDP

	END

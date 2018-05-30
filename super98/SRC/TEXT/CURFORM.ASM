	.MODEL	small,c
	.CODE

; void SetCursorForm(int form)
; ----------------------------
; カーソルの形状をテキスト用のGDCに設定する。
; 200ライン表示のディスプレイを使用するモードや、
; ハイレゾモードには対応していない。
;
; form: 次のようなカーソルの形状を指定する。
;        0  ボックス（通常の状態）
;        1  太いアンダーライン
;        2  細いアンダーライン

SetCursorForm PROC form:WORD
	mov	ax,form
	mov	cl,6		; １つの形状指示で６バイトのデータを使う
	mul	cl
	mov	bx,ax
	sub	ax,ax		; システム共通領域：セグメント0000h
	mov	es,ax
	mov	al,es:[053ch]	; 表示行数のチェック
	test	al,01h		; 表示行数は２０行か
	jnz	gdcloop
	add	bx,3		; ポインタを＋３して２５行用のデータにする
gdcloop:
	pushf
	cli			; 他のプログラムとの競合回避のため割込み禁止
	in	al,60h		; ＧＤＣのステータスを調べる
	test	al,04h		; ＦＩＦＯが空か
	jz	gdcwait		; 空でなければgdcwaitへ
	jmp	$+2		; リカバリータイム用
	jmp	$+2
	jmp	$+2
	mov	al,4bh		; ＧＤＣのCSRFORMコマンド
	out	62h,al		; ＧＤＣにコマンド出力
	mov	cx,3		; ＧＤＣに３バイトのデータを出力
gdcdata:
	jmp	$+2		; リカバリータイム用
	jmp	$+2
	jmp	$+2
	mov	al,cs:cdata[bx]	; カーソル形状データ
	inc	bx
	out	60h,al		; カーソル形状データをＧＤＣに設定
	loop	gdcdata
	popf
	ret

gdcwait:
	popf
	jmp	$+2		; ＧＤＣのＦＩＦＯが空になるまでの待ち処理
	jmp	$+2
	jmp	SHORT gdcloop

cdata	db	93h,00h,9bh	; ２０行，ボックス
	db	8fh,00h,7bh	; ２５行，ボックス
	db	93h,10h,8bh	; ２０行，アンダーライン（太）
	db	8fh,0eh,7bh	; ２５行，アンダーライン（太）
	db	93h,11h,8bh	; ２０行，アンダーライン（細）
	db	8fh,0fh,7bh	; ２５行，アンダーライン（細）

SetCursorForm ENDP

	END

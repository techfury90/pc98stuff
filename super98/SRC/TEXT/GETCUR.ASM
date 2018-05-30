	.MODEL	small,c
	.CODE

; void GetGdcCursor(int *colum, int *line)
; ----------------------------------------
; テキスト用のGDCから現在のカーソル位置を取得する。
; カーソルOFFの状態では正しい位置が取得できない場合がある。

GetGdcCursor PROC colum:PTR WORD, line:PTR WORD
gdcloop:
	pushf
	cli			; 他のプログラムとの競合回避のため割込み禁止
	in	al,60h		; ＧＤＣのステータスを調べる
	test	al,04h		; ＦＩＦＯが空か
	jz	gdcwait		; 空でなければgdcwaitへ
	jmp	$+2		; リカバリータイム用
	jmp	$+2
	jmp	$+2
	mov	al,0e0h		; ＧＤＣのCSRRコマンド
	out	62h,al		; ＧＤＣにコマンド出力
gdcbusy:
	jmp	$+2		; リカバリータイム用
	jmp	$+2
	jmp	$+2
	in	al,60h		; ＧＤＣのステータスを調べる
	test	al,01h		; コマンド実行終了か
	jz	gdcbusy		; 終了でなければgdcbusyへ
	jmp	$+2		; リカバリータイム用
	jmp	$+2
	jmp	$+2
	in	al,62h		; アドレスデータ読み込み
	mov	bl,al		; アドレスの下位バイトを保存
	jmp	$+2		; リカバリータイム用
	jmp	$+2
	jmp	$+2
	in	al,62h		; アドレスデータ読み込み
	mov	bh,al		; アドレスの上位バイトを保存
	mov	cx,3		; 後続の３データを読み飛ばす
gdcskip:
	jmp	$+2		; リカバリータイム用
	jmp	$+2
	jmp	$+2
	in	al,62h		; データを読み飛ばす
	loop	gdcskip
	popf
	mov	ax,bx		; 読み出したアドレス
	sub	dx,dx
	mov	bx,80		; 画面の１行の文字数
	div	bx		; axに行を，dxに桁を格納
	mov	bx,line		; 行の格納アドレス
	mov	[bx],ax		; カーソル位置（行）を格納
	mov	bx,colum	; 桁の格納アドレス
	mov	[bx],dx		; カーソル位置（桁）を格納
	ret

gdcwait:
	popf
	jmp	$+2		; ＧＤＣのＦＩＦＯが空になるまでの待ち処理
	jmp	$+2
	jmp	SHORT gdcloop

GetGdcCursor ENDP

	END

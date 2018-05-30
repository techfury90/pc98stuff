	.MODEL	small,c
	.CODE

; int GetSpeed(void)
; ------------------
; シリアルポートの現在の通信速度を取得し、通信速度に応じた数値を返す。
; 通信速度と戻り値の関係は次のようになる。
; 戻り値    0,  1,   2,   3,   4,    5,    6,    7,    8,     9
; 通信速度  75, 150, 300, 600, 1200, 2400, 4800, 9600, 19200, 38400(bps)

GetSpeed PROC
	mov	cx,20		; ループ回数を設定
	mov	dx,0
	mov	bx,0
loop1:
	pushf
	cli
	mov	al,80h		; タイマのカウンタ＃２へのラッチコマンド
	out	77h,al		; モード指定
	jmp	$+2		; リカバリータイム用
	jmp	$+2
	in	al,75h		; カウント値の下位バイト
	mov	ah,al
	jmp	$+2		; リカバリータイム用
	jmp	$+2
	in	al,75h		; カウント値の上位バイト
	xchg	ah,al
	popf

	cmp	ax,bx		; 最大値と比較
	jbe	skip1
	mov	bx,ax		; 最大値を更新
skip1:
	cmp	ax,dx		; 1回前と比較
	jbe	skip2
	dec	cx		; ループ回数を減らす
skip2:
	mov	dx,ax		; 次回のために記録
	or	cx,cx
	jnz	loop1		; 終わりでなかったら繰り返し

	sub	ax,ax		; システム共通領域のセグメント：0000h
	mov	es,ax		; esレジスタでシステム共通領域をアクセス
	mov	dx,2048		; 5MHz系の基底分周値
	mov	al,es:[0501h]	; システム共通領域の機種情報を読み出す
	test	al,80h		; システムクロックが5MHz系か8MHz系かのチェック
	jz	count		; 速度判定処理へ
	mov	dx,1664		; 8MHz系の基底分周値
count:
	sub	ax,ax		; 速度判定値（戻り値）を基底の75bpsにセット
calc:
	shr	dx,1		; 基底分周値を1/2にする
	cmp	dx,bx		; カウント最大値と比較
	jb	pend		; 基底分周値がカウント最大値より小なら終了へ
	inc	ax		; 速度判定値（戻り値）を次の値にする
	jmp	SHORT calc
pend:
	ret
GetSpeed ENDP

	END

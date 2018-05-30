	.MODEL	small,c
	.DATA

rsivadr	label	dword
rsivofs	dw	?		; ベクタ保存用
rsivseg	dw	?		; ベクタ保存用

rscmd_d	db	00001000b	; 0: キャラクタ長 7bit
	db	00001100b	; 1: キャラクタ長 8bit
rscmd_p	db	00110000b	; 0: 偶数パリティ
	db	00010000b	; 1: 奇数パリティ
	db	00000000b	; 2: パリティ無し
rscmd_s	db	01000000b	; 0: ストップビット 1bit
	db	10000000b	; 1: ストップビット 1.5bit
	db	11000000b	; 2: ストップビット 2bit

siocmd	db	00110111b	; 8251に出力したコマンドの保存用

	EVEN

rbrdpos	dw	0		; 受信バッファの読み出し位置
rbwrpos	dw	0		; 受信バッファの書き込み位置
rblen	dw	0		; 受信データ長

tbrdpos	dw	0		; 送信バッファの読み出し位置
tbwrpos	dw	0		; 送信バッファの書き込み位置
tblen	dw	0		; 送信データ長

RBSIZE	equ	6000		; 受信バッファ長
RBXOFF	equ	4000		; XOFF送信あるいはRS=OFFをするバッファ長
RBXON	equ	2000		; XON送信あるいはRS=ONをするバッファ長
TBSIZE	equ	2000		; 送信バッファ長

rbbuf	db	RBSIZE dup (0)	; 受信バッファ
tbbuf	db	TBSIZE dup (0)	; 送信バッファ

rbflow	db	0		; フロー制御フラグ
				; 0:無し, 1:XON/XOFF, 2:RS/CS
rbxout	db	0		; 送信状態フラグ
				; 0:XON状態, 1:XOFF要求, 2:XOFF状態, 3:XON要求

	.CODE

; void RsOpen(int speed, int datalen, int parity, int stopbit, int flow)
; ----------------------------------------------------------------------
; RS-232Cの割り込み処理の登録とRS-232Cの初期化を行なう
; 初期化によりRS-232CのER信号とRS信号はONになる
; speed   通信速度 0,  1,   2,   3,   4,    5,    6,    7,    8,     9
;                  75, 150, 300, 600, 1200, 2400, 4800, 9600, 19200, 38400(bps)
; datalen データ長 0:7bit, 1:8bit
; parity  パリティ 0:Even, 1:Odd, 2:None
; stopbit ストップビット 0:1bit, 1:1.5bit, 2:2bit
; flow    フロー制御 0:無し, 1:XON/XOFF, 2:RS/CS

RsOpen	PROC speed:WORD, datalen:WORD, parity:WORD, stopbit:WORD, flow:WORD
	call	RsDisable
	mov	ax,350ch	; INT-0CHベクタの設定を取得
	int	21h
	mov	rsivseg,es	; セグメントアドレスを保存
	mov	rsivofs,bx	; オフセットアドレスを保存
	push	ds
	mov     ax,cs
	mov     ds,ax
	mov     dx,OFFSET RsIntrEntry	; 割り込み処理のアドレス
	mov     ax,250ch	; INT-0CHベクタに割り込み処理を登録
	int     21h
	pop	ds
;
	push	speed
	call	SetSpeed	; 通信速度を設定
	add	sp,2
;
	mov	ax,flow
	mov	rbflow,al	; フロー制御を設定
;
	pushf
	cli
	mov	al,0		; ダミーコマンド:00H
	out	32h,al		; ダミーコマンド発行
	call	RsWait
	out	32h,al		; ダミーコマンド発行
	call	RsWait
	out	32h,al		; ダミーコマンド発行
	call	RsWait
;
	mov	al,01000000b	; 8251リセット
	out	32h,al
	call	RsWait
;
	mov	al,00000010b	; ×１６モード
	mov	bx,datalen
	or	al,rscmd_d[bx]	; キャラクタ長の設定
	mov	bx,parity
	or	al,rscmd_p[bx]	; パリティの設定
	mov	bx,stopbit
	or	al,rscmd_s[bx]	; ストップビットの設定
	out	32h,al		; モード命令を出力
	call	RsWait
;
	mov	al,00110111b	; 送受信許可，ER信号とRS信号はON
	mov	siocmd,al
	out	32h,al		; コマンドを出力
;
	in	al,02h		; 割り込みコントローラからIMRを読む
	and	al,11101111b	; RS-232Cの割り込みマスクを解除
	out	02h,al
	popf
	call	RsEnable
	ret
RsOpen	ENDP


; void RsReOpen(int datalen, int parity, int stopbit, int flow)
; -------------------------------------------------------------
; RS-232Cのデータ長などの設定を変更する
; datalen データ長 0:7bit, 1:8bit
; parity  パリティ 0:Even, 1:Odd, 2:None
; stopbit ストップビット 0:1bit, 1:1.5bit, 2:2bit

RsReOpen PROC datalen:WORD, parity:WORD, stopbit:WORD, flow:WORD
	call	RsDisable
	pushf
	cli
	mov	ax,flow
	mov	rbflow,al
	mov	al,siocmd	; コマンドポート出力用データ
	or	al,01000000b	; 8251リセット
	out	32h,al
	call	RsWait
;
	mov	al,02h		; ×１６モード
	mov	bx,datalen
	or	al,rscmd_d[bx]	; データ長の設定
	mov	bx,parity
	or	al,rscmd_p[bx]	; パリティの設定
	mov	bx,stopbit
	or	al,rscmd_s[bx]	; ストップビットの設定
	out	32h,al		; モード命令を出力
	call	RsWait
;
	mov	al,siocmd
	out	32h,al		; コマンドを出力
	call	RsEnable
	popf
	ret
RsReOpen ENDP


; void RsWait(void)
; -----------------
; 8251リカバリータイム用

RsWait	PROC
	mov	cx,16
	loop	$
	ret
RsWait	ENDP


; void RsClose(void)
; ------------------
; RS-232Cの割り込みの停止とベクタの登録解除を行なう
; RS-232CのER信号とRS信号はOFFになる

RsClose	PROC
	call	RsDisable	; RS-232Cの全割り込みを禁止
	call	SetErOff	; ERをOFFにする
	call	SetRsOff	; RSをOFFにする
	pushf
	cli
	in	al,02h		; 割り込みコントローラからIMRを読む
	or	al,00010000b	; RS-232Cの割り込みをマスク
	out	02h,al
	popf
	push	ds
	lds	dx,rsivadr
	mov     ax,250ch	; INT-0CHベクタを元に戻す
	int     21h
	pop	ds
	ret
RsClose	ENDP


; void RsDisable(void)
; --------------------
; RS-232Cの全割り込みを禁止する

RsDisable PROC
	pushf
	cli
	in	al,35h		; システムポートを読む
	jmp	$+2
	and	al,11111000b
	out	35h,al		; RS-232Cの全割り込みを禁止
	popf
	ret
RsDisable ENDP


; void RsEnable(void)
; -------------------
; RS-232Cの送受信割り込みを許可する

RsEnable PROC
	pushf
	cli
	in	al,35h		; システムポートを読む
	jmp	$+2
	and	al,11111000b
	or	al,00000101b	; RS-232Cの送受信割り込みを許可
	out	35h,al
	popf
	ret
RsEnable ENDP


; int SetSpeed(int speed)
; -----------------------
; RS-232Cの通信速度を設定する
; speed   通信速度 0,  1,   2,   3,   4,    5,    6,    7,    8,     9
;                  75, 150, 300, 600, 1200, 2400, 4800, 9600, 19200, 38400(bps)

SetSpeed PROC speed:WORD
	sub	ax,ax		; システム共通領域のセグメント値：0000h
	mov	es,ax
	mov	al,es:[0501h]	; システム共通領域のBIOS-FLAG(機種情報)
	mov	cx,2048		; 5MHz系の基底分周値をセット
	test	al,10000000b	; 5MHz系か8MHz系かのチェック
	jz	set
	mov	cx,1664		; 8MHz系の基底分周値をセット
	mov	ax,speed
	cmp	ax,8		; 19200bps以上か
	jae	seterr		; 設定できないのでエラー終了へ
set:
	mov	ax,speed
	cmp	ax,9		; 38400bpsより大きいか
	ja	seterr		; 38400bpsより大きければエラー終了へ
	xchg	ax,cx
	shr	ax,cl		; 分周値を計算
	mov	cx,ax		; cxレジスタに分周値を設定
;
	pushf
	cli
	mov	al,10110110b	; タイマのカウンタ＃２への分周値設定のコマンド
	out	77h,al          ; モード指定
	jmp	$+2
	jmp	$+2
	mov	al,cl		; clは分周値の下位バイト
	out	75h,al          ; カウンタ＃２に分周値の下位バイトを設定
	jmp	$+2
	jmp	$+2
	mov	al,ch		; clは分周値の上位バイト
	out	75h,al          ; カウンタ＃２に分周値の上位バイトを設定
	popf
	mov	ax,1		; 正常終了時の戻り値：1
	jmp	SHORT setend
seterr:
	sub	ax,ax		; エラー時の戻り値：0
setend:
	ret
SetSpeed ENDP


; RsIntrEntry
; -----------
; RS-232C割り込み処理

RsIntrEntry PROC FAR
	push	ax
	in	al,35h		; 送受信割り込みのマスクを読む
	push	bx
	push	ds
	push	ax
	mov	bx,@data	; データセグメントを設定
	mov	ds,bx
	and	al,11111000b	; 送受信割り込みをマスク
	out	35h,al
	in	al,32h		; 8251のステータスをチェック
	test	al,00000010b	; 受信データがあるか
	jz	rsout
;
	in	al,30h		; 受信データを読み込む
	cmp	rblen,RBSIZE	; 受信バッファに入るか
	jae	rsout
	mov	bx,rbwrpos
	mov	rbbuf[bx],al	; 受信データをバッファに書き込む
	inc	rbwrpos
	inc	rblen
	cmp	bx,RBSIZE
	jb	rsflow
	mov	rbwrpos,0	; 書き込み位置を受信バッファの先頭へ
rsflow:
	cmp	rbflow,0	; フロー制御をするか
	jz	rsout
	cmp	rblen,RBXOFF	; XOFF送信あるいはRS=OFFが必要か
	jb	rsout
	cmp	rbxout,0	; XOFF送信要求が無いか
	jnz	rsout
	cmp	rbflow,1	; XON/XOFFフロー制御か
	jz	flow1
;
	mov	al,siocmd
	and	al,11011111b	; RS=OFFにする
	out	32h,al
	mov	siocmd,al
	mov	rbxout,2	; RS=OFF状態
	jmp	SHORT rsout
flow1:
	mov	rbxout,1	; XOFF送信要求
	pop	ax
	or	al,00000100b	; RS-232Cの送信割り込みを許可
	push	ax
rsout:
	in	al,32h		; 8251のステータスをチェック
	test	al,00000001b	; 送信が可能か
	jz	rsend
	test	rbxout,1	; XON送信要求あるいはXOFF送信要求か
	jz	rsout2
	cmp	rbxout,1	; XON/XOFF送信要求か
	jz	rsxoff
	mov	rbxout,0	; XON送信済みにする
	cmp	rbflow,1	; XON/XOFFフロー制御か
	jz	softflow2
;
	mov	al,siocmd
	or	al,00100000b	; RS信号をONにする
	out	32h,al
	mov	siocmd,al
	jmp	SHORT rsnext
softflow2:
	mov	al,11h		; XONを送信
	out	30h,al
	jmp	SHORT rsnext
rsxoff:
	cmp	rbflow,1	; XON/XOFFフロー制御か
	jz	flow3
	mov	al,siocmd
	and	al,11011111b	; RS信号をOFFにする
	out	32h,al
	mov	siocmd,al
	jmp	SHORT rsnext
flow3:
	mov	al,13h		; XOFFを送信
	out	30h,al
	mov	rbxout,2	; XOFF送信済みにする
	jmp	SHORT rsnext
rsout2:
	cmp	tblen,0		; 送信データがあるか
	jz 	rsmask
	mov	bx,tbrdpos
	mov	al,tbbuf[bx]	; 送信データ読み出し
	out	30h,al		; データを送信
	inc	tbrdpos
	dec	tblen
	cmp	bx,TBSIZE
	jb	rsnext
	mov	tbrdpos,0	; 読み込み位置を送信バッファの先頭へ
rsnext:
	cmp	tblen,0		; 送信データがあるか
	jnz	rsend
rsmask:
	pop	ax
	and	al,11111001b	; RS-232Cの送信割り込みをマスク
	push	ax
rsend:
	mov	al,00100000b	; EOIコマンド
	out	00h,al		; 割り込みコントローラにEOIを出力
	pop	ax
	out	35h,al		; 送受信割り込みのマスクを設定
	pop	ds
	pop	bx
	pop	ax
	iret
RsIntrEntry ENDP


; int ReceiveLength(void)
; -----------------------
; 受信バッファ内の文字数を返す

ReceiveLength PROC
	mov	ax,rblen
	ret
ReceiveLength ENDP


; int ReceiveSpace(void)
; -----------------------
; 受信バッファ内の空き文字数を返す

ReceiveSpace PROC
	mov	ax,RBSIZE
	sub	ax,rblen
	ret
ReceiveSpace ENDP


; int TransLength(void)
; ---------------------
; 送信バッファ内の文字数を返す

TransLength PROC
	mov	ax,tblen
	ret
TransLength ENDP


; int TransSpace(void)
; ---------------------
; 送信バッファ内の空き文字数を返す

TransSpace PROC
	mov	ax,TBSIZE
	sub	ax,tblen
	ret
TransSpace ENDP


; int ReceiveData(void)
; ----------------------
; 受信バッファから１文字を取得する

ReceiveData PROC
	pushf
	cli
	mov	ax,-1		; 受信データがないときの戻り値：-1
	cmp	rblen,0
	jz	flow_chk1
	mov	bx,rbrdpos	; 読み出し位置
	mov	al,rbbuf[bx]	; 受信データ読み出し
	sub	ah,ah
	inc	rbrdpos
	dec	rblen
	cmp	bx,RBSIZE	; バッファの終端か
	jb	flow_chk1
	mov	rbrdpos,0	; 読み込み位置を受信バッファの先頭へ
flow_chk1:
	cmp	rbxout,2	; XOFF送信済みか
	jnz	rdend
	cmp	rblen,RBXON	; XON送信が必要か
	jae	rdend
	cmp	rbflow,1	; XON/XOFFフロー制御か
	jz	flow_chk2
;
	mov	rbxout,0
	mov	al,siocmd
	or	al,00100000b	; RS信号をONにする
	out	32h,al
	mov	siocmd,al
	jmp	SHORT rdend
flow_chk2:
	mov	rbxout,3	; XON送信要求
	push	ax
	mov	al,00000101b	; RS-232Cの送信割り込みを許可
	out	37h,al
	pop	ax
rdend:
	popf
	ret
ReceiveData ENDP


; void TransData(int txdata)
; -----------------------
; １文字を送信バッファに入れて送信する

TransData PROC txdata:WORD
	pushf
	cli
	cmp	tblen,TBSIZE	; 送信バッファに空きがあるか
	jae	txend
	mov	bx,tbwrpos
	mov	ax,txdata
	mov	tbbuf[bx],al	; データを送信バッファに書き込む
	inc	tbwrpos
	inc	tblen
	cmp	bx,TBSIZE	; バッファの終端か
	jb	send
	mov	tbwrpos,0	; 書き込み位置を受信バッファの先頭へ
send:
	mov	al,00000101b	; RS-232Cの送信割り込みを許可
	out	37h,al
txend:
	popf
	ret
TransData ENDP


; void SetErOn(void)
; ------------------
; RS-232CのER信号をONにする

SetErOn	PROC
	pushf
	cli
	mov	al,siocmd
	or	al,00000010b
	out	32h,al
	mov	siocmd,al
	popf
	ret
SetErOn	ENDP


; void SetErOff(void)
; -------------------
; RS-232CのER信号をOFFにする

SetErOff PROC
	pushf
	cli
	mov	al,siocmd
	and	al,11111101b
	out	32h,al
	mov	siocmd,al
	popf
	ret
SetErOff ENDP


; void SetRsOn(void)
; ------------------
; RS-232CのRS信号をONにする

SetRsOn PROC
	pushf
	cli
	mov	al,siocmd
	or	al,00100000b
	out	32h,al
	mov	siocmd,al
	popf
	ret
SetRsOn ENDP


; void SetRsOff(void)
; -------------------
; RS-232CのRS信号をOFFにする

SetRsOff PROC
	pushf
	cli
	mov	al,siocmd
	and	al,11011111b
	out	32h,al
	mov	siocmd,al
	popf
	ret
SetRsOff ENDP


; int CheckEr(void)
; ----------------
; RS-232CのER信号の状態を返す

CheckEr	PROC
	mov	al,siocmd
	shr	al,1
	not	al
	and	ax,1
	ret
CheckEr	ENDP


; int CheckRs(void)
; ----------------
; RS-232CのRS信号の状態を返す

CheckRs	PROC
	mov	al,siocmd
	and	al,00100000b
	cmp	al,1
	sbb	ax,ax
	inc	ax
	ret
CheckRs	ENDP


; int CheckCd(void)
; -----------------
; RS-232CのCD信号の状態を返す

CheckCd	PROC
	in	al,33h
	and	al,00100000b
	cmp	al,1
	sbb	ax,ax
	neg	ax
	ret
CheckCd	ENDP


; int CheckCs(void)
; -----------------
; RS-232CのCS信号の状態を返す

CheckCs	PROC
	in	al,33h
	rol	al,1
	rol	al,1
	and	ax,1
	ret
CheckCs	ENDP


; int CheckCi(void)
; -----------------
; RS-232CのCI信号の状態を返す
; 初代PC-9801ではCI信号は調べられない

CheckCi	PROC
	in	al,33h
	rol	al,1
	and	ax,1
	ret
CheckCi	ENDP


; int CheckDr(void)
; -----------------
; RS-232CのDR信号の状態を返す

CheckDr	PROC
	in	al,32h
	rol	al,1
	and	ax,1
	ret
CheckDr	ENDP


; void RsSendBreak(void)
; ----------------------
; 約300ミリ秒のブレーク信号を送信する

RsSendBreak PROC
	call	RsBreakOn
	mov	cx,45000	; 約300ミリ秒のウェイト
wloop:
	out	5fh,al		; ウェイトポート
	out	5fh,al
	out	5fh,al
	out	5fh,al
	out	5fh,al
	loop	wloop
	call	RsBreakOff
	ret
RsSendBreak ENDP


; void RsBreakOn(void)
; --------------------
; ブレーク信号の送信を開始する

RsBreakOn PROC
	pushf
	cli
	mov	al,siocmd
	or	al,00001000b	; BREAKビットを1にする
	out	32h,al
	mov	siocmd,al
	popf
	ret
RsBreakOn ENDP


; void RsBreakOff(void)
; ---------------------
; ブレーク信号の送信を中止する

RsBreakOff PROC
	pushf
	cli
	mov	al,siocmd
	and	al,11110111b	; BREAKビットを0にする
	out	32h,al
	mov	siocmd,al
	popf
	ret
RsBreakOff ENDP

	END

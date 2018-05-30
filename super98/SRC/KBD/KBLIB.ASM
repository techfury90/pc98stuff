		TITLE Keyboard Type Check

		.8086
		.MODEL	SMALL,C

		.CODE


;==========
;int GetKeyType(void);
;キーボードの種類を取得する
;----------
;引数
;  なし
;戻り値
;  bit 6: vf･1～5→f･6～10変換（1=必要，0=不要）
;  bit 5: NFER（1=あり，0=なし）
;  bit 4: HOME（1=あり，0=なし）
;  bit 3: vf･1～5，ﾊﾞｯｸ･ｸｫｰﾄ（1=あり，0=なし）
;  bit 2: BS,DEL,HELP,ROLL UP,ROLL DOWN（1=あり，0=なし）
;  bit 1: CAPS,カナソフトウェア制御機能（1=あり，0=なし）
;  bit 0: NUMソフトウェア制御機能（1=あり，0=なし）
;----------
		PUBLIC	GetKeyType
GetKeyType	PROC
;--- 新キーボード判別
	;---以下に示すように、AHにキーボード情報を入れる
	;bit 6 = 0000:0481 bit 6（キーボード識別(1)）
	;bit 3 = 0000:0481 bit 3（キーボード識別(2)）
		push	es
		mov	ax,0000H	;システム共通域
		mov	es,ax
		mov	ah,es:[0481H]	;キーボード識別(1),(2)→AL bit 6,3
		and	ah,48H
	;--- タイプ分類
		cmp	ah,40H		;ＲＡタイプ判別
		mov	al,0101110B	;    /NFER/    /vf/HELP/LOCK/   
		je	Quit
		cmp	ah,48H		;ＬＳタイプ判別(vf変換不要)
		mov	al,0101111B	;    /NFER/    /vf/HELP/LOCK/NUM
		je	Quit
		cmp	ah,08H		;ＬＳタイプ判別(vf変換必要)
		mov	al,1100111B	;変換/NFER/    /  /HELP/LOCK/NUM
		je	Quit
;--- 旧キーボード判別
	;--- 以下に示すように、AHに機種情報を入れる
	;bit 7 = 0000:0500 bit 0（機種情報(1)）
	;bit 6 = 0000:0501 bit 4（機種情報(3)）
	;bit 5 = 0000:0501 bit 3（機種情報(4)）
		mov	ah,es:[0500H]	;機種情報(1)→bit7
		and	ah,01H
		ror	ah,1
		mov	al,es:[0501H]	;機種情報(3),機種情報(4)→bit 6,5
		and	al,18H
		shl	al,1
		shl	al,1
		or	ah,al
	;--- タイプ分類
		cmp	ah,00H		;無印タイプ判別
		mov	al,0000100B	;    /    /    /  /HELP/    /   
		je	Quit
		test	ah,20H		;ＸＡタイプ判別
		mov	al,0111100B	;    /NFER/HOME/vf/HELP/    /   
		jnz	Quit
		test	ah,80H		;ＶＭタイプ判別
		mov	al,0100100B	;    /NFER/    /  /HELP/    /   
		jnz	Quit
;--- ＬＴ／ＨＡ判別
		push	bx
		mov	ax,0B600H	;カードサイズ取得コマンド
		int	1FH		;メモリカードBIOS
		pop	bx
		cmp	ax,0B600H	;LTならAXの値は不変，HAなら必ず変化
		mov	al,0100000B	;    /NFER/    /  /    /    /   (LT)
		je	Quit
		mov	al,0100100B	;    /NFER/    /  /HELP/    /   (HA)
Quit:		mov	ah,00H
		pop	es
		ret
GetKeyType	ENDP


;==========
;int KeyTouch(int KeyCodeGroup);
;連続押下されているキーの押下調査
;----------
;引数
;  KeyCodeGroup : BIOS AH=04 INT 18Hのキーコードグループ番号
;戻り値
;  キーコードグループ内のキーの押下状態
;機能
;  オートリピートするキーを押しつづけると、オートリピートのために
;  ソフトウェアからはキーが押下されていないように見えてしまう瞬間が
;  ある。この関数ではキーリピートしていても押下しているかどうかを
;  調べることができる。
;注意
;  この関数の実行には数msかかる。
;----------
		PUBLIC	KeyTouch
KeyTouch	PROC	NEAR,KeyCodeGroup:WORD
	;--- キー押下状態取得（１回目）
		mov	ax,KeyCodeGroup
		mov	ah,04H
		int	18H
		mov	bl,ah
	;--- 1ms以上のウェイト
		;ウェイト用OUTポートのアドレス決定
		;無印･E･F･M→BFDBH（マウス割込周期設定用ポート）
		;その他    →005FH（ウェイト用ポート）
		push	es
		mov	dx,0000H	;ES←システム共通域
		mov	es,dx
		mov	dx,0BFDBH
		test	es:[0500H],WORD PTR 1801H	;無印･E･F･M検出
		jz	@f
		mov	dx,005FH
	@@:	pop	es
		mov	cx,300H
waitloop:	out	dx,al
		loop	waitloop
	;--- キー押下状態取得（２回目）
		mov	ax,KeyCodeGroup
		mov	ah,04H
		int	18H
	;--- １回目と２回目の押下状態をＯＲする
		or	ah,bl
		mov	al,ah
		mov	ah,00H
		ret
KeyTouch	ENDP


;==========
;int GetKeyBeepMode(void);
;----------
;引数
;  なし
;戻り値
;  0 = ビープを鳴らす（デフォルト）
;  1 = ビープを鳴らさない
;機能
;  キーバッファがオーバーフローしたときにビープを鳴らすモードか
;  どうかを取得する関数
;----------
		PUBLIC	GetKeyBeepMode
GetKeyBeepMode	PROC
		mov	ax,0000H	;ES←システム共通域
		mov	es,ax
		mov	al,es:[0500H]	;bit 5
		and	ax,0020H
		shl	al,1
		shl	al,1
		rol	al,1
		ret
GetKeyBeepMode	ENDP


;==========
;void KeyBeepOn(void);
;----------
;引数
;  なし
;戻り値
;  なし
;機能
;  キーバッファがオーバーフローしたときにビープを鳴らす
;  モードに設定する関数
;----------
		PUBLIC	KeyBeepOn
KeyBeepOn	PROC
		mov	ax,0000H	;ES←システム共通域
		mov	es,ax
		and	es:[0500H],BYTE PTR 0DFH	;bit 5=0
		ret
KeyBeepOn	ENDP


;==========
;void KeyBeepOff(void);
;----------
;引数
;  なし
;戻り値
;  なし
;機能
;  キーバッファがオーバーフローしたときにビープを鳴らさない
;  モードに設定する関数
;----------
		PUBLIC	KeyBeepOff
KeyBeepOff	PROC
		mov	ax,0000H	;ES←システム共通域
		mov	es,ax
		or	es:[0500H],BYTE PTR 20H		;bit 5=1
		ret
KeyBeepOff	ENDP


;==========
;void CapsSwitch(int sw);
;CAPSキーをON/OFFする
;----------
;引数
;  sw = 0 : OFF
;  sw = 1 : ON
;戻り値
;  なし
;機能
;注意
;----------
		PUBLIC	CapsSwitch
CapsSwitch	PROC	NEAR,sw:WORD
	;キーボード割込のマスク
		cli
		in	al,0002H
		or	al,02H
		out	0002H,al
		sti
	;LED制御コマンド送出
		mov	ah,9DH		;LED制御コマンド
		call	KbSendCommand
		jc	quit		;エラーなら中止
	;LED ON/OFF情報送出
		push	es
		mov	ax,0000H	;ES←システム共通域
		mov	es,ax
		mov	ah,es:[053AH]
		pop	es
		shl	ah,1
		and	ah,08H		;ｶﾅ制御ビットを残しマスク
		or	ah,70H
		cmp	sw,0000H
		je	off
		or	ah,04H		;CAPS ON
off:		call	KbSendCommand
quit:	;KB BIOSイニシャライズ
		mov	ah,03H
		int	18H
	;キーボード割込許可
		cli
		in	al,0002H
		and	al,NOT 02H
		out	0002H,al
		sti
		ret
CapsSwitch	ENDP


;==========
;void KanaSwitch(int sw);
;カナキーをON/OFFする
;----------
;引数
;  sw = 0 : OFF
;  sw = 1 : ON
;戻り値
;  なし
;機能
;注意
;----------
		PUBLIC	KanaSwitch
KanaSwitch	PROC	NEAR,sw:WORD
	;キーボード割込のマスク
		cli
		in	al,0002H
		or	al,02H
		out	0002H,al
		sti
	;LED制御コマンド送出
		mov	ah,9DH
		call	KbSendCommand
		jc	quit		;エラーなら中止
	;LED ON/OFF情報送出
		push	es
		mov	ax,0000H	;ES←システム共通域
		mov	es,ax
		mov	ah,es:[053AH]
		pop	es
		shl	ah,1
		and	ah,04H		;CAPS制御ビットを残しマスク
		or	ah,70H
		cmp	sw,0000H
		je	off
		or	ah,08H		;ｶﾅ ON
off:		call	KbSendCommand
quit:	;KB BIOSイニシャライズ
		mov	ah,03H
		int	18H
	;キーボード割込許可
		cli
		in	al,0002H
		and	al,NOT 02H
		out	0002H,al
		sti
		ret
KanaSwitch	ENDP


;==========
;int GetKbType(void);
;キーボードのタイプを取得する
;----------
;引数
;  なし
;戻り値
;  0 = 旧型
;  1 = 新型
;機能
;注意
;----------
		PUBLIC	GetKbType
GetKbType	PROC	NEAR
	;キーボード割込のマスク
		cli
		in	al,0002H
		or	al,02H
		out	0002H,al
		sti
	;キーボードタイプ取得コマンド発行
		mov	ah,9FH
		call	KbSendCommand
		jc	oldtype
		call	KbReceiveData	;データ受信
		jc	oldtype
		cmp	al,0A0H		;0A0H ?
		jne	oldtype
		call	KbReceiveData	;データ受信
		jc	oldtype
		cmp	al,80H		;80H ?
		jne	oldtype
		mov	bx,0001H
		jmp	SHORT quit
oldtype:	mov	bx,0000H
quit:	;キーボード割込の許可
		cli
		in	al,0002H
		and	al,NOT 02H
		out	0002H,al
		sti
		mov	ax,bx
		ret
GetKbType	ENDP


;----------
;キーボードへのデータ送信
;引数：AH←キーボードに送信するコマンド
;戻値：CF=0 : 正常終了
;      CF=1 : エラー終了
;----------
		PUBLIC	KbSendCommand
KbSendCommand	PROC	NEAR
	;--- 8251Aにコマンドワード書込（送信許可）
SendRetry:	mov	al,00010111B	;KB用8251Aの設定
			;  ^^^^^^^^
			;  |||||||+-KB I/F送信設定（1=許可）
			;  ||||||+--DTR#設定（1=LOW）KBリトライ非要求
			;  |||||+---KB I/F受信設定（1=許可）
			;  ||||+----ブレーク送信設定（0=しない）KBﾘｾｯﾄしない
			;  |||+-----エラーフラグのクリア（1=する）
			;  ||+------RTS#設定（0=HIGH）KBからの送信を許可
			;  |+-------リセット（0=しない）
			;  +--------Don't care
		out	0043H,al
		;ウェイト用OUTポートのアドレス決定
		;無印･E･F･M→BFDBH（マウス割込周期設定用ポート）
		;その他    →005FH（ウェイト用ポート）
		push	es
		mov	dx,0000H	;ES←システム共通域
		mov	es,dx
		mov	dx,0BFDBH
		test	es:[0500H],WORD PTR 1801H	;無印･E･F･M検出
		jz	@f
		mov	dx,005FH
	@@:	pop	es
		mov	cx,0007H	;4μs以上のウェイト(I/Oﾘｶﾊﾞﾘ)
	@@:	out	dx,al
		loop	@b
	;--- キーボードにコマンドデータ送信
		mov	al,ah
		out	0041H,al
		mov	cx,0007H	;4μs以上のウェイト(I/Oﾘｶﾊﾞﾘ)
	@@:	out	dx,al
		loop	@b
	;--- 8251Aにコマンドワード書込（送信禁止）
		mov	al,00010110B	;KB用8251Aのモード設定
			;  ^^^^^^^^
			;  |||||||+-KB I/F送信設定（0=禁止）
			;  ||||||+--DTR#設定（1=LOW）KBリトライ非要求
			;  |||||+---KB I/F受信許可
			;  ||||+----ブレーク送信設定（0=しない）KBﾘｾｯﾄしない
			;  |||+-----エラーフラグのクリア（1=する）
			;  ||+------RTS#設定（0=HIGH）KBからの送信を許可
			;  |+-------リセット（0=しない）
			;  +--------Don't care
		out	0043H,al
	;--- アクノリッジ確認
		mov	bl,00H
AckRetry:	call	KbReceiveData
		jc	TimeOut
		cmp	al,0FAH		;ACK ?
		jne	NotAck
		clc			;正常終了
		ret
NotAck:		cmp	al,0FCH		;NACK ?
		je	SendRetry
		inc	bl
		cmp	bl,04H
		jne	AckRetry	;非ACK,非NACKを4回受信したらエラー終了
TimeOut:	stc
		ret
KbSendCommand	ENDP


;----------
;キーボードからのデータ受信
;引数：なし
;戻値：CF=0 : AL←キーボードからの値
;      CF=1 : タイムアウト
;----------
		PUBLIC	KbReceiveData
KbReceiveData	PROC	NEAR
		mov	cx,8000H	;タイムアウトになるRDY#チェック回数
RdyCheckLoop:	in	al,0043H	;RDY#チェック
		test	al,02H
		jnz	Ready
		loop	RdyCheckLoop
		stc			;タイムアウト
		ret
Ready:		;ウェイト用OUTポートのアドレス決定
		;無印･E･F･M→BFDBH（マウス割込周期設定用ポート）
		;その他    →005FH（ウェイト用ポート）
		push	es
		mov	dx,0000H	;ES←システム共通域
		mov	es,dx
		mov	dx,0BFDBH
		test	es:[0500H],WORD PTR 1801H	;無印･E･F･M検出
		jz	@f
		mov	dx,005FH
	@@:	pop	es
		mov	cx,18H		;37μsec以上ウェイト
ReceiveLoop:	out	dx,al
		loop	ReceiveLoop
	;ステータス読み出し
		in	al,0043H
		and	al,38H
	;エラーがあればRTY#=ACTIVE、なければRTY#=INACTIVE
		jnz	ReceiveError
		mov	al,00010110B	;RTY#=1(INACTIVE)
		out	0043H,al
		mov	cx,0007H	;4μs以上のウェイト(I/Oﾘｶﾊﾞﾘ)
	@@:	out	dx,al
		loop	@b
		in	al,0041H	;受信データ読み出し
		clc			;キャリーをクリア
		ret
ReceiveError:	mov	al,00010100B	;RTY#=0(ACTIVE)
		out	0043H,al
		mov	cx,0007H	;4μs以上のウェイト(I/Oﾘｶﾊﾞﾘ)
	@@:	out	dx,al
		loop	@b
		in	al,0041H	;受信データ読み出し
		stc			;キャリーをセット
		ret
KbReceiveData	ENDP


END

		TITLE MemorySwitch

		.8086
		.MODEL	SMALL,C

		.CODE

;==========
;unsigned char GetMemorySwitch(unsigned char number);
;指定したメモリスイッチの値を読む
;----------
;引数
;  number : メモリスイッチの番号（１～８）
;戻り値
;  メモリスイッチの内容
;機能
;  ノーマル，ハイレゾ，ＬＴ／ＨＡの判別をし、指定されたメモリスイッチから
;  値を読み出す。
;----------
GetMemorySwitch	PROC	NEAR,number:BYTE
		mov	ax,0000H	;ES←0000（システム共通域）
		mov	es,ax
		mov	ax,es:[0500H]
		and	ax,1001H	;LT,HA判定
		cmp	ax,1000H
		je	BiosUse
		test	es:[0501H],BYTE PTR 08H	;ハイレゾ判定
		jnz	BiosUse
		;** ノーマルモードの処理 **
		mov	ax,0A000H	;テキストＶＲＡＭセグメント
		mov	es,ax		;ES←メモリスイッチのセグメント
		mov	bh,00H		;3FE2Hに(number-1)AND 7を４倍した値を
		mov	bl,number	;加算すると目的のメモリスイッチの
		dec	bl		;アドレスになる
		and	bl,07H
		add	bx,bx
		add	bx,bx
		mov	al,es:[3FE2H+bx]	;メモリスイッチ読出
		mov	ah,0
		ret
		;** ハイレゾ，LT/HAの処理（BIOS使用） **
BiosUse:	mov	ah,21H		;メモリスイッチ読出
		mov	al,number
		int	18H
		mov	al,dl
		mov	ah,0
		ret
GetMemorySwitch	ENDP


;==========
;void SetMemorySwitch(unsigned char number, unsigned char value);
;指定したメモリスイッチに値を書く
;----------
;引数
;  number : メモリスイッチの番号（１～８）
;  value  : 設定する値
;戻り値
;  なし
;機能
;  ノーマル，ハイレゾ，ＬＴ／ＨＡの判別をし、ハイレゾ，ＬＴ／ＨＡなら
;  ＢＩＯＳを使用する。ノーマルならメモリスイッチを書き込み可にして
;  指定されたメモリスイッチに値をセットし、メモリスイッチを書き込み
;  不可にする。
;----------
SetMemorySwitch	PROC	NEAR,number:BYTE, value:BYTE
		mov	ax,0000H	;ES←0000（システム共通域）
		mov	es,ax
		mov	ax,es:[0500H]
		and	ax,1001H	;LT,HA判定
		cmp	ax,1000H
		je	BiosUse
		test	es:[0501H],BYTE PTR 08H	;ハイレゾ判定
		jnz	BiosUse
		;** ノーマルモードの処理 **
		mov	ax,0A000H	;テキストＶＲＡＭのセグメント
		mov	es,ax		;ES←メモリスイッチのセグメント
		mov	bh,00H		;3FE2Hに(number-1)AND 7を４倍した値を
		mov	bl,number	;加算すると目的のメモリスイッチの
		dec	bl		;アドレスになる
		and	bl,7
		add	bx,bx
		add	bx,bx
		;メモリスイッチ書換え許可
		mov	al,0DH
		out	68H,al
		;メモリスイッチに書き込み
		mov	al,value	;メモリスイッチへ書き込み
		mov	es:[bx+3FE2H],al
		;メモリスイッチ書換え禁止
		mov	al,0CH
		out	68H,al
		ret
		;** ハイレゾ，LT/HAの処理（BIOS使用） **
BiosUse:	mov	ah,22H		;メモリスイッチ書換
		mov	al,number
		mov	dl,value
		int	18H
		ret
SetMemorySwitch	ENDP


;==========
;int ExistExtRom(int CheckSegment);
;拡張メモリ領域のメモリ存在調査
;----------
;引数
;  なし
;戻り値
;   0 = メモリなし
;   1 = メモリあり
;機能
;  CheckSegmentで指定されたセグメントの先頭4KBにメモリが
;  存在するかどうかを調べる。
;----------
AREA_SIZE EQU 1000H	;4KB		;１つのＲＯＭ領域のサイズ
INTERVAL  EQU 10H	;16bytes	;調査間隔（高速化のため全ては調べない）

ExistExtRom	PROC	USES ds si, CheckSegment:WORD
		mov	ds,CheckSegment
	;--- FFH読出のテスト
		;全部FFH → 書込／読出テスト（ＲＡＭチェック）
		;その他の値が読めた → アクティブターミネータのためのテスト
		mov	cx,AREA_SIZE / 4
		mov	si,0000H	;検査開始番地のオフセット
		cld
RomTestLoop:	push	cx		;rep lodswを用いて、データバスの
		mov	cx,0002H	;  電圧が安定してからの値を比較する
		cli
		rep	lodsw		;  （ハイレゾ対応のため。ノーマルは
		sti			;　いきなり読んでも大丈夫）
		pop	cx
		cmp	ax,0FFFFH	;読み出した値がFFFFHでなかったら
		jne	AtTest		;その他の値が読めた → ATのための確認へ
		loop	RomTestLoop
		;			;全部FFH → RAMかどうかの確認へ


	;--- 書込／読出テスト（ＲＡＭチェック）
		;書き込んだ値が読みだせた（ＲＡＭあり）→メモリあり
		;書き込んだ値が読みだせない→メモリなし
		mov	cx,AREA_SIZE / INTERVAL
		mov	si,0000H	;SI←0000H
		mov	ax,si		;AX←0000H
		mov	bx,ax
		dec	bx		;BX←FFFFH
RamTestLoop:	cli			;割込禁止
		push	[si]		;[SI]の値を保存
		mov	[si],ax		;[SI]に0000Hを書き込む
		cmp	[si],ax		;[SI]の値を0000Hと比較
		jne	RamTest1
		mov	[si],bx		;[SI]にFFFFHを書き込む
		cmp	[si],bx		;[SI]の値をFFFFHと比較
RamTest1:	pop	[si]		;[SI]の値を復帰
		sti			;割込許可
		je	MemoryPresent	;一致したら「ＲＡＭあり」
		add	si,INTERVAL
		loop	RamTestLoop
		jmp	MemoryAbsent	;「ＲＡＭなし」


	;--- アクティブターミネータ（ＡＴ）のためのテスト
AtTest:		mov	cx,AREA_SIZE / INTERVAL
		mov	si,0000H
AtTestLoop:	cli			;割込禁止
		mov	ax,[si]		;[SI]をAXに読み込む
		cmp	ax,[si]		;再び[SI]を読みAXと比較
		sti			;割込許可
		je	MemoryPresent	;一致したらメモリあり
		add	si,INTERVAL
		loop	AtTestLoop
;		jmp	MemoryAbsent	;一致しなかったらメモリなし


MemoryAbsent:	mov	ax,0000H	;メモリなし
		ret
MemoryPresent:	mov	ax,0001H	;メモリあり
		ret
ExistExtRom	ENDP


;==========
;unsigned int GetPrnStat(void);
;プリンタの状態取得
;----------
;引数
;  なし
;戻り値
;   0 : データ送信可能状態
;   1 : ＢＵＳＹ状態（ハイレゾ，Ｈ９８のみサポート）
;   2 : タイムアウトで送信不可能だった（ハイレゾ，Ｈ９８のみサポート）
;   3 : ディセレクト状態
;   4 : ペーパーエンド（ハイレゾ，Ｈ９８のみサポート）
;   5 : プリンタ未接続または電源ＯＦＦ
;機能
;  プリンタの状態を調べる。ハイレゾ，Ｈ９８ではフルセントロニクスＩ／Ｆから
;  プリンタの詳細な状態を取得する。ノーマル（除Ｈ９８）では詳細な情報を得る
;  ことが不可能なので、BUSY端子の振舞いから状態を推定する。ただし、この場合
;  プリンタの仕様によっては「ディセレクト状態」を検出できない機種もある。
;----------
GetPrnStat	PROC	NEAR
	;ハイレゾなら、プリンタＢＩＯＳの12Hを実行してリターン
		mov	ax,0000H	;ES←0000（システム共通域）
		mov	es,ax
		test	es:[0501H],BYTE PTR 08H	;ハイレゾ／ノーマル判定
		jz	Normal
		mov	ah,12H		;ステータス取得
		int	1AH
		mov	al,ah
		mov	ah,00
		ret
Normal:
	;フルセントロサポートなら、プリンタＢＩＯＳの18Hを実行してリターン
		test	es:[0458H],BYTE PTR 02H	;フルセントロ可能ビット検査
		jz	MiniCentro
		mov	ah,18H		;センス
		int	1AH
		mov	al,ah
		mov	ah,00
		ret
;--- 以下、簡易セントロニクスモードのときの処理 ---
MiniCentro:
	;プリンタがＢＵＳＹなら、電源ＯＮでＯＦＦＬＩＮＥ
		in	al,0042H	;BUSY信号チェック(zero active)
		test	al,04H
		jz	offline		;アクティブならオフライン
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
	;DC1を送る（DC1以外のコードでもプリンタが余計な動作をしなければ良い）
		mov	al,11H		;プリンタポートに11H(DC1)をセット
		out	0040H,al
		out	dx,al		;0.6μsウェイト
		out	dx,al		;もう一度
		mov	al,0EH		;PSTB#アクティブ
		out	0046H,al
		out	dx,al		;0.6μsウェイト
		out	dx,al		;もう一度
		or	al,01H		;PSTB#インアクティブ
		out	0046H,al
	;ＢＵＳＹが一瞬アクティブになったらプリンタ電源ＯＮと判断
	;一定時間待ってもアクティブにならなければ電源ＯＦＦと判断
		mov	cx,1000H
BusyCheckLoop:	in	al,0042H	;BUSY信号チェック(zero active)
		test	al,04H
		jz	online		;アクティブになればオンライン
		loop	BusyCheckLoop
		mov	ax,0005H
		ret
online:		mov	ax,0000H
		ret
offline:	mov	ax,0003H
		ret
GetPrnStat	ENDP


;==========
;void PrinterSelect(void);
;プリンタを強制的にセレクト状態にする
;（for PC-PR(except Page Printer)，NM series）
;----------
;機能
;  プリンタを強制的にセレクトにする。ただし、プリンタの仕様によっては
;  プリンタポート経由で強制的にセレクトできない機種（PC-PRのページプ
;  リンタ，ESC/Pプリンタなど）もある。
;  セレクトが成功したかどうかはGetPrnStatで調べる。
;----------
PrinterSelect	PROC	NEAR
		push	es
		mov	ax,0000H	;ES←0000（システム共通域）
		mov	es,ax
		mov	ah,04H
		test	es:[0501H],BYTE PTR 08H	;ハイレゾ／ノーマル判定
		jz	FullCentro
		test	es:[0458H],BYTE PTR 04H	;H98 NORMALのフルセントロ
		jnz	FullCentro
		mov	ah,0EH
FullCentro:
		;ウェイト用OUTポートのアドレス決定
		;無印･E･F･M→BFDBH（マウス割込周期設定用ポート）
		;その他    →005FH（ウェイト用ポート）
		mov	dx,0BFDBH
		test	es:[0500H],WORD PTR 1801H	;無印･E･F･M検出
		jz	@f
		mov	dx,005FH
	@@:	pop	es
		mov	al,11H		;プリンタポートに11H(DC1)をセット
		out	0040H,al
		out	dx,al		;0.6μsウェイト
		out	dx,al		;もう一度
		mov	al,ah		;PSTB#をアクティブ
		out	0046H,al
		out	dx,al		;0.6μsウェイト
		out	dx,al		;もう一度
		or	al,01H		;PSTB#をインアクティブ
		out	0046H,al
		ret
PrinterSelect	ENDP



;==========
;int ExistSoundBoard(void);
;サウンド機能の存在調査
;----------
;引数
;  なし
;戻り値
;   0 = サウンド機能なし
;   1 = サウンド機能あり。ＲＯＭなし（ハイレゾ含む）
;   2 = サウンド機能あり。サウンドＲＯＭあり
;機能
;  サウンド機能の有無とそのＲＯＭの有無を調べる。
;----------
ExistSoundBoard	PROC	NEAR
	;--- OPNの有無判別
		mov	cx,0100H	;256回繰り返す
OpnCheckLoop:	mov	dx,0188H	;ＯＰＮステータスポート
		in	al,dx
		cmp	al,0FFH
		jne	OpnExist	;FFでなければOPNあり
		loop	OpnCheckLoop
		mov	ax,0000H
		jmp	Quit
OpnExist:
	;--- ハイレゾ判別
		mov	ax,0000H	;ES←0000（システム共通域）
		mov	es,ax
		test	es:[0501H],BYTE PTR 08H	;ハイレゾ／ノーマル判定
		mov	ax,0001H
		jnz	Quit		;ハイレゾならＲＯＭなし
	;--- ＲＯＭ存在判別
		mov	ax,0CC00H
		mov	es,ax
		mov	ax,0001H	;ＲＯＭなしの戻り値
		mov	bx,2E00H	;INTベクタエントリ情報
		cmp	es:[bx],WORD PTR 0001H	;エントリ数
		jne	Quit
		add	bx,2
		cmp	es:[bx],WORD PTR 0000H
		jne	Quit
		add	bx,2
		cmp	es:[bx],WORD PTR 00D2H	;ベクタ番号
		jne	Quit
		mov	ax,0002H	;ＲＯＭありの戻り値
Quit:		ret
ExistSoundBoard	ENDP


;==========
;int ExistMouseIF(void);
;マウスＩ／Ｆの存在調査
;----------
;引数
;  なし
;戻り値
;   0 = Ｉ／Ｆなし
;   1 = Ｉ／Ｆあり。割込周期設定機能なし
;   2 = Ｉ／Ｆあり。割込周期設定機能あり
;機能
;  マウスＩ／Ｆの有無とその割込周期設定機能の有無を調べる。
;  PC-9801-71とF3/M2内蔵マウスＩ／Ｆにはソフトウェアから割込周期を
;  設定する機能はなく、ボード上のDIP SWで設定する。ハイレゾの割込
;  周期は120Hzで固定。
;----------
ExistMouseIF	PROC	NEAR
		push	es
		mov	ax,0000H	;システム共通域セグメント
		mov	es,ax
		mov	ax,es:[0500H]	;機種情報
		test	ax,0800H	;ハイレゾ判定
		mov	bl,01H		;I/Fあり，周期設定なし
		jnz	Quit
		and	ax,1001H
		cmp	ax,0000H	;無印,E,F,M判定
		je	BoardCheck
		cmp	ax,1000H	;PC-98LT,HA判定
		mov	bl,00H		;I/Fなし，周期設定なし
		je	Quit
		mov	bl,02H		;I/Fあり，周期設定あり
		jmp	Quit		;その他
BoardCheck:	mov	dx,7FD9H	;ボタン押下状態，座標読取用PORT(ﾉｰﾏﾙ)
		in	al,dx
		cmp	al,0FFH
		mov	bl,00H		;I/Fなし，周期設定なし
		je	Quit
		mov	bl,01H		;I/Fあり，周期設定なし
Quit:		mov	al,bl
		mov	ah,00H
		pop	es
		ret
ExistMouseIF	ENDP


END

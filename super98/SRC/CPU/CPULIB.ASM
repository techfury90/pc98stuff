TITLE CPU

		.8086
		.MODEL	SMALL,C

		.CODE


;==========
;int CpuKind(void);
;入力：なし
;出力： 0=8086
;       1=80186
;       2=80286
;       3=80386
;       4=80486
;      11=V30・V50・V33A
;      31=V33
;      83=80386(V86)
;      84=80486(V86)
;==========

cpuis86  =  0H
cpuis186 =  1H
cpuis286 =  2H
cpuis386 =  3H
cpuis486 =  4H
cpuisV30 = 11H
cpuisV33 = 31H

		PUBLIC	CpuKind
CpuKind		PROC	NEAR
;--- 8086,80186,V30,V33(A),V50 / 80286,386,486 判別
		pushf			;mov ax,FLAGS
		pop	ax
		test	ax,8000H	;FLAGSのMSBをチェック
		jnz	chk186				;MSB = 1
;--- 80286 / 8086,80186,V30,V33(A),V50,386,486 判別
chk286:		pushf			;フラグ待避
		mov	ax,4000H	;FLAGSにbit 12=1を書き込む
		push	ax		;mov FLAGS,ax
		popf
		pushf			;mov ax,FLAGS
		pop	ax
		popf			;フラグ復帰
		test	ax,4000H	;FLAGSのbit 12をチェック
		mov	al,cpuis286
		jz	DoneCheckCpu
;--- 386 / 486 判別
;    386,486以外で実行させてはならない。
;４８６での動作は未確認
	.386
		pushfd			;EFLAGS待避
		push	bp		;アラインメントチェックが起動しない
		mov	bp,sp		;ようにスタックポインタを32bit境界に
		and	sp,0FFFCH	;調整
		pushfd			;mov eax,EFLAGS
		pop	eax
		or	eax,00040000H	;bit18=1(Alignment Check ON)
		push	eax		;mov EFLAGS,eax
		popfd
		pushfd			;mov eax,EFLAGS
		pop	eax
		mov	sp,bp		;スタックポインタを元に戻す
		pop	bp
		popfd			;EFLAGS復帰
		test	eax,00040000H	;EFLAGSのbit 18をチェック
	.8086
		mov	al,cpuis486
		jnz	chkV86
		mov	al,cpuis386
		jmp	chkV86
;--- 8086,V30,V33(A),V50 / 80186,80286,386,486 判別
chk186:		mov	al,01H		;被シフト値
		mov	cl,20H		;シフト回数（３２回）
		shr	al,cl
		or	al,al
		mov	al,cpuis186
		jnz	DoneCheckCpu
;--- V30,V50,V33A / 8086,80186,80286,386,486,V33 判別
		mov	ax,0100H	;被変換値
	DB	0D5H,00H
	;80x86  : AAD 00 --> AL=AH*00H+AL, AH=00
	;V30,50 : AAD    --> AL=AH*0AH+AL, AH=00
		mov	ax,cpuisV30
		jnz	DoneCheckCpu
;--- 8086,80186,V30,V50,V33A / V33,80286,386,486 判別
		push	sp
		pop	ax
		cmp	ax,sp
		mov	ax,cpuisV33
		je	DoneCheckCpu
		mov	ax,cpuis86
		jmp	DoneCheckCpu
;--- Real Mode / V86 Mode 判別
chkV86:
	.286P
		smsw	bx	;mov ax,MSW(CR0)
		test	bl,1	;MSWのbit 0(Protect Mode Flag)をチェック
		jz	DoneCheckCpu	;PMF=0
		or	al,80H	;PMF=1
	.8086
DoneCheckCpu:	mov	ah,00H
		ret
CpuKind		ENDP


;==========
;int GetSysClk(void);
;入力：なし
;出力：0 = 10MHz系，1 = 8MHz系
;==========
		PUBLIC	GetSysClk
GetSysClk	PROC	NEAR
		push	es
		mov	ax,0000H
		mov	es,ax			;ES←Low Memory Segment
		mov	ax,es:[0500H]		;AX←[0000:0500]
		pop	es
		and	ax,8000H		;bit 15を残してマスク
		rol	ax,1			;bit 15をbit 0に移動
		ret
GetSysClk	ENDP


;==========
;void CpuReset(void);
;ＣＰＵをソフトウェアからリセットする
;==========
CpuReset	PROC	NEAR
;--- 外部割込禁止
;　　タイマなどが動作しているとき、イニシャライズ処理の途中で割込が
;　　かかると誤動作する可能性があるので、それを防ぐ。
		cli
;--- 80286/386/486搭載機種のための準備
		mov	al,0FH		;SHUT0=1
		out	37H,al
		mov	al,0BH		;SHUT1=1
		out	37H,al
;--- 動作ＣＰＵ判定
;    VM21でOUT F0H,00Hを行うとハングするので、それを回避するため
;    V30のときはOUT F0Hをスキップする
		pushf
		pop	ax
		test	ax,8000H
		jnz	JumpFFFF
;--- ＣＰＵリセット実行
;　　80286/386/486搭載機種ではCPU RESETポートにOUTすると、CPUの
;　　RESET端子のみアクティブになる。
		mov	al,0
		mov	dx,00F0H
		out	dx,al		;CPU RESET実行
		mov	cx,1000H
		loop	$		;リセットがかかるまで待つ
;--- イニシャライズ処理ルーチンにジャンプ
;　　シャットダウン・ポートを持たない機種の場合のため、CPUのリセット時に
;　　近い状態にしてFFFF:0000Hにジャンプする。
JumpFFFF:	mov	ax,0000H
		push	ax
		popf
		mov	ds,ax
		mov	es,ax
		mov	ss,ax
		jmp	FAR PTR ResetEntry
CpuReset	ENDP


ResetSeg	SEGMENT	AT 0FFFFH
		ASSUME	cs:ResetSeg
		ORG	0000H
ResetEntry	PROC	FAR
ResetEntry	ENDP
ResetSeg	ENDS


END


●各種ＣＰＵ判別ルーチン
;--- 8086、V30、V33(A)、V50／80186、80286、386、486判別
;    AL←01H、 CL←20Hとセットして、SHR AL,CLを実行する。
;    8086とVシリーズでは20H(32)回シフトが行われてAL=0となる。
;    80186以上のCPUでは20H and 1FH=00となり、シフトは行われずAL=1となる。
		mov	al,01H		;被シフト値
		mov	cl,20H		;シフト回数（32回）
		shr	al,cl
		or	al,al
		jz	(8086,V30,V33,V50)	;シフトが行われてAL=0
		jmp	(80186,80286,386,486)	;シフトは行われずAL=1


;--- V30・V50・V33A／8086・80186・80286・386・486・V33判別
;    AX←0100Hをセットして、AAD 00を実行する。
;    Vシリーズ（除くV33）ではALが01*0AH+00=0AHとなる。
;    80x86・V33ではALが01*00H+00=00Hとなる。
		mov	ax,0100H	;被変換値
	DB	0D5H,00H
	;80x86  : AAD 00	;AL=AH*00H+AL, AH=00
	;V30    : AAD		;AL=AH*0AH+AL, AH=00
		jz	(8086,80186,80286,386,486,V33)	;0が乗算されてAL=0
		jmp	(V30,V50)			;10が乗算されてAL=0AH


;--- V30、V33(A)、V50／8086判別
;    8086、V30、V33(A)、V50以外のCPUでこのルーチンを実行させてはならない
		mov	bx,sp		;スタックポインタ保存
		push	cs		;POP CSに備えてCSをPUSH
		mov	al,0		;adc al,0C0Hで繰り上がらないように
		stc			;CF=1
	DB	0FH,14H,0C0H
	;V30  : set1	al,cl		;ALのbit clがsetされる,CF=no change
	;8086 :	pop	cs
	;8086 : adc	al,0C0H		;AL=0C1H、CF=0
		mov	sp,bx		;スタックポインタ復帰
		jc	(V30,V33(A),V50)
		jmp	(8086)


;--- 8086、80186、V30、V50、V33A／V33、80286、386、486判別
		push	sp
		pop	ax
		cmp	ax,sp
		je	(V33,80286,386,486)
		jmp	(8086,80186,V30,V50,V33A)


;--- 386・486／8086・80186・80286・V30・V33(A)・V50判別
;    386命令を使用するときにこの判定が利用できる。
;    386・486ではbit 15は常に0、bit 14は書き換え可能なので、
;    bit 14=1を書き込んだとき、bit 15,14=0,1が読み出せれば
;    386・486である。
		pushf
		pop	ax		;mov ax,FLAGS
		pushf			;FLAGS待避
		or	ax,4000H	;FLAGS bit 14=1 をセット
		push	ax
		popf			;mov FLAGS,ax
		pushf
		pop	ax		;mov ax,FLAGS
		popf			;フラグ復帰
		and	ax,0C000H	;FLAGS bit 15,14 を残してマスク
		cmp	ax,4000H	;FLAGS bit 15,14=01なら386以上
		je	(386,486)
		jmp	(8086,80186,80286,V30,V33(A),V50)


;--- 80286・386・486／8086・80186・V30・V33(A)・V50判別
;    80286・386・486ではbit 15は常に0なので、bit 15=0が
;    読み出せれば80286・286・486である。
		pushf			;mov ax,FLAGS
		pop	ax
		test	ax,8000H	;FLAGS bit 15=0 なら 80286以上
		jz	(80286,386,486)
		jmp	(8086,80186,V30,V33(A),V50)


;--- 80286／8086・80186・V30・V33(A)・V50・386・486判別
;    80286ではbit14は常に0なので、bit 14=1を書き込んで、
;    0が読み出せれば80286である。
		pushf
		pop	ax		;mov ax,FLAGS
		pushf			;フラグ待避
		or	ax,4000H	;FLAGS bit 14=1をセット
		push	ax
		popf			;mov FLAGS,ax
		pushf
		pop	ax		;mov ax,FLAGS
		popf			;フラグ復帰
		test	ax,4000H	;FLAGS bit 14=0なら80286
		jz	(80286)
		jmp	(8086,80186,V30,V33(A),V50,386,486)


;--- 386・486 Real Mode／
;	386・486 V86 Mode・8086・80186・80286・V30・V50・V33(A)判別
;    386,486のリアルモードでしか実行できない機能（CRnレジスタ等の書き換え、
;    V86モードへの移行など）を使用するときにこの判定が利用できる。
;    386,486のリアルモードのみbit 13～12が書き換えできるので、ここを反転
;    させた値をFLAGSに書き込み、それを読みだして元のFLAGSと異なれば386,486
;    リアルモードと判断できる。
		pushf
		pop	ax		;mov ax,FLAGS
		pushf			;フラグ待避
		mov	bx,ax		;元のFLAGSの値を保存
		xor	ax,3000H	;FLAGS bit 13～12=を反転
		push	ax
		popf			;mov FLAGS,ax
		pushf
		pop	ax		;mov ax,FLAGS
		popf			;フラグ復帰
		cmp	ax,bx		;元のFLAGSの値と比較
		jne	(386,486 Real Mode)
		jmp	(386,486 V86 Mode, 80286,80186,8086,V series)


;--- Real Mode／V86 Mode判別
;    80286・386・486のみで実行すること。
;    8086・80186・V30・V33(A)・V50で実行させてはならない。
	.286P
		smsw	ax	;mov ax,MSW(CR0)
		test	al,1	;MSWのbit 0(Protect Mode Flag)をチェック
		jz	(Real Mode)	;PMF=0
		jmp	(V86 Mode)	;PMF=1


;--- 386／486判別
;    386・486以外で実行させてはならない。
	.386
		mov	bx,sp		;SP保存
		and	sp,0FFFCH	;ACが起動しないようSPを32bit境界に調整
		pushfd			;EFLAGS待避
		cli			;割込禁止
		pushfd
		pop	eax		;mov eax,EFLAGS
		or	eax,00040000H	;bit18=1(Alignment Check ON)
		push	eax
		popfd			;mov EFLAGS,eax
		pushfd
		pop	eax		;mov eax,EFLAGS
		popfd			;EFLAGS復帰
		mov	sp,bx		;SP復帰
		test	eax,00040000H	;EFLAGSのbit 18をチェック
	.8086	;16bit相対条件ジャンプ命令が生成されないように.386を解除
		jnz	(486)		;bit 18=1
		jmp	(386)		;bit 18=0


;8086・V30・V50・V33で実行しないこと。
;注）80486の命令を使っている部分があるため、MASM 6.00以降またはTASM 2.0以降でなければアセンブルできない。
		push	ds
		push	es
	;--- INT 06Hベクタ保存
		mov	ax,3506H
		int	21H		;ES:BX ← INT 06H entry
	;--- INT 06Hベクタ変更
		mov	ax,cs
		mov	ds,ax
		mov	dx,OFFSET InvCodeDetect
		mov	ax,2506H
		int	21H
		cli
		mov	cx,sp		;SP保存
	;--- 80286特有命令のテスト
		mov	dx,01H
	.286P
		smsw	ax		;80186,V33Aでは未定義
	;--- 386特有命令のテスト
		inc	dx
	.386
		bt	ax,1		;80286では未定義
	;--- 486特有命令のテスト
		inc	dx
	.486
		bswap	eax		;386では未定義
	.8086
		inc	dx
InvCodeDetect:	;無効命令が検出された場合のジャンプ先
		mov	sp,cx		;SP復帰
	;--- INT 06Hベクタ復帰
		push	dx
		mov	ax,es
		mov	ds,ax
		mov	dx,bx
		mov	ax,2506H
		int	21H
		pop	dx
		sti
	;--- レジスタ復帰
		pop	es
		pop	ds
	;DX=1 : 80186,V33A
	;DX=2 : 80286
	;DX=3 : 386
	;DX=4 : 486

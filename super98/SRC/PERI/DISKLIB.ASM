		TITLE DISK I/O

		.8086
		.MODEL	SMALL,C

		.CODE


;==========
;unsigned char DriveToDaua(unsigned char drive);
;MS-DOSのドライブ名をDA/UA（デバイス種別／ユニット番号）に変換する
;----------
;引数
;  drive : ドライブ名（'A'..'Z'）
;戻り値
;	0      = BIOSアクセス不可能なドライブ
;	70～73 = 640KB FD, 両用FD I/Fの640KB I/Fモード
;	80～83 = SASI HD（82H～83HはH98のみ）
;	90～93 = 1MB FD, 両用FD I/Fの1MB I/Fモード
;	A0～A7 = SCSI HD
;注意
;  JOIN,SUBSTの設定にかかわらず、起動時のドライブ割り当てに従う
;----------
DriveToDaua	PROC	NEAR,drive:BYTE
;0060H:006CH に A:～P:のDA/UAリストがある。

	.DATA?
DriveDauaMap	DB	10H DUP(?)
		DB	0AH DUP(?)
DriveDauaMap2	DB	26D DUP(?,?)
		DB	01H DUP(?,?)
		DB	10H DUP(?)

	.CODE
		mov	bh,0
		mov	bl,drive
		sub	bl,'A'		;'A'→0に
	;--- MS-DOS 製品番号チェック
		mov	cl,12H
		mov	ax,0000H
		int	0DCH
		cmp	ax,0000H
		je	old_type	;新方式が使えない
	;--- 新方式変換
		cmp	bl,'Z'-'A'	;A:～Z:ドライブが有効
		ja	error
		mov	cl,13H
		mov	dx,OFFSET DriveDauaMap
		int	0DCH
		shl	bx,1
		inc	bx
		mov	al,DriveDauaMap2[bx]
		jmp	check
	;--- 旧方式変換
old_type:	cmp	bl,'P'-'A'	;A:～P:ドライブが有効
		ja	error
		mov	ax,0060H	;MS-DOSのワークエリア
		mov	es,ax
		mov	al,es:[006CH+bx]
	;--- 範囲チェック
check:		cmp	al,70H		;00H～6FH→error
		jb	error
		cmp	al,0A8H		;A8H～FFH→error
		jae	error
		cmp	al,0A0H		;A0H～A7H→SCSI check
		jae	ScsiCheck
		test	al,0CH		;x4H～xFH→error
		jnz	error
good:		mov	ah,00H
		ret
error:		mov	ax,00H
		ret
	;--- SCSIチェック
	;	3.5"MOはSCSI HDのDA/UAを示すが、そのDA/UAでは
	;	DISK BIOSでアクセスできないので、それを検出する。
ScsiCheck:	push	ax
		mov	ah,84H		;センス
		int	1BH		;DISK BIOS
		pop	ax
		jc	error
		jmp	good
DriveToDaua	ENDP


END



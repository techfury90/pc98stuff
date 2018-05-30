; キークリック音発生プログラム

code	segment
	assume	cs:code,ds:code

	org	100h

p_start:
	jmp	p_entry

pro_id	db	'KEY_CLICK',0	; 常駐チェック用ID

	even
iv_adr	label	dword		; INT-09H
iv_ofs	dw	0		; オフセット保存用
iv_seg	dw	0		; セグメント保存用

entmask	db	0		; 再入禁止フラグ
key_n	db	0		; キーコード数のワーク

; INT-09Hエントリ

iv_ent proc far
	push	ax
	push	es
	sub	ax,ax
	mov	es,ax
	mov	al,es:[0528h]	; キーコードバッファ内のキーコード数
	mov	cs:key_n,al
	pop	es
	pop	ax

	pushf
	call	dword ptr cs:iv_adr	; 本来の割り込み処理

	push	ax
	push	es
	sub	ax,ax
	mov	es,ax
	mov	al,es:[0528h]	; キーコードバッファ内のキーコード数
	cmp	al,cs:key_n
	pop	es
	pop	ax
	jz	iv_end

	cmp	cs:entmask,0	; 再入チェック
	jnz	iv_end
	mov	cs:entmask,1
	sti
	push	ax
	mov	al,06h
	out	37h,al
	mov	ax,1000
cloop:
	out	5fh,al
	dec	ax
	jnz	cloop
	mov	al,07h
	out	37h,al
	pop	ax
	mov	cs:entmask,0
iv_end:
	iret
iv_ent endp

p_entry proc
	mov	ax,cs
	mov	ds,ax
	mov	es,ax

	mov	ax,3509h
	int	21h		; INT-09H ベクタ読み出し
	mov	iv_ofs,bx
	mov	iv_seg,es

	mov	di,offset pro_id
	mov	si,di
	mov	cx,10
	cld
	repe cmpsb		; 常駐チェック
	jz	remove		; 常駐解除

	mov	dx,offset iv_ent
	mov	ax,2509h
	int	21h		; ベクタ書き込み

	mov	es,word ptr cs:[002ch]	; 環境エリアのセグメント取得
	mov	ax,4900h
	int	21h		; 環境エリアを解放

	mov	dx,offset p_entry
	mov	cl,4
	shr	dx,cl
	inc	dx		; 常駐サイズ計算
	mov	ax,3100h
	int	21h		; 常駐終了

; 常駐解除の処理

remove:
	push	ds
	mov	es,iv_seg	; 常駐プログラムのセグメント
	lds	dx,es:iv_adr	; 常駐プログラム内のINT-09H元ベクタ
	mov	ax,2509h
	int	21h		; ベクタを書き戻す
	pop	ds

	mov	es,iv_seg	; 常駐プログラムのセグメント
	mov	ax,4900h
	int	21h		; 常駐部のコードエリアを解放

	mov	ax,4c00h
	int	21h		; 終了
p_entry endp

code	ends
	end	p_start

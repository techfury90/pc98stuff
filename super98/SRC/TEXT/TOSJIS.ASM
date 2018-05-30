	.MODEL	small,c
	.CODE

ToSjis	PROC chcode:WORD
	mov	ax,chcode	; ＪＩＳ漢字コードを取得
	cmp	ah,21h		; ＪＩＳ漢字コードの１バイト目の範囲チェック
	jb	error
	cmp	ah,7eh		; 範囲チェック
	ja	error
	cmp	al,21h		; ＪＩＳ漢字コードの２バイト目の範囲チェック
	jb	error
	cmp	al,7eh		; 範囲チェック
	ja	error
	sub	ah,21h		; 21h～7dhを00h～5chに変換
	shr	ah,1		; 00h～5chを00h～2ehに変換
	jnc	conv1		; 変換前のahが偶数ならconv1へ
	add	al,5eh		; 21h～7ehを7fh～dchに変換
conv1:
	add	al,1fh		; 21h～dchを40h～fbhに変換
	cmp	al,7eh		; +1補正が必要か
	jbe	conv2		; +1補正が不要ならconv2へ
	inc	al		; 7fh～fbhを80h～fchに変換
conv2:
	add	ah,81h		; 00h～2ehを81h～afhに変換
	cmp	ah,9fh		; 81h～9fhか
	jbe	pend		; 81h～9fhなら変換終了へ
	add	ah,40h		; a0h～afhをe0h～efhに変換
	jmp	SHORT pend	; 変換終了へ
error:
	sub	ax,ax		; 0はエラー時のリターン値
pend:
	ret
ToSjis	ENDP

	END

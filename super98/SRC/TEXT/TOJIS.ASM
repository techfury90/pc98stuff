	.MODEL	small,c
	.CODE

ToJis	PROC chcode:WORD
	mov	ax,chcode	; シフトＪＩＳ漢字コードを取得
	cmp	ah,81h		; １バイト目の範囲チェック
	jb	error
	cmp	ah,9fh		; 範囲チェック
	jbe	conv1		; 範囲内なら変換処理へ
	cmp	ah,0e0h		; 範囲チェック
	jb	error
	cmp	ah,0efh		; 範囲チェック
	ja	error
conv1:
	and	ah,3fh		; 81h～9fhとe0h～efhを01h～2fhに変換
	add	ah,ah		; 01h～2fhを02h～5ehの偶数に変換
	add	ah,1fh		; 02h～5ehを21h～7dhの奇数に変換
	cmp	al,40h		; ２バイト目の範囲チェック
	jb	error
	cmp	al,7fh		; 範囲チェック
	jb	conv2		; 範囲内なら変換処理へ
	jz	error
	cmp	al,0fch		; 範囲チェック
	ja	error
	cmp	al,09fh		; ＪＩＳ漢字の偶数コードかチェック
	jae	conv3		; 偶数区なら変換処理へ
	sub	al,20h		; 80h～9ehを60h～7ehに変換
	jmp	SHORT pend
conv2:
	sub	al,1fh		; 40h～7ehを21h～5fhに変換
	jmp	SHORT pend
conv3:
	inc	ah		; １バイト目を奇数→偶数に変換
	sub	al,7eh		; 9fh～fchのコードを21h～7ehに変換
	jmp	SHORT pend
error:
	sub	ax,ax		; 0はエラー時のリターン値
pend:
	ret
ToJis	ENDP

	END

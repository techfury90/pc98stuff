	.MODEL	small,c
	.CODE

ToSjisFast PROC chcode:WORD
	mov	ax,chcode	; ＪＩＳ漢字コードを取得
	add	ah,21h		; 21h〜5ehを42h〜7fhに変換
				; 5fh〜7ehを80h〜9fhに変換
	sar	ah,1		; 42h〜7fhを21h〜3fhに変換
				; 80h〜9fhをc0h〜cfhに変換
	jnc	conv		; シフト前のahが偶数ならconvへ
	add	al,5eh		; 21h〜7ehを7fh〜dchに変換
conv:
	add	al,0a0h		; 21h〜5fhをc1h〜ffhに変換しキャリーを０にする
				; 60h〜dchを00h〜7chに変換しキャリーを１にする
	adc	al,7fh		; c1h〜ffhを40h〜7ehに変換
				; 00h〜7chを80h〜fchに変換
	xor	ah,20h		; 21h〜3fhを01h〜1fhに変換
				; c0h〜cfhをe0h〜efhに変換
	or	ah,80h		; 01h〜1fhを81h〜9fhに変換
	ret
ToSjisFast ENDP

	END

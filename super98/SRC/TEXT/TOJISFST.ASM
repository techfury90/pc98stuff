	.MODEL	small,c
	.CODE

ToJisFast PROC chcode:WORD
	mov	ax,chcode	; シフトＪＩＳ漢字コードを取得
	add	ah,ah		; 81h～9fhを02h～3ehの偶数に変換
				; e0h～efhをc0h～dehの偶数に変換
	sub	al,1fh		; 40h～7ehを21h～5fhに変換
				; 80h～9ehを61h～7fhに変換
				; 9fh～fchを80h～ddhに変換
	js	conv		; 80h～ddhの場合はconvへ
	cmp	al,61h		; 21h～5fhの場合はキャリーフラグを1にセット
				; 61h～7fhの場合はキャリーフラグを0にセット
	adc	al,0deh		; alが21h～5fhなら00h～3ehに変換
				; alが61h～7fhなら3fh～5dhに変換
conv:
	add	ax,1fa1h	; alが00h～5dhならa1h～fehに変換しahに1fhを加算
				; alが80h～ddhなら21h～7ehに変換しahに20hを加算
	and	ax,7f7fh	; ＪＩＳ漢字コードにするためのマスク処理
	ret
ToJisFast ENDP

	END

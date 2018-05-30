	.MODEL	small,c
	.CODE

ToSjisFast PROC chcode:WORD
	mov	ax,chcode	; ‚i‚h‚rŠ¿ŽšƒR[ƒh‚ðŽæ“¾
	add	ah,21h		; 21h`5eh‚ð42h`7fh‚É•ÏŠ·
				; 5fh`7eh‚ð80h`9fh‚É•ÏŠ·
	sar	ah,1		; 42h`7fh‚ð21h`3fh‚É•ÏŠ·
				; 80h`9fh‚ðc0h`cfh‚É•ÏŠ·
	jnc	conv		; ƒVƒtƒg‘O‚Ìah‚ª‹ô”‚È‚çconv‚Ö
	add	al,5eh		; 21h`7eh‚ð7fh`dch‚É•ÏŠ·
conv:
	add	al,0a0h		; 21h`5fh‚ðc1h`ffh‚É•ÏŠ·‚µƒLƒƒƒŠ[‚ð‚O‚É‚·‚é
				; 60h`dch‚ð00h`7ch‚É•ÏŠ·‚µƒLƒƒƒŠ[‚ð‚P‚É‚·‚é
	adc	al,7fh		; c1h`ffh‚ð40h`7eh‚É•ÏŠ·
				; 00h`7ch‚ð80h`fch‚É•ÏŠ·
	xor	ah,20h		; 21h`3fh‚ð01h`1fh‚É•ÏŠ·
				; c0h`cfh‚ðe0h`efh‚É•ÏŠ·
	or	ah,80h		; 01h`1fh‚ð81h`9fh‚É•ÏŠ·
	ret
ToSjisFast ENDP

	END

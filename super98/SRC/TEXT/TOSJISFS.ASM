	.MODEL	small,c
	.CODE

ToSjisFast PROC chcode:WORD
	mov	ax,chcode	; �i�h�r�����R�[�h���擾
	add	ah,21h		; 21h�`5eh��42h�`7fh�ɕϊ�
				; 5fh�`7eh��80h�`9fh�ɕϊ�
	sar	ah,1		; 42h�`7fh��21h�`3fh�ɕϊ�
				; 80h�`9fh��c0h�`cfh�ɕϊ�
	jnc	conv		; �V�t�g�O��ah�������Ȃ�conv��
	add	al,5eh		; 21h�`7eh��7fh�`dch�ɕϊ�
conv:
	add	al,0a0h		; 21h�`5fh��c1h�`ffh�ɕϊ����L�����[���O�ɂ���
				; 60h�`dch��00h�`7ch�ɕϊ����L�����[���P�ɂ���
	adc	al,7fh		; c1h�`ffh��40h�`7eh�ɕϊ�
				; 00h�`7ch��80h�`fch�ɕϊ�
	xor	ah,20h		; 21h�`3fh��01h�`1fh�ɕϊ�
				; c0h�`cfh��e0h�`efh�ɕϊ�
	or	ah,80h		; 01h�`1fh��81h�`9fh�ɕϊ�
	ret
ToSjisFast ENDP

	END
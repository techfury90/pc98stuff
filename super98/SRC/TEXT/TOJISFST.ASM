	.MODEL	small,c
	.CODE

ToJisFast PROC chcode:WORD
	mov	ax,chcode	; �V�t�g�i�h�r�����R�[�h���擾
	add	ah,ah		; 81h�`9fh��02h�`3eh�̋����ɕϊ�
				; e0h�`efh��c0h�`deh�̋����ɕϊ�
	sub	al,1fh		; 40h�`7eh��21h�`5fh�ɕϊ�
				; 80h�`9eh��61h�`7fh�ɕϊ�
				; 9fh�`fch��80h�`ddh�ɕϊ�
	js	conv		; 80h�`ddh�̏ꍇ��conv��
	cmp	al,61h		; 21h�`5fh�̏ꍇ�̓L�����[�t���O��1�ɃZ�b�g
				; 61h�`7fh�̏ꍇ�̓L�����[�t���O��0�ɃZ�b�g
	adc	al,0deh		; al��21h�`5fh�Ȃ�00h�`3eh�ɕϊ�
				; al��61h�`7fh�Ȃ�3fh�`5dh�ɕϊ�
conv:
	add	ax,1fa1h	; al��00h�`5dh�Ȃ�a1h�`feh�ɕϊ���ah��1fh�����Z
				; al��80h�`ddh�Ȃ�21h�`7eh�ɕϊ���ah��20h�����Z
	and	ax,7f7fh	; �i�h�r�����R�[�h�ɂ��邽�߂̃}�X�N����
	ret
ToJisFast ENDP

	END
	.MODEL	small,c
	.CODE

; unsigned int GetVram(int colum, int line)
; -----------------------------------------
; �����Ŏw�肳�ꂽ��ʏ�̈ʒu�̕�����ǂݎ��A���̕����R�[�h��Ԃ��B
; �n�C���]���[�h��PC-98HA�Ȃǂɂ͑Ή����Ă��Ȃ��B

GetVram	PROC colum:WORD, line:WORD
	mov	ax,80		; ��ʏ�̂P�s�̕�����
	mul	WORD PTR line	; �w��s�̍s���̈ʒu���v�Z
	add	ax,colum	; �w�茅���擾���ʒu���v�Z
	add	ax,ax		; �Q�{���Ău�q�`�l��̃I�t�Z�b�g�A�h���X�ɕϊ�
	mov	bx,ax
	mov	ax,0a000h	; �u�q�`�l�̃Z�O�����g�A�h���X
	mov	es,ax
	mov	ax,es:[bx]	; �u�q�`�l�̓��e��ǂݏo��
	or	ah,ah		; ANK�������`�F�b�N
	jz	pend		; ANK�����Ȃ�I����
	xchg	ah,al		; ��ʃo�C�g�Ɖ��ʃo�C�g������
	add	ah,20h		; �i�h�r�����R�[�h�ɕϊ�
pend:
	ret
GetVram	ENDP

	END
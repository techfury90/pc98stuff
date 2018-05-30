	.MODEL	small,c
	.DATA
fbuf	db	2+32 dup (0)	; �t�H���g�o�b�t�@

	.CODE

; void SetUcgBios(int chrcode, char *fontbuf, int num)
; ----------------------------------------------------
; ���[�U��`������ݒ肷��

	PUBLIC	SetUcgBios
SetUcgBios PROC chrcode:WORD, fontbuf:WORD, num:WORD
	push	si
	push	di
	call	vsync_wait	; ��ʂ̗����h�~���邽��V-SYNC��҂�
	mov	ah,0dh		; �e�L�X�g��ʕ\����~
	int	18h
;
	mov	ax,1b01h	; KCG�h�b�g�A�N�Z�X���[�h�ɂ���
	int	18h
;
        mov	si,fontbuf
set_loop:
	mov	ax,ds
	mov	es,ax
	mov	di,OFFSET DGROUP:fbuf+2
	mov	cx,16
	cld
	rep movsw		; �t�H���g�f�[�^��]��
;
	mov	bx,ds
	mov	cx,OFFSET DGROUP:fbuf
        mov	dx,chrcode
	mov	ah,1ah		; ���[�U��`�����̏�������
	int	18h
;
	mov	ax,chrcode
	inc	al		; ���̓o�^�R�[�h��
	cmp	al,7fh		; �s�A���_��
	jnz	skip
	mov	al,21h
	inc	ah		; 1���̓o�^�R�[�h��
skip:
	mov	chrcode,ax
	dec	num
	jnz	set_loop	; �w��̓o�^���I���܂ŌJ��Ԃ�
;
	mov	ax,1b00h	; KCG�R�[�h�A�N�Z�X���[�h�ɂ���
	int	18h
;
	call	vsync_wait	; ��ʂ̗����h�~���邽��V-SYNC��҂�
	mov	ah,0ch		; �e�L�X�g��ʕ\���J�n
	int	18h
	pop	di
	pop	si
	ret
SetUcgBios ENDP


; V-SYNC�҂�����

vsync_wait:
	in	al,60h		; GDC�̃X�e�[�^�X��ǂݏo��
	jmp	$+2		; ���J�o���[�^�C���p
	jmp	$+2
	test	al,20h		; V-SYNC����
	jz	vsync_wait
	ret

	END
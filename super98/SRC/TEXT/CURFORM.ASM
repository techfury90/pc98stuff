	.MODEL	small,c
	.CODE

; void SetCursorForm(int form)
; ----------------------------
; �J�[�\���̌`����e�L�X�g�p��GDC�ɐݒ肷��B
; 200���C���\���̃f�B�X�v���C���g�p���郂�[�h��A
; �n�C���]���[�h�ɂ͑Ή����Ă��Ȃ��B
;
; form: ���̂悤�ȃJ�[�\���̌`����w�肷��B
;        0  �{�b�N�X�i�ʏ�̏�ԁj
;        1  �����A���_�[���C��
;        2  �ׂ��A���_�[���C��

SetCursorForm PROC form:WORD
	mov	ax,form
	mov	cl,6		; �P�̌`��w���łU�o�C�g�̃f�[�^���g��
	mul	cl
	mov	bx,ax
	sub	ax,ax		; �V�X�e�����ʗ̈�F�Z�O�����g0000h
	mov	es,ax
	mov	al,es:[053ch]	; �\���s���̃`�F�b�N
	test	al,01h		; �\���s���͂Q�O�s��
	jnz	gdcloop
	add	bx,3		; �|�C���^���{�R���ĂQ�T�s�p�̃f�[�^�ɂ���
gdcloop:
	pushf
	cli			; ���̃v���O�����Ƃ̋�������̂��ߊ����݋֎~
	in	al,60h		; �f�c�b�̃X�e�[�^�X�𒲂ׂ�
	test	al,04h		; �e�h�e�n����
	jz	gdcwait		; ��łȂ����gdcwait��
	jmp	$+2		; ���J�o���[�^�C���p
	jmp	$+2
	jmp	$+2
	mov	al,4bh		; �f�c�b��CSRFORM�R�}���h
	out	62h,al		; �f�c�b�ɃR�}���h�o��
	mov	cx,3		; �f�c�b�ɂR�o�C�g�̃f�[�^���o��
gdcdata:
	jmp	$+2		; ���J�o���[�^�C���p
	jmp	$+2
	jmp	$+2
	mov	al,cs:cdata[bx]	; �J�[�\���`��f�[�^
	inc	bx
	out	60h,al		; �J�[�\���`��f�[�^���f�c�b�ɐݒ�
	loop	gdcdata
	popf
	ret

gdcwait:
	popf
	jmp	$+2		; �f�c�b�̂e�h�e�n����ɂȂ�܂ł̑҂�����
	jmp	$+2
	jmp	SHORT gdcloop

cdata	db	93h,00h,9bh	; �Q�O�s�C�{�b�N�X
	db	8fh,00h,7bh	; �Q�T�s�C�{�b�N�X
	db	93h,10h,8bh	; �Q�O�s�C�A���_�[���C���i���j
	db	8fh,0eh,7bh	; �Q�T�s�C�A���_�[���C���i���j
	db	93h,11h,8bh	; �Q�O�s�C�A���_�[���C���i�ׁj
	db	8fh,0fh,7bh	; �Q�T�s�C�A���_�[���C���i�ׁj

SetCursorForm ENDP

	END
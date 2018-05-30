	.MODEL	small,c
	.CODE

; void SetUcgIo(int chrcode, char *fontbuf, int num)
; --------------------------------------------------
; ���[�U��`������ݒ肷��

SetUcgIo PROC chrcode:WORD, fontbuf:PTR WORD, num:WORD
	push	si
	cld
	mov	si,fontbuf
	mov	dx,chrcode
	mov	bx,0		; �ݒ�񐔃J�E���^
	jmp	SHORT sync_main

sync_wait:
	or	bx,bx		; �񐔃J�E���^��0��
	jz	sync_wait2
	dec	bx		; �񐔃J�E���^�����炷
	jmp	SHORT ucg_set

sync_wait2:
	popf
	jmp	$+2		; ���J�o���[�^�C�������̊��荞�݋N���p
	jmp	$+2

sync_main:
	pushf
	cli
	in	al,60h		; GDC�̃X�e�[�^�X��ǂ�
	test	al,20h		; V-SYNC��
	jz	sync_wait
	inc	bx		; �񐔃J�E���^�𑝂₷
ucg_set:
	mov	al,0bh
	out	68h,al		; KCG�h�b�g�A�N�Z�X

	mov	ax,dx
	out	0a1h,al		; �����R�[�h��2�o�C�g��
	mov	al,ah
	sub	al,20h		; KCG�p�ɃR�[�h��ϊ�����
	out	0a3h,al		; �����R�[�h��1�o�C�g��

	mov	cl,0		; ���C���J�E���^
set_loop:
	mov	al,cl
	or	al,20h		; ���E�r�b�g��1�i���j�ɂ���
	out	0a5h,al		; ���C���J�E���^
	lodsw
	out	0a9h,al		; �����̃t�H���g����������
	mov	al,cl		; ���E�r�b�g��0�i�E�j
	out	0a5h,al		; ���C���J�E���^
	mov	al,ah
	out	0a9h,al		; �E���̃t�H���g����������
	inc	cl		; ���̃��C���ɂ���
	cmp	cl,16
	jnz	set_loop	; 16���C�����J��Ԃ�

	mov	al,0ah
	out	68h,al		; KCG�R�[�h�A�N�Z�X
	popf

	inc	dl		; ���̓o�^�R�[�h��
	cmp	dl,7fh		; 1��̏I��肩
	jnz	skip
	mov	dl,21h
	inc	dh		; 1���̓o�^�R�[�h��
skip:
	dec	num
	jnz	sync_main	; �w�萔�����J��Ԃ�

	pop	si
	ret
SetUcgIo ENDP

	END
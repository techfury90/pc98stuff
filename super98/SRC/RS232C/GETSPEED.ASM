	.MODEL	small,c
	.CODE

; int GetSpeed(void)
; ------------------
; �V���A���|�[�g�̌��݂̒ʐM���x���擾���A�ʐM���x�ɉ��������l��Ԃ��B
; �ʐM���x�Ɩ߂�l�̊֌W�͎��̂悤�ɂȂ�B
; �߂�l    0,  1,   2,   3,   4,    5,    6,    7,    8,     9
; �ʐM���x  75, 150, 300, 600, 1200, 2400, 4800, 9600, 19200, 38400(bps)

GetSpeed PROC
	mov	cx,20		; ���[�v�񐔂�ݒ�
	mov	dx,0
	mov	bx,0
loop1:
	pushf
	cli
	mov	al,80h		; �^�C�}�̃J�E���^���Q�ւ̃��b�`�R�}���h
	out	77h,al		; ���[�h�w��
	jmp	$+2		; ���J�o���[�^�C���p
	jmp	$+2
	in	al,75h		; �J�E���g�l�̉��ʃo�C�g
	mov	ah,al
	jmp	$+2		; ���J�o���[�^�C���p
	jmp	$+2
	in	al,75h		; �J�E���g�l�̏�ʃo�C�g
	xchg	ah,al
	popf

	cmp	ax,bx		; �ő�l�Ɣ�r
	jbe	skip1
	mov	bx,ax		; �ő�l���X�V
skip1:
	cmp	ax,dx		; 1��O�Ɣ�r
	jbe	skip2
	dec	cx		; ���[�v�񐔂����炷
skip2:
	mov	dx,ax		; ����̂��߂ɋL�^
	or	cx,cx
	jnz	loop1		; �I���łȂ�������J��Ԃ�

	sub	ax,ax		; �V�X�e�����ʗ̈�̃Z�O�����g�F0000h
	mov	es,ax		; es���W�X�^�ŃV�X�e�����ʗ̈���A�N�Z�X
	mov	dx,2048		; 5MHz�n�̊�ꕪ���l
	mov	al,es:[0501h]	; �V�X�e�����ʗ̈�̋@�����ǂݏo��
	test	al,80h		; �V�X�e���N���b�N��5MHz�n��8MHz�n���̃`�F�b�N
	jz	count		; ���x���菈����
	mov	dx,1664		; 8MHz�n�̊�ꕪ���l
count:
	sub	ax,ax		; ���x����l�i�߂�l�j������75bps�ɃZ�b�g
calc:
	shr	dx,1		; ��ꕪ���l��1/2�ɂ���
	cmp	dx,bx		; �J�E���g�ő�l�Ɣ�r
	jb	pend		; ��ꕪ���l���J�E���g�ő�l��菬�Ȃ�I����
	inc	ax		; ���x����l�i�߂�l�j�����̒l�ɂ���
	jmp	SHORT calc
pend:
	ret
GetSpeed ENDP

	END
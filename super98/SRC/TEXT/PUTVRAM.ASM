	.MODEL	small,c
	.CODE

; void PutVram(int colum, int line, unsigned int chcode)
; ------------------------------------------------------
; ��ʂ̎w��ʒu�ɕ�����\������B
;
; colum:  ��ʏ�̌��ʒu(0�`79)
; line:   ��ʏ�̍s�ʒu(0�`���݂̉�ʕ\���s��-1)
; chcode: �\�����镶���R�[�h�B

CHRATR	equ	00e1h		; �����̕\���F
CLRCHR	equ	0020h		; �����Ɏg������

PutVram	PROC colum:WORD, line:WORD, chcode:WORD
	mov	cx,colum	; �w�茅���擾
	mov	ax,80		; ��ʏ�̂P�s�̕�����
	mul	WORD PTR line	; �w��s�̍s���̈ʒu���v�Z
	add	ax,cx		; �w�茅�̈ʒu���v�Z
	add	ax,ax		; 2�{����VRAM��̃I�t�Z�b�g�A�h���X�ɕϊ�
	mov	bx,ax
	mov	ax,0a000h	; �e�L�X�gVRAM�Z�O�����g�A�h���X
	mov	es,ax
	jcxz	putmain		; �s���Ȃ�putmain��
	mov	ax,es:[bx]	; �������݈ʒu�̓��e��ǂݏo��
	or	ah,ah		; ANK�������`�F�b�N
	jz	putmain		; ANK�����Ȃ�㏑���Ȃ̂�putmain��
	test	al,80h		; �S�p�����̉E����
	jz	putmain		; �S�p�����̉E���łȂ����putmain��
	mov	ax,CLRCHR
	mov	es:[bx-2],ax	; �S�p�����̍���������
putmain:
	mov	ax,chcode	; �����R�[�h���擾
	or	ah,ah		; ANK�������ǂ����`�F�b�N
	jz	putank		; ANK�����Ȃ�putank��
	xchg	ah,al		; ��ʃo�C�g�Ɖ��ʃo�C�g������
	sub	al,20h		; �I�t�Z�b�g����
	cmp	al,09h		; 2�o�C�g���p�����̃`�F�b�N
	jb	putzen		; �S�p�����Ȃ�putzen��
	cmp	al,0ah		; 2�o�C�g���p�����̃`�F�b�N
	jbe	putank		; ���p�����Ȃ�putank��
putzen:
	mov	es:[bx],ax	; �S�p�����̍���������
	or	al,80h		; �S�p�E���̃t���O�𗧂Ă�
	mov	es:[bx+2],ax	; �S�p�����̉E��������
	mov	ax,CHRATR
	add	bh,20h		; �A�g���r���[�g���ɂ���
	mov	es:[bx],ax	; ������������������
	add	bl,02h		; �����̉E���ɂ���
	jmp	SHORT clrcheck
putank:
	mov	es:[bx],ax	; ��������������
	mov	ax,CHRATR
	add	bh,20h		; �A�g���r���[�g���ɂ���
clrcheck:
	mov	es:[bx],ax	; ������������������
	sub	bh,20h		; �A�h���X���e�L�X�g���ɖ߂�
	mov	dx,es:[bx+2]	; �������݈ʒu�̎��̓��e��ǂݏo��
	or	dh,dh		; ANK�������`�F�b�N����
	jz	pend
	test	dl,80h		; 2�o�C�g�����̉E����
	jz	pend
	mov	dx,CLRCHR
	mov	es:[bx+2],dx	; �S�p�����̍���������
pend:
	ret
PutVram	ENDP

	END
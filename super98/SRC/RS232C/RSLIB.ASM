	.MODEL	small,c
	.DATA

rsivadr	label	dword
rsivofs	dw	?		; �x�N�^�ۑ��p
rsivseg	dw	?		; �x�N�^�ۑ��p

rscmd_d	db	00001000b	; 0: �L�����N�^�� 7bit
	db	00001100b	; 1: �L�����N�^�� 8bit
rscmd_p	db	00110000b	; 0: �����p���e�B
	db	00010000b	; 1: ��p���e�B
	db	00000000b	; 2: �p���e�B����
rscmd_s	db	01000000b	; 0: �X�g�b�v�r�b�g 1bit
	db	10000000b	; 1: �X�g�b�v�r�b�g 1.5bit
	db	11000000b	; 2: �X�g�b�v�r�b�g 2bit

siocmd	db	00110111b	; 8251�ɏo�͂����R�}���h�̕ۑ��p

	EVEN

rbrdpos	dw	0		; ��M�o�b�t�@�̓ǂݏo���ʒu
rbwrpos	dw	0		; ��M�o�b�t�@�̏������݈ʒu
rblen	dw	0		; ��M�f�[�^��

tbrdpos	dw	0		; ���M�o�b�t�@�̓ǂݏo���ʒu
tbwrpos	dw	0		; ���M�o�b�t�@�̏������݈ʒu
tblen	dw	0		; ���M�f�[�^��

RBSIZE	equ	6000		; ��M�o�b�t�@��
RBXOFF	equ	4000		; XOFF���M���邢��RS=OFF������o�b�t�@��
RBXON	equ	2000		; XON���M���邢��RS=ON������o�b�t�@��
TBSIZE	equ	2000		; ���M�o�b�t�@��

rbbuf	db	RBSIZE dup (0)	; ��M�o�b�t�@
tbbuf	db	TBSIZE dup (0)	; ���M�o�b�t�@

rbflow	db	0		; �t���[����t���O
				; 0:����, 1:XON/XOFF, 2:RS/CS
rbxout	db	0		; ���M��ԃt���O
				; 0:XON���, 1:XOFF�v��, 2:XOFF���, 3:XON�v��

	.CODE

; void RsOpen(int speed, int datalen, int parity, int stopbit, int flow)
; ----------------------------------------------------------------------
; RS-232C�̊��荞�ݏ����̓o�^��RS-232C�̏��������s�Ȃ�
; �������ɂ��RS-232C��ER�M����RS�M����ON�ɂȂ�
; speed   �ʐM���x 0,  1,   2,   3,   4,    5,    6,    7,    8,     9
;                  75, 150, 300, 600, 1200, 2400, 4800, 9600, 19200, 38400(bps)
; datalen �f�[�^�� 0:7bit, 1:8bit
; parity  �p���e�B 0:Even, 1:Odd, 2:None
; stopbit �X�g�b�v�r�b�g 0:1bit, 1:1.5bit, 2:2bit
; flow    �t���[���� 0:����, 1:XON/XOFF, 2:RS/CS

RsOpen	PROC speed:WORD, datalen:WORD, parity:WORD, stopbit:WORD, flow:WORD
	call	RsDisable
	mov	ax,350ch	; INT-0CH�x�N�^�̐ݒ���擾
	int	21h
	mov	rsivseg,es	; �Z�O�����g�A�h���X��ۑ�
	mov	rsivofs,bx	; �I�t�Z�b�g�A�h���X��ۑ�
	push	ds
	mov     ax,cs
	mov     ds,ax
	mov     dx,OFFSET RsIntrEntry	; ���荞�ݏ����̃A�h���X
	mov     ax,250ch	; INT-0CH�x�N�^�Ɋ��荞�ݏ�����o�^
	int     21h
	pop	ds
;
	push	speed
	call	SetSpeed	; �ʐM���x��ݒ�
	add	sp,2
;
	mov	ax,flow
	mov	rbflow,al	; �t���[�����ݒ�
;
	pushf
	cli
	mov	al,0		; �_�~�[�R�}���h:00H
	out	32h,al		; �_�~�[�R�}���h���s
	call	RsWait
	out	32h,al		; �_�~�[�R�}���h���s
	call	RsWait
	out	32h,al		; �_�~�[�R�}���h���s
	call	RsWait
;
	mov	al,01000000b	; 8251���Z�b�g
	out	32h,al
	call	RsWait
;
	mov	al,00000010b	; �~�P�U���[�h
	mov	bx,datalen
	or	al,rscmd_d[bx]	; �L�����N�^���̐ݒ�
	mov	bx,parity
	or	al,rscmd_p[bx]	; �p���e�B�̐ݒ�
	mov	bx,stopbit
	or	al,rscmd_s[bx]	; �X�g�b�v�r�b�g�̐ݒ�
	out	32h,al		; ���[�h���߂��o��
	call	RsWait
;
	mov	al,00110111b	; ����M���CER�M����RS�M����ON
	mov	siocmd,al
	out	32h,al		; �R�}���h���o��
;
	in	al,02h		; ���荞�݃R���g���[������IMR��ǂ�
	and	al,11101111b	; RS-232C�̊��荞�݃}�X�N������
	out	02h,al
	popf
	call	RsEnable
	ret
RsOpen	ENDP


; void RsReOpen(int datalen, int parity, int stopbit, int flow)
; -------------------------------------------------------------
; RS-232C�̃f�[�^���Ȃǂ̐ݒ��ύX����
; datalen �f�[�^�� 0:7bit, 1:8bit
; parity  �p���e�B 0:Even, 1:Odd, 2:None
; stopbit �X�g�b�v�r�b�g 0:1bit, 1:1.5bit, 2:2bit

RsReOpen PROC datalen:WORD, parity:WORD, stopbit:WORD, flow:WORD
	call	RsDisable
	pushf
	cli
	mov	ax,flow
	mov	rbflow,al
	mov	al,siocmd	; �R�}���h�|�[�g�o�͗p�f�[�^
	or	al,01000000b	; 8251���Z�b�g
	out	32h,al
	call	RsWait
;
	mov	al,02h		; �~�P�U���[�h
	mov	bx,datalen
	or	al,rscmd_d[bx]	; �f�[�^���̐ݒ�
	mov	bx,parity
	or	al,rscmd_p[bx]	; �p���e�B�̐ݒ�
	mov	bx,stopbit
	or	al,rscmd_s[bx]	; �X�g�b�v�r�b�g�̐ݒ�
	out	32h,al		; ���[�h���߂��o��
	call	RsWait
;
	mov	al,siocmd
	out	32h,al		; �R�}���h���o��
	call	RsEnable
	popf
	ret
RsReOpen ENDP


; void RsWait(void)
; -----------------
; 8251���J�o���[�^�C���p

RsWait	PROC
	mov	cx,16
	loop	$
	ret
RsWait	ENDP


; void RsClose(void)
; ------------------
; RS-232C�̊��荞�݂̒�~�ƃx�N�^�̓o�^�������s�Ȃ�
; RS-232C��ER�M����RS�M����OFF�ɂȂ�

RsClose	PROC
	call	RsDisable	; RS-232C�̑S���荞�݂��֎~
	call	SetErOff	; ER��OFF�ɂ���
	call	SetRsOff	; RS��OFF�ɂ���
	pushf
	cli
	in	al,02h		; ���荞�݃R���g���[������IMR��ǂ�
	or	al,00010000b	; RS-232C�̊��荞�݂��}�X�N
	out	02h,al
	popf
	push	ds
	lds	dx,rsivadr
	mov     ax,250ch	; INT-0CH�x�N�^�����ɖ߂�
	int     21h
	pop	ds
	ret
RsClose	ENDP


; void RsDisable(void)
; --------------------
; RS-232C�̑S���荞�݂��֎~����

RsDisable PROC
	pushf
	cli
	in	al,35h		; �V�X�e���|�[�g��ǂ�
	jmp	$+2
	and	al,11111000b
	out	35h,al		; RS-232C�̑S���荞�݂��֎~
	popf
	ret
RsDisable ENDP


; void RsEnable(void)
; -------------------
; RS-232C�̑���M���荞�݂�������

RsEnable PROC
	pushf
	cli
	in	al,35h		; �V�X�e���|�[�g��ǂ�
	jmp	$+2
	and	al,11111000b
	or	al,00000101b	; RS-232C�̑���M���荞�݂�����
	out	35h,al
	popf
	ret
RsEnable ENDP


; int SetSpeed(int speed)
; -----------------------
; RS-232C�̒ʐM���x��ݒ肷��
; speed   �ʐM���x 0,  1,   2,   3,   4,    5,    6,    7,    8,     9
;                  75, 150, 300, 600, 1200, 2400, 4800, 9600, 19200, 38400(bps)

SetSpeed PROC speed:WORD
	sub	ax,ax		; �V�X�e�����ʗ̈�̃Z�O�����g�l�F0000h
	mov	es,ax
	mov	al,es:[0501h]	; �V�X�e�����ʗ̈��BIOS-FLAG(�@����)
	mov	cx,2048		; 5MHz�n�̊�ꕪ���l���Z�b�g
	test	al,10000000b	; 5MHz�n��8MHz�n���̃`�F�b�N
	jz	set
	mov	cx,1664		; 8MHz�n�̊�ꕪ���l���Z�b�g
	mov	ax,speed
	cmp	ax,8		; 19200bps�ȏォ
	jae	seterr		; �ݒ�ł��Ȃ��̂ŃG���[�I����
set:
	mov	ax,speed
	cmp	ax,9		; 38400bps���傫����
	ja	seterr		; 38400bps���傫����΃G���[�I����
	xchg	ax,cx
	shr	ax,cl		; �����l���v�Z
	mov	cx,ax		; cx���W�X�^�ɕ����l��ݒ�
;
	pushf
	cli
	mov	al,10110110b	; �^�C�}�̃J�E���^���Q�ւ̕����l�ݒ�̃R�}���h
	out	77h,al          ; ���[�h�w��
	jmp	$+2
	jmp	$+2
	mov	al,cl		; cl�͕����l�̉��ʃo�C�g
	out	75h,al          ; �J�E���^���Q�ɕ����l�̉��ʃo�C�g��ݒ�
	jmp	$+2
	jmp	$+2
	mov	al,ch		; cl�͕����l�̏�ʃo�C�g
	out	75h,al          ; �J�E���^���Q�ɕ����l�̏�ʃo�C�g��ݒ�
	popf
	mov	ax,1		; ����I�����̖߂�l�F1
	jmp	SHORT setend
seterr:
	sub	ax,ax		; �G���[���̖߂�l�F0
setend:
	ret
SetSpeed ENDP


; RsIntrEntry
; -----------
; RS-232C���荞�ݏ���

RsIntrEntry PROC FAR
	push	ax
	in	al,35h		; ����M���荞�݂̃}�X�N��ǂ�
	push	bx
	push	ds
	push	ax
	mov	bx,@data	; �f�[�^�Z�O�����g��ݒ�
	mov	ds,bx
	and	al,11111000b	; ����M���荞�݂��}�X�N
	out	35h,al
	in	al,32h		; 8251�̃X�e�[�^�X���`�F�b�N
	test	al,00000010b	; ��M�f�[�^�����邩
	jz	rsout
;
	in	al,30h		; ��M�f�[�^��ǂݍ���
	cmp	rblen,RBSIZE	; ��M�o�b�t�@�ɓ��邩
	jae	rsout
	mov	bx,rbwrpos
	mov	rbbuf[bx],al	; ��M�f�[�^���o�b�t�@�ɏ�������
	inc	rbwrpos
	inc	rblen
	cmp	bx,RBSIZE
	jb	rsflow
	mov	rbwrpos,0	; �������݈ʒu����M�o�b�t�@�̐擪��
rsflow:
	cmp	rbflow,0	; �t���[��������邩
	jz	rsout
	cmp	rblen,RBXOFF	; XOFF���M���邢��RS=OFF���K�v��
	jb	rsout
	cmp	rbxout,0	; XOFF���M�v����������
	jnz	rsout
	cmp	rbflow,1	; XON/XOFF�t���[���䂩
	jz	flow1
;
	mov	al,siocmd
	and	al,11011111b	; RS=OFF�ɂ���
	out	32h,al
	mov	siocmd,al
	mov	rbxout,2	; RS=OFF���
	jmp	SHORT rsout
flow1:
	mov	rbxout,1	; XOFF���M�v��
	pop	ax
	or	al,00000100b	; RS-232C�̑��M���荞�݂�����
	push	ax
rsout:
	in	al,32h		; 8251�̃X�e�[�^�X���`�F�b�N
	test	al,00000001b	; ���M���\��
	jz	rsend
	test	rbxout,1	; XON���M�v�����邢��XOFF���M�v����
	jz	rsout2
	cmp	rbxout,1	; XON/XOFF���M�v����
	jz	rsxoff
	mov	rbxout,0	; XON���M�ς݂ɂ���
	cmp	rbflow,1	; XON/XOFF�t���[���䂩
	jz	softflow2
;
	mov	al,siocmd
	or	al,00100000b	; RS�M����ON�ɂ���
	out	32h,al
	mov	siocmd,al
	jmp	SHORT rsnext
softflow2:
	mov	al,11h		; XON�𑗐M
	out	30h,al
	jmp	SHORT rsnext
rsxoff:
	cmp	rbflow,1	; XON/XOFF�t���[���䂩
	jz	flow3
	mov	al,siocmd
	and	al,11011111b	; RS�M����OFF�ɂ���
	out	32h,al
	mov	siocmd,al
	jmp	SHORT rsnext
flow3:
	mov	al,13h		; XOFF�𑗐M
	out	30h,al
	mov	rbxout,2	; XOFF���M�ς݂ɂ���
	jmp	SHORT rsnext
rsout2:
	cmp	tblen,0		; ���M�f�[�^�����邩
	jz 	rsmask
	mov	bx,tbrdpos
	mov	al,tbbuf[bx]	; ���M�f�[�^�ǂݏo��
	out	30h,al		; �f�[�^�𑗐M
	inc	tbrdpos
	dec	tblen
	cmp	bx,TBSIZE
	jb	rsnext
	mov	tbrdpos,0	; �ǂݍ��݈ʒu�𑗐M�o�b�t�@�̐擪��
rsnext:
	cmp	tblen,0		; ���M�f�[�^�����邩
	jnz	rsend
rsmask:
	pop	ax
	and	al,11111001b	; RS-232C�̑��M���荞�݂��}�X�N
	push	ax
rsend:
	mov	al,00100000b	; EOI�R�}���h
	out	00h,al		; ���荞�݃R���g���[����EOI���o��
	pop	ax
	out	35h,al		; ����M���荞�݂̃}�X�N��ݒ�
	pop	ds
	pop	bx
	pop	ax
	iret
RsIntrEntry ENDP


; int ReceiveLength(void)
; -----------------------
; ��M�o�b�t�@���̕�������Ԃ�

ReceiveLength PROC
	mov	ax,rblen
	ret
ReceiveLength ENDP


; int ReceiveSpace(void)
; -----------------------
; ��M�o�b�t�@���̋󂫕�������Ԃ�

ReceiveSpace PROC
	mov	ax,RBSIZE
	sub	ax,rblen
	ret
ReceiveSpace ENDP


; int TransLength(void)
; ---------------------
; ���M�o�b�t�@���̕�������Ԃ�

TransLength PROC
	mov	ax,tblen
	ret
TransLength ENDP


; int TransSpace(void)
; ---------------------
; ���M�o�b�t�@���̋󂫕�������Ԃ�

TransSpace PROC
	mov	ax,TBSIZE
	sub	ax,tblen
	ret
TransSpace ENDP


; int ReceiveData(void)
; ----------------------
; ��M�o�b�t�@����P�������擾����

ReceiveData PROC
	pushf
	cli
	mov	ax,-1		; ��M�f�[�^���Ȃ��Ƃ��̖߂�l�F-1
	cmp	rblen,0
	jz	flow_chk1
	mov	bx,rbrdpos	; �ǂݏo���ʒu
	mov	al,rbbuf[bx]	; ��M�f�[�^�ǂݏo��
	sub	ah,ah
	inc	rbrdpos
	dec	rblen
	cmp	bx,RBSIZE	; �o�b�t�@�̏I�[��
	jb	flow_chk1
	mov	rbrdpos,0	; �ǂݍ��݈ʒu����M�o�b�t�@�̐擪��
flow_chk1:
	cmp	rbxout,2	; XOFF���M�ς݂�
	jnz	rdend
	cmp	rblen,RBXON	; XON���M���K�v��
	jae	rdend
	cmp	rbflow,1	; XON/XOFF�t���[���䂩
	jz	flow_chk2
;
	mov	rbxout,0
	mov	al,siocmd
	or	al,00100000b	; RS�M����ON�ɂ���
	out	32h,al
	mov	siocmd,al
	jmp	SHORT rdend
flow_chk2:
	mov	rbxout,3	; XON���M�v��
	push	ax
	mov	al,00000101b	; RS-232C�̑��M���荞�݂�����
	out	37h,al
	pop	ax
rdend:
	popf
	ret
ReceiveData ENDP


; void TransData(int txdata)
; -----------------------
; �P�����𑗐M�o�b�t�@�ɓ���đ��M����

TransData PROC txdata:WORD
	pushf
	cli
	cmp	tblen,TBSIZE	; ���M�o�b�t�@�ɋ󂫂����邩
	jae	txend
	mov	bx,tbwrpos
	mov	ax,txdata
	mov	tbbuf[bx],al	; �f�[�^�𑗐M�o�b�t�@�ɏ�������
	inc	tbwrpos
	inc	tblen
	cmp	bx,TBSIZE	; �o�b�t�@�̏I�[��
	jb	send
	mov	tbwrpos,0	; �������݈ʒu����M�o�b�t�@�̐擪��
send:
	mov	al,00000101b	; RS-232C�̑��M���荞�݂�����
	out	37h,al
txend:
	popf
	ret
TransData ENDP


; void SetErOn(void)
; ------------------
; RS-232C��ER�M����ON�ɂ���

SetErOn	PROC
	pushf
	cli
	mov	al,siocmd
	or	al,00000010b
	out	32h,al
	mov	siocmd,al
	popf
	ret
SetErOn	ENDP


; void SetErOff(void)
; -------------------
; RS-232C��ER�M����OFF�ɂ���

SetErOff PROC
	pushf
	cli
	mov	al,siocmd
	and	al,11111101b
	out	32h,al
	mov	siocmd,al
	popf
	ret
SetErOff ENDP


; void SetRsOn(void)
; ------------------
; RS-232C��RS�M����ON�ɂ���

SetRsOn PROC
	pushf
	cli
	mov	al,siocmd
	or	al,00100000b
	out	32h,al
	mov	siocmd,al
	popf
	ret
SetRsOn ENDP


; void SetRsOff(void)
; -------------------
; RS-232C��RS�M����OFF�ɂ���

SetRsOff PROC
	pushf
	cli
	mov	al,siocmd
	and	al,11011111b
	out	32h,al
	mov	siocmd,al
	popf
	ret
SetRsOff ENDP


; int CheckEr(void)
; ----------------
; RS-232C��ER�M���̏�Ԃ�Ԃ�

CheckEr	PROC
	mov	al,siocmd
	shr	al,1
	not	al
	and	ax,1
	ret
CheckEr	ENDP


; int CheckRs(void)
; ----------------
; RS-232C��RS�M���̏�Ԃ�Ԃ�

CheckRs	PROC
	mov	al,siocmd
	and	al,00100000b
	cmp	al,1
	sbb	ax,ax
	inc	ax
	ret
CheckRs	ENDP


; int CheckCd(void)
; -----------------
; RS-232C��CD�M���̏�Ԃ�Ԃ�

CheckCd	PROC
	in	al,33h
	and	al,00100000b
	cmp	al,1
	sbb	ax,ax
	neg	ax
	ret
CheckCd	ENDP


; int CheckCs(void)
; -----------------
; RS-232C��CS�M���̏�Ԃ�Ԃ�

CheckCs	PROC
	in	al,33h
	rol	al,1
	rol	al,1
	and	ax,1
	ret
CheckCs	ENDP


; int CheckCi(void)
; -----------------
; RS-232C��CI�M���̏�Ԃ�Ԃ�
; ����PC-9801�ł�CI�M���͒��ׂ��Ȃ�

CheckCi	PROC
	in	al,33h
	rol	al,1
	and	ax,1
	ret
CheckCi	ENDP


; int CheckDr(void)
; -----------------
; RS-232C��DR�M���̏�Ԃ�Ԃ�

CheckDr	PROC
	in	al,32h
	rol	al,1
	and	ax,1
	ret
CheckDr	ENDP


; void RsSendBreak(void)
; ----------------------
; ��300�~���b�̃u���[�N�M���𑗐M����

RsSendBreak PROC
	call	RsBreakOn
	mov	cx,45000	; ��300�~���b�̃E�F�C�g
wloop:
	out	5fh,al		; �E�F�C�g�|�[�g
	out	5fh,al
	out	5fh,al
	out	5fh,al
	out	5fh,al
	loop	wloop
	call	RsBreakOff
	ret
RsSendBreak ENDP


; void RsBreakOn(void)
; --------------------
; �u���[�N�M���̑��M���J�n����

RsBreakOn PROC
	pushf
	cli
	mov	al,siocmd
	or	al,00001000b	; BREAK�r�b�g��1�ɂ���
	out	32h,al
	mov	siocmd,al
	popf
	ret
RsBreakOn ENDP


; void RsBreakOff(void)
; ---------------------
; �u���[�N�M���̑��M�𒆎~����

RsBreakOff PROC
	pushf
	cli
	mov	al,siocmd
	and	al,11110111b	; BREAK�r�b�g��0�ɂ���
	out	32h,al
	mov	siocmd,al
	popf
	ret
RsBreakOff ENDP

	END
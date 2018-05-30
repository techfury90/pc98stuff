;=================================================
;	PC9801 Palette Set routine
;		      1991 10/1	ZOBplus	Hayami
;=================================================


		TITLE Palette Set routine

		.MODEL small,C		; �X���[�����f��

		.DATA
		EXTRN	_board16_set:BYTE
		EXTRN	_analog     :BYTE

;---------- �f�W�^���p���b�g�������f�[�^
degital_init	dw	0	;0
		dw	1	;1
		dw	2	;2
		dw	3	;3
		dw	4	;4
		dw	5	;5
		dw	6	;6
		dw	7	;7
;---------- �f�W�^���p���b�g�f�[�^
degital_color	dw	0	;0
		dw	1	;1
		dw	2	;2
		dw	3	;3
		dw	4	;4
		dw	5	;5
		dw	6	;6
		dw	7	;7

;---------- �A�i���O�p���b�g�������f�[�^
analog_init	dw	0000h	;0
		dw	0007h	;1
		dw	0070h	;2
		dw	0077h	;3
		dw	0700h	;4
		dw	0707h	;5
		dw	0770h	;6
		dw	0777h	;7
		dw	0444h	;8
		dw	000Fh	;9
		dw	00F0h	;10
		dw	00FFh	;11
		dw	0F00h	;12
		dw	0F0Fh	;13
		dw	0FF0h	;14
		dw	0FFFh	;15
;---------- �A�i���O�p���b�g�f�[�^
analog_color	dw	0000h	;0
		dw	0007h	;1
		dw	0070h	;2
		dw	0077h	;3
		dw	0700h	;4
		dw	0707h	;5
		dw	0770h	;6
		dw	0777h	;7
		dw	0444h	;8
		dw	000Fh	;9
		dw	00F0h	;10
		dw	00FFh	;11
		dw	0F00h	;12
		dw	0F0Fh	;13
		dw	0FF0h	;14
		dw	0FFFh	;15


		.CODE
		
		EXTRN	VsyncStart : NEAR
		
;----------------------------------------------------------
;  void	PaletteAll(unsigned int* ColorCode)
;  IN  : unsigned int* ColorCode �J���[�R�[�h�̊i�[�A�h���X 
;  RET : Nothing
;----------------------------------------------------------

		PUBLIC	PaletteAll
PaletteAll	PROC ColorCode:PTR 
		cld
		push	si
		push	di
		mov	si,ColorCode
		push	ds
		pop	es
		cmp	[_analog],0		; �A�i���O���[�h���̃`�F�b�N
		jnz	pala_analog
		mov	cx,8
		mov	dx,OFFSET DGROUP:degital_color
		mov	di,dx
	rep	movsw	
		call	PaletteDegital
		jmp	SHORT pala_exit
pala_analog:
		mov	cx,16
		mov	dx,OFFSET DGROUP:analog_color
		mov	di,dx
	rep	movsw	
		call	PaletteAnalog
pala_exit:
		pop	di
		pop	si
		ret
PaletteAll	ENDP		

;----------------------------------------------------------
;  void	Palette(int ColorNo, int ColorCode)
;  IN  : int ColorNo   �F�ԍ�  
;	 int ColorCode �F�R�[�h
;  RET : Nothing
;----------------------------------------------------------

		PUBLIC	Palette
Palette		PROC ColorNo:WORD,ColorCode:WORD 
		mov	ax,ColorNo
		shl	ax,1
		cmp	[_analog],0		; �A�i���O���[�h���̃`�F�b�N
		jnz	pal_analog
		mov	dx,OFFSET DGROUP:degital_color
		mov	bx,dx
		add	bx,ax
		mov	ax,ColorCode
		mov	[bx],ax
		call	PaletteDegital
		jmp	SHORT pal_exit
pal_analog:
		mov	dx,OFFSET DGROUP:analog_color
		mov	bx,dx
		add	bx,ax
		mov	ax,ColorCode
		mov	[bx],ax
		call	PaletteAnalog
pal_exit:
		ret
Palette		ENDP		

;----------------------------------------------------------
;  void	PaletteInit(void)
;  IN  : Nothing
;  RET : Nothing
;----------------------------------------------------------
	
		PUBLIC PaletteInit
PaletteInit	PROC NEAR
		cmp	[_analog],0		; �A�i���O���[�h���̃`�F�b�N
		jnz	palinit_analog
		mov	ax,OFFSET DGROUP:degital_init
		jmp	SHORT palinit_set
palinit_analog:
		mov	ax,OFFSET DGROUP:analog_init
palinit_set:		
		push	ax
		call	PaletteAll
		add	sp,2
		ret
PaletteInit	ENDP		


;---------- �f�W�^���p���b�g�ݒ�
;    IN : DS:DX �F�R�[�h�i�[�A�h���X

PaletteDegital:
		push	si
		mov	si,dx
		pushf
		call	VsyncStart
		mov	cl,4
		call	DPSub
		out	0AEh,al		; #0,#4	�ݒ�
		call	DPSub
		out	0AAh,al		; #1,#5	�ݒ�
		call	DPSub
		out	0ACh,al		; #2,#6	�ݒ�
		call	DPSub
		out	0A8h,al		; #3,#7	�ݒ�
		popf
		pop	si
		ret

;---------- 2�̃J���[�R�[�h��1byte�̃f�[�^�ɕϊ�����
; PaletteDegital����R�[�������T�u���[�`��

DPSub:
		lodsw
		shl	al,cl
		or	al,[si+8-2]
		ret

;---------- �A�i���O�p���b�g�ݒ�
;    IN : DS:DX �F�R�[�h�i�[�A�h���X

PaletteAnalog:
		push	si
		mov	si,dx
		pushf
		call	VsyncStart
		sub	cx,cx		; cx = 0
anapal_loop:
		push	cx
		mov	al,cl
		out	0A8h,al		; �p���b�g���W�X�^No.�ݒ�
		lodsw
		mov	dx,ax
		xchg	ah,al
		out	0AAh,al		; �p���b�gGreen
		and	ah,0F0h
		mov	cl,4
		shr	ah,cl
		xchg	ah,al
		out	0ACh,al		; �p���b�gRed
		mov	ax,dx
		and	ax,0Fh
		out	0AEh,al		; �p���b�gBlue
		pop	cx
		inc	cx
		cmp	cx,8
		jne	anapal_1
		cmp	[_board16_set],0  ; 16�F�{�[�h���݃`�F�b�N
		jnz	anapal_1
		sub	si,16		; 16�F�{�[�h�������Ƃ������f�[�^��
anapal_1:				; �p���b�g���W�X�^8�`15�ɏ�������
		cmp	cx,16
		jb	anapal_loop
		popf
		pop	si
		ret
		
		END
;=================================================
;	PC9801 Graphic Initialize routine
;		      1991 10/1	ZOBplus	Hayami
;=================================================


		TITLE Graphic Initialize

		.MODEL small,C		; �X���[�����f��

		.DATA
;-------------------------------------------------
;	�O���t�B�b�N�֘A�O���[�o���ϐ�
;-------------------------------------------------
		PUBLIC	_gc_set,_egc_set,_board16_set,_gdc_clock
		PUBLIC	_analog,_lines

_gc_set		db	0		; GRCG �O���t�B�b�N�`���[�W���[
					; 0 = ����, 1 =	�L��
_egc_set	db	0		; EGC �G���n���X�gGRCG
					; 0 = ����, 1 =	�L��
_board16_set	db	0		; 16�F�{�[�h
					; 0 = ����, 1 =	�L��
_gdc_clock	db	0		; GDC �N���b�N
					; 0 = 2.5MHz, 1	= 5MHz
_analog		db	0		; �A�i���O�\��
					; 0 = �f�W�^���\��, 1 =	�A�i���O�\��
_lines		db	0		; �c���C����
					; 0 = 200 lines	, 1 = 400 lines

		.CODE
		PUBLIC	GraphicInit
;-----------------------------------------------------
;  �O���t�B�b�N��ʏ�����
;  void	GraphicInit(int Lines, int ColorMode)
;  IN  :int Lines      0 = 200 lines
;		       1 = 400 lines
;	int ColorMode  0 = �f�W�^���\���i8�F�j
;		       1 = �A�i���O�\���i16�F�^4096�j
;  RET : Nothing
;-----------------------------------------------------
GraphicInit	PROC Lines:WORD,ColorMode:WORD
		pushf
		cli			; ���荞�݋֎~
		call	GraphicOFF	; �O���t�B�b�N�\����~
		call	GraphicSystem	; �O���t�B�b�N�V�X�e���`�F�b�N
		mov	ax,Lines
		mov	[_lines],al	; �O���[�o���ϐ��ݒ�
		push	ax
		call	GraphicLineSet
		add	sp,2
		mov	ax,ColorMode	; �f�W�^���A�A�i���O�ݒ�
		mov	[_analog],al	; �O���[�o���ϐ��ݒ�
		push	ax
		call	GraphicColorMode
		add	sp,2
		call	GraphicON	; �O���t�B�b�N�\���J�n
		popf
		ret
GraphicInit		ENDP

;---------- �O���t�B�b�N��ʕ\��ON
GraphicON	PROC
		mov	ah,40h
		int	18h
		ret
GraphicON	ENDP


;---------- �O���t�B�b�N��ʕ\��OFF
GraphicOFF	PROC
		mov	ah,41h
		int	18h
		ret
GraphicOFF	ENDP

;---------- GDC�O���t�B�b�N��ʕ\��ON
GraphicGdcON	PROC
		call	FifoReady		; FIFO FULL?
		mov	al,0Dh			; �\��ON�R�}���h
		out	0A2h,al
		push	es
		mov	ax,0
		mov	es,ax
		mov	al,80h
		or	es:[054Ch],al
		pop	es
		ret
GraphicGdcON	ENDP


;---------- GDC�O���t�B�b�N��ʕ\��OFF
GraphicGdcOFF	PROC
		call	FifoReady		; FIFO FULL?
		mov	al,0Ch			; �\��OFF�R�}���h
		out	0A2H,al
		push	es
		mov	ax,0
		mov	es,ax
		mov	al,7Fh
		and	es:[054Ch],al
		pop	es
		ret
GraphicGdcOFF	ENDP

;---------- GDC	FIFO ���󂭂܂Ń��[�v
FifoReady	PROC
fifo_full:	in	al,0A2h		; GDC�X�e�[�^�X���[�h
		test	al,02h		; FIFO��FULL�H
		jmp	$+2		; �E�F�C�g
		jmp	$+2		; �E�F�C�g
		jne	fifo_full
		ret
FifoReady	ENDP


;---------- �O���t�B�b�N�c���C���ݒ�
;    int Line :	0 = 200lines, 1	= 400lines

GraphicLineSet	PROC Line : WORD
		mov	ax,Line
		cmp	ax,0
		jz	lines200
		cmp	ax,1
		jz	lines400
		jmp	SHORT lines_exit

lines200:
		mov	ch,10000000b		; LOWER	COLOR BANK0
		jmp	SHORT lines_go
lines400:
		mov	ch,11000000b		; ALL	COLOR BANK0
lines_go:
		mov	ah,42h
		int	18h			; Graphic BIOS
lines_exit:
		ret
GraphicLineSet	ENDP


;---------- �f�W�^���^�A�i���O�J���[���[�h�ݒ�
;    int ColorMode : 0 = Degital, 1 = Analog

GraphicColorMode PROC ColorMode : WORD
		mov	ax,ColorMode
		out	06Ah,al
		ret
GraphicColorMode ENDP

;---------------------------------------------------------------
;  VSYNC�̃X�^�[�g���_���`�F�b�N
;  void VsyncStart()
; VYSNC	���������Ă��Ȃ���Ԃ���A�������n�܂������܂Ń��[�v����
;---------------------------------------------------------------

		PUBLIC	VsyncStart
VsyncStart	PROC
vsync_ing:
		jmp	$+2		; �E�F�C�g
		jmp	$+2		; �E�F�C�g
		in	al,0A0h		; GDC�X�e�[�^�X���[�h
		test	al,020h		; VSYNC	Check
		jnz	vsync_ing	; VSYNC���������Ă�����Loop
		pushf
vsync_not:
		cli
		in	al,0A0h		; GDC�X�e�[�^�X���[�h
		test	al,20h		; VSYNC	Check
		jnz	vsync_go
		popf
		pushf
		jmp	vsync_not
vsync_go:
		pop	ax
		ret
VsyncStart	ENDP



;---------- ���������M���iVSYNC�j����������܂Ń��[�v
		PUBLIC	VsyncCheck
VsyncCheck	PROC
not_vsync:	in	al,0A0h		; GDC�X�e�[�^�X���[�h
		test	al,20h		; VSYNC	Check
		jmp	$+2		; �E�F�C�g
		jmp	$+2		; �E�F�C�g
		jz	not_vsync
		ret
VsyncCheck	ENDP

;---------- �O���t�B�b�N�V�X�e���f�[�^�i�[
GraphicSystem	PROC
		sub	ax,ax		; ax = 0
		mov	es,ax		; es = 0
		mov	al,es:[054Ch]	; GRCG �L��
		and	al,02h
		shl	al,1
		mov	[_gc_set],al	; GRCG �O���t�B�b�N�`���[�W���[
					; 0 = ����, 1 =	�L��
		mov	al,es:[054Ch]	; 16�F�{�[�h �L��
		and	al,04h
		mov	cl,2
		shr	al,cl
		mov	[_board16_set],al
		mov	al,es:[054Dh]
		mov	dl,al
		and	al,40h		; EGC �L��
		mov	cl,6
		shr	al,cl
		mov	[_egc_set],al	; EGC �G���n���X�gGRCG
					; 0 = ����, 1 =	�L��
		and	dl,04h
		mov	cl,2
		shr	dl,cl		; GDC�N���b�N�𓾂�
		mov	[_gdc_clock],dl	; GDC �N���b�N
					; 0 = 2.5MHz, 1	= 5MHz
		ret
GraphicSystem	ENDP
		END
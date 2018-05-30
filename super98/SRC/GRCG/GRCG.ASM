;=================================================
;	PC9801 Graphic Charger routine 
;			by ZOBplus Hayami
;			1991 10/25
;=================================================

		TITLE	GRCG
		
		.MODEL	small,C
		
		.186			; GRCG���ڃ}�V���͂��ׂ�186�g������
					; ���g�p�\
		
		.CODE
		PUBLIC GrcgReadSet,GrcgSet
		PUBLIC GrcgReset,GrcgColor	
;-------------------------------------------------
;  �O���t�B�b�N�`���[�W�� TCR TDW ���[�h�ݒ�
;  void GrcgReadSet(void)
;-------------------------------------------------
GrcgReadSet	PROC
		mov	al,080h		; Grcg TCR TDW mode
		jmp	SHORT GrcgMode
GrcgReadSet	ENDP

;-------------------------------------------------
;  �O���t�B�b�N�`���[�W�� RMW ���[�h�ݒ�
;  void GrcgSet(void)
;-------------------------------------------------
GrcgSet	PROC	
		mov	al,0C0h		; Grcg RMW mode
GrcgSet	ENDP

;---------- GRCG Set subroutine
GrcgMode:
		push	es
		push	0
		pop	es
		pushf
		cli
		out	7Ch,al
		mov	es:[0495h],al	; GRCG mode �f�[�^�i�[
		popf
		pop	es
		ret

;-------------------------------------------------
;  �O���t�B�b�N�`���[�W�� ���Z�b�g
;  void GrcgReset(void)
;-------------------------------------------------
GrcgReset	PROC
		mov	al,0		; Grcg mode off
		jmp	SHORT GrcgMode
GrcgReset	ENDP

		
;-------------------------------------------------
; �O���t�B�b�N�`���[�W���^�C�����W�X�^�ݒ�		
;  void GrcgColor(int Color)
;  IN  : int Color �^�C�����W�X�^�ɐݒ肷��F�ԍ�
;-------------------------------------------------

GrcgColor	PROC Color : WORD	; Color = 0�`15
		pushf
		cld
		push	di
		push	es
		mov	di,0496h	; Grcg Tile register �i�[�A�h���X
		sub	ax,ax		; ax = 0
		mov	es,ax		; es = 0
		mov	ax,Color
		pushf
		cli
	REPT 4
		ror	al,1
		cbw			; bit = 1 �̂Ƃ� ah = FFh
		xchg	ah,al		; bit = 0 �̂Ƃ� ah = 0 �ƂȂ�
		out	07Eh,al		; Tile register �Ƀf�[�^�Z�b�g
		stosb			; �V�X�e�����[�N�փf�[�^�i�[
		xchg	ah,al
	ENDM
		popf
		pop	es
		pop	di
		popf
		ret
GrcgColor	ENDP
		
;-----------------------------------------------------
;  �O���t�B�b�N��ʏ���
;  void	GraphicCls(int Color)
;  IN  : int Color ��ʂ���������F�ԍ�
;-----------------------------------------------------
		
		PUBLIC	GraphicCls
GraphicCls	PROC Color : WORD
		push	di
		cld
		call	GrcgReadSet 	; TDW ���[�h�Z�b�g
		mov	ax,Color
		push	ax
		call	GrcgColor
		add	sp,2
		sub	di,di		; di = 0
		mov	ax,0A800h	; Plane 0 �Z�O�����g
		mov	es,ax
		mov	cx,80 * 400 / 2	; Plane 0 VRAM �̃o�C�g�� / 2
	rep	stosw			; cx ���[�h��ʂɏ������� ax�͕s��
		call	GrcgReset	; GRCG ���Z�b�g
		pop	di
		ret
GraphicCls		ENDP

;---------------------------------------------------------
;  �O���t�B�b�N�{�b�N�X�t�B��
;  void GraphicBoxf(int X1,int Y1,int X2,int Y2,int Color)
;  IN  : int X1,Y1 �{�b�N�X����[���W
;        int X2,Y2 �{�b�N�X�E���[���W
;	 int Color �h��ׂ��F�ԍ�
;----------------------------------------------------------
		.DATA
xpats		dw	?			; ���[�r�b�g�f�[�^
xpate		dw	?			; �E�[�r�b�g�f�[�^
lndx		dw	?			; ���o�C�g��
		
		.CODE		
		PUBLIC GraphicBoxf
GraphicBoxf	PROC X1:WORD,Y1:WORD,X2:WORD,Y2:WORD,Color:WORD
		push	di
		cld
		call	GrcgSet		; RMW ���[�h�ݒ�
		mov	ax,Color
		push	ax
		call	GrcgColor		; GRCG �^�C�����W�X�^�ݒ�
		add	sp,2
		mov	bx,X1			; bx = x1
		mov	dx,X2			; dx = x2
		mov	ax,639
		cmp	bx,ax
		jbe	gboxf_1
		mov	bx,ax
gboxf_1:
		cmp	dx,ax
		jbe	gboxf_2
		mov	dx,ax
gboxf_2:
		cmp	bx,dx
		jbe	not_xchg
		xchg	bx,dx			; X1 > X2 �Ȃ�X1,X2�����ւ���
not_xchg:
		mov	cx,bx
		and	cx,00Fh
		mov	ax,0FFFFh
		shr	ax,cl	
		xchg	ah,al
		mov	[xpats],ax		; ���[�̃r�b�g�f�[�^
		mov	cx,dx
		and	cx,000Fh	
		sub	cx,000Fh
		neg	cx
		mov	ax,0FFFFh
		shl	ax,cl
		xchg	ah,al
		mov	[xpate],ax		; �E�[�̃r�b�g�f�[�^
		shr	bx,4			; bx = x1
		mov	di,bx
		shr	dx,4			; dx = x2
		sub	dx,di
		dec	dx
		mov	[lndx],dx
		shl	di,1
		mov	ax,Y1
		mov	cx,Y2
		mov	dx,399
		cmp	ax,dx
		jbe	gboxf_3
		mov	ax,dx
gboxf_3:
		cmp	cx,dx
		jbe	gboxf_4
		mov	cx,dx
gboxf_4:
		cmp	ax,cx
		jbe	not_ychg
		xchg	ax,cx			; Y1 > Y2 �Ȃ�Y1,Y2�����ւ���
not_ychg:
		sub	cx,ax
		inc	cx
		mov	dx,80
		mul	dx
		add	di,ax			; di = �擪VRAM�A�h���X
		call	BoxFill
		call	GrcgReset		; GRCG ���Z�b�g
		pop	di
		ret
GraphicBoxf	ENDP

;---------- �{�b�N�X�t�B���T�u���[�`��
;  IN : di = �擪VRAM �A�h���X, cx = �c���C����

BoxFill		PROC
		mov	ax,0A800h
		mov	es,ax
		mov	ax,[lndx]
		or	ax,ax
		js	boxf_1			; ����1word
		jz	boxf_2			; ����2word
;---------- ����3word�ȏ�
boxf_0:		
		mov	bx,[xpats]	;
		mov	dx,[xpate]
		mov	ax,0FFFFh
boxf_01:		
		push	cx
		push	di
		mov	cx,[lndx]
		mov	es:[di],bx
		add	di,2
	rep	stosw
		mov	es:[di],dx
		pop	di
		add	di,80
		pop	cx
		loop	boxf_01
boxf_exit:		
		ret

;---------- ����1word
boxf_1:
		mov	ax,[xpats]
		and	ax,[xpate]
boxf_11:	mov	es:[di],ax
		add	di,80
		loop	boxf_11
		jmp	boxf_exit	

;---------- ����2word
boxf_2:
		mov	ax,[xpats]
		mov	dx,[xpate]
boxf_21:		
		stosw
		mov	es:[di],dx
		add	di,80 - 2
		loop	boxf_21
		jmp	boxf_exit	
BoxFill		ENDP
		
		END
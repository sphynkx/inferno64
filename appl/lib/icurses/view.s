#0
	load	0(mp),$1,176(mp)
	bnew	176(mp),168(mp),$3
	raise	160(mp)
	load	8(mp),$0,184(mp)
	bnew	184(mp),168(mp),$6
	raise	152(mp)
	mframe	184(mp),$0,64(fp)
	mcall	64(fp),$0,184(mp)
	ret	
	frame	$5,80(fp)
#10
	movp	72(mp),64(80(fp))
	movp	64(fp),72(80(fp))
	movw	72(fp),80(80(fp))
	lea	88(fp),32(80(fp))
	mcall	80(fp),$0,176(mp)
	bnew	184(mp),168(mp),$22
	frame	$2,88(fp)
	movp	80(mp),64(88(fp))
	lea	80(fp),32(88(fp))
	mcall	88(fp),$0,176(mp)
#20
	movw	$-1,0(32(fp))
	ret	
	frame	$2,88(fp)
	movp	88(mp),64(88(fp))
	lea	80(fp),32(88(fp))
	mcall	88(fp),$0,176(mp)
	mframe	184(mp),$1,80(fp)
	movp	64(fp),64(80(fp))
	movw	72(fp),72(80(fp))
	lea	96(fp),32(80(fp))
#30
	mcall	80(fp),$1,184(mp)
	frame	$3,88(fp)
	movp	96(mp),64(88(fp))
	movw	96(fp),72(88(fp))
	lea	80(fp),32(88(fp))
	mcall	88(fp),$0,176(mp)
	movw	96(fp),0(32(fp))
	ret	
	frame	$5,80(fp)
	movp	104(mp),64(80(fp))
#40
	movp	64(fp),72(80(fp))
	movw	72(fp),80(80(fp))
	lea	88(fp),32(80(fp))
	mcall	80(fp),$0,176(mp)
	bnew	184(mp),168(mp),$51
	frame	$2,88(fp)
	movp	112(mp),64(88(fp))
	lea	80(fp),32(88(fp))
	mcall	88(fp),$0,176(mp)
	movp	168(mp),0(32(fp))
#50
	ret	
	frame	$2,88(fp)
	movp	120(mp),64(88(fp))
	lea	80(fp),32(88(fp))
	mcall	88(fp),$0,176(mp)
	mframe	184(mp),$2,80(fp)
	movp	64(fp),64(80(fp))
	movw	72(fp),72(80(fp))
	lea	96(fp),32(80(fp))
	mcall	80(fp),$2,184(mp)
#60
	frame	$2,88(fp)
	movp	128(mp),64(88(fp))
	lea	80(fp),32(88(fp))
	mcall	88(fp),$0,176(mp)
	bnew	168(mp),96(fp),$71
	frame	$2,88(fp)
	movp	136(mp),64(88(fp))
	lea	80(fp),32(88(fp))
	mcall	88(fp),$0,176(mp)
	movp	168(mp),0(32(fp))
#70
	ret	
	frame	$3,88(fp)
	movp	144(mp),64(88(fp))
	lena	96(fp),72(88(fp))
	lea	80(fp),32(88(fp))
	mcall	88(fp),$0,176(mp)
	movp	96(fp),0(32(fp))
	ret	
	frame	$3,72(fp)
	movp	16(mp),64(72(fp))
#80
	movw	64(fp),72(72(fp))
	lea	80(fp),32(72(fp))
	mcall	72(fp),$0,176(mp)
	bnew	184(mp),168(mp),$90
	frame	$2,80(fp)
	movp	24(mp),64(80(fp))
	lea	72(fp),32(80(fp))
	mcall	80(fp),$0,176(mp)
	movp	168(mp),0(32(fp))
	ret	
#90
	frame	$2,80(fp)
	movp	32(mp),64(80(fp))
	lea	72(fp),32(80(fp))
	mcall	80(fp),$0,176(mp)
	mframe	184(mp),$3,72(fp)
	movw	64(fp),64(72(fp))
	lea	88(fp),32(72(fp))
	mcall	72(fp),$3,184(mp)
	frame	$2,80(fp)
	movp	40(mp),64(80(fp))
#100
	lea	72(fp),32(80(fp))
	mcall	80(fp),$0,176(mp)
	bnew	168(mp),88(fp),$109
	frame	$2,80(fp)
	movp	48(mp),64(80(fp))
	lea	72(fp),32(80(fp))
	mcall	80(fp),$0,176(mp)
	movp	168(mp),0(32(fp))
	ret	
	frame	$3,80(fp)
#110
	movp	56(mp),64(80(fp))
	lena	88(fp),72(80(fp))
	lea	72(fp),32(80(fp))
	mcall	80(fp),$0,176(mp)
	movw	$0,96(fp)
	lena	88(fp),72(fp)
	blew	72(fp),96(fp),$126
	frame	$4,80(fp)
	movp	64(mp),64(80(fp))
	movw	96(fp),72(80(fp))
#120
	indl	88(fp),104(fp),96(fp)
	movw	0(104(fp)),80(80(fp))
	lea	72(fp),32(80(fp))
	mcall	80(fp),$0,176(mp)
	addw	$1,96(fp)
	jmp	$115
	movp	88(fp),0(32(fp))
	ret	
	entry	0, 1
	desc	$0,192,"ffffff"
	desc	$1,72,""
	desc	$2,72,"0080"
	desc	$3,80,"0080"
	desc	$4,88,"0080"
	desc	$5,88,"00c0"
	desc	$6,104,"0080"
	desc	$7,104,"0088"
	desc	$8,112,"0010"
	var	@mp,192
	string	@mp+0,"$Sys"
	string	@mp+8,"/dis/lib/icurses/text.dis"
	string	@mp+16,"CN0 enter n=%d\n"
	string	@mp+24,"CN0a text=nil\n"
	string	@mp+32,"CN1 before wrapnums\n"
	string	@mp+40,"CN2 after wrapnums\n"
	string	@mp+48,"CN2a a=nil\n"
	string	@mp+56,"CN3 len=%d\n"
	string	@mp+64,"CN4 a[%d]=%d\n"
	string	@mp+72,"CVS0 enter s=\"%s\" width=%d\n"
	string	@mp+80,"CVS0a text=nil\n"
	string	@mp+88,"CVS1 before strlen2\n"
	string	@mp+96,"CVS2 after strlen2 n=%d\n"
	string	@mp+104,"CW0 enter s=\"%s\" width=%d\n"
	string	@mp+112,"CW0a text=nil\n"
	string	@mp+120,"CW1 before wrapline\n"
	string	@mp+128,"CW2 after wrapline\n"
	string	@mp+136,"CW2a a=nil\n"
	string	@mp+144,"CW3 len=%d\n"
	string	@mp+152,"fail:load ictext"
	string	@mp+160,"fail:load sys"
	module	IcView
	link	6,9,0xbb323c87,"callstrlen2"
	link	7,38,0xcf6808d5,"callwrap"
	link	8,78,0xdea472a8,"callwrapnums"
	link	1,0,0x9cd71c5e,"init"
	ldts	@ldt,2
	word	@ldt+0,4
	ext	@ldt+8,0x9cd71c5e,"init"
	ext	@ldt+24,0xbb323c87,"strlen2"
	ext	@ldt+40,0xcf6808d5,"wrapline"
	ext	@ldt+64,0xdea472a8,"wrapnums"
	word	@ldt+1,1
	ext	@ldt+16,0xac849033,"print"
	source	"/appl/lib/icurses/view.b"

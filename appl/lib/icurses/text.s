#0
	load	0(mp),$0,168(mp)
	bnew	168(mp),160(mp),$3
	raise	152(mp)
	ret	
	frame	$4,80(fp)
	movp	8(mp),64(80(fp))
	lea	88(fp),32(80(fp))
	mcall	80(fp),$0,168(mp)
	frame	$5,88(fp)
	movp	16(mp),64(88(fp))
#10
	movw	72(fp),72(88(fp))
	lea	80(fp),32(88(fp))
	mcall	88(fp),$0,168(mp)
	frame	$4,88(fp)
	movp	24(mp),64(88(fp))
	lea	80(fp),32(88(fp))
	mcall	88(fp),$0,168(mp)
	lenc	64(fp),96(fp)
	frame	$5,88(fp)
	movp	32(mp),64(88(fp))
#20
	movw	96(fp),72(88(fp))
	lea	80(fp),32(88(fp))
	mcall	88(fp),$0,168(mp)
	addw	72(fp),96(fp),80(fp)
	subw	72(fp),80(fp),0(32(fp))
	ret	
	frame	$4,80(fp)
	movp	40(mp),64(80(fp))
	lea	88(fp),32(80(fp))
	mcall	80(fp),$0,168(mp)
#30
	frame	$5,88(fp)
	movp	48(mp),64(88(fp))
	movw	72(fp),72(88(fp))
	lea	80(fp),32(88(fp))
	mcall	88(fp),$0,168(mp)
	frame	$4,88(fp)
	movp	56(mp),64(88(fp))
	lea	80(fp),32(88(fp))
	mcall	88(fp),$0,168(mp)
	bltw	$0,72(fp),$41
#40
	movw	$1,72(fp)
	frame	$5,88(fp)
	movp	64(mp),64(88(fp))
	movw	72(fp),72(88(fp))
	lea	80(fp),32(88(fp))
	mcall	88(fp),$0,168(mp)
	frame	$4,88(fp)
	movp	72(mp),64(88(fp))
	lea	80(fp),32(88(fp))
	mcall	88(fp),$0,168(mp)
#50
	lenc	64(fp),96(fp)
	frame	$5,88(fp)
	movp	80(mp),64(88(fp))
	movw	96(fp),72(88(fp))
	lea	80(fp),32(88(fp))
	mcall	88(fp),$0,168(mp)
	bnew	$0,96(fp),$65
	frame	$4,88(fp)
	movp	88(mp),64(88(fp))
	lea	80(fp),32(88(fp))
#60
	mcall	88(fp),$0,168(mp)
	newa	$1,$2,0(32(fp))
	indl	0(32(fp)),80(fp),$0
	movp	160(mp),0(80(fp))
	ret	
	frame	$4,88(fp)
	movp	96(mp),64(88(fp))
	lea	80(fp),32(88(fp))
	mcall	88(fp),$0,168(mp)
	addw	72(fp),96(fp),80(fp)
#70
	subw	$1,80(fp)
	divw	72(fp),80(fp),136(fp)
	frame	$5,88(fp)
	movp	104(mp),64(88(fp))
	movw	136(fp),72(88(fp))
	lea	80(fp),32(88(fp))
	mcall	88(fp),$0,168(mp)
	frame	$4,88(fp)
	movp	112(mp),64(88(fp))
	lea	80(fp),32(88(fp))
#80
	mcall	88(fp),$0,168(mp)
	newa	136(fp),$2,128(fp)
	frame	$4,88(fp)
	movp	120(mp),64(88(fp))
	lea	80(fp),32(88(fp))
	mcall	88(fp),$0,168(mp)
	movw	$0,120(fp)
	movw	$0,112(fp)
	bgew	120(fp),96(fp),$112
	addw	72(fp),120(fp),104(fp)
#90
	blew	104(fp),96(fp),$92
	movw	96(fp),104(fp)
	frame	$8,88(fp)
	movp	128(mp),64(88(fp))
	movw	120(fp),72(88(fp))
	movw	104(fp),80(88(fp))
	movw	112(fp),88(88(fp))
	lea	80(fp),32(88(fp))
	mcall	88(fp),$0,168(mp)
	indl	128(fp),80(fp),112(fp)
#100
	movp	64(fp),0(80(fp))
	slicec	120(fp),104(fp),0(80(fp))
	frame	$7,88(fp)
	movp	136(mp),64(88(fp))
	movw	112(fp),72(88(fp))
	indl	128(fp),144(fp),112(fp)
	movp	0(144(fp)),80(88(fp))
	lea	80(fp),32(88(fp))
	mcall	88(fp),$0,168(mp)
	addw	$1,112(fp)
#110
	movw	104(fp),120(fp)
	jmp	$88
	frame	$5,80(fp)
	movp	144(mp),64(80(fp))
	lena	128(fp),72(80(fp))
	lea	144(fp),32(80(fp))
	mcall	80(fp),$0,168(mp)
	movp	128(fp),0(32(fp))
	ret	
	blew	$0,64(fp),$121
#120
	movw	$0,64(fp)
	newa	$3,$1,72(fp)
	indl	72(fp),80(fp),$0
	movw	64(fp),0(80(fp))
	indl	72(fp),80(fp),$1
	addw	$1,64(fp),0(80(fp))
	indl	72(fp),80(fp),$2
	addw	$2,64(fp),0(80(fp))
	movp	72(fp),0(32(fp))
	ret	
	entry	0, 3
	desc	$0,176,"fffffc"
	desc	$1,8,""
	desc	$2,8,"80"
	desc	$3,72,""
	desc	$4,72,"0080"
	desc	$5,80,"0080"
	desc	$6,88,"0040"
	desc	$7,88,"00a0"
	desc	$8,96,"0080"
	desc	$9,104,"0080"
	desc	$10,152,"008080"
	var	@mp,176
	string	@mp+0,"$Sys"
	string	@mp+8,"TS0 enter\n"
	string	@mp+16,"TS1 width=%d\n"
	string	@mp+24,"TS2 before len\n"
	string	@mp+32,"TS3 len=%d\n"
	string	@mp+40,"TW0 enter\n"
	string	@mp+48,"TW0a width=%d\n"
	string	@mp+56,"TW0b before width check\n"
	string	@mp+64,"TW0c after width check width=%d\n"
	string	@mp+72,"TW1 before len s\n"
	string	@mp+80,"TW1a len s=%d\n"
	string	@mp+88,"TW1b empty string\n"
	string	@mp+96,"TW2 before n calc\n"
	string	@mp+104,"TW2a n=%d\n"
	string	@mp+112,"TW3 before alloc\n"
	string	@mp+120,"TW3a after alloc\n"
	string	@mp+128,"TW4 start=%d i=%d k=%d\n"
	string	@mp+136,"TW5 lines[%d]=\"%s\"\n"
	string	@mp+144,"TW6 return len=%d\n"
	string	@mp+152,"fail:load sys"
	module	IcText
	link	3,0,0x9cd71c5e,"init"
	link	9,4,0xbb323c87,"strlen2"
	link	10,26,0xcf6808d5,"wrapline"
	link	6,119,0xdea472a8,"wrapnums"
	ldts	@ldt,1
	word	@ldt+0,1
	ext	@ldt+8,0xac849033,"print"
	source	"/appl/lib/icurses/text.b"

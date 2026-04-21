#0
	load	0(mp),$0,168(mp)	#text.b:10.1,text.b:10.25
	bnew	168(mp),160(mp),$3	#text.b:11.4,text.b:11.14
	raise	152(mp)	#text.b:12.2,text.b:12.23
	ret		#text.b:13.0,text.b:13.1
	frame	$4,80(fp)	#Sys->print	#text.b:19.1,text.b:19.26
	movp	8(mp),64(80(fp))	#text.b:19.12,text.b:19.25
	lea	88(fp),32(80(fp))	#text.b:19.1,text.b:19.26
	mcall	80(fp),$0,168(mp)	#text.b:19.1,text.b:19.26
	frame	$5,88(fp)	#Sys->print	#text.b:20.1,text.b:20.36
	movp	16(mp),64(88(fp))	#text.b:20.12,text.b:20.28
#10
	movw	72(fp),72(88(fp))	#text.b:20.30,text.b:20.35
	lea	80(fp),32(88(fp))	#text.b:20.1,text.b:20.36
	mcall	88(fp),$0,168(mp)	#text.b:20.1,text.b:20.36
	frame	$4,88(fp)	#Sys->print	#text.b:21.1,text.b:21.31
	movp	24(mp),64(88(fp))	#text.b:21.12,text.b:21.30
	lea	80(fp),32(88(fp))	#text.b:21.1,text.b:21.31
	mcall	88(fp),$0,168(mp)	#text.b:21.1,text.b:21.31
	lenc	64(fp),96(fp)	#text.b:22.1,text.b:22.10
	frame	$5,88(fp)	#Sys->print	#text.b:23.1,text.b:23.30
	movp	32(mp),64(88(fp))	#text.b:23.12,text.b:23.26
#20
	movw	96(fp),72(88(fp))	#text.b:23.28,text.b:23.29
	lea	80(fp),32(88(fp))	#text.b:23.1,text.b:23.30
	mcall	88(fp),$0,168(mp)	#text.b:23.1,text.b:23.30
	addw	72(fp),96(fp),80(fp)	#text.b:25.8,text.b:25.17
	subw	72(fp),80(fp),0(32(fp))	#text.b:25.8,text.b:25.25
	ret		#text.b:25.1,text.b:25.25
	frame	$4,80(fp)	#Sys->print	#text.b:34.1,text.b:34.26
	movp	40(mp),64(80(fp))	#text.b:34.12,text.b:34.25
	lea	88(fp),32(80(fp))	#text.b:34.1,text.b:34.26
	mcall	80(fp),$0,168(mp)	#text.b:34.1,text.b:34.26
#30
	frame	$5,88(fp)	#Sys->print	#text.b:35.1,text.b:35.37
	movp	48(mp),64(88(fp))	#text.b:35.12,text.b:35.29
	movw	72(fp),72(88(fp))	#text.b:35.31,text.b:35.36
	lea	80(fp),32(88(fp))	#text.b:35.1,text.b:35.37
	mcall	88(fp),$0,168(mp)	#text.b:35.1,text.b:35.37
	frame	$4,88(fp)	#Sys->print	#text.b:37.1,text.b:37.40
	movp	56(mp),64(88(fp))	#text.b:37.12,text.b:37.39
	lea	80(fp),32(88(fp))	#text.b:37.1,text.b:37.40
	mcall	88(fp),$0,168(mp)	#text.b:37.1,text.b:37.40
	bltw	$0,72(fp),$41	#text.b:38.4,text.b:38.14
#40
	movw	$1,72(fp)	#text.b:39.2,text.b:39.11
	frame	$5,88(fp)	#Sys->print	#text.b:40.1,text.b:40.55
	movp	64(mp),64(88(fp))	#text.b:40.12,text.b:40.47
	movw	72(fp),72(88(fp))	#text.b:40.49,text.b:40.54
	lea	80(fp),32(88(fp))	#text.b:40.1,text.b:40.55
	mcall	88(fp),$0,168(mp)	#text.b:40.1,text.b:40.55
	frame	$4,88(fp)	#Sys->print	#text.b:42.1,text.b:42.33
	movp	72(mp),64(88(fp))	#text.b:42.12,text.b:42.32
	lea	80(fp),32(88(fp))	#text.b:42.1,text.b:42.33
	mcall	88(fp),$0,168(mp)	#text.b:42.1,text.b:42.33
#50
	lenc	64(fp),96(fp)	#text.b:43.1,text.b:43.11
	frame	$5,88(fp)	#Sys->print	#text.b:44.1,text.b:44.34
	movp	80(mp),64(88(fp))	#text.b:44.12,text.b:44.29
	movw	96(fp),72(88(fp))	#text.b:44.31,text.b:44.33
	lea	80(fp),32(88(fp))	#text.b:44.1,text.b:44.34
	mcall	88(fp),$0,168(mp)	#text.b:44.1,text.b:44.34
	bnew	$0,96(fp),$65	#text.b:46.4,text.b:46.11
	frame	$4,88(fp)	#Sys->print	#text.b:47.2,text.b:47.35
	movp	88(mp),64(88(fp))	#text.b:47.13,text.b:47.34
	lea	80(fp),32(88(fp))	#text.b:47.2,text.b:47.35
#60
	mcall	88(fp),$0,168(mp)	#text.b:47.2,text.b:47.35
	newa	$1,$2,0(32(fp))	#text.b:48.9,text.b:48.26
	indl	0(32(fp)),80(fp),$0	#text.b:48.22,text.b:48.24
	movp	160(mp),0(80(fp))	#text.b:48.22,text.b:48.24
	ret		#text.b:48.2,text.b:48.26
	frame	$4,88(fp)	#Sys->print	#text.b:51.1,text.b:51.34
	movp	96(mp),64(88(fp))	#text.b:51.12,text.b:51.33
	lea	80(fp),32(88(fp))	#text.b:51.1,text.b:51.34
	mcall	88(fp),$0,168(mp)	#text.b:51.1,text.b:51.34
	addw	72(fp),96(fp),80(fp)	#text.b:52.6,text.b:52.16
#70
	subw	$1,80(fp)	#text.b:52.5,text.b:52.21
	divw	72(fp),80(fp),136(fp)	#text.b:52.1,text.b:52.29
	frame	$5,88(fp)	#Sys->print	#text.b:53.1,text.b:53.29
	movp	104(mp),64(88(fp))	#text.b:53.12,text.b:53.25
	movw	136(fp),72(88(fp))	#text.b:53.27,text.b:53.28
	lea	80(fp),32(88(fp))	#text.b:53.1,text.b:53.29
	mcall	88(fp),$0,168(mp)	#text.b:53.1,text.b:53.29
	frame	$4,88(fp)	#Sys->print	#text.b:55.1,text.b:55.33
	movp	112(mp),64(88(fp))	#text.b:55.12,text.b:55.32
	lea	80(fp),32(88(fp))	#text.b:55.1,text.b:55.33
#80
	mcall	88(fp),$0,168(mp)	#text.b:55.1,text.b:55.33
	newa	136(fp),$2,128(fp)	#text.b:56.1,text.b:56.27
	frame	$4,88(fp)	#Sys->print	#text.b:57.1,text.b:57.33
	movp	120(mp),64(88(fp))	#text.b:57.12,text.b:57.32
	lea	80(fp),32(88(fp))	#text.b:57.1,text.b:57.33
	mcall	88(fp),$0,168(mp)	#text.b:57.1,text.b:57.33
	movw	$0,120(fp)	#text.b:59.1,text.b:59.10
	movw	$0,112(fp)	#text.b:60.1,text.b:60.6
	bgew	120(fp),96(fp),$112	#text.b:61.7,text.b:61.17
	addw	72(fp),120(fp),104(fp)	#text.b:62.2,text.b:62.19
#90
	blew	104(fp),96(fp),$92	#text.b:63.5,text.b:63.11
	movw	96(fp),104(fp)	#text.b:64.3,text.b:64.9
	frame	$8,88(fp)	#Sys->print	#text.b:65.2,text.b:65.53
	movp	128(mp),64(88(fp))	#text.b:65.13,text.b:65.39
	movw	120(fp),72(88(fp))	#text.b:65.41,text.b:65.46
	movw	104(fp),80(88(fp))	#text.b:65.48,text.b:65.49
	movw	112(fp),88(88(fp))	#text.b:65.51,text.b:65.52
	lea	80(fp),32(88(fp))	#text.b:65.2,text.b:65.53
	mcall	88(fp),$0,168(mp)	#text.b:65.2,text.b:65.53
	indl	128(fp),80(fp),112(fp)	#text.b:66.2,text.b:66.10
#100
	movp	64(fp),0(80(fp))	#text.b:66.13,text.b:66.14
	slicec	120(fp),104(fp),0(80(fp))	#text.b:66.2,text.b:66.23
	frame	$7,88(fp)	#Sys->print	#text.b:67.2,text.b:67.51
	movp	136(mp),64(88(fp))	#text.b:67.13,text.b:67.37
	movw	112(fp),72(88(fp))	#text.b:67.39,text.b:67.40
	indl	128(fp),144(fp),112(fp)	#text.b:67.42,text.b:67.50
	movp	0(144(fp)),80(88(fp))	#text.b:67.42,text.b:67.50
	lea	80(fp),32(88(fp))	#text.b:67.2,text.b:67.51
	mcall	88(fp),$0,168(mp)	#text.b:67.2,text.b:67.51
	addw	$1,112(fp)	#text.b:68.2,text.b:68.5
#110
	movw	104(fp),120(fp)	#text.b:69.2,text.b:69.11
	jmp	$88	#text.b:69.2,text.b:69.11
	frame	$5,80(fp)	#Sys->print	#text.b:72.1,text.b:72.45
	movp	144(mp),64(80(fp))	#text.b:72.12,text.b:72.33
	lena	128(fp),72(80(fp))	#text.b:72.35,text.b:72.44
	lea	144(fp),32(80(fp))	#text.b:72.1,text.b:72.45
	mcall	80(fp),$0,168(mp)	#text.b:72.1,text.b:72.45
	movp	128(fp),0(32(fp))	#text.b:73.8,text.b:73.13
	ret		#text.b:73.1,text.b:73.13
	blew	$0,64(fp),$121	#text.b:95.4,text.b:95.9
#120
	movw	$0,64(fp)	#text.b:96.2,text.b:96.7
	newa	$3,$1,72(fp)	#text.b:98.1,text.b:98.20
	indl	72(fp),80(fp),$0	#text.b:99.1,text.b:99.5
	movw	64(fp),0(80(fp))	#text.b:99.1,text.b:99.9
	indl	72(fp),80(fp),$1	#text.b:100.1,text.b:100.5
	addw	$1,64(fp),0(80(fp))	#text.b:100.1,text.b:100.13
	indl	72(fp),80(fp),$2	#text.b:101.1,text.b:101.5
	addw	$2,64(fp),0(80(fp))	#text.b:101.1,text.b:101.13
	movp	72(fp),0(32(fp))	#text.b:103.8,text.b:103.9
	ret		#text.b:103.1,text.b:103.9
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

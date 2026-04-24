implement IcText;

include "sys.m";
include "icurses/text.m";

sys: Sys;

init()
{
	sys = load Sys Sys->PATH;
	if(sys == nil)
		raise "fail:load sys";
}

strlen2(s: string, width: int): int
{
	n: int;

	sys->print("TS0 enter\n");
	sys->print("TS1 width=%d\n", width);
	sys->print("TS2 before len\n");
	n = len s;
	sys->print("TS3 len=%d\n", n);

	return n + width - width;
}

wrapline(s: string, width: int): array of string
{
	n, i, start, k: int;
	lines: array of string;
	ls: int;

	sys->print("TW0 enter\n");
	sys->print("TW0a width=%d\n", width);

	sys->print("TW0b before width check\n");
	if(width <= 0)
		width = 1;
	sys->print("TW0c after width check width=%d\n", width);

	sys->print("TW1 before len s\n");
	ls = len s;
	sys->print("TW1a len s=%d\n", ls);

	if(ls == 0){
		sys->print("TW1b empty string\n");
		return array[] of { "" };
	}

	sys->print("TW2 before n calc\n");
	n = (ls + width - 1) / width;
	sys->print("TW2a n=%d\n", n);

	sys->print("TW3 before alloc\n");
	lines = array[n] of string;
	sys->print("TW3a after alloc\n");

	start = 0;
	k = 0;
	while(start < ls){
		i = start + width;
		if(i > ls)
			i = ls;
		sys->print("TW4 start=%d i=%d k=%d\n", start, i, k);
		lines[k] = s[start:i];
		sys->print("TW5 lines[%d]=\"%s\"\n", k, lines[k]);
		k++;
		start = i;
	}

	sys->print("TW6 return len=%d\n", len lines);
	return lines;
}

wrapnums_ISX(n: int): array of int
{
	a: array of int;

	if(n < 0)
		n = 0;

	a = array[3] of int;
	a[0] = n;
	a[1] = n + 1;
	a[2] = n + 2;

	return a;
}

wrapnums(n: int): array of int
{
	a: array of int;

	if(n < 0)
		n = 0;

	a = array[3] of int;
	a[0] = n;
	a[1] = n + 1;
	a[2] = n + 2;

	return a;
}

implement IcView;

include "sys.m";
include "icurses/view.m";

sys: Sys;
text: IcText;

init()
{
	sys = load Sys Sys->PATH;
	if(sys == nil)
		raise "fail:load sys";

	text = load IcText IcText->PATH;
	if(text == nil)
		raise "fail:load ictext";

	text->init();
}

callstrlen2(s: string, width: int): int
{
	n: int;

	sys->print("CVS0 enter s=\"%s\" width=%d\n", s, width);

	if(text == nil){
		sys->print("CVS0a text=nil\n");
		return -1;
	}

	sys->print("CVS1 before strlen2\n");
	n = text->strlen2(s, width);
	sys->print("CVS2 after strlen2 n=%d\n", n);

	return n;
}

callwrap(s: string, width: int): array of string
{
	a: array of string;

	sys->print("CW0 enter s=\"%s\" width=%d\n", s, width);

	if(text == nil){
		sys->print("CW0a text=nil\n");
		return nil;
	}

	sys->print("CW1 before wrapline\n");
	a = text->wrapline(s, width);
	sys->print("CW2 after wrapline\n");

	if(a == nil){
		sys->print("CW2a a=nil\n");
		return nil;
	}

	sys->print("CW3 len=%d\n", len a);
	return a;
}

callwrapnums(n: int): array of int
{
	a: array of int;
	i: int;

	sys->print("CN0 enter n=%d\n", n);

	if(text == nil){
		sys->print("CN0a text=nil\n");
		return nil;
	}

	sys->print("CN1 before wrapnums\n");
	a = text->wrapnums(n);
	sys->print("CN2 after wrapnums\n");

	if(a == nil){
		sys->print("CN2a a=nil\n");
		return nil;
	}

	sys->print("CN3 len=%d\n", len a);
	for(i = 0; i < len a; i++)
		sys->print("CN4 a[%d]=%d\n", i, a[i]);

	return a;
}

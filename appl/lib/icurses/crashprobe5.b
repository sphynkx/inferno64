implement Wrapcallsmoke;

include "sys.m";
include "draw.m";
include "icurses/view.m";

Wrapcallsmoke: module
{
	init: fn(nil: ref Draw->Context, nil: list of string);
};

sys: Sys;

showlines(tag: string, a: array of string)
{
	i: int;

	if(a == nil){
		sys->print("%s: nil\n", tag);
		return;
	}

	sys->print("%s: len=%d\n", tag, len a);
	for(i = 0; i < len a; i++)
		sys->print("%s[%d]=\"%s\"\n", tag, i, a[i]);
}

showints(tag: string, a: array of int)
{
	i: int;

	if(a == nil){
		sys->print("%s: nil\n", tag);
		return;
	}

	sys->print("%s: len=%d\n", tag, len a);
	for(i = 0; i < len a; i++)
		sys->print("%s[%d]=%d\n", tag, i, a[i]);
}

init(nil: ref Draw->Context, nil: list of string)
{
	view: IcView;
	n: int;
	a: array of string;
	ai: array of int;

	sys = load Sys Sys->PATH;
	if(sys == nil)
		raise "fail:load sys";

	sys->print("S0 load view\n");
	view = load IcView IcView->PATH;
	if(view == nil)
		raise "fail:load view";

	sys->print("S1 init\n");
	view->init();

	sys->print("S2 callstrlen2\n");
	n = view->callstrlen2("abcdefghij", 4);
	sys->print("S3 callstrlen2 returned n=%d\n", n);

	sys->print("S4 callwrapnums\n");
	ai = view->callwrapnums(10);
	showints("nums", ai);

	sys->print("S5 callwrap\n");
	a = view->callwrap("abcdefghij", 4);
	showlines("indirect", a);

	sys->print("S6 ok\n");
}

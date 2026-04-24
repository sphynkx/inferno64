implement Icursesreboot12b;

include "draw.m";
include "icurses/icurses.m";
include "icurses/theme.m";

Icursesreboot12b: module
{
	init: fn(nil: ref Draw->Context, nil: list of string);
};

sys: Sys;

Bcancel, Bok, Breboot: con iota;

drawtext: fn(icur: Icurses, theme: IcTheme, out: ref Sys->FD, row, col, attr: int, s: string);
drawbox: fn(icur: Icurses, theme: IcTheme, out: ref Sys->FD, x, y, w, h: int);
drawbuttons: fn(icur: Icurses, theme: IcTheme, out: ref Sys->FD, focus: int);
drawui: fn(icur: Icurses, theme: IcTheme, out: ref Sys->FD, focus: int, status: string);
focusprev: fn(f: int): int;
focusnext: fn(f: int): int;
focusname: fn(f: int): string;
cleanup: fn(icur: Icurses, out: ref Sys->FD);

drawtext(icur: Icurses, theme: IcTheme, out: ref Sys->FD, row, col, attr: int, s: string)
{
	icur->emitrun(out, row, col, theme->sgr(0, attr), s);
}

drawbox(icur: Icurses, theme: IcTheme, out: ref Sys->FD, x, y, w, h: int)
{
	i, inner: int;
	line: string;

	inner = w - 2;
	line = "";
	for(i = 0; i < inner; i++)
		line += " ";

	drawtext(icur, theme, out, y, x, IcTheme->AttrButton, "+" + line + "+");
	for(i = 1; i < h-1; i++)
		drawtext(icur, theme, out, y+i, x, IcTheme->AttrButton, "|" + line + "|");
	drawtext(icur, theme, out, y+h-1, x, IcTheme->AttrButton, "+" + line + "+");
}

drawbuttons(icur: Icurses, theme: IcTheme, out: ref Sys->FD, focus: int)
{
	attr: int;

	attr = IcTheme->AttrButton;
	if(focus == Bok)
		attr = IcTheme->AttrFocus;
	drawtext(icur, theme, out, 11, 22, attr, "[  OK  ]");

	attr = IcTheme->AttrButton;
	if(focus == Breboot)
		attr = IcTheme->AttrFocus;
	drawtext(icur, theme, out, 11, 33, attr, "[ Reboot ]");

	attr = IcTheme->AttrButton;
	if(focus == Bcancel)
		attr = IcTheme->AttrFocus;
	drawtext(icur, theme, out, 11, 46, attr, "[Cancel]");
}

drawui(icur: Icurses, theme: IcTheme, out: ref Sys->FD, focus: int, status: string)
{
	icur->cleartty(out);

	drawbox(icur, theme, out, 8, 2, 58, 12);

	drawtext(icur, theme, out, 3, 11, IcTheme->AttrButton, "icurses-reboot-12b");
	drawtext(icur, theme, out, 5, 12, IcTheme->AttrLabel,
		"Minimal interactive dialog smoke test.");
	drawtext(icur, theme, out, 6, 12, IcTheme->AttrLabel,
		"Tab/arrows move focus.");
	drawtext(icur, theme, out, 7, 12, IcTheme->AttrLabel,
		"Enter confirms, Esc/q/c cancel.");

	drawbuttons(icur, theme, out, focus);

	drawtext(icur, theme, out, 14, 1, IcTheme->AttrStatus,
		"                                                                                ");
	drawtext(icur, theme, out, 14, 1, IcTheme->AttrStatus, status);
}

focusprev(f: int): int
{
	if(f == Bok)
		return Bcancel;
	if(f == Breboot)
		return Bok;
	return Breboot;
}

focusnext(f: int): int
{
	if(f == Bok)
		return Breboot;
	if(f == Breboot)
		return Bcancel;
	return Bok;
}

focusname(f: int): string
{
	if(f == Bok)
		return "OK";
	if(f == Breboot)
		return "Reboot";
	return "Cancel";
}

cleanup(icur: Icurses, out: ref Sys->FD)
{
	icur->closekbd();
	icur->resettty(out);
	icur->cleartty(out);
	icur->cup(out, 1, 1);
	icur->showcursor(out);
}

init(nil: ref Draw->Context, nil: list of string)
{
	icur: Icurses;
	theme: IcTheme;
	out: ref Sys->FD;
	rc, k, nav, focus, done: int;
	result, status: string;

	sys = load Sys Sys->PATH;
	if(sys == nil)
		raise "fail:load sys";

	icur = load Icurses Icurses->PATH;
	if(icur == nil)
		raise "fail:load icurses";

	theme = load IcTheme IcTheme->PATH;
	if(theme == nil)
		raise "fail:load ictheme";

	icur->init();
	theme->init();

	out = sys->fildes(1);
	if(out == nil)
		raise "fail:stdout nil";

	icur->hidecursor(out);
	icur->cleartty(out);

	rc = icur->openkbd();
	if(rc < 0){
		drawtext(icur, theme, out, 3, 1, IcTheme->AttrFocus, "openkbd failed");
		cleanup(icur, out);
		sys->print("result: openkbd failed\n");
		return;
	}

	focus = Bok;
	done = 0;
	result = "cancel";
	status = "openkbd ok";

	drawui(icur, theme, out, focus, status);

	while(done == 0){
		k = icur->readkey();
		if(k < 0){
			status = "readkey failed";
			result = "error";
			break;
		}

		if(k == 27 || k == 'q' || k == 'Q' || k == 'c' || k == 'C'){
			result = "cancel";
			status = sys->sprint("cancel by key=%d name=%s", k, icur->keyname(k));
			done = 1;
		}
		else if(k == 10 || k == 13){
			if(focus == Bok){
				result = "ok";
				status = sys->sprint("confirm OK by key=%d", k);
			}
			else if(focus == Breboot){
				result = "reboot";
				status = sys->sprint("confirm Reboot by key=%d", k);
			}
			else{
				result = "cancel";
				status = sys->sprint("confirm Cancel by key=%d", k);
			}
			done = 1;
		}
		else{
			nav = icur->navkind(k);

			if(nav == Icurses->NavPrev ||
			   nav == Icurses->NavLeft ||
			   nav == Icurses->NavUp){
				focus = focusprev(focus);
				status = sys->sprint("focus moved: %s (key=%d name=%s)",
					focusname(focus), k, icur->keyname(k));
			}
			else if(nav == Icurses->NavNext ||
			        nav == Icurses->NavRight ||
			        nav == Icurses->NavDown){
				focus = focusnext(focus);
				status = sys->sprint("focus moved: %s (key=%d name=%s)",
					focusname(focus), k, icur->keyname(k));
			}
			else{
				status = sys->sprint("diag key=%d name=%s", k, icur->keyname(k));
			}
		}

		drawui(icur, theme, out, focus, status);
	}

	cleanup(icur, out);
	sys->print("result: %s\n", result);
}

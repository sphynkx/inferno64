implement Icurses;

include "icurses/icurses.m";

sys: Sys;

kbd: ref Sys->FD;
consctl: ref Sys->FD;
kbuf: array of byte;
ks: string;
ki: int;
kn: int;

LogPathEnv: con "/env/INFERNO_MINGW_EKBD_LOG";
LogWdirEnv: con "/env/emuwdir";
LogPathDefault: con "inferno-mingw-ekbd.log";
LogSeparator: con "======================\n";
LogWrapperTag: con "LIMBO-OKBD-WRAPPER";
HostFsPrefix: con "#U";

init()
{
	sys = load Sys Sys->PATH;
	if(sys == nil)
		raise "fail:load sys";

	kbd = nil;
	consctl = nil;
	kbuf = array[64] of byte;
	ks = "";
	ki = 0;
	kn = 0;
}

readfile(path: string): string
{
	fd := sys->open(path, Sys->OREAD);
	if(fd == nil)
		return nil;
	(ok, st) := sys->fstat(fd);
	if(ok < 0 || int st.length <= 0){
		fd = nil;
		return nil;
	}
	buf := array[int st.length] of byte;
	n := sys->read(fd, buf, len buf);
	fd = nil;
	if(n <= 0)
		return nil;
	return string buf[0:n];
}

trimline(s: string): string
{
	if(s == nil)
		return nil;
	while(len s > 0){
		c := s[len s-1];
		if(c != '\n' && c != '\r')
			break;
		s = s[0:len s-1];
	}
	return s;
}

hostjoin(base, leaf: string): string
{
	if(base == nil || len base == 0)
		return leaf;
	c := base[len base-1];
	if(c == '/' || c == '\\')
		return base + leaf;
	return base + "/" + leaf;
}

hostlogpath(): string
{
	path := trimline(readfile(LogPathEnv));
	if(path != nil && len path > 0)
		return path;

	wdir := trimline(readfile(LogWdirEnv));
	if(wdir == nil || len wdir == 0)
		return LogPathDefault;
	return hostjoin(wdir, LogPathDefault);
}

infernohostpath(hostpath: string): string
{
	if(hostpath == nil || len hostpath == 0)
		return nil;
	if(len hostpath >= len HostFsPrefix && hostpath[0:len HostFsPrefix] == HostFsPrefix)
		return hostpath;
	return HostFsPrefix + hostpath;
}

openlog(): (ref Sys->FD, string, string)
{
	hostpath := hostlogpath();
	path := infernohostpath(hostpath);
	fd := sys->open(path, Sys->OWRITE);
	if(fd == nil)
		fd = sys->create(path, Sys->OWRITE, 8r666);
	if(fd != nil)
		sys->seek(fd, big 0, Sys->SEEKEND);
	return (fd, hostpath, path);
}

writelog(line: string): int
{
	(fd, nil, nil) := openlog();
	if(fd == nil)
		return -1;
	buf := array of byte line;
	n := sys->write(fd, buf, len buf);
	fd = nil;
	if(n != len buf)
		return -1;
	return n;
}

logwrapper(run: int, step: string, detail: string)
{
	line: string;

	if(detail == nil || len detail == 0)
		line = sys->sprint("%s run=%d pid=%d step=%s\n", LogWrapperTag, run, sys->pctl(0, nil), step);
	else
		line = sys->sprint("%s run=%d pid=%d step=%s detail=%s\n", LogWrapperTag, run, sys->pctl(0, nil), step, detail);
	if(writelog(line) < 0)
		return;
}

logwrapperbegin(run: int)
{
	(fd, hostpath, path) := openlog();
	if(fd == nil)
		return;
	sys->fprint(fd, "%s%s run=%d pid=%d step=begin detail=host=%s inferno=%s\n",
		LogSeparator, LogWrapperTag, run, sys->pctl(0, nil), hostpath, path);
	fd = nil;
}

openkbd(): int
{
	runstamp := sys->millisec();

	logwrapperbegin(runstamp);
	logwrapper(runstamp, "cons.open.begin", ConsctlPath);
	consctl = sys->open(ConsctlPath, Sys->OWRITE);
	if(consctl == nil)
		logwrapper(runstamp, "cons.open.fail", sys->sprint("%r"));
	else{
		logwrapper(runstamp, "cons.open.ok", sys->sprint("fd=%d", consctl.fd));
		logwrapper(runstamp, "rawon.begin", nil);
		if(sys->fprint(consctl, "rawon") < 0)
			logwrapper(runstamp, "rawon.fail", sys->sprint("%r"));
		else
			logwrapper(runstamp, "rawon.ok", nil);
	}

	logwrapper(runstamp, "ekbd.open.begin", KeyboardPath);
	kbd = sys->open(KeyboardPath, Sys->OREAD);
	if(kbd == nil){
		logwrapper(runstamp, "ekbd.open.fail", sys->sprint("%r"));
		if(consctl != nil){
			logwrapper(runstamp, "cleanup.rawoff.begin", nil);
			if(sys->fprint(consctl, "rawoff") < 0)
				logwrapper(runstamp, "cleanup.rawoff.fail", sys->sprint("%r"));
			else
				logwrapper(runstamp, "cleanup.rawoff.ok", nil);
		}
		consctl = nil;
		logwrapper(runstamp, "return.fail", "kbd=nil");
		return -1;
	}
	logwrapper(runstamp, "ekbd.open.ok", sys->sprint("fd=%d", kbd.fd));

	ks = "";
	ki = 0;
	kn = 0;
	logwrapper(runstamp, "return.ok", nil);
	return 0;
}

closekbd()
{
	if(consctl != nil)
		sys->fprint(consctl, "rawoff");

	kbd = nil;
	consctl = nil;
	ks = "";
	ki = 0;
	kn = 0;
}

readkey(): int
{
	k: int;

	if(kbd == nil)
		return -1;

	for(;;){
		if(ki < len ks){
			k = int ks[ki];
			ki++;
			return k;
		}

		kn = sys->read(kbd, kbuf, len kbuf);
		if(kn <= 0)
			return -1;

		ks = string kbuf[0:kn];
		ki = 0;
	}
}

keyname(k: int): string
{
	if(k == Khome) return "Home";
	if(k == Kend) return "End";
	if(k == Kup) return "Up";
	if(k == Kdown) return "Down";
	if(k == Kleft) return "Left";
	if(k == Kright) return "Right";
	if(k == Kpgup) return "PgUp";
	if(k == Kpgdown) return "PgDown";
	if(k == Kbacktab) return "Shift-Tab";
	if(k == Kins) return "Ins";
	if(k == Kdel) return "Del";
	if(k == 9) return "Tab";
	if(k == 10) return "Enter";
	if(k == 13) return "CR";
	if(k == 27) return "Esc";
	if(k == 'q') return "q";
	if(k == 'Q') return "Q";
	return sys->sprint("%d", k);
}

stepok(done: int): StepCtl
{
	ctl: StepCtl;

	ctl.rc = 0;
	ctl.done = done;
	return ctl;
}

steperr(): StepCtl
{
	ctl: StepCtl;

	ctl.rc = -1;
	ctl.done = 0;
	return ctl;
}

isconfirm(k: int): int
{
	return k == 10 || k == 13;
}

iscancel(k: int): int
{
	return k == 27 || k == 'q' || k == 'Q';
}

navkind(k: int): int
{
	if(k == Kleft) return NavLeft;
	if(k == Kright) return NavRight;
	if(k == Kup) return NavUp;
	if(k == Kdown) return NavDown;
	if(k == 9) return NavNext;
	if(k == Kbacktab) return NavPrev;
	if(k == Khome) return NavHome;
	if(k == Kend) return NavEnd;
	if(k == Kpgup) return NavPageUp;
	if(k == Kpgdown) return NavPageDown;
	return NavNone;
}

cleartty(out: ref Sys->FD)
{
	if(out == nil)
		return;
	sys->fprint(out, "%c[2J", 27);
	sys->fprint(out, "%c[H", 27);
}

resettty(out: ref Sys->FD)
{
	if(out == nil)
		return;
	sys->fprint(out, "%c[0m", 27);
}

hidecursor(out: ref Sys->FD)
{
	if(out == nil)
		return;
	sys->fprint(out, "%c[?25l", 27);
}

showcursor(out: ref Sys->FD)
{
	if(out == nil)
		return;
	sys->fprint(out, "%c[?25h", 27);
}

cup(out: ref Sys->FD, row, col: int)
{
	if(out == nil)
		return;
	sys->fprint(out, "%c[%d;%dH", 27, row, col);
}

sgr(out: ref Sys->FD, code: string)
{
	if(out == nil)
		return;
	sys->fprint(out, "%c[%sm", 27, code);
}

emitrun(out: ref Sys->FD, row, col: int, code, text: string)
{
	cup(out, row, col);
	sgr(out, code);
	sys->fprint(out, "%s", text);
}

#include	"dat.h"
#include	"fns.h"
#include	"error.h"
#include	"version.h"
#include	"mp.h"
#include	"libsec.h"
#include	"keyboard.h"

extern int cflag;
extern int exdebug;
extern int keepbroken;

enum
{
	Qdir,
	Qcons,
	Qconsctl,
	Qdrivers,
	Qhostowner,
	Qhoststdin,
	Qhoststdout,
	Qhoststderr,
	Qjit,
	Qkeyboard,
	Qekeyboard,
	Qemouse,
	Qkprint,
	Qmemory,
	Qmsec,
	Qnotquiterandom,
	Qnull,
	Qrandom,
	Qscancode,
	Qsysctl,
	Qsysname,
	Qtime,
	Quser
};

Dirtab contab[] =
{
	".",	{Qdir, 0, QTDIR},	0,		DMDIR|0555,
	"cons",		{Qcons},	0,	0666,
	"consctl",	{Qconsctl},	0,	0222,
	"drivers",	{Qdrivers},	0,	0444,
	"ekeyboard",	{Qekeyboard},	0,	0666,
	"emouse",	{Qemouse},	0,	0666,
	"hostowner",	{Qhostowner},	0,	0644,
	"hoststdin",	{Qhoststdin},	0,	0444,
	"hoststdout",	{Qhoststdout},	0,	0222,
	"hoststderr",	{Qhoststderr},	0,	0222,
	"jit",	{Qjit},	0,	0666,
	"keyboard",	{Qkeyboard},	0,	0666,
	"kprint",	{Qkprint},	0,	0444,
	"memory",	{Qmemory},	0,	0444,
	"msec",		{Qmsec},	NUMSIZE,	0444,
	"notquiterandom",	{Qnotquiterandom},	0,	0444,
	"null",		{Qnull},	0,	0666,
	"random",	{Qrandom},	0,	0444,
	"scancode",	{Qscancode},	0,	0444,
	"sysctl",	{Qsysctl},	0,	0644,
	"sysname",	{Qsysname},	0,	0644,
	"time",		{Qtime},	0,	0644,
	"user",		{Quser},	0,	0644,
};

Queue*	gkscanq;		/* Graphics keyboard raw scancodes */
extern	char	gkscanid[];	/* name of raw scan format (if defined) */
Queue*	ekbdq;			/* Enhanced console keyboard input */
Queue*	emouseq;		/* Enhanced console mouse input */
Queue*	gkbdq;			/* Graphics keyboard unprocessed input */
Queue*	kbdq;			/* Console window unprocessed keyboard input */
Queue*	lineq;			/* processed console input */

char	*ossysname;

static struct
{
	RWlock l;
	Queue*	q;
} kprintq;

vlong	timeoffset;

extern int	dflag;

static int	sysconwrite(void*, ulong);
extern char**	rebootargv;

static struct
{
	QLock	q;
	QLock	gq;		/* separate lock for the graphical input */

	int	raw;		/* true if we shouldn't process input */
	Ref	ctl;		/* number of opens to the control file */
	Ref	ptr;		/* number of opens to the ptr file */
	Ref	ekbd;		/* number of opens to the enhanced keyboard file */
	int	scan;		/* true if reading raw scancodes */
	int	x;		/* index into line */
	char	line[1024];	/* current input line */

	Rune	c;
	int	count;
} kbd;

void
kbdslave(void *a)
{
	char b;

	USED(a);
	for(;;) {
		b = readkbd();
		if(kbd.raw == 0){
			switch(b){
			case 0x15:
				write(1, "^U\n", 3);
				break;
			default:
				write(1, &b, 1);
				break;
			}
		}
		qproduce(kbdq, &b, 1);
	}
	/* pexit("kbdslave", 0); */	/* not reached */
}

static void
ekbdputc(int ch)
{
	if(ekbdq == nil)
		return;
	gkbdputc(ekbdq, ch);
}

static int
ordinarykey(int k)
{
	return k >= 0 && k < Spec;
}

static int
ekbdsessionactive(void)
{
	/*
	 * MinGW keeps draining host console input continuously, so gating
	 * legacy mirroring on kbd.ekbd.ref alone can keep shell input
	 * suppressed after the visible session has ended if FD finalization
	 * lags.  The proven leak only happens while the enhanced raw session
	 * is actively owning input, so require both raw mode and an open
	 * /dev/ekeyboard reference there.
	 */
#ifdef __MINGW32__
	return kbd.raw != 0 && kbd.ekbd.ref != 0;
#else
	return kbd.ekbd.ref != 0;
#endif
}

#ifdef __MINGW32__
extern int reademouse(char *buf, int n);
extern void enableconsolemouse(void);
extern void disableconsolemouse(void);
extern int consoleinputpending(void);
extern int consoleinputpeek(char *buf, int n);
extern int mingwtraceverboseenabled(void);
extern void mingwtracelog(char *fmt, ...);

static int mouseprocstarted;

enum
{
	MinGWEkbdRecent = 16,
	MinGWEkbdRoute = 16
};

static int mingwekbdtrace = -1;
static ulong mingwekbdseq;
static ulong mingwekbdphaseseq;
static Lock mingwekbdlock;
static struct
{
	ulong	seq;
	int	ch;
	int	ordinary;
	int	raw;
	long	ctlref;
	long	ekbdref;
	int	ekbdqlen;
	int	kbdqlen;
	int	hostpending;
} mingwekbdrecent[MinGWEkbdRecent];
static int mingwekbdrecentn;
static int mingwekbdrecenti;
static struct
{
	ulong	seq;
	int	ch;
	int	raw;
	long	ctlref;
	long	ekbdref;
	int	kbdqbefore;
	int	kbdqafter;
	int	hostpending;
} mingwekbdroute[MinGWEkbdRoute];
static int mingwekbdrouten;
static int mingwekbdroutei;

static int
mingwekbdtraceenabled(void)
{
	char *v;

	if(mingwekbdtrace >= 0)
		return mingwekbdtrace;

	v = getenv("INFERNO_MINGW_EKBD_TRACE");
	mingwekbdtrace = v != nil && *v != '\0' && strcmp(v, "0") != 0;
	return mingwekbdtrace;
}

static void
mingwekbdstate(char *edge, char *tag, int line)
{
	char peek[128];
	ulong seq;

	if(!mingwekbdtraceenabled())
		return;

	lock(&mingwekbdlock);
	seq = ++mingwekbdphaseseq;
	peek[0] = '\0';
	consoleinputpeek(peek, sizeof(peek));
	if(peek[0] == '\0')
		snprint(peek, sizeof(peek), "unavailable");
	/* DBG  MinGW */
	mingwtracelog("okbd step=%s phase=%s @devcons.c:%d seq=%lud pid=%d ctl=%ld ekbd=%ld raw=%d ekbdq=%d kbdq=%d hp=%d peek=%s",
		tag,
		edge,
		line,
		seq,
		up != nil ? up->pid : -1,
		kbd.ctl.ref,
		kbd.ekbd.ref,
		kbd.raw,
		ekbdq != nil ? qlen(ekbdq) : -1,
		kbdq != nil ? qlen(kbdq) : -1,
		consoleinputpending(),
		peek);
	/* /DBG  MinGW */
	unlock(&mingwekbdlock);
}

static void
mingwekbdhost(char *tag, int line)
{
	char peek[128];
	int pending;

	if(!mingwekbdtraceenabled())
		return;

	lock(&mingwekbdlock);
	pending = consoleinputpending();
	peek[0] = '\0';
	consoleinputpeek(peek, sizeof(peek));
	if(peek[0] == '\0')
		snprint(peek, sizeof(peek), "unavailable");
	/* DBG  MinGW */
	mingwtracelog("okbd host=%s @devcons.c:%d hp=%d peek=%s ctl=%ld ekbd=%ld raw=%d ekbdq=%d kbdq=%d",
		tag,
		line,
		pending,
		peek,
		kbd.ctl.ref,
		kbd.ekbd.ref,
		kbd.raw,
		ekbdq != nil ? qlen(ekbdq) : -1,
		kbdq != nil ? qlen(kbdq) : -1);
	/* /DBG  MinGW */
	unlock(&mingwekbdlock);
}

static void
mingwekbdqtransition(char *tag, char *qname, int line, int before, int after)
{
	if(!mingwekbdtraceenabled())
		return;

	lock(&mingwekbdlock);
	/* DBG  MinGW */
	mingwtracelog("okbd queue=%s op=%s @devcons.c:%d before=%d after=%d ctl=%ld ekbd=%ld raw=%d hp=%d",
		tag,
		qname,
		line,
		before,
		after,
		kbd.ctl.ref,
		kbd.ekbd.ref,
		kbd.raw,
		consoleinputpending());
	/* /DBG  MinGW */
	unlock(&mingwekbdlock);
}

static void
mingwekbdresidue(char *tag, int line)
{
	if(!mingwekbdtraceenabled())
		return;
	if(kbdq == nil || qlen(kbdq) == 0)
		return;

	lock(&mingwekbdlock);
	/* DBG  MinGW */
	mingwtracelog("okbd residue=%s @devcons.c:%d kbdq=%d ekbdq=%d ctl=%ld ekbd=%ld raw=%d hp=%d",
		tag,
		line,
		qlen(kbdq),
		ekbdq != nil ? qlen(ekbdq) : -1,
		kbd.ctl.ref,
		kbd.ekbd.ref,
		kbd.raw,
		consoleinputpending());
	/* /DBG  MinGW */
	unlock(&mingwekbdlock);
}

static void
mingwekbdrecord(int ch)
{
	if(!mingwekbdtraceenabled())
		return;
	if(!mingwtraceverboseenabled())
		return;

	lock(&mingwekbdlock);
	mingwekbdrecent[mingwekbdrecenti].seq = ++mingwekbdseq;
	mingwekbdrecent[mingwekbdrecenti].ch = ch;
	mingwekbdrecent[mingwekbdrecenti].ordinary = ordinarykey(ch);
	mingwekbdrecent[mingwekbdrecenti].raw = kbd.raw;
	mingwekbdrecent[mingwekbdrecenti].ctlref = kbd.ctl.ref;
	mingwekbdrecent[mingwekbdrecenti].ekbdref = kbd.ekbd.ref;
	mingwekbdrecent[mingwekbdrecenti].ekbdqlen = ekbdq != nil ? qlen(ekbdq) : -1;
	mingwekbdrecent[mingwekbdrecenti].kbdqlen = kbdq != nil ? qlen(kbdq) : -1;
	mingwekbdrecent[mingwekbdrecenti].hostpending = consoleinputpending();

	mingwekbdrecenti = (mingwekbdrecenti + 1) % MinGWEkbdRecent;
	if(mingwekbdrecentn < MinGWEkbdRecent)
		mingwekbdrecentn++;
	unlock(&mingwekbdlock);
}

static void
mingwekbddumprecent(char *tag)
{
	int i, idx;

	if(!mingwekbdtraceenabled())
		return;

	lock(&mingwekbdlock);
	if(mingwekbdrecentn == 0){
		unlock(&mingwekbdlock);
		return;
	}
	/* DBG  MinGW */
	mingwtracelog("okbd ring=input tag=%s n=%d", tag, mingwekbdrecentn);
	/* /DBG  MinGW */
	for(i = 0; i < mingwekbdrecentn; i++){
		idx = mingwekbdrecenti - mingwekbdrecentn + i;
		if(idx < 0)
			idx += MinGWEkbdRecent;
		/* DBG  MinGW */
		mingwtracelog("okbd ring=input idx=%d seq=%lud ch=%d ordinary=%d raw=%d ctl=%ld ekbd=%ld ekbdq=%d kbdq=%d hp=%d",
			i,
			mingwekbdrecent[idx].seq,
			mingwekbdrecent[idx].ch,
			mingwekbdrecent[idx].ordinary,
			mingwekbdrecent[idx].raw,
			mingwekbdrecent[idx].ctlref,
			mingwekbdrecent[idx].ekbdref,
			mingwekbdrecent[idx].ekbdqlen,
			mingwekbdrecent[idx].kbdqlen,
			mingwekbdrecent[idx].hostpending);
		/* /DBG  MinGW */
	}
	unlock(&mingwekbdlock);
}

static void
mingwekbdroutekbdq(int ch, int before, int after)
{
	if(!mingwekbdtraceenabled())
		return;
	if(!mingwtraceverboseenabled())
		return;

	lock(&mingwekbdlock);
	mingwekbdroute[mingwekbdroutei].seq = ++mingwekbdseq;
	mingwekbdroute[mingwekbdroutei].ch = ch;
	mingwekbdroute[mingwekbdroutei].raw = kbd.raw;
	mingwekbdroute[mingwekbdroutei].ctlref = kbd.ctl.ref;
	mingwekbdroute[mingwekbdroutei].ekbdref = kbd.ekbd.ref;
	mingwekbdroute[mingwekbdroutei].kbdqbefore = before;
	mingwekbdroute[mingwekbdroutei].kbdqafter = after;
	mingwekbdroute[mingwekbdroutei].hostpending = consoleinputpending();

	mingwekbdroutei = (mingwekbdroutei + 1) % MinGWEkbdRoute;
	if(mingwekbdrouten < MinGWEkbdRoute)
		mingwekbdrouten++;
	unlock(&mingwekbdlock);
}

static void
mingwekbddumproute(char *tag)
{
	int i, idx;

	if(!mingwekbdtraceenabled())
		return;

	lock(&mingwekbdlock);
	if(mingwekbdrouten == 0){
		unlock(&mingwekbdlock);
		return;
	}
	/* DBG  MinGW */
	mingwtracelog("okbd ring=kbdq tag=%s n=%d", tag, mingwekbdrouten);
	/* /DBG  MinGW */
	for(i = 0; i < mingwekbdrouten; i++){
		idx = mingwekbdroutei - mingwekbdrouten + i;
		if(idx < 0)
			idx += MinGWEkbdRoute;
		/* DBG  MinGW */
		mingwtracelog("okbd ring=kbdq idx=%d seq=%lud ch=%d raw=%d ctl=%ld ekbd=%ld before=%d after=%d hp=%d",
			i,
			mingwekbdroute[idx].seq,
			mingwekbdroute[idx].ch,
			mingwekbdroute[idx].raw,
			mingwekbdroute[idx].ctlref,
			mingwekbdroute[idx].ekbdref,
			mingwekbdroute[idx].kbdqbefore,
			mingwekbdroute[idx].kbdqafter,
			mingwekbdroute[idx].hostpending);
		/* /DBG  MinGW */
	}
	unlock(&mingwekbdlock);
}

static void
emouseput(char *buf, int n)
{
	if(emouseq == nil || n <= 0)
		return;
	qproduce(emouseq, buf, n);
}

/*
 * MinGW/MSYS2 console keyboard reader:
 * single source of truth for console input.
 *
 * All key events go to /dev/ekeyboard.
 * Ordinary text input is also translated to the legacy console queue
 * so /dev/cons and the shell continue to work from the same event stream.
 */
void
winkbdslave(void *a)
{
	int k, nb, kbdqbefore;
	Rune r;
	char b;
	char ubuf[UTFmax];

	USED(a);
	for(;;){
		k = readekbd();
		if(k < 0)
			continue;
		mingwekbdrecord(k);

		/*
		 * Full event stream for enhanced console clients.
		 * MinGW keeps draining host console input into ekbdq and trims
		 * stale entries on open via qflush(ekbdq), rather than waiting
		 * for kbd.ekbd.ref before it starts collecting host events.
		 */
		ekbdputc(k);

		/*
		 * Legacy console path:
		 * ordinary text should only reach /dev/cons when the enhanced
		 * raw session does not currently own input.
		 *
		 * When MinGW raw + /dev/ekeyboard are both active, mirroring the
		 * same ordinary key into kbdq leaks dialog-consumed text back to
		 * the shell after the interactive session ends.
		 */
		if(ordinarykey(k) && !ekbdsessionactive()){
			r = k;
			if(r == '\r')
				r = '\n';

			if(r < 0x80){
				b = r;
				if(kbd.raw == 0){
					switch(b){
					case 0x15:
						write(1, "^U\n", 3);
						break;
					default:
						write(1, &b, 1);
						break;
					}
				}
				kbdqbefore = kbdq != nil ? qlen(kbdq) : -1;
				qproduce(kbdq, &b, 1);
				mingwekbdroutekbdq(k, kbdqbefore, kbdq != nil ? qlen(kbdq) : -1);
			}else{
				nb = runetochar(ubuf, &r);
				if(nb <= 0)
					continue;
				if(kbd.raw == 0)
					write(1, ubuf, nb);
				kbdqbefore = kbdq != nil ? qlen(kbdq) : -1;
				qproduce(kbdq, ubuf, nb);
				mingwekbdroutekbdq(k, kbdqbefore, kbdq != nil ? qlen(kbdq) : -1);
			}
		}
	}
	/* not reached */
}

void
winmouseslave(void *a)
{
	char buf[128];
	int n;

	USED(a);
	for(;;){
		n = reademouse(buf, sizeof(buf));
		if(n <= 0)
			continue;
		emouseput(buf, n);
	}
	/* not reached */
}

#else

static void
mingwekbdstate(char *edge, char *tag, int line)
{
	USED(edge);
	USED(tag);
	USED(line);
}

static void
mingwekbdhost(char *tag, int line)
{
	USED(tag);
	USED(line);
}

static void
mingwekbdqtransition(char *tag, char *qname, int line, int before, int after)
{
	USED(tag);
	USED(qname);
	USED(line);
	USED(before);
	USED(after);
}

static void
mingwekbdresidue(char *tag, int line)
{
	USED(tag);
	USED(line);
}

static void
mingwekbddumprecent(char *tag)
{
	USED(tag);
}

static void
mingwekbdrecord(int ch)
{
	USED(ch);
}

static void
mingwekbdroutekbdq(int ch, int before, int after)
{
	USED(ch);
	USED(before);
	USED(after);
}

static void
mingwekbddumproute(char *tag)
{
	USED(tag);
}

#endif

#ifdef __linux__
void
linuxkbdslave(void *a)
{
	int k, nb;
	Rune r;
	char b;
	char ubuf[UTFmax];

	USED(a);
	for(;;){
		k = readekbd();
		if(k < 0)
			continue;

		if(kbd.ekbd.ref != 0)
			ekbdputc(k);

		if(kbd.ekbd.ref == 0 && ordinarykey(k)){
			r = k;
			if(r == '\r')
				r = '\n';

			if(r < 0x80){
				b = r;
				if(kbd.raw == 0){
					switch(b){
					case 0x15:
						write(1, "^U\n", 3);
						break;
					default:
						write(1, &b, 1);
						break;
					}
				}
				qproduce(kbdq, &b, 1);
			}else{
				nb = runetochar(ubuf, &r);
				if(nb <= 0)
					continue;
				if(kbd.raw == 0)
					write(1, ubuf, nb);
				qproduce(kbdq, ubuf, nb);
			}
		}
	}
	/* not reached */
}
#endif

void
gkbdputc(Queue *q, int ch)
{
	int n;
	Rune r;
	static uchar kc[5*UTFmax];
	static int nk, collecting = 0;
	char buf[UTFmax];

	r = ch;
	if(r == Latin) {
		collecting = 1;
		nk = 0;
		return;
	}
	if(collecting) {
		int c;
		nk += runetochar((char*)&kc[nk], &r);
		c = latin1(kc, nk);
		if(c < -1)	/* need more keystrokes */
			return;
		collecting = 0;
		if(c == -1) {	/* invalid sequence */
			qproduce(q, kc, nk);
			return;
		}
		r = (Rune)c;
	}
	n = runetochar(buf, &r);
	if(n == 0)
		return;
	/* if(!isdbgkey(r)) */ 
		qproduce(q, buf, n);
}

void
consinit(void)
{
	kbdq = qopen(512, 0, nil, nil);
	if(kbdq == 0)
		panic("no memory");
	lineq = qopen(2*1024, 0, nil, nil);
	if(lineq == 0)
		panic("no memory");
	gkbdq = qopen(512, 0, nil, nil);
	if(gkbdq == 0)
		panic("no memory");
	ekbdq = qopen(512, 0, nil, nil);
	if(ekbdq == 0)
		panic("no memory");
	emouseq = qopen(2*1024, 0, nil, nil);
	if(emouseq == 0)
		panic("no memory");
	randominit();
}

/*
 *  return true if current user is eve
 */
int
iseve(void)
{
	return strcmp(eve, up->env->user) == 0;
}

static Chan*
consattach(char *spec)
{
	static int kp;

	if(kp == 0 && !dflag) {
		kp = 1;
#ifdef __MINGW32__
		kproc("kbd", winkbdslave, 0, 0);
#elif defined(__linux__)
		kproc("kbd", linuxkbdslave, 0, 0);
#else
		kproc("kbd", kbdslave, 0, 0);
#endif
	}
	return devattach('c', spec);
}

static Walkqid*
conswalk(Chan *c, Chan *nc, char **name, int nname)
{
	return devwalk(c, nc, name, nname, contab, nelem(contab), devgen);
}

static int
consstat(Chan *c, uchar *db, int n)
{
	return devstat(c, db, n, contab, nelem(contab), devgen);
}

static Chan*
consopen(Chan *c, int omode)
{
	c = devopen(c, omode, contab, nelem(contab), devgen);
	switch((ulong)c->qid.path) {
	case Qconsctl:
		mingwekbdstate("begin", "cons.open.backend", __LINE__);
		incref(&kbd.ctl);
		mingwekbdstate("ok", "cons.open.backend", __LINE__);
		break;

	case Qemouse:
#ifdef __MINGW32__
		if(incref(&kbd.ptr) == 1)
			enableconsolemouse();
		if(mouseprocstarted == 0){
			mouseprocstarted = 1;
			kproc("mouse", winmouseslave, 0, 0);
		}
#else
		incref(&kbd.ptr);
#endif
		break;

	case Qekeyboard:
	{
#ifdef __MINGW32__
		int before, beforekbd;

		mingwekbdstate("begin", "ekbd.open.backend", __LINE__);
		incref(&kbd.ekbd);
		mingwekbdstate("ok", "ekbd.open.backend", __LINE__);
		/*
		 * Drop stale enhanced-key events on every open.
		 *
		 * The MinGW reader already drains console input continuously
		 * into ekbdq, so flushing the queue here is enough to discard
		 * pre-open shell/build keystrokes without depending on
		 * first-open / last-close transitions that can lag under
		 * GC-driven FD finalization.
		 */
		before = ekbdq != nil ? qlen(ekbdq) : -1;
		qflush(ekbdq);
		mingwekbdqtransition("flush", "ekbdq", __LINE__, before, ekbdq != nil ? qlen(ekbdq) : -1);
		beforekbd = kbdq != nil ? qlen(kbdq) : -1;
		qflush(kbdq);
		mingwekbdqtransition("flush", "kbdq", __LINE__, beforekbd, kbdq != nil ? qlen(kbdq) : -1);
		mingwekbdstate("ok", "ekbd.open.flush", __LINE__);
#else
		if(incref(&kbd.ekbd) == 1){
			qflush(ekbdq);
		}
#endif
		break;
	}

	case Qscancode:
		qlock(&kbd.gq);
		if(gkscanq != nil || gkscanid[0] == '\0') {
			qunlock(&kbd.q);
			c->flag &= ~COPEN;
			if(gkscanq)
				error(Einuse);
			else
				error("not supported");
		}
		gkscanq = qopen(256, 0, nil, nil);
		qunlock(&kbd.gq);
		break;

	case Qkprint:
		wlock(&kprintq.l);
		if(waserror()){
			wunlock(&kprintq.l);
			c->flag &= ~COPEN;
			nexterror();
		}
		if(kprintq.q != nil)
			error(Einuse);
		kprintq.q = qopen(32*1024, Qcoalesce, nil, nil);
		if(kprintq.q == nil)
			error(Enomem);
		qnoblock(kprintq.q, 1);
		poperror();
		wunlock(&kprintq.l);
		c->iounit = qiomaxatomic;
		break;
	}
	return c;
}

static void
consclose(Chan *c)
{
	if((c->flag & COPEN) == 0)
		return;

	switch((ulong)c->qid.path) {
	case Qconsctl:
		mingwekbdstate("begin", "cons.close", __LINE__);
		/* last close of control file turns off raw */
		if(decref(&kbd.ctl) == 0)
			kbd.raw = 0;
		mingwekbdresidue("consctl close", __LINE__);
		mingwekbdstate("ok", "cons.close", __LINE__);
		break;

	case Qemouse:
		if(decref(&kbd.ptr) == 0){
#ifdef __MINGW32__
			disableconsolemouse();
#endif
		}
		break;

	case Qekeyboard:
		mingwekbdstate("begin", "ekbd.close", __LINE__);
		if(decref(&kbd.ekbd) == 0)
		{
			int before, beforekbd;

			before = ekbdq != nil ? qlen(ekbdq) : -1;
			qflush(ekbdq);
			mingwekbdqtransition("flush", "ekbdq", __LINE__, before, ekbdq != nil ? qlen(ekbdq) : -1);
			beforekbd = kbdq != nil ? qlen(kbdq) : -1;
			qflush(kbdq);
			mingwekbdqtransition("flush", "kbdq", __LINE__, beforekbd, kbdq != nil ? qlen(kbdq) : -1);
		}
		mingwekbdresidue("ekeyboard close", __LINE__);
		mingwekbddumprecent("ekeyboard close");
		mingwekbddumproute("ekeyboard close");
		mingwekbdstate("ok", "ekbd.close", __LINE__);
		break;

	case Qscancode:
		qlock(&kbd.gq);
		if(gkscanq) {
			qfree(gkscanq);
			gkscanq = nil;
		}
		qunlock(&kbd.gq);
		break;

	case Qkprint:
		wlock(&kprintq.l);
		qfree(kprintq.q);
		kprintq.q = nil;
		wunlock(&kprintq.l);
		break;
	}
}

static long
consread(Chan *c, void *va, long n, vlong offset)
{
	int send;
	char buf[64], ch;

	if(c->qid.type & QTDIR)
		return devdirread(c, va, n, contab, nelem(contab), devgen);

	switch((ulong)c->qid.path) {
	default:
		error(Egreg);

	case Qsysctl:
		return readstr(offset, va, n, VERSION);

	case Qsysname:
		if(ossysname == nil)
			return 0;
		return readstr(offset, va, n, ossysname);

	case Qrandom:
		return randomread(va, n);

	case Qnotquiterandom:
		genrandom(va, n);
		return n;

	case Qhostowner:
		return readstr(offset, va, n, eve);

	case Qhoststdin:
		return read(0, va, n);	/* should be pread */

	case Quser:
		return readstr(offset, va, n, up->env->user);

	case Qjit:
		snprint(buf, sizeof(buf), "%d", cflag);
		return readstr(offset, va, n, buf);

	case Qtime:
		snprint(buf, sizeof(buf), "%.lld", timeoffset + osusectime());
		return readstr(offset, va, n, buf);

	case Qdrivers:
		return devtabread(c, va, n, offset);

	case Qmemory:
		return poolread(va, n, offset);

	case Qnull:
		return 0;

	case Qmsec:
		return readnum(offset, va, n, osmillisec(), NUMSIZE);

	case Qcons:
		qlock(&kbd.q);
		if(waserror()){
			qunlock(&kbd.q);
			nexterror();
		}

		if(dflag)
			error(Enonexist);

		while(!qcanread(lineq)) {
			if(qread(kbdq, &ch, 1) == 0)
				continue;
			send = 0;
			if(ch == 0){
				/* flush output on rawoff -> rawon */
				if(kbd.x > 0)
					send = !qcanread(kbdq);
			}else if(kbd.raw){
				kbd.line[kbd.x++] = ch;
				send = !qcanread(kbdq);
			}else{
				switch(ch){
				case '\b':
					if(kbd.x)
						kbd.x--;
					break;
				case 0x15:
					kbd.x = 0;
					break;
				case 0x04:
					send = 1;
					break;
				case '\n':
					send = 1;
				default:
					kbd.line[kbd.x++] = ch;
					break;
				}
			}
			if(send || kbd.x == sizeof kbd.line){
				qwrite(lineq, kbd.line, kbd.x);
				kbd.x = 0;
			}
		}
		n = qread(lineq, va, n);
		qunlock(&kbd.q);
		poperror();
		return n;

	case Qscancode:
		if(offset == 0)
			return readstr(0, va, n, gkscanid);
		return qread(gkscanq, va, n);

	case Qekeyboard:
		return qread(ekbdq, va, n);

	case Qemouse:
		return qread(emouseq, va, n);

	case Qkeyboard:
		return qread(gkbdq, va, n);

	case Qkprint:
		rlock(&kprintq.l);
		if(waserror()){
			runlock(&kprintq.l);
			nexterror();
		}
		n = qread(kprintq.q, va, n);
		poperror();
		runlock(&kprintq.l);
		return n;
	}
}

static long
conswrite(Chan *c, void *va, long n, vlong offset)
{
	char buf[128], *a, ch;
	int x;

	if(c->qid.type & QTDIR)
		error(Eperm);

	switch((ulong)c->qid.path) {
	default:
		error(Egreg);

	case Qcons:
		if(canrlock(&kprintq.l)){
			if(kprintq.q != nil){
				if(waserror()){
					runlock(&kprintq.l);
					nexterror();
				}
				qwrite(kprintq.q, va, n);
				poperror();
				runlock(&kprintq.l);
				return n;
			}
			runlock(&kprintq.l);
		}
		return write(1, va, n);

	case Qsysctl:
		return sysconwrite(va, n);

	case Qconsctl:
		if(n >= sizeof(buf))
			n = sizeof(buf)-1;
		strncpy(buf, va, n);
		buf[n] = 0;
		for(a = buf; a;){
			if(strncmp(a, "rawon", 5) == 0){
				mingwekbdstate("begin", "rawon", __LINE__);
				kbd.raw = 1;
				/* clumsy hack - wake up reader */
				ch = 0;
				x = kbdq != nil ? qlen(kbdq) : -1;
				qwrite(kbdq, &ch, 1);
				mingwekbdqtransition("qwrite", "kbdq", __LINE__, x, kbdq != nil ? qlen(kbdq) : -1);
				mingwekbdstate("ok", "rawon", __LINE__);
			} else if(strncmp(buf, "rawoff", 6) == 0){
				mingwekbdstate("begin", "rawoff", __LINE__);
				kbd.raw = 0;
				mingwekbdresidue("consctl rawoff", __LINE__);
				mingwekbdstate("ok", "rawoff", __LINE__);
			}
			if((a = strchr(a, ' ')) != nil)
				a++;
		}
		break;

	case Qkeyboard:
		for(x=0; x<n; ) {
			Rune r;
			x += chartorune(&r, &((char*)va)[x]);
			gkbdputc(gkbdq, r);
		}
		break;

	case Qnull:
		break;

	case Qtime:
		if(n >= sizeof(buf))
			n = sizeof(buf)-1;
		strncpy(buf, va, n);
		buf[n] = '\0';
		timeoffset = strtoll(buf, 0, 0)-osusectime();
		break;

	case Qhostowner:
		if(!iseve())
			error(Eperm);
		if(offset != 0 || n >= sizeof(buf))
			error(Ebadarg);
		memmove(buf, va, n);
		buf[n] = '\0';
		if(n > 0 && buf[n-1] == '\n')
			buf[--n] = '\0';
		if(n == 0)
			error(Ebadarg);
		/* renameuser(eve, buf); */
		/* renameproguser(eve, buf); */
		kstrdup(&eve, buf);
		kstrdup(&up->env->user, buf);
		break;

	case Quser:
		if(!iseve())
			error(Eperm);
		if(offset != 0)
			error(Ebadarg);
		if(n <= 0 || n >= sizeof(buf))
			error(Ebadarg);
		strncpy(buf, va, n);
		buf[n] = '\0';
		if(n > 0 && buf[n-1] == '\n')
			buf[--n] = '\0';
		if(n == 0)
			error(Ebadarg);
		setid(buf, 0);
		break;

	case Qhoststdout:
		return write(1, va, n);

	case Qhoststderr:
		return write(2, va, n);

	case Qjit:
		if(n >= sizeof(buf))
			n = sizeof(buf)-1;
		strncpy(buf, va, n);
		buf[n] = '\0';
		x = atoi(buf);
		if(x < 0 || x > 9)
			error(Ebadarg);
		cflag = x;
		break;

	case Qsysname:
		if(offset != 0)
			error(Ebadarg);
		if(n < 0 || n >= sizeof(buf))
			error(Ebadarg);
		strncpy(buf, va, n);
		buf[n] = '\0';
		if(buf[n-1] == '\n')
			buf[n-1] = 0;
		kstrdup(&ossysname, buf);
		break;
	}
	return n;
}

static int	
sysconwrite(void *va, ulong count)
{
	Cmdbuf *cb;
	int e;
	cb = parsecmd(va, count);
	if(waserror()){
		free(cb);
		nexterror();
	}
	if(cb->nf == 0)
		error(Enoctl);
	if(strcmp(cb->f[0], "reboot") == 0){
		osreboot(rebootargv[0], rebootargv);
		error("reboot not supported");
	}else if(strcmp(cb->f[0], "halt") == 0){
		if(cb->nf > 1)
			e = atoi(cb->f[1]);
		else
			e = 0;
		cleanexit(e);		/* XXX ignored for the time being (and should be a string anyway) */
	}else if(strcmp(cb->f[0], "broken") == 0)
		keepbroken = 1;
	else if(strcmp(cb->f[0], "nobroken") == 0)
		keepbroken = 0;
	else if(strcmp(cb->f[0], "exdebug") == 0)
		exdebug = !exdebug;
	else
		error(Enoctl);
	poperror();
	free(cb);
	return count;
} 

Dev consdevtab = {
	'c',
	"cons",

	consinit,
	consattach,
	conswalk,
	consstat,
	consopen,
	devcreate,
	consclose,
	consread,
	devbread,
	conswrite,
	devbwrite,
	devremove,
	devwstat
};

static	ulong	randn;

static void
seedrand(void)
{
	randomread((void*)&randn, sizeof(randn));
}

int
nrand(int n)
{
	if(randn == 0)
		seedrand();
	randn = randn*1103515245 + 12345 + osusectime();
	return (randn>>16) % n;
}

int
rand(void)
{
	nrand(1);
	return randn;
}

ulong
truerand(void)
{
	ulong x;

	randomread(&x, sizeof(x));
	return x;
}

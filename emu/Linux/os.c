#include	<sys/types.h>
#include	<time.h>
#include	<termios.h>
#include	<signal.h>
#include 	<pwd.h>
#include	<sched.h>
#include	<sys/resource.h>
#include	<sys/select.h>
#include	<sys/wait.h>
#include	<sys/time.h>
#include	<sys/ioctl.h>

#include	<errno.h>
#include	<stdint.h>

#include	"dat.h"
#include	"fns.h"
#include	"error.h"
#include	"keyboard.h"

#include <semaphore.h>

#include	<raise.h>

/* glibc 2.3.3-NTPL messes up getpid() by trying to cache the result, so we'll do it ourselves */
#include	<sys/syscall.h>
#define	getpid()	syscall(SYS_getpid)

enum
{
	DELETE	= 0x7f,
	CTRLC	= 'C'-'@',
	NSTACKSPERALLOC = 16,
	X11STACK=	256*1024
};
char *hosttype = "Linux";
#if defined(__x86_64__)
char *cputype = "amd64";
#elif defined(__aarch64__)
char *cputype = "arm64";
#elif defined(__i386__)
char *cputype = "386";
#elif defined(__arm__)
char *cputype = "arm";
#elif defined(__mips__)
char *cputype = "mips";
#elif defined(__powerpc__) || defined(__powerpc64__)
char *cputype = "power";
#else
char *cputype;
#endif

typedef sem_t	Sem;

extern int dflag;

int	gidnobody = -1;
int	uidnobody = -1;
static struct 	termios tinit;

static void
sysfault(char *what, void *addr)
{
	char buf[64];

	snprint(buf, sizeof(buf), "sys: %s%#llux", what, addr);
	disfault(nil, buf);
}

static void
trapILL(int signo, siginfo_t *si, void *a)
{
	USED(signo);
	USED(a);
	sysfault("illegal instruction pc=", si->si_addr);
}

static int
isnilref(siginfo_t *si)
{
	return si != 0 && (si->si_addr == (void*)~(uintptr_t)0 || (uintptr_t)si->si_addr < 512);
}

static void
trapmemref(int signo, siginfo_t *si, void *a)
{
	USED(a);	/* ucontext_t*, could fetch pc in machine-dependent way */
	if(isnilref(si))
		disfault(nil, exNilref);
	else if(signo == SIGBUS)
		sysfault("bad address addr=", si->si_addr);	/* eg, misaligned */
	else
		sysfault("segmentation violation addr=", si->si_addr);
}

static void
trapFPE(int signo, siginfo_t *si, void *a)
{
	char buf[64];

	USED(signo);
	USED(a);
	snprint(buf, sizeof(buf), "sys: fp: exception status=%.4lux pc=%#p", getfsr(), si->si_addr);
	disfault(nil, buf);
}

static void
trapUSR1(int signo)
{
	int intwait;

	USED(signo);

	intwait = up->intwait;
	up->intwait = 0;	/* clear it to let proc continue in osleave */

	if(up->type != Interp)		/* Used to unblock pending I/O */
		return;

	if(intwait == 0)		/* Not posted so it's a sync error */
		disfault(nil, Eintr);	/* Should never happen */
}

void
oslongjmp(void *regs, osjmpbuf env, int val)
{
	USED(regs);
	siglongjmp(env, val);
}

static void
termset(void)
{
	struct termios t;

	tcgetattr(0, &t);
	tinit = t;
	t.c_lflag &= ~(ICANON|ECHO|ISIG);
	t.c_cc[VMIN] = 1;
	t.c_cc[VTIME] = 0;
	tcsetattr(0, TCSANOW, &t);
}

static void
termrestore(void)
{
	tcsetattr(0, TCSANOW, &tinit);
}

void
cleanexit(int x)
{
	USED(x);

	if(up->intwait) {
		up->intwait = 0;
		return;
	}

	if(dflag == 0)
		termrestore();

	/*kill(0, SIGKILL);*/
	exit(0);
}

void
osreboot(char *file, char **argv)
{
	if(dflag == 0)
		termrestore();
	execvp(file, argv);
	error("reboot failure");
}

void
libinit(char *imod)
{
	struct sigaction act;
	struct passwd *pw;
	Proc *p;
	char sys[64];

	setsid();

	gethostname(sys, sizeof(sys));
	kstrdup(&ossysname, sys);
	pw = getpwnam("nobody");
	if(pw != nil) {
		uidnobody = pw->pw_uid;
		gidnobody = pw->pw_gid;
	}

	if(dflag == 0)
		termset();

	memset(&act, 0, sizeof(act));
	act.sa_handler = trapUSR1;
	sigaction(SIGUSR1, &act, nil);

	act.sa_handler = SIG_IGN;
	sigaction(SIGCHLD, &act, nil);

	/*
	 * For the correct functioning of devcmd in the
	 * face of exiting slaves
	 */
	signal(SIGPIPE, SIG_IGN);
	if(signal(SIGTERM, SIG_IGN) != SIG_IGN)
		signal(SIGTERM, cleanexit);
	if(signal(SIGINT, SIG_IGN) != SIG_IGN)
		signal(SIGINT, cleanexit);

	if(sflag == 0) {
		act.sa_flags = SA_SIGINFO;
		act.sa_sigaction = trapILL;
		sigaction(SIGILL, &act, nil);
		act.sa_sigaction = trapFPE;
		sigaction(SIGFPE, &act, nil);
		act.sa_sigaction = trapmemref;
		sigaction(SIGBUS, &act, nil);
		sigaction(SIGSEGV, &act, nil);
		act.sa_flags &= ~SA_SIGINFO;
	}

	p = newproc();
	kprocinit(p);

	pw = getpwuid(getuid());
	if(pw != nil)
		kstrdup(&eve, pw->pw_name);
	else
		print("cannot getpwuid\n");

	p->env->uid = getuid();
	p->env->gid = getgid();

	emuinit(imod);
}

int
readkbd(void)
{
	int n;
	char buf[1];

	n = read(0, buf, sizeof(buf));
	if(n < 0)
		print("keyboard close (n=%d, %s)\n", n, strerror(errno));
	if(n <= 0)
		pexit("keyboard thread", 0);

	switch(buf[0]) {
	case '\r':
		buf[0] = '\n';
		break;
	case DELETE:
		buf[0] = 'H' - '@';
		break;
	case CTRLC:
		cleanexit(0);
		break;
	}
	return buf[0];
}

static int
readkbdchar(int *cp, int timeoutms)
{
	int n;
	char ch;

	if(timeoutms >= 0){
		fd_set rd;
		struct timeval tv;

		FD_ZERO(&rd);
		FD_SET(0, &rd);
		tv.tv_sec = timeoutms/1000;
		tv.tv_usec = (timeoutms%1000)*1000;
		n = select(1, &rd, nil, nil, &tv);
		if(n <= 0)
			return 0;
	}

	n = read(0, &ch, sizeof(ch));
	if(n < 0){
		if(errno == EINTR)
			return 0;
		print("keyboard read error (n=%d, %s)\n", n, strerror(errno));
		pexit("keyboard thread", 0);
		return 0;
	}
	/* stdin EOF is a normal way for the keyboard thread to terminate */
	if(n <= 0)
		pexit("keyboard thread", 0);

	*cp = (uchar)ch;
	return 1;
}

static int
readkbdrune(int c0)
{
	int c, n;
	char buf[UTFmax];
	Rune r;

	buf[0] = c0;
	n = 1;
	while(n < UTFmax && !fullrune(buf, n)){
		if(!readkbdchar(&c, -1))
			return c0;
		buf[n++] = c;
	}
	/*
	 * If UTF decoding still fails here, treat it as malformed UTF-8 and
	 * fall back to the first byte rather than inventing a synthetic token.
	 */
	if(chartorune(&r, buf) <= 0)
		return c0;
	return r;
}

static int
parsecsikey(int lead)
{
	int c, i, n, num;
	char seq[32];

	seq[0] = lead;
	n = 1;
	while(n < (int)sizeof(seq)-1){
		if(!readkbdchar(&c, 25))
			break;
		seq[n++] = c;
		/* ECMA-48 CSI/SS3 final byte range */
		if(c >= '@' && c <= '~')
			break;
	}
	seq[n] = 0;

	if(lead == '['){
		switch(seq[n-1]){
		case 'A':
			return Up;
		case 'B':
			return Down;
		case 'C':
			return Right;
		case 'D':
			return Left;
		case 'F':
			return End;
		case 'H':
			return Home;
		case 'Z':
			return BackTab;
		case '~':
			num = 0;
			for(i = 1; i < n-1 && seq[i] >= '0' && seq[i] <= '9'; i++)
				num = num*10 + seq[i] - '0';
			switch(num){
			case 1:
			case 7:
				return Home;
			case 2:
				return Ins;
			case 3:
				return Del;
			case 4:
			case 8:
				return End;
			case 5:
				return Pgup;
			case 6:
				return Pgdown;
			case 15:
				return KF|5;
			case 17:
				return KF|6;
			case 18:
				return KF|7;
			case 19:
				return KF|8;
			case 20:
				return KF|9;
			case 21:
				return KF|10;
			case 23:
				return KF|11;
			case 24:
				return KF|12;
			}
			break;
		}
	}else if(lead == 'O'){
		switch(seq[1]){
		case 'A':
			return Up;
		case 'B':
			return Down;
		case 'C':
			return Right;
		case 'D':
			return Left;
		case 'F':
			return End;
		case 'H':
			return Home;
		case 'P':
			return KF|1;
		case 'Q':
			return KF|2;
		case 'R':
			return KF|3;
		case 'S':
			return KF|4;
		}
	}

	return No;
}

int
readekbd(void)
{
	int c, k;

	if(!readkbdchar(&c, -1))
		return -1;

	switch(c){
	case '\r':
		return '\n';
	case DELETE:
		return '\b';
	case CTRLC:
		cleanexit(0);
		return -1;
	case Esc:
		if(!readkbdchar(&c, 25))
			return Esc;
		if(c == '[' || c == 'O'){
			k = parsecsikey(c);
			if(k != No)
				return k;
			/*
			 * Treat unrecognised CSI/SS3 sequences as a bare Escape.
			 * Non-CSI ESC-prefixed input such as Alt+key combinations
			 * continues below into the APP|c path.
			 */
			return Esc;
		}
		if((c & 0x80) != 0)
			return readkbdrune(c);
		return APP | c;
	}

	if((c & 0x80) != 0)
		return readkbdrune(c);

	return c;
}

/*
 * Return an arbitrary millisecond clock time
 */
long
osmillisec(void)
{
	static long sec0 = 0, usec0;
	struct timeval t;

	if(gettimeofday(&t,(struct timezone*)0)<0)
		return 0;

	if(sec0 == 0) {
		sec0 = t.tv_sec;
		usec0 = t.tv_usec;
	}
	return (t.tv_sec-sec0)*1000+(t.tv_usec-usec0+500)/1000;
}

int
osconssize(char *buf, int n)
{
	struct winsize ws;
	int cols, rows;
	int ok;
	char *source;

	if(buf == nil || n <= 0)
		return -1;

	cols = 80;
	rows = 24;
	ok = 0;
	source = "fallback-linux";

	memset(&ws, 0, sizeof ws);

	if(ioctl(1, TIOCGWINSZ, &ws) == 0 && ws.ws_col > 0 && ws.ws_row > 0){
		cols = ws.ws_col;
		rows = ws.ws_row;
		ok = 1;
		source = "linux-ioctl-stdout";
	}else{
		memset(&ws, 0, sizeof ws);
		if(ioctl(0, TIOCGWINSZ, &ws) == 0 && ws.ws_col > 0 && ws.ws_row > 0){
			cols = ws.ws_col;
			rows = ws.ws_row;
			ok = 1;
			source = "linux-ioctl-stdin";
		}else{
			memset(&ws, 0, sizeof ws);
			if(ioctl(2, TIOCGWINSZ, &ws) == 0 && ws.ws_col > 0 && ws.ws_row > 0){
				cols = ws.ws_col;
				rows = ws.ws_row;
				ok = 1;
				source = "linux-ioctl-stderr";
			}
		}
	}

	if(cols <= 0)
		cols = 80;
	if(rows <= 0)
		rows = 24;

	return snprint(buf, n,
		"%d %d\n"
		"cols=%d\n"
		"rows=%d\n"
		"pixelwidth=%d\n"
		"pixelheight=%d\n"
		"source=%s\n"
		"ok=%d\n",
		cols, rows,
		cols, rows,
		(int)ws.ws_xpixel,
		(int)ws.ws_ypixel,
		source,
		ok);
}


/*
 * Return the time since the epoch in nanoseconds and microseconds
 * The epoch is defined at 1 Jan 1970
 */
vlong
osnsec(void)
{
	struct timeval t;

	gettimeofday(&t, nil);
	return (vlong)t.tv_sec*1000000000L + t.tv_usec*1000;
}

vlong
osusectime(void)
{
	struct timeval t;
 
	gettimeofday(&t, nil);
	return (vlong)t.tv_sec * 1000000 + t.tv_usec;
}

int
osmillisleep(ulong milsec)
{
	struct  timespec time;

	time.tv_sec = milsec/1000;
	time.tv_nsec= (milsec%1000)*1000000;
	nanosleep(&time, NULL);
	return 0;
}

int
limbosleep(ulong milsec)
{
	return osmillisleep(milsec);
}

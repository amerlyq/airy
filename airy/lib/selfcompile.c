#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include <sys/stat.h>
// #include <sys/types.h>
#include <sys/wait.h>

// SEE:DEV: http://code.metager.de/source/xref/gnu/coreutils/src/timeout.c

// #ifdef SRC_PATH
// static char const * const src_path = SRC_PATH;
// #else
// # error "specify -DSRC_PATH=... when compiling"
// #endif

// DEV: must be compiled into resulting .bin only
static char * const src_path = "/tmp";

extern int _main(int argc, char **argv);

static int
timestamp_cmp(char const * const s, char const * const d)
{
    struct stat sstat, dstat;
    if (stat(s, &sstat) == -1) {
        perror(s);
        _exit(127);
    }
    if (stat(d, &dstat) == -1) {
        perror(d);
        _exit(126);
    }
    // NOTE:(c11): statbuf.st_mtim.tv_sec/nsec is more accurate
    // OR also use .st_mtimensec  BET: st_mtim timespec subtract
    return sstat.st_mtime - dstat.st_mtime;
}

static pid_t
fork_cmd(char * const * const cmdv)
{
    int p = fork();

    if (p == -1) {
        perror("fork");
        _exit(1);
    }

    if (p == 0) {
        // TODO: restore sig masks for child
        // signal(SIGALRM, SIG_DFL);
        puts ("child: sleeping...");
        sleep (10);
        if (-1 == execvp(cmdv[0], cmdv)) {
            perror("child process execve failed [%m]");
            return -1;
        }
        puts ("child: exiting");
        _exit (0);
    }

    return p;
}


#define S1E9 1000000000L

// WARN: timespec must be signed
inline static void
ts_normalize(struct timespec * const t)
{
    if (t->tv_nsec >= S1E9 || t->tv_nsec <= -S1E9) {
        t->tv_sec += t->tv_nsec / S1E9;
        t->tv_nsec %= S1E9;
    }
    if (t->tv_nsec < 0) {
        t->tv_sec -= 1;
        t->tv_nsec += S1E9;
    }
}

inline static void
ts_positive(struct timespec * const t)
{
    if (t->tv_sec < 0) {
        t->tv_sec = 0;
        t->tv_nsec = 0;
    }
}

inline static void
ts_add(struct timespec * const t, struct timespec const * const s)
{
    t->tv_sec += s->tv_sec;
    t->tv_nsec += s->tv_nsec;
    ts_normalize(t);
}

inline static void
ts_sub(struct timespec * const t, struct timespec const * const s)
{
    t->tv_sec -= s->tv_sec;
    t->tv_nsec -= s->tv_nsec;
    ts_normalize(t);
}

inline static int
ts_cmp(struct timespec * const t, struct timespec * const s)
{
    return t->tv_sec < s->tv_sec ? -1 : t->tv_sec > s->tv_sec ? 1 :
        t->tv_nsec < s->tv_nsec ? -1 : t->tv_nsec > s->tv_nsec ? 1 : 0;
}

inline static void
timer_update(struct timespec * const beg, struct timespec * const t)
{
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);

    if (t) {
        // NOTE: reduce timer t by elapsed time
        ts_sub(t, &now);
        ts_add(t, beg);
        ts_positive(t);
    }

    beg->tv_sec = now.tv_sec;
    beg->tv_nsec = now.tv_nsec;
}

static int
wait_pid_timeout_ms(pid_t const pid, int const ms)
{
    // THINK: check for pid == 0 then err ?
    sigset_t mask, orig_mask;
    struct timespec tcur;
    struct timespec timeout = { ms / 1000, (ms % 1000) * 1000000 };

    sigemptyset(&mask);
    sigaddset(&mask, SIGCHLD);

    // FIND: remove sigprocmask in child SEE: timeout.c
    if (0 != sigprocmask(SIG_BLOCK, &mask, &orig_mask)) {
        perror("sigprocmask");
        return 1;
    }

    timer_update(&tcur, NULL);

    while (0 > sigtimedwait(&mask, NULL, &timeout)) {
        switch (errno) {
        case EINTR:  // Interrupted by a signal other than SIGCHLD.
            timer_update(&tcur, &timeout);  // wait rest of timeout
            continue;
        case EAGAIN:  // WARN: racing if pr exits between sigtimedwait and here
            perror("timeout");
            if (-1 == kill(pid, SIGTERM)) {
                perror("kill");
            } else {
                sleep(5);
                kill(pid, SIGKILL);
            }
            return -1;
        default:
            perror("sigtimedwait");
            return 1;
        }
    }

    int status = -1;
    if (0 > waitpid(pid, &status, WNOHANG)) {
        perror ("waitpid");
        return 1;
    }

    if (1 != WIFEXITED(status) || 0 != WEXITSTATUS(status)) {
        perror("%s failed, halt system");
        return -1;
    }

    return 0;
}

int
main(int argc, char **argv)  // , char **envp
{
    // NOTE: ctrl args are allowed only as first/last ones (easy to discard)
    if (argc > 1 && !strcmp(argv[1], "-no-rebuild")) {
        argv[1] = argv[0];
        --argc, ++argv;
        return _main(argc, argv);
    }
    // WARN: changes saved during compilation won't trigger rebuild
    //  ALT: use -cmp-hash (slow) ?
    if (!timestamp_cmp(src_path, argv[0])) {
        char * cmdv[] = { "r.airy-compile-src", src_path, NULL };
        pid_t pid = fork_cmd(cmdv);
        // timeout = strtof (argv[1], NULL);
        // BET: call two times strtod (w/o exp if possible)
        wait_pid_timeout_ms(pid, 5000);
        execvp(argv[0], argv);
    }
    return _main(argc, argv);
}

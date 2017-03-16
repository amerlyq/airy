#include <errno.h>
#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <sys/wait.h>

#define E_SHIFT  100
#define E_LOGICAL -1
#define E_TIMEOUT -3
#define E_SYSFAIL -5
#define E_IMPSBLE -9

#define S1E9 1000000000L
#define KILL_AFTER 5

static void
ts_set(struct timespec * const t, __time_t sec, __syscall_slong_t nsec)
{
    if (nsec >= S1E9 || nsec <= -S1E9) {
        sec += nsec / S1E9;
        nsec %= S1E9;
    }
    if (nsec < 0) {
        sec -= 1;
        nsec += S1E9;
    }
    if (sec < 0) {
        sec = 0;
        nsec = 0;
    }
    t->tv_sec = sec;
    t->tv_nsec = nsec;
}

static int
timer_update(struct timespec * const t, struct timespec * const prev)
{
    struct timespec now;
    if (0 != clock_gettime(CLOCK_MONOTONIC, &now)) {
        perror("clock_gettime");
        return E_SYSFAIL;
    }
    // NOTE: reduce timer t by elapsed time
    if (t)
        ts_set(t, t->tv_sec - (now.tv_sec - prev->tv_sec),
               t->tv_nsec - (now.tv_nsec - prev->tv_nsec));

    ts_set(prev, now.tv_sec, now.tv_nsec);
    return 0;
}

static pid_t
fork_cmd(char * const * const argv)
{
    pid_t p = fork();

    if (p > 0)
        return p;

    if (p < 0) {
        perror("fork");
        return p;
    }

    // TODO: restore sig masks for child
    // signal(SIGALRM, SIG_DFL);
    if (-1 == execvp(argv[0], argv)) {
        perror(argv[0]);
        return E_SYSFAIL;
    }
    return E_IMPSBLE;  // must be unreachable
}

static int
wait_pid_timeout(pid_t const pid, float const sec)
{
    // THINK: check for pid == 0 then err ?
    int sig = SIGTERM;

    struct timespec tcur, timeout;
    ts_set(&timeout, sec, (sec - (int)sec) * S1E9);
    if (0 != timer_update(NULL, &tcur))
        return E_SYSFAIL;

    sigset_t mask;
    sigemptyset(&mask);
    sigaddset(&mask, SIGCHLD);

    // FIND: remove sigprocmask in child SEE: timeout.c
    if (0 != sigprocmask(SIG_BLOCK, &mask, NULL)) {
        perror("sigprocmask");
        return E_SYSFAIL;
    }

    while (0 > sigtimedwait(&mask, NULL, &timeout)) {
        switch (errno) {
        case EINTR:  // Interrupted by a signal other than SIGCHLD.
            // if (0 == pid)
            //     signal(sig, SIG_IGN);
            // if (0 == kill(pid, sig))
            //     return E_IMPSBLE;
            if (0 != timer_update(&timeout, &tcur))  // wait rest of timeout
                return E_SYSFAIL;
        break;
        case EAGAIN:  // WARN: racing if pr exits between sigtimedwait and here
            if (0 == kill(pid, sig))
                return E_TIMEOUT;  // OK, timeout
            perror("kill");
            if (SIGKILL == sig)
                return E_IMPSBLE;
            // if term don't work, wait and hard kill
            sig = SIGKILL;
            ts_set(&timeout, KILL_AFTER, 0);
        break;
        default:
            perror("sigtimedwait");
            return E_IMPSBLE;
        }
    }

    int status = E_IMPSBLE;
    if (0 > waitpid(pid, &status, WNOHANG)) {
        perror ("waitpid");
        return E_SYSFAIL;
    }
    if (1 != WIFEXITED(status)) {
        perror("%s child exit failed, halt system");
        return E_IMPSBLE;
    }
    return WEXITSTATUS(status);
}

int run_timeout(char * const * const argv, float timeout)
{
    pid_t p = fork_cmd(argv);
    if (p <= 0)
        return p;
    return wait_pid_timeout(p, timeout);
}

// NEED: kill childs when dtimeout is killed
//  CHECK:(install_signal_handlers): http://code.metager.de/source/xref/gnu/coreutils/src/timeout.c
//  http://stackoverflow.com/questions/284325/how-to-make-child-process-die-after-parent-exits

#ifndef BUILD_LIB
#include <stdlib.h>
int main(int argc, char **argv)
{
    if (argc < 3)
        return E_SHIFT + (-E_LOGICAL);
    // setlocale (LC_ALL, "");
    int r = run_timeout(argv + 2, strtof(argv[1], NULL));
    return r >= 0 ? r : (E_TIMEOUT == r) ? E_SHIFT : E_SHIFT + (-r);
}
#endif

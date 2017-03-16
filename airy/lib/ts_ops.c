#include <time.h>

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

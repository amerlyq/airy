#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/wait.h>

// NOTE: must be linked into resulting .bin
extern char src_path[] asm ("_binary_src_path_start");
// FIXME: for this to work, 'compile-src' must extract DFL path from profile
static char * const recompile_cmdv[] = {
    "timeout", "5", "r.airy-compile-src", "-qc", src_path, NULL };
extern int _main(int argc, char **argv);

static int
timestamp_cmp(char const * const s, char const * const d)
{
    struct stat ss, ds;
    if (stat(s, &ss) == -1) {
        perror(s);
        _exit(127);
    }
    if (stat(d, &ds) == -1) {
        perror(d);
        _exit(126);
    }
    // ALT:(no st_mtim): .st_mtime and .st_mtimensec
    return ss.st_mtim.tv_sec < ds.st_mtim.tv_sec ? -1
        : ss.st_mtim.tv_sec > ds.st_mtim.tv_sec ? 1
        : ss.st_mtim.tv_nsec < ds.st_mtim.tv_nsec ? -1
        : ss.st_mtim.tv_nsec > ds.st_mtim.tv_nsec ? 1 : 0;
}

static int
run_cmd(char * const * const argv)
{
    pid_t p = fork();
    if (p == 0) {  // child
        execvp(argv[0], argv);
    } else if (p > 0) {  // main
        int status = -1;
        if (0 <= waitpid(p, &status, 0) && 1 == WIFEXITED(status))
            return WEXITSTATUS(status);
    }
    perror("run_cmd");
    _exit(9);
}

int
main(int argc, char **argv)  // , char **envp
{
    // NOTE: parse all ctrl args at beg (or end -- easy to discard)
    while (argc > 1) {
        if (!strcmp(argv[1], "-src-path")) {
            printf("%s\n", src_path);
            return 0;
        } else if (!strcmp(argv[1], "-no-rebuild")) {
            return _main(argc, argv);
        } else
            break;
        --argc, argv[1] = *argv++;
    }

    // WARN: rebuild won't be triggered
    //  * changes saved directly during compilation
    //      ALT:(slow): -cmp-hash and func_ptr
    //  * updated static libs  ALT:(slow): use make
    if (0 < timestamp_cmp(src_path, argv[0])) {
        if (0 != run_cmd(recompile_cmdv))
            return 99;
        execvp(argv[0], argv);
        _exit(9);
    }
    return _main(argc, argv);
}

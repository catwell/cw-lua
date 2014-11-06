#include "usual.h"

#define MSG "hello world\n"

int main(int argc, char **argv) {

    int p[2];
    int err;

    err = pipe(p); assert(!err);
    pid_t pid = fork(); assert(pid >= 0);

    if (pid) { /* parent */
        err = close(p[0]); assert(!err);
        size_t len = strlen(MSG);
        ssize_t sz = write(p[1], MSG, len);
        assert(sz == len);
        err = close(p[1]); assert(!err);
    }
    else { /* child */
        assert(!(close(STDIN_FILENO) || dup(p[0])));
        assert(!(close(p[0]) || close(p[1])));
        char* _argv[2] = {"wc", NULL};
        execv("/bin/wc", _argv); assert(0);
    }

    return EXIT_SUCCESS;
}

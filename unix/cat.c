#include "usual.h"

#define CHUNK_SZ 512

int main(int argc, char **argv) {

    char buf[CHUNK_SZ];
    int r, w;

    for(;;) {
        r = read(STDIN_FILENO, buf, sizeof(buf));
        if (r == 0) break;
        assert (r > 0);
        w = write(STDOUT_FILENO, buf, r);
        assert (w == r);
    }

    return EXIT_SUCCESS;
}

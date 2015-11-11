#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <pthread.h>
#include <errno.h>
#include <sys/socket.h>

int fd[2];

void * reader(void* arg)
{
    int err;
    fd_set readset;
    char x;

    for (;;) {

        do {
           FD_ZERO(&readset);
           FD_SET(fd[0], &readset);
           err = select(fd[0] + 1, &readset, NULL, NULL, NULL);
           printf("x\n");
        } while (err == -1 && errno == EINTR);

        if (err < 0) {
            perror("select");
            exit(1);
        }

       if (FD_ISSET(fd[0], &readset)) {
          err = read(fd[0], &x, 1);
          if (err == 0) {
             close(fd[0]);
             exit(1);
          }
          else if (err != 1) {
            perror("recv");
            exit(1);
          }
          else {
             printf("%c\n", x);
             if (x == 'e') return NULL;
          }
       }

    }
}

int main()
{
    pthread_t th;

    if (pipe(fd) < 0) {
        perror("pipe");
        exit(1);
    }

    if (pipe(fd) < 0){
       perror("pipe ");
       exit(1);
    }

    pthread_create(&th ,NULL, reader, NULL);

    char x;
    for (x='a'; x <= 'e'; x++) {
        if (write (fd[1], &x, 1) != 1) {
            perror ("write");
            exit(1);
        }
        sleep(1);
    }

    pthread_join(th, NULL);
}

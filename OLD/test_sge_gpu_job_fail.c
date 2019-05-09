#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

/* Allocate a user-specified amount of memory (in MiB) 
 * after sleeping for 60s */
int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Usage: %s <MB-to-allocate>\n", argv[0]);
        return 1;
    }

    int *p;
    int mb_to_alloc = atoi(argv[1]);
    sleep(60);
    
    printf("Trying to allocate %d MB of memory...", mb_to_alloc);
    p = calloc(mb_to_alloc, 1024 * 1024);

    if (! p) {
        printf("failed!\n");
        return 1;
    } else {
        printf("succeeded!\n");
        return 1;
    }
}

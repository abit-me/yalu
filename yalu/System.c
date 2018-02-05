//
//  System.c
//  yalu
//
//  Created by A on 2018/2/5.
//  Copyright © 2018年 A. All rights reserved.
//

#include "System.h"
#include <stdlib.h>
#include <string.h>
#include <spawn.h>

int my_system(const char *cmd, char * params[])
{
    const int maxparams = 512;
    
    // argv
    char * argv[maxparams];
    memset(argv, 0, sizeof(argv));
    argv[0] = (char *)cmd;
    
    char ** p = params;
    int i = 0;
    for (i = 0; (p != NULL) && (*p != NULL); ++i, ++p) {
        printf("argv i: %d == %s\n", i, *p);
        argv[i+1] = *p;
    }
    if (i >= maxparams) {
        printf("my_system params beyond maxparams");
        return 1;
    }
    
    // envp
    char * path_env = getenv("PATH");
    char * cp_env = strdup(path_env);
    
    char * envp[maxparams];
    memset(envp, 0, sizeof(envp));
    char * token = NULL;
    i = 0;
    while ((token = strsep(&cp_env, ":")) != NULL) {
        //printf("PATH: %s\n", token);
        envp[i] = token;
        ++i;
    }
    if (i >= maxparams) {
        printf("my_system envp beyond maxparams");
        return 2;
    }
    
    // spawn
    pid_t pid;
    posix_spawnattr_t attr;
    posix_spawn_file_actions_t fact;
    posix_spawnattr_init(&attr);
    posix_spawn_file_actions_init(&fact);
    posix_spawn(&pid, cmd, &fact, &attr, argv, envp);
    
    int stat = 0;
    waitpid(pid, &stat, 0);
    return stat;
}

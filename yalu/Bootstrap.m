//
//  Bootstrap.m
//  yalu
//
//  Created by A on 2018/1/22.
//  Copyright © 2018年 A. All rights reserved.
//

#import "Bootstrap.h"
#import <sys/mount.h>
#import <spawn.h>
#import <copyfile.h>
#import <mach-o/dyld.h>
#import <sys/types.h>
#import <sys/stat.h>
#import <sys/utsname.h>

//@implementation Bootstrap
//
//@end

void kill_sb() {
    
    char *killall_argv[] = {"/usr/bin/killall", "-9", "SpringBoard", NULL};
    
    pid_t killall_pid = 0;
    posix_spawn(&killall_pid, "/usr/bin/killall", 0, 0, (char **)killall_argv, 0);
    waitpid(killall_pid, 0, 0);
    NSLog(@"kill sb...");
}

int my_system(const char *cmd, char * params[])
{
    pid_t pid;
    posix_spawnattr_t x;
    posix_spawn_file_actions_t y;
    
    char * argv[512];
    memset(argv, 0, sizeof(argv));
    argv[0] = (char *)cmd;
    
    char ** p = params;
    for (int i = 0; *p != NULL; ++i, ++p) {
        //printf("i: %d == %s\n", i, *p);
        argv[i+1] = *p;
    }
    char * path_env = getenv("PATH");
    char * cp_env = strdup(path_env);
    
    char * envp[512];
    memset(envp, 0, sizeof(envp));
    char * token = NULL;
    int i = 0;
    while ((token = strsep(&cp_env, ":")) != NULL) {
        //printf("token: %s\n", token);
        envp[i] = token;
        ++i;
    }
    
    posix_spawnattr_init(&x);
    posix_spawn_file_actions_init(&y);
    posix_spawn(&pid, cmd, &y, &x, argv, envp);
    
    int stat = 0;
    waitpid(pid, &stat, 0);
    return stat;
}

bool file_exist(const char *path) {
    
    if((access(path, F_OK)) != -1) {
        return true;
    } else {
        return false;
    }
}

bool copyed_bootstrap() {
    return file_exist("/usr/local/bin/scp");
}

void copy_bootstrap() {
    
    char path[256];
    uint32_t size = sizeof(path);
    _NSGetExecutablePath(path, &size);
    char* pt = realpath(path, 0);

    NSString* execpath = [[NSString stringWithUTF8String:pt] stringByDeletingLastPathComponent];
    NSString* tar = [execpath stringByAppendingPathComponent:@"tar"];
    NSString* bootstrap = [execpath stringByAppendingPathComponent:@"bootstrap.tar"];
    const char* jl = [tar UTF8String];

    unlink("/bin/tar");
    copyfile(jl, "/bin/tar", 0, COPYFILE_ALL);
    chmod("/bin/tar", 0777);
    jl = "/bin/tar";

    chdir("/");

    // -p, --preserve-permissions, --same-permissions extract information about file permissions(default for superuser)
    // --no-overwrite-dir preserve metadata of existing directories
    char **argv = (char**)&(const char*[]){jl, "--preserve-permissions", "--no-overwrite-dir", "-xvf", [bootstrap UTF8String], NULL};
    pid_t copy_pid = 0;
    posix_spawn(&copy_pid, jl, 0, 0, argv, NULL);
    waitpid(copy_pid, 0, 0);
    NSLog(@"copy bootstap...");

    pid_t uicache_pid = 0;
    posix_spawn(&uicache_pid, "/usr/bin/uicache", 0, 0, 0, 0);
    waitpid(uicache_pid, 0, 0);

    NSLog(@"uicache...");

    NSString* jlaunchctl = [execpath stringByAppendingPathComponent:@"launchctl"];
    jl = [jlaunchctl UTF8String];

    unlink("/bin/launchctl");
    copyfile(jl, "/bin/launchctl", 0, COPYFILE_ALL);
    chmod("/bin/launchctl", 0755);

    my_system("/bin/echo", (char *[]){"'127.0.0.1 iphonesubmissions.apple.com'", ">>", "/etc/hosts", NULL});
    my_system("/bin/echo", (char *[]){"'127.0.0.1 radarsubmissions.apple.com'", ">>", "/etc/hosts", NULL});

    my_system("/usr/bin/killall", (char *[]){"-SIGSTOP", "cfprefsd", NULL});
    NSMutableDictionary* md = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.springboard.plist"];
    [md setObject:[NSNumber numberWithBool:YES] forKey:@"SBShowNonDefaultSystemApps"];
    [md writeToFile:@"/var/mobile/Library/Preferences/com.apple.springboard.plist" atomically:YES];
    my_system("/usr/bin/killall", (char *[]){"-SIGSTOP", "cfprefsd", NULL});

    NSString* reload = [execpath stringByAppendingPathComponent:@"reload"];
    unlink("/usr/libexec/reload");
    copyfile([reload UTF8String], "/usr/libexec/reload", 0, COPYFILE_ALL);

    chmod("/usr/libexec/reload", 0755);
    chown("/usr/libexec/reload", 0, 0);
    chmod("/Library/LaunchDaemons/0.reload.plist", 0644);
    chown("/Library/LaunchDaemons/0.reload.plist", 0, 0);
    chmod("/Library/LaunchDaemons/dropbear.plist", 0644);
    chown("/Library/LaunchDaemons/dropbear.plist", 0, 0);
    unlink("/System/Library/LaunchDaemons/com.apple.mobile.softwareupdated.plist");
}

void run_bootstrap() {
    
    chmod("/private", 0777);
    chmod("/private/var", 0777);
    chmod("/private/var/mobile", 0777);
    chmod("/private/var/mobile/Library", 0777);
    chmod("/private/var/mobile/Library/Preferences", 0777);
    
    remove("/var/MobileAsset/Assets/com_apple_MobileAsset_SoftwareUpdate");
    open("/var/MobileAsset/Assets/com_apple_MobileAsset_SoftwareUpdate", O_CREAT | O_TRUNC | O_WRONLY, 000);
    chown("/var/MobileAsset/Assets/com_apple_MobileAsset_SoftwareUpdate", 0, 0);
    
    my_system("/bin/launchctl", (char *[]){"load", "/Library/LaunchDaemons/0.reload.plist", NULL});
}

void fixSubstrate() {
    
    uid_t uid = getuid();
    NSLog(@"uid: %d", uid);
    setuid(0);
    NSLog(@"uid2: %d", uid);
    int stat = 0;
    stat = my_system("/usr/libexec/substrate", NULL);
    if (stat != 0) {
        NSLog(@"/usr/libexec/substrate failed");
    }
    stat = my_system("killall", (char *[]){"-9", "SpringBoard", NULL});
    if (stat != 0) {
        NSLog(@"killall -9 SpringBoard failed", NULL);
    }
}

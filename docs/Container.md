# `pot` as *container*

## Introduction

A *container* is a method to package an application so it can be run, with its dependencies, isolated from other processes. The goal is to focus on one process only.

`pot` can be used to run containers, imitating the behavior of other containerization technologies, like Docker.

Containers are like *thick* jails, with a couple of additional configuration, to modify the standard behavior.

## Create the `pot`
First of all, a *thick* jail `pot` is needed:
```console
# pot create -p box -b 12.1 -t single [-f fbsd-update]
```

By default, jails start with the command `/bin/sh /etc/rc` to initialize the FreeBSD system and spawn a bunch of services in background.

However, a container, usually, runs directly the command that is needed. To change the starting command, we can use:
```console
# pot set-cmd -p box -c '/bin/echo Hello Cookware'
# pot start box
===>  Starting the pot box
Hello Cookware
# pot stop box
```
### Not returning commands
Usually, the initial commands for jail terminates. The `/bin/sh /etc/rc` will start all services in background and, when it's over, will return the control to the `jail(8)` command that re-takes control.

Typically, in containers the initial command is not forking in background (for example, as in the nginx docker image, as explained [here](https://hub.docker.com/_/nginx/)). For example:

```console
# pot create -p blocking-box -12.1 -t single -N public-bridge
# pot run blocking-box
blocking-box# pkg install nginx
blocking-box# exit
# pot stop blocking-box
# pot set-cmd -p blocking-box -c "/usr/local/sbin/nginx -g 'daemon off;'"
# pot set-attr -p blocking-box -A no-rc-script -V True
# pot start blocking-box
===>  Starting the pot blocking-box
add net default: gateway 10.192.0.1
^T
load: 0.14  cmd: nginx 3723 [kqread] 43.40r 0.00u 0.00s 0% 7468k
^C
#
```
## Container oriented attributes

### `no-rc-script` attribute
The role of the initial `rc` script is dual: initialize the FreeBSD jail and spawn services.

Changing the initial command to something else will prevent additional services to be started, but also the initialization of FreeBSD inside the jail, for instance to apply the network configuration. This attribute can be used to inform `pot` that the initialization is not performed by the `rc` script.

```console
# pot set-attr -p box -A no-rc-script -V ON
```

This attribute has to be used with custom commands for network types that uses bridges.

### `persistent` attribute
By default, all jails are persistent, meaning that the jail environment will exists even if no processes are running in it.

```console
# pot start box
===>  Starting the pot box
Hello Cookware
# pot top -p box
last pid:  7986;  load averages:  1.74,  1.55,  1.21; battery: 43%                                              up 0+03:58:57  23:03:35
85 processes:  2 running, 83 sleeping
CPU: 14.8% user,  0.0% nice,  5.0% system,  0.1% interrupt, 80.1% idle
Mem: 1651M Active, 3326M Inact, 310M Laundry, 3677M Wired, 4809M Free
ARC: 2406M Total, 750M MFU, 1544M MRU, 1180K Anon, 20M Header, 91M Other
     1823M Compressed, 3106M Uncompressed, 1.70:1 Ratio
Swap: 4096M Total, 4096M Free

  PID   JID USERNAME    THR PRI NICE   SIZE    RES STATE    C   TIME    WCPU COMMAND

# pot stop box
```
The jail is still there, but it's empty, the initial command terminated.

To automatically let the jail be destroyed when no processes are running, the `persistent` attribute can be used:
```console
# pot set-attr -p box -A persistent -V False
# pot start box
===>  Starting the pot box
Hello Cookware
# pot top -p box
###>  pot box is not in execution
```

!!! warning
    Only the jail disappear automatically, everything else, like redirection rules, IP aliases, mounted filesystems, won't be cleaned up. For this reason, it's best practice to use `pot stop box` also for not persistent jails.
	Also stop hooks won't be automatically executed.

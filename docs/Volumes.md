# Copy and mount folders in a `pot`

In this section we explore all features available to *mount* a folder or a ZFS dataset or to copy files or directories from the host to a `pot`

## Copy in a pot

`pot` supports a command to copy directories or files inside a `pot`

The copy happens when the command is executed and only at that time. `copy-in` is not a configuration parameter of a `pot`, it's just a command that copy things over.

### Copy a file

Copying a single file in a `pot` is very straightforward:
```console
# pot copy-in -p casserole -s myfile -d /var/tmp
```

With this command, the file `myfile` is copied in `/var/tmp` of the `pot` `casserole`.

!!! note
    This command supports single file only. No glob or regular expression can be used

### Copy a directory

Copying a directory is also very straightforward:
```console
# pot copy-in -p casserole -s mydir -d /var/tmp
```
With this command, the directory `mydir` (and all its content) is copied in `/var/tmp`, creating the directory `/var/tmp/mydir`.

## Mount in a pot

`pot` supports several mount options. In particular, three different types of *things* can be mounted:

* a generic directory
* a ZFS dataset
* a `fscomp`

`pot` provides the `mount-in` command to specify what has to be mounted, how and where.

If the `pot` is already running, the mount will occur on the fly. If the `pot` is not running, the element will be mounted at start.

The `mount-in` command will change the `pot` configuration. Every time the `pot` start, the element will be mounted at start and unmounted at stop.

To check what will be mounted in a `pot`, the following command will show:
```console
# pot info -v -p casserole
```
The `-v` flag is relevant to show the `dataset` section, where the mounts are listed.

### Generic directory
A directory can be mounted in an existing `pot` via the command:
```console
# pot mount-in -p casserole -m /mnt -d mydir
```
where:

* `-p casserole` : the name of the `pot`
* `-m /mnt` : the mountpoint inside the `pot`
* `-d mydir` : the directory to be mounted

By default, the mount is implemented via `nullfs(5)` and in read/write mode.

To mount in read-only mode, the flag `-r` can be used.

### ZFS dataset
A ZFS dataset can be mounted in an existing `pot` via the command:
```console
# pot mount-in -p casserole -m /mnt -z zroot/mydataset
```
where:

* `-p casserole` : the name of the `pot`
* `-m /mnt` : the mountpoint inside the `pot`
* `-z zroot/mydataset` : the ZFS dataset to be mounted

By default, the mount is implemented via `nullfs(5)` and in read/write mode.

To mount in read-only mode, the flag `-r` can be used.

If the ZFS dataset is used only by one `pot` and the performance penalty introduced by `nullfs(5)` is undesired, the flag `-w` can be used. This flag will change the mountpoint of the ZFS dataset to be inside the pot.

### `fscomp`
To support users managing additional ZFS datasets for `pot`, the concept of `fscomp` (AKA file system component) has been introduced.

A `fscomp` is just a ZFS dataset, but it can be convenient to use for users that are not familiar with ZFS, because `pot` already provides some commands (snapshot, rollback, clone) to manage those ZFS dataset. However, an experienced user would probably prefer to manage ZFS datasets independently.

To use a `fscomp`, it has first to be created:
```console
# pot create-fscomp -f myfscomp
```
This command creates an empty ZFS dataset, a *volume*, that can be attached to one or more `pot`s.

The list of available `fscomp`s can be obtained with the command:
```console
# pot ls -f
```

Finally, a `fscomp` can be mounted in a `pot` with the command:
```console
# pot mount-in -p casserole -f myfscomp -m /mnt
```
where:

* `-p casserole` : the name of the `pot`
* `-m /mnt` : the mountpoint inside the `pot`
* `-f myfscomp` : the `fscomp` to be mounted

By default, the mount is implemented via `nullfs(5)` and in read/write mode.

To mount in read-only mode, the flag `-r` can be used.

The `fscomp` is a ZFS dataset, hence the `-w` flag can be used to avoid `nullfs(5)` overhead, by changing the mountpoint of the dataset. This feature, however, make sense if the `fscomp` is used only by one `pot` at a time.


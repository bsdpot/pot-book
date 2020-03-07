# Snapshot and rollback of a `pot`

In this section we explore all features related to snapshot and rollback.

## Take a snapshot of your `pot`
Thanks to ZFS, taking a snapshot of a `pot` is easy and super fast. Currently, it is not allowed to take a snapshot of `pot` that is running. 

The syntax of the snapshot command is the same for a thin or a thick jail (`single` or `multi` type `pot`). However, the operations performed and the meaning is slightly different.

The snapshot name is always a number, that is the [UNIX epoch time](https://en.wikipedia.org/wiki/Unix_time) when the snapshot is taken.

??? note "Unix time monotony"
    UNIX time is used to desume the chronological order of snapshots. Many operations, like *rollback* and snapshot rotations depends on this assumption.

Let's take a snapshot of a `single` type `pot`:
```console
# pot stop casserole
# pot snap -p casserole
# pot info -v -p casserole
[..]
	datasets:
		casserole/m
	snapshot:
		zroot/pot/jails/casserole@1583601150
		zroot/pot/jails/casserole/m@1583601150
```

??? note "snap or snapshot?"
    The command `snapshot` can be also invoked using the abbreviated form `snap`. Those two forms are fully equivalent, `snap` is just an *alias* of `snapshot`

It's possible to notice, that two datasets are considered: the main dataset and the filesystem dataset.

Let's take a snapshot of a `multi` type `pot`:
```console
# pot stop saucepan
# pot snap -p saucepan
# pot info -v -p saucepan
[..]
	datasets:
		saucepan/m => bases/12.1
		saucepan/m/usr/local => jails/saucepan/usr.local
		saucepan/m/opt/custom => jails/saucepan/custom
	snapshots:
		zroot/pot/jails/saucepan@1583601687
		zroot/pot/jails/saucepan/custom@1583601687
		zroot/pot/jails/saucepan/usr.local@1583601687

```

When a snapshot of a `pot` is taken, a snapshot of all datasets that belongs to the `pot` is taken. The *base* of a thin jail doesn't belong to the `pot`, so a snapshot of the *base* is not taken. 

## Rollback
If a snapshot of a `pot` is available, a rollback can be performed. Currently, it is not allowed to rollback a snapshot of a `pot` that is running.

The syntax of the rollback command is the same for a think or a thick jail (`single` or `mutli` type `pot`). However, like for snapshots, the operations performed are slightly different.

Just for fun (and to prove that snapshot/rollback are really useful), some damage can be done to a `pot` (those steps are optional):
```console
# pot run casserole
root@casserole:~ # rm -rf /*
[..]
root@casserole:~ # exit
# pot stop mypot
```
Almost every file has been deleted and the `pot` cannot start anymore. But no panic, we have a snapshot:
```console
# pot revert -p casserole
# pot run casserole
root@casserole:~ # exit
```
The revert command automatically selects the latest snapshot available.

??? note "revert or rollback?"
    The command `revert` can be also invoked using the alternative form `rollback`. Those two forms are fully equivalent, `rollback` is just an *alias* of `revert`

## Remove old snapshots
Snapshots are great, they can be used for backup/rollback or to [export `pot`](Thick.md#export-a-pot-as-image). However, snapshots use disk spaces and too many snapshots can fill up disk space.

`pot` provides two mechanism to keep the number of snapshot under control: an option to rotate snapshots and a command to remove old snapshots.

### Snapshots rotation
In general, it's always possible to take other snapshots, even if nothing is changed:
```console
# pot stop casserole
# pot snap -p casserole
# pot info -v -p casserole
[..]
	datasets:
		casserole/m
	snapshot:
		zroot/pot/jails/casserole@1583601150
		zroot/pot/jails/casserole@1583617777
		zroot/pot/jails/casserole/m@1583601150
		zroot/pot/jails/casserole/m@1583617777
```

A way to keep the same number of snapshots, is to use the `-r` flag in the snapshot command:
```console
# pot snap -p casserole -r
# pot info -v -p casserole
[..]
	datasets:
		casserole/m
	snapshot:
		zroot/pot/jails/casserole@1583617777
		zroot/pot/jails/casserole@1583617881
		zroot/pot/jails/casserole/m@1583617777
		zroot/pot/jails/casserole/m@1583617881
```

From the snapshot epoch, it's possible to notice that the oldest snapshot (**1583601150**) has been removed and a new one (**1583617881**) has taken its place.

### Snapshot purge
The command purge-snapshots has been designed to remove old snapshots and keep only the last one:

```console
# pot info -v -p casserole
[..]
	datasets:
		casserole/m
	snapshot:
		zroot/pot/jails/casserole@1583617777
		zroot/pot/jails/casserole@1583617881
		zroot/pot/jails/casserole/m@1583617777
		zroot/pot/jails/casserole/m@1583617881
# pot purge-snapshots -p casserole
# pot info -v -p casserole
[..]
	datasets:
		casserole/m
	snapshot:
		zroot/pot/jails/casserole@1583617881
		zroot/pot/jails/casserole/m@1583617881
```

An additional flag, `-a`, allows to remove all snapshots, the last one included:
```console
# pot purge-snapshots -p casserole -a
# pot info -v -p casserole
[..]
	datasets:
		casserole/m
	snapshot:
		no snapshots
```

## Snapshot and rollback of a `fscomp`
`fscomp` is a ZFS dataset, managed by the `pot` framework and explained in the [section about volumes](Volumes.md).

All the commands that manipulate `pot` snapshots, have been extended to manipulate `fscomp` snapshots as well:
```console
# pot create-fscomp -f lid
# pot info -v -f lid 
not yet implemented
# pot snapshot -f lid # take a snapshot
# pot rollback -f lid # revert to the last snapshot
# pot purge-snapshots -a -f lid # delete all snapshot
```

A snapshot of a `fscomp` can be taken even if a `pot` is using it. The responsibility of the consistency of the data contained in the `fscomp` is upon the user.

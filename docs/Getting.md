# Getting started with `pot`

For this guide, we assume that you have a FreeBSD 12+ machine, with a ZFS pool available.

!!! note
    ZFS is mandatory, so if you don't know what it is or you don't have a ZFS pool, please consider to read this [quick guide](https://www.freebsd.org/doc/handbook/zfs-quickstart.html).

## Install `pot`
`pot` is available as package or port. The suggested way is to install it using the packages:
```console
# pkg install -y pot
```

## Enable the resource accounting
The resource accounting, even if not mandatory for `pot` to run, is a suggested FreeBSD feature that can be used. This feature is still disabled by default on FreeBSD 12.x, and it can be enabled only at boot time.  
To do so:
```console
# echo kern.racct.enable=1 >> /boot/loader.conf
# reboot
```

!!! note
    This settings will take effect ONLY after the next reboot.

#### Known issue
We have found a performance issue with the `vtnet` driver.
If you are installing `pot` on a VM using `vtnet`, probably you want to add this line to your `/boot/loader.conf`:
```console
# echo hw.vtnet.lro_disable=1 >> /boot/loader.conf
```

!!! note
    This settings will take effect ONLY after the next reboot.

## `pot` framework configuration

Under the folder `/usr/local/etc/pot` you'll find the files `pot.conf`.  
The file configuration file has comments to with default values and explanations.

However,  it's important to check if few defaults are compatible with your system:

- `POT_ZFS_ROOT` : the name of the the dataset where to put all `pot`s (it will be created later)
- `POT_FS_ROOT` : the mountpoint fo the `POT_ZFS_ROOT`
- `POT_EXTIF` : the network interface
- `POT_NETWORK` : the IPv4 network that will be used for internal communication only (it must not overlap with your network setup)
- `POT_GATEWAY` : an address consistent with the internal IPv4 network 

For instance, as an example, those are alternative values that someone can use:
```sh
POT_ZFS_ROOT=zroot/potpool
POT_FS_ROOT=/var/potjails
POT_EXTIF=wlan0
POT_NETWORK=192.168.0.0/16
POT_GATEWAY=192.168.0.1
```
#### Network validation
If you want to run a naive check on the network side of your configuration, you can run:

```console
# potnet config-check -v
```

## Initialize the environment
When the configuration file is ready, you can now run the initialization.

!!! note
    If you are already using `pf`, I suggest to make a backup of you `pf` configuration file.

To initialize, run the command (use the flag `-v` if you want a bit more of verbosity):
```console
# cp /etc/pf.conf /etc/pf.conf.bak
# pot init -v
```
## Create a simple `pot`
We can now create the simplest `pot`
```console
# pot create -p mypot -t single -b 12.1
```

This command creates a `pot` named `mypot` based on FreeBSD 12.1 using one ZFS dataset (thick jail).

Now you can start/stop it, via:
```console
# pot start mypot
# pot stop mypot
```
If you want to have a shell inside your pot:
```console
# pot term mypot # when already running
# pot run mypot # an alias for start+term
```

If you want to get some imformation about your pot, you can:
```console
# pot info -v -p mypot
```

## Congratulations!

Congrats! You created your first jail using `pot`.  
To learn more about the supported types of jails, you car read the documention for [Thin jails](Thin.md), [Thick jails](Thick.md) and [Containers](Container.md).  


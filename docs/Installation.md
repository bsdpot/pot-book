# `pot` installation guide

This is a guide to prepare your FreeBSD installation to use the `pot` jail framework.

??? note "`root` user"
    Many operations need `root` privileges. In this guide, we consider to be logged in as `root`

??? note "ZFS"
    ZFS is mandatory, so if you don't know what it is or you don't have a ZFS pool, please consider to read this [quick guide](https://www.freebsd.org/doc/handbook/zfs-quickstart.html).

## FreeBSD version
`pot` is usually developed on CURRENT, but it's mainly tested and used on 12.1.
It should work also on 11.3, even if the kernel has to be rebuild, to activate `VNET(9)`, via the `VIMAGE` option.
If you want to use FreeBSD 11.3, please follow the instruction reported on the [handbook](https://www.freebsd.org/doc/handbook/kernelconfig.html) to build a custom kernel with the `VIMAGE` option enabled.

## Install `pot`
`pot` is available as package or port.

The suggested way is to install `pot` is to use the package:
```console
# pkg install -y pot
```
All dependencies will be automatically installed, if not already installed.

If you want to install it using ports, you can
```console
# cd /usr/ports/sysutils/pot
# make install clean
```

??? note "Build with `ports`"
    A dependency of `pot`, called `potnet` is written in Rust. If you install `potnet` via ports, the build dependencies will be built as well, and it can take really long time (depending on the power of you system, it could be several hours).

## Enable the resource limit database
One really useful feature, needed to improve the isolation between jails, is the resource limit database.
This feature is normally disabled (it seems it causes a performance penalty in previous FreeBSD versions), and it can be enabled only at boot. To do so:
```console
# echo kern.racct.enable=1 >> /boot/loader.conf
# reboot
```
This settings will take effect at the next reboot.

#### Known issue
An issue with the `vtnet` driver can cause poor performance on the network card.
If `pot` is installed on a VM based on `vtnet`, the following command avoids the performance penalty:
```console
# echo hw.vtnet.lro_disable=1 >> /boot/loader.conf
```

This setting needs a reboot to take effect.
## `pot` framework configuration
Under the folder `/usr/local/etc/pot` you'll find two files:

* `pot.default.conf`
* `pot.conf`

The `pot.default.conf` contains all the default values and it shouldn't be touched.
All needed changes can be made in the `pot.conf` file.
This configuration file provide already a brief explanation for all parameters, but here we go deep, explaining them one by one

### File system parameters
`pot` is based on ZFS. In the configuration file, 2 parameters are used to let `pot` use your ZFS pool correctly.
#### `POT_ZFS_ROOT` (default `zroot/pot`)
This parameter is the ZFS dataset that will be used by `pot` to store whatever will be needed: jails file systems, bases, and so on.
If the dataset doesn't exist, it will be created by the initialization command (See the [last chapter](Installation.md#initialize-the-environment)).
#### `POT_FS_ROOT` (default `/opt/pot`)
This parameter is the mountpoint for the `POT_ZFS_ROOT` dataset. You shouldn't use a mountpoint that exists and contains file, otherwise the content will become unreachable.
#### `POT_CACHE` (default `/var/cache/pot`)
This parameter specifies the mountpoint of the dataset `POT_ZFS_ROOT/cache`. This dataset is used only to store `pot` images for the `import` and the `prepare`command. The default value is the suggested one.

### Network parameters
In order to use network types like `alias`, `public-bridge` or `private-bridge`, some configuration parameters are needed.

#### `POT_EXTIF` (default `em0`)
Currently, `pot` assumes that all the network traffic is going through one physical network interface.
This parameter configures `pot` to use the specified network interface.

#### `POT_EXTIF_ADDR` (default empty)
++"0.12.0"++ In case the `POT_EXTIF` has multiple addresses, `public-bridge` and `private-bridge` setup will use the first not alias IPv4 address for NAT and redirection.
The parameter `POT_EXTIF_ADDR` can be used to specify which IPv4 address (assigned to `POT_EXTIF`) is the one to be used for NAT and redirection.

#### `POT_NETWORK_STACK` (default `ipv4`)
++"0.11.0"++ This parameter configures the network stack that a `pot` will set when created.
There are three possible values

* `ipv4` : all `pot`s will use IPv4 only
* `ipv6` : all `pot`s will use IPv6 only
* `dual` : all `pot`s will have dual stack support, both IPv4 and IPv6

As explained [here](Network.md#network-stack), this variable is only used as default value when a `pot` is created or cloned and no specific option is provided..

#### `POT_NETWORK` (default `10.192.0.0/10`)
This parameter specifies the IPv4 address of you internal virtual network and is used by the `public-bridge` network type only.
It's wise to choose a private network segment that doesn't conflict with your current network setup.
The default address space is huge, however you can choose the network range that match your needs.

#### `POT_NETMASK` (default `255.192.0.0`)
This parameter specifies the netmask relative to the `POT_NETWORK`.
Theoretically, the netmask can be derived from the `POT_NETWORK`. For now, this is not the case, so you have to provide a netmask consistent with the network specified in `POT_NETWORK`

#### `POT_GATEWAY` (default `10.192.0.1`)
This parameter specifies the IP address that will be used as default gateway in your internal virtual network. It has to be part of the network specified in `POT_NETWORK` and it will be used as default gateway for all `pot`s attached to the internal virtual network (`public-bridge` network type).

#### `POT_EXTRA_EXTIF` (default empty)
In case your host has multiple network interfaces connected to multiple network segments, this option allows your `pot`s to access those network segments.
For example, let's say that you have 2 vlan interfaces, called `vlan20` and `vlan30`.

* `vlan20` is configured as 10.0.20.4/24
* `vlan30` is configured as 10.0.30.8/24

To make those segments accessible, the configuration file should look like:
```
POT_EXTRA_EXTIF=vlan20 vlan30
POT_NETWORK_vlan20=10.0.20.0/24
POT_NETWORK_vlan30=10.0.30.0/24
```
Currently there is no way to use additional external interface for the network type `alias`.
All other network types are supported

#### Network validation
If you want to check that your network configuration is valid, you can use the utility `potnet`:

```console
# potnet config-check
```
This command will show only the errors.

### Other parameters

#### `POT_LOG_FACILITY` (default `local2`)
++"0.10.4"++ Every time `pot` is invoked, its activity is logged via `syslogd(8)`.
By default, the facility used is `local2`, but this parameter can be used to change it.

### Experimental parameters
There are other parameters that are used by some experimental features.

#### VPN support
If your host system is using a VPN to reach some network segments, you can add some parameters in order to be able to connect your internal virtual network to those networks

* `POT_VPN_EXTIF`: the name of the network interface of the VPN software tunnel; default: `tun0`
* `POT_VPN_NETWORKS`: a list of all network segments served by the VPN; default: `192.168.0.0/16`

If you have multiple network segments, you have to list them all. For instance:
```sh
POT_VPN_NETWORKS="192.168.0.0/24 192.168.10.0/24 10.10.0.0/16"
```

#### dns `pot` [DEPRECATED]
An experimental feature is to provide an internal dns service running in a `pot` attached to the internal virtual network.
The dns is still a work in progress, however two parameters are already present for this feature:

* `POT_DNS_NAME`: this parameter specifies the name of the `pot` that will run the dns; default => `dns`
* `POT_DNS_IP`: this parameter specifies the IP (internal to the `POT_NETWORK` that the "dns `pot`" will have; default => `10.192.0.2`

## Initialize the environment
The initialization of the environment will:

* Create the ZFS datasets
* Validate the network parameters
* Configure `pf(4)` to be aware of the internal virtual network

If you are already using `pf`, I suggest to make a backup of you `pf` configuration file.

When ready, you can initialize the environment with the command (use the flag `-v` if you want a bit more of verbosity):
```console
# cp /etc/pf.conf /etc/pf.conf.bak
# pot init -v
```

### Initialize and test the internal virtual network
The internal virtual network is not always active, but it's automatically activated if a `pot` configured to use it get started.
However, a command is provided to activate the virtual network:

```console
# pot vnet-start
```

From your host, you can now ping the virtual network default gateway (always reachable from the host):
```console
# ping 10.192.0.1
```

## Remove the `pot` environment
In order to remove the `pot` from your system, a command is provided to make it easy:
```console
# pot de-init
```
This powerful command will remove everything related to `pot` and it cannot be undone.

Even if not mandatory, it would be nice to know why you removed it.
Please, consider to write a feedback email to pizzamig at FreeBSD dot org

* What's wrong with `pot`?
* What's the missing feature I really need?
* How bad is to use it? How can it be more user-friendly?

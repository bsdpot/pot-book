# Network configuration available for `pot`

The creation phase of a `pot` sets its network configuration.
The three main network parameters are:

* network stack
* network type
* DNS resolver

Those three parameters, together with their more specific options, define the network setup of a `pot`.

## Network stack
++"0.11.0"++ This parameter set the network stack that the `pot` can use.

The three possible choices are:

* `ipv4` : the `pot` has access to the IPv4 stack only
* `ipv6` : the `pot` has access to the IPv6 stack only
* `dual` : the `pot` has access to both IPv4 and IPv6 network stacks

Different network types provide different support to the selected network stack. However, even if the implementation can differ, the outcome is always the same.

The network stack is assigned when the `pot` is created. The option `-S` selects which network stack will be used by the created `pot`.
If no network stack is selected, the default one is assigned ([here](Installation.md#pot_network_stack-default-ipv4) on how to configure the default network stack)


## Network types

`pot` supports four different type of network types:

* inherit
* alias (IPv4 or IPv6) on a network interface
* IPv4 and/or IPv6 addresses on the public internal virtual network
* IPv4 address on a private internal virtual network

By default, `inherit` is the chosen one.

In the next sections, all network setups will be explained in details.

## Network configuration: inherit
This network configuration means that the jail will use the same network stack of the hosting machine: the same IP address, the same network configuration.
The `inherit` network type is the default one, but it can be explicitly selected during the creation, with the command:
```console
# pot create -p casserole4 -t single -b 12.2 -N inherit -S ipv4
# pot create -p casserole6 -t single -b 12.2 -N inherit -S ipv6
# pot create -p casserole -t single -b 12.2 -N inherit -S dual
```

As explained in [Network stack](Network.md#netowrk-stack), `casserole4` inherits the network stack of the host, but only `ipv4` is allowed, `ipv6` is not usable. Similarly, `casserole6` inherits `ipv6` stack only, while `casserole` inherits the whole stack

If the option `-S` is omitted, `pot create` will use the `POT_NETWORK_STACK` configuration parameter ([here](Installation.md#pot_network_stack-default-ipv4) for the explanation).

The network type `inherit` works pretty well when your `pot` doesn't provide/export any network services, but it uses the network's host as client, like a `pot` created to build applications.

## Network configuration: IPv4 or IPv6 alias
If the host is in a network where static IPs can be assigned, one or more IPs address can be bound to a `pot` via this network configuration type.

??? note
    Be sure that in the `pot` configuration file (`/usr/local/etc/pot/pot.conf`) you have correctly set the variable `POT_EXTIF`; this network interface is the one used by default to route the network traffic and to assign the IP address ([here](Installation.md#pot_extif-default-em0) more defails).
	If your network interface has IPv4 multiple addressed, check the `POT_EXTIF_ADDR` configuration section ([here](Installation.md#pot_extif_addr-default-empty))

Let's make a complex, but comprehensive example:
```console
# pot create -p casserole -t single -b 12.2 -N alias -i "em0|2a00:1234:1234:1234::443" -i "em0|192.168.178.200" -i "2a00:1234:1234:1234::80" -S dual
# pot start casserole
# pot info -vp casserole
# ifconfig
```

Let's explain the `create` command line:

* `-N alias` : the network type has to be explicitly specified
* `-i "em0|2a00:1234:1234:1234::443"` : assign the IPv6 address `2a00:1234:1234:1234::443` to the network interface `em0`
* `-i "em0|192.168.178.200"` : assign the IPv4 address `192.168.178.200` to the network interface `em0`
* `-i "2a00:1234:1234:1234::80"`: assign the IPv6 address `2a00:1234:1234:1234::80` to the default network interface, specified in the variable `POT_EXTIF`
* `-S dual` : enable both IP stacks

If `POT_EXTIF`'s value is `em0`, the network interface can be omitted.

To provide a bit of flexibility, it's possible to specify IP addresses of a stack, even if it's not used; those IPs will be just ignored. For instance:
```console
# pot create -p casserole -t single -b 12.2 -N alias -i "em0|2a00:1234:1234:1234::443" -i "em0|192.168.178.200" -i "2a00:1234:1234:1234::80" -S ipv4
```

The IPv6 addresses will be just ignored during `pot start`.

The command `pot stop` takes care to automatically remove the alias IP from the interface.

## Network configuration: public bridge virtual network
Thanks to `VNET(9)`, `pot` supports an internal virtual network.
Let's start explaining few things:

* bridge  : it's based on the pseudo network bridge device ([man page](https://www.freebsd.org/cgi/man.cgi?query=bridge&manpath=FreeBSD+12.1-RELEASE+and+Ports))
* public  : there is one bridge for IPv4 and one for IPv6. All `pot`s using this network type are connected to the same bridge
* virtual : well, it's not a virtual network, even if a physical network card is needed for external access

### public bridge on IPv4

The IPv4 public bridge is a network that lives only on the host system. This network is directly connected to the host network, but it masked via NAT.

The network setup is stored in the configuration file (`/usr/local/etc/pot/pot.conf`), so be sure to have it properly configured (a full explanation is available [here](Installation.md#network-parameters)).

??? note
    To help the `pot` framework and all users to manage the public virtual network, an additional package is required, normally automatically installed as dependency of the package `pot`. It's also manually installable via:
    ```console
    # pkg install potnet
    ```

To verify your virtual network configuration, this command can be used:
```console
# potnet show
Network topology:
	network : 10.192.0.0
	min addr: 10.192.0.0
	max addr: 10.255.255.255

Addresses already taken:
	10.192.0.0
	10.192.0.1	default gateway
	10.192.0.2	dns
```
The output is from my configuration (and also the default one), however your address' range can differ, depending on the adopted configuration values. Please, make sure that the virtual network doesn't overlap with any networks your host system is attached to.

Optionally, you can start the virtual network via the command:
```console
# pot vnet-start
```
This command will create and configure the network interfaces properly and will activate `pf` to perform NAT on the virtual network.

!!! info
    The command `vnet-start` is automatically executed when a `pot` is configured to use the public virtual network. There should be no need to run it manually.

The following command creates a `pot` on the internal network:
```console
# pot create -p casserole4 -t single -b 12.2 -N public-bridge -i auto -S ipv4
# pot run casserole4
root@casserole4:~ # ping 8.8.8.8
[..]
root@casserole4:~ # exit
# pot stop casserole4
```
The `auto` keyword will automatically select an available address in the internal virtual network. `auto` is the default value, in this example it can be omitted.

Commands like `pot info -p casserole4` will show exactly which address has been assigned to the `pot`, while `potnet show` will show an overview of the assigned IP addresses of your internal network.

If preferable, it's possible to assign a specific IP address to the `pot`:
```console
# pot create -p casserole4 -t single -b 12.2 -N public-bridge -i 10.192.0.10
```
`pot` will verify if the IP address is available and free to be used.

### public bridge on IPv6

++"0.11.0"++ The IPv6 public bridge is a bridge that contains the `POT_EXTIF` network interface. All the `pot`s connected to this bridge will share the bridge and are connected to the network through the network interface.

!!! Warning
    The `pot`s attached to the IPv6 bridge will set their IP via SLAAC. If the host network doesn't provide such feature, the IPv6 bridge cannot be used.

!!! Warning
    Bridge needs to put the network card in *promiscuous mode*. Typically, many WiFi network cards (and apparently few ethernet cards) don't support the *promiscuous mode*. If the host network card doesn't support this mode, the public bridge cannot run on IPv6.

The following command creates a `pot` on the internal network:
```console
# pot create -p casserole6 -t single -b 12.2 -N public-bridge -i auto -S ipv6
# pot run casserole6
root@casserole6:~ # ping6 2001:4860:4860::8888
[..]
root@casserole6:~ # exit
# pot stop casserole6
```

## Network configuration: private bridge virtual network
The public virtual network has the downside that all `pot`s share the same bridge, potentially affecting isolation or performance.
To mitigate this issue, private virtual network has been introduced, but only IPv4 is supported.

!!! warning
    If IPv6 support is needed, only the private bridge network type cannot be used

A private virtual network is like the just a different separated bridge, that can be used to connect multiple `pot`s, but it's not shared with all `pot`s. From a technological point of view, a private bridge is exactly like a public bridge, but it's dedicated to specifics `pot`s.

First of all, to use a private virtual network a private bridge has to be created:
```console
# pot create-private-bridge -B stove -S 4
```
This command will create a new private bridge, called `stove`, with a network segment big enough to connect 4 `pot`s.

!!! note
    The size is fixed and cannot be modified after the bridge is created.

Using `potnet` it's possible to check the details of the private bridge via the command:
```console
# potnet show -b stove
	10.192.0.16	stove bridge - network
	10.192.0.17	stove bridge - gateway
	10.192.0.23	stove bridge - broadcast
```
The output is from my configuration, however your address' range can differ, depending on the configuration values you have adopted and the network segment available when the bridge is created.

To activate a specific bridge, you can use the command:
```console
# pot vnet-start -B stove
```
This command will create and configure the network interfaces properly and will activate `pf` to perform NAT on the virtual network.

!!! note
    This command is automatically executed when a `pot` is configured to use the private virtual network. There should be no need to run it manually.

The following command will create a `pot` running on the private internal network:
```console
# pot create -p casserole -t single -b 12.2 -N private-bridge -B stove -i auto -S ipv4
# pot run casserole
root@casserole:~ # ping 1.1.1.1
[..]
root@casserole:~ # exit
# pot stop casserole
```
The `auto` keyword will automatically select an available address in the internal virtual network and it's the default value, hence the `-i` option can be omitted.

Commands like `pot info -p casserole` and `potnet show -b stove` show the `pot` network configuration and the status of the bridge.

If preferable, it's possible to assign a specific IP address to the `pot`:
```console
# pot create -p casserole -t single -b 12.2 -N private-bridge -B stove -i 10.192.0.19
```
`pot` will verify if the IP address is available, compatible with the selected bridge and free to be used.

## Export network services while using internal network

Depending on the adopted network type, network services needs an extra configuration step, in order to be reachable. In general, all network types that rely on NAT (`private-bridge` and `public-bridge` on IPv4) need to specify redirection rule make network services accessible from the host system

Network types like `inherit`, `alias` and `public-bridge` on IPv6 do not need any extra configuration, their network services are already ready to be used out of the box.

The required redirection rule is automatically injected by `pot` if and when needed.

`pot` provides a command to configure port redirection:
```console
# pot export-ports -p casserole -e 80:30080 -e 443:30443
# pot start casserole
# pot show -p casserole
pot casserole
	disk usage      : 266M
	virtual memory  : 33M
	physical memory : 17M

	Network port redirection
		192.168.178.20 port 30080 -> 10.192.0.11 port 80
		192.168.178.20 port 30443 -> 10.192.0.11 port 443
```

If the user doesn't want to specify a port for the redirection, `pot` can choose a port at runtime:
```console
# pot export-ports -p casserole -e 80 -e 443
```

To know which port is used, you can use the `show` command:
```console
# pot start casserole
# pot show -p casserole
pot casserole
	disk usage      : 274M
	virtual memory  : 13M
	physical memory : 4824K

	Network port redirection
		192.168.178.20 port 1024 -> 10.192.0.3 port 80
		192.168.178.20 port 1025 -> 10.192.0.3 port 443
```

## DNS resolver
By default, when a `pot` is created, it's configured to inherit the DNS resolver configuration of the host, with the assumption that if it's working for the host, it should be good for the `pot` as well.

However, there are many cases where users want to have a better control of the DNS resolver configuration of their `pot`. There are four possible configuration, usable at creation time:
* `inherit`
* `off`
* `custom:filename`
* `pot`

### DNS resolver: `inherit`

This is the default value:
```console
# pot create -p casserole -t single -b 12.2 -N inherit -d inherit
```

When the `pot` starts, the host `/etc/resolv.conf` file is copied inside the `pot` with the assumption that it's valid for both system, the host and the `pot`.

??? attention
	If your host is configured to use `unbound`, `inherit` is not usable for `public-bridge` and `private-bridge` network configuration, because `unbound` is listening only on the host's `lo0` interface

### DNS resolver: `off`

++"0.11.5"++ This is value allows to disable any automatic configuration of the DNS resolver. It's up to the user to provide an appropriate `resolv.conf` file, with a pre-start hook or the `copy-in` command.
```console
# pot create -p casserole -t single -b 12.2 -N inherit -d off
```

### DNS resolver: `custom:filename`

++"0.12.0"++ This setup allows the user to provide a custom `resolv.conf` provided at creation time:
```console
# pot create -p casserole -t single -b 12.2 -N inherit -d custom:myresolv.conf
```

The file `myresolv.conf` will be copied as part of the `pot` configuration and it will be copied over as `/etc/resolv.conf` in the `pot` at start time.

The user is fully responsible of the validity of the content of `myresolv.conf`, no validation is performed.

### DNS resolver: `pot` [partially DEPRECATED]
If the user has a `pot` acting as DNS server, this option can be used to automatically configure other `pot`s DNS resolver:
```console
# pot create -p casserole -t single -b 12.2 -N inherit -d pot
```

In order to have this feature properly working, there are several requirements:
* the `pot` serving as DNS has to exist :)
* variables `POT_DNS_NAME` and `POT_DNS_IP` has to be configured accordingly
* `pot`'s network types need to be compatible in order to be mutually reachable

??? note
	With ++"0.12.0"++ the function to automatically create a DNS server in a `pot` has been removed, becuase of the maintenance burden and its very low adoption. However, the ability to autogenerate a `resolve.conf` is still avaliable

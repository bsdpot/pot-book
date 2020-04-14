# Network configuration available for `pot`

The creation phase of a `pot` sets its network configuration. 
The two main network parameters are:

* network stack
* network type

Those two parameters, together with their more specific options, define the network setup of a `pot`.

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
# pot create -p casserole4 -t single -b 11.3 -N inherit -S ipv4
# pot create -p casserole6 -t single -b 11.3 -N inherit -S ipv6
# pot create -p casserole -t single -b 11.3 -N inherit -S dual
```

As explained in [Network stack](Network.md#netowrk-stack), `casserole4` inherits the network stack of the host, but only `ipv4` is allowed, `ipv6` is not usable. Similarly, `casserole6` inherits `ipv6` stack only, while `casserole` inherits the whole stack

If the option `-S` is omitted, `pot create` will use the `POT_NETWORK_STACK` configuration parameter ([here](Installation.md#pot_network_stack-default-ipv4) for the explanation).

The network type `inherit` works pretty well when your `pot` doesn't provide/export any network services, but it uses the network's host as client, like a `pot` created to build applications.

## Network configuration: IPv4 or IPv6 alias
If your host is in a network where you can assign static IPs, you can bind one static IP address to your `pot` via this network configuration type.

??? note
    Be sure that in the `pot` configuration file (`/usr/local/etc/pot/pot.conf`) you have correctly set the variable `POT_EXTIF`; this network interface is the one used by default to route the network traffic and to assign the IP address ([here](Installation.md#pot_extif-default-em0) more defails).

For example, the host system has `192.168.178.20/24` as IP address and the network administrator reserved an additional IP address, for instance the IP `192.168.178.200` for the service running in the `pot`. 
To assign this IP address to the `pot`, the following command can be used:
```console
# pot create -p mypot -t single -b 11.3 -N alias -i 192.168.178.200
# pot start mypot
# pot info -vp mypot
# ifconfig
```

The alias `192.168.178.200` will be assigned to the network interface `POT_EXTIF`, specified in `/usr/local/etc/pot/pot.conf`, during the start phase.  When running, the `pot` is bound to the address `192.168.178.200`.

If you want to used a different network interface, `alias` network type support an additional option for that purpose:
```console
# pot create -p mypot_vlan -t single -b 11.3 -N alias -i 10.200.0.80 -I vlan30
# pot start mypot
# pot info -vp mypot
# ifconfig
```

In this example, the created `pot` will use the IP address 10.200.0.80, but on a different network interface.

This network type supports IPv6 as well:
```console
# pot create -p mypot_vlan -t single -b 11.3 -N alias -i 2a00:1234:1234:1234::443
# pot start mypot
# pot info -vp mypot
# ifconfig
```
In this example, we assigned the IPv6 address 2a00:1234:1234:1234::443 to our `pot`.

When the `pot` is stopped, the alias will be automatically removed from the interface.

## Network configuration: public virtual network bridge
Thanks to `VNET(9)`, `pot` supports an IPv4 virtual network. This network is configured in the configuration file (`/usr/local/etc/pot/pot.conf`), so be sure you have it properly configured (a full explanation is available [here](Installation.md#network-parameters)).

This network type refers to a shared bridge where the public virtual network lives. All `pot`s with this network type will share it. The virtual internal network is connected with the outside via NAT.

!!! note
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
The output is from my configuration (and also the default one), however your address' range can differ, depending on the configuration values you have adopted.

Optionally, you can start the virtual network via the command:
```console
# pot vnet-start
```
This command will create and configure the network interfaces properly and will activate `pf` to perform NAT on the virtual network.

!!! note
    The command `vnet-start` is automatically executed when a `pot` is configured to use the public virtual network. There should be no need to run it manually.

The following command will create a `pot` running on the internal network:
```console
# pot create -p mypot -t single -b 11.3 -N public-bridge -i auto
# pot run mypot
root@mypot:~ # ping 1.1.1.1
[..]
root@mypot:~ # exit
# pot stop mypot
```
The `auto` keyword will automatically select an available address in the internal virtual network. `auto` is the default value, in this example it can be omitted.

Commands like `pot info -p mypot` will show exactly which address has been assigned to the `pot`, while `potnet show` will show an overview of the assigned IP addresses of your internal network.

If preferable, it's possible to assign a specific IP address to the `pot`:
```console
# pot create -p mypot2 -t single -b 11.3 -N public-bridge -i 10.192.0.10
```
`pot` will verify if the IP address is available and free to be used.

## Network configuration: private virtual network bridge
The public virtual network has the downside that all `pot`s share the same bridge, potentially affecting isolation.  
To mitigate this issue, private virtual network has been introduced.

A private virtual network is like the just a different separated bridge, that can be used to connect multiple `pot`s, but it's not shared with all `pot`s. From a technological point of view, a private bridge is like a public bridge, but it's shared between fewer `pot`s.

First of all, to use a private virtual network a private bridge has to be created:
```console
# pot create-private-bridge -B mybridge -S 4
```
This command will create a new private bridge, called `mybridge`, with a network segment big enough to connect 4 `pot`s.

!!! note
    The size is fixed and cannot be modified after the bridge is created.

Using `potnet` it's possible to check the details of the private bridge via the command:
```console
# potnet show -b mybridge
	10.192.0.16	mybridge bridge - network
	10.192.0.17	mybridge bridge - gateway
	10.192.0.23	mybridge bridge - broadcast
```
The output is from my configuration, however your address' range can differ, depending on the configuration values you have adopted and the network segment available when the bridge is created.

To activate a specific bridge, you can use the command:
```console
# pot vnet-start -B mybridge
```
This command will create and configure the network interfaces properly and will activate `pf` to perform NAT on the virtual network.

!!! note
    This command is automatically executed when a `pot` is configured to use the private virtual network. There should be no need to run it manually.

The following command will create a `pot` running on the private internal network:
```console
# pot create -p mypot -t single -b 11.3 -N private-bridge -B mybridge -i auto
# pot run mypot
root@mypot:~ # ping 1.1.1.1
[..]
root@mypot:~ # exit
# pot stop mypot
```
The `auto` keyword will automatically select an available address in the internal virtual network and it's the default value, hence the `-i` option can be omitted.

Commands like `pot info -p mypot` and `potnet show -b mybridge` show the `pot` network configuration and the status of the bridge.

If preferable, it's possible to assign a specific IP address to the `pot`:
```console
# pot create -p mypot2 -t single -b 11.3 -N private-bridge -B mybridge -i 10.192.0.19
```
`pot` will verify if the IP address is available and free to be used.

## Export network services while using internal network
Virtual networks are not visible outside the host machine, the bridges are masked outside via NAT.

To make network services reachable from outside the TCP desired ports have to be exported/redirected.

The host port can be selected automatically or it can be provided by the user, depending on the needs.

`pot` provides a command to setup port redirection:
```console
# pot export-ports -p mypot -e 80 -e 443
```
The `export-ports` command will mark ports 80 and 443 as exportable. When the `pot` starts, available ports will be identified and redirection rules will be automatically set up.

To know which port is used, you can use the `show` command:
```console
# pot start mypot
# pot show -p mypot
pot mypot
	disk usage      : 274M
	virtual memory  : 13M
	physical memory : 4824K

	Network port redirection
		192.168.178.20 port 1024 -> 10.192.0.3 port 80
		192.168.178.20 port 1025 -> 10.192.0.3 port 443
```

To map the network services to a specific port, instead of leaving the decision to `pot`, the following syntax can be used:
```console
# pot export-ports -p mypot -e 80:30080 -e 443:30443
# pot start mypot
# pot show -p mypot
pot mypot
	disk usage      : 266M
	virtual memory  : 33M
	physical memory : 17M

	Network port redirection
		192.168.178.20 port 30080 -> 10.192.0.11 port 80
		192.168.178.20 port 30443 -> 10.192.0.11 port 443

```


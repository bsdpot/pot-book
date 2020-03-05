# `pot` as *thick* jail

## Introduction
A *thick* jail is a jail that doesn't exploit the base/package separation that FreeBSD provides, but put all the needed files in one file system.

In `pot`, a thick jail is a jail composed by only one ZFS dataset and is called `pot` of type *single* (as *single ZFS dataset*)

Thick jails have advantages and disadvantages that has to be evaluated before the jail is created. Once adopted a type, `pot` doesn't provide yet a way to convert jails from one type to another.

## Create a thick jail
The following command creates a `pot` of type *single*:
```console
# pot create -p casserole -b 12.1 -t single
```

In detail:

* `-p casserole` : the name of the `pot`
* `-b 12.1` : the version of FreeBSD to use to create the jail
* `-t single` : the `pot` type (single ZFS dataset)

The *create* command will:

* fetch the FreeBSD base tarball (if not already cached)
* extract the tarball

!!! note
    The FreeBSD base tarball doesn't contain any security updates. A flavour is provided to run the update during the creation:
	```console
	# pot create -p casserole -b 12.1 -t single -f fbsd-update
	```
## Use the thick jail

In common with all `pot`s, several commands are available to thick jails:
```console
# pot info -vp casserole     # to show information about the pot
# pot start casserole        # to start the pot
# pot show -p casserole      # to show run-time information about the pot
# pot term casserole         # to open a shell in the pot
# pot run casserole          # to start and open a shell in the pot [start+term]
# pot stop casserole         # to stop the pot
```

## Additional features
Because their internal structure is easier to manage, thick jails provide additional features, that are not available for thin jails

### Export a `pot` as image

A `pot` image is a snapshot of the ZFS dataset stored in a compressed file. Technically, a snapshot of a `pot` is exported in a file, not the `pot` itself.

<!---
TODO: add a link to a snapshot/rollback section, when ready
-->
A snapshot can be taken with the commands:
```console
# pot stop casserole # if the pot is running
# pot snapshot -p casserole
# pot purge-snapshot -p casserole
```

When a snapshot is available, an image of the snapshot can be exported:

```console
# pot export -p casserole -t 1.0
```
In detail:

* `-p casserole` : the name of the `pot`
* `-t 1.0` : the tag, a label that can be used for versioning

The output is two files:
```console
# ls
casserole_1.0.xz
casserole_1.0.xz.skein
```

The `casserole_1.0.xz` file is the image and contains the filesystem of the `pot`, while the `casserole_1.0.xz.skein` file is just a hash

??? note "Compression performance"
    The compression utility chosen is `xz(1)` that provides high compression ratio, but it can be a bit slow. `xz(1)` is configured to run in parallel using as many core as possible. If you are running `pot` in a VM, you can consider to add more CPU core to speed up the compression process

<!---
TODO: document the other options of export
-->
### Import a `pot` from an image

The opposite operation of `export` is `import`.

As example, the `casserole` image can be imported from the local directory with the command:
```console
# pot import -p casserole -t 1.0 -U .
```

In detail:

* `-p casserole` : the name of the `pot`
* `-t 1.0` : the tag, a label that can be used for versioning
* `-U .` : the URL where to look for the image; in this case, the local folder (`.`)

The `pot` is imported with the name `casserole_1_0`.

```console
# pot ls -q
casserole_1_0
casserole
```

<!---
TODO: document the other options of import
TODO: add an example of download from a web server
-->

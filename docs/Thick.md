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

### export a `pot` as image

### import an image of a `pot`

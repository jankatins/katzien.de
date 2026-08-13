---
layout: post
title: "How to debug a hardened k8s containers without shell and with read-only filesystem"
comments: True
date: "2026-08-13"
description: "Stuff I learned while debugging a problem in a hardened k8s container without a included shell and with
read-only filesystem."
---

I had the pleasure of debugging a container running in k8s which uses a hardened base images without any included shell
and a read-only root filesystem
([readOnlyRootFilesystem=True](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)).
This makes debugging stuff in the running container ugly as there is no regular "run shell in running container" like
for other containers (e.g. via k9s).

This is a personal TIL how to get access to such containers and information out of such containers.

## Get a shell in a container sidecar

Open k9s, browse to the relevant pod you want to debug and copy out the pod name
(or use `kubectl get pods --namespace=<namespace>`).
The following will start up a new container in the pod as a sidecar to the relevant already running container:

```shell
kubectl debug -it <podname-with-random-stuff-at-the-end> \
   --image=alpine \
   --target=<container-name> \
   --namespace=<namespace> \
   --profile=general
```

This will give you an `alpine` debug sidecar which has access to the running container stuff.

## Poke around from the sidecar

To see the running processes:

```shell
ps aux
```

In our case it showed a bunch of python processes.

You can poke at the running processes:

```shell
# The root filesystem as seen by the running process
ls -la /proc/12/root/
# Seeing the env vars of the running process
su root
cat /proc/12/environ | tr '\0' '\n'
# All the mounted secrets
ls -la /proc/12/root/mnt/secrets
cat /proc/12/root/mnt/secrets/SECRET_PASSWORD
```

But the current root filesystem (`/`) is not the same as the root filesystem of the processes
which run in the container.

```shell
# PID 12 showed up in the above ps aux...
$ ls -la /proc/12/root/usr/bin/python3.14
-rwxr-xr-x    1 root     root         15792 Aug  6 07:43 /proc/12/root/usr/bin/python3.14
$ /proc/12/root/usr/bin/python3.14
/bin/sh: /proc/12/root/usr/bin/python3.14: not found
```

As one can see above, one cannot execute the python binary
(probably, because it is dynamically linked and the libraries are not in the current root file system but relatively to
the root file system of the running process).

To actually access the root filesystem of the running process, you need `chroot`.

## Chroot into the running process

Because at this point we do not have a regular shell in the containers root file system,
we go straight to the python REPL:

```shell
$ chroot /proc/12/root python3.14
Python 3.14.7 (tags/v3.14.7-9-gd3b588836d-dirty:d3b588836d, Aug  6 2026, 07:43:54) [GCC 16.1.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
```

To get a regular shell, you have to symlink the items from the `alpine` container into the root filesystem of the
running process.
But you have to find a writable place.
It seems `/dev/shm` is such a place, and it is available and writable in our case:

```shell
# First install a completely static busybox, that makes a lot of things easier:
apk add busybox-static
# Again 12 is the process we want to look at and we got that PID from ps aux above
mkdir /proc/12/root/dev/shm/bin
ln -s /proc/$$/root/bin/busybox.static /proc/12/root/dev/shm/bin/busybox
export PATH=$PATH:/dev/shm/bin/
chroot /proc/12/root busybox sh
```

And, boom, you have a regular (busybox based) shell in the running container:

```shell
busybox ls -la
# If you want to have all the regular unix commands:
/dev/shm/bin/busybox --install -s /dev/shm/bin/
```

Now you can poke around...
Don't forget to restart the pod after you are done to not leave the changes around!

If you have any improvements or additional tipps: please leave a comment!

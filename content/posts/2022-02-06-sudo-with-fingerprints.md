---
layout: post
title: "Configure sudo with fingerprints"
comments: True
date: "2022-02-06"
description: "Run sudo commands by authenticating via a fingerprint reader with working askpass workflows in ansible/pyinfra"
---

I want to be able to run sudo commands by authenticating via a fingerprint reader, but only when I run them
interactively. This shows how to do it without breaking ansible/pyinfra usage of sudo.

### Enabling sudo fingerprint authentication on debian

I've a debian unstable system and at the time of writing, it didn't configure fingerprint authentication for `sudo`
out of the box. Adding support for it was two steps:

```bash
# Installing the required software
λ  sudo apt install fprintd libpam-fprintd
# Enabling it in debians pam stack
# -> select "fingerprint authentication"
λ  sudo pam-auth-update
```

This changed the following in `/etc/pam.d/common-auth`:

```diff
-auth   [success=1 default=ignore]      pam_unix.so nullok
+auth   [success=2 default=ignore]      pam_fprintd.so max-tries=1 timeout=10 # debug
+auth   [success=1 default=ignore]      pam_unix.so nullok try_first_pass
```

(Fedora 34 had fingerprint support for sudo enabled out of the box in this laptop, if I remember correctly)

### Working with ansible / pyinfra

The above configures pam to first authenticate against the fingerprint pam module (`pam_fprintd.sp`) and only afterwards
against the password module (`pam_unix.so`). If you have a script which runs sudo with a password command (e.g.
ansible/pyinfra, both python apps), this means every sudo call will ask for fingerprint authentication. Which made me
quite mad when I tried it, and I quickly gave up on this. But since
[sudo 1.9.9](https://github.com/sudo-project/sudo/commit/48bc498a6fbbe6a98de916a6a3e68f0ee6acfab1), `sudo` now supports
a different `pam` profile when `sudo --askpass` (or `sudo -A`) is used:

> **pam_askpass_service**
> On systems that use PAM for authentication, this is the service name used when the -A option is specified. The default value is either “@pam_service@” or “sudo”, depending on whether or not the -i option is also specified. See the description of pam_service for more information.
> This setting is only supported by version 1.9.9 or higher. -- [sudoers(5)](https://www.sudo.ws/docs/man/1.9.9/sudoers.man/)

So, lets create a `sudo-askpass` `pam` configuration:

```bash
# sudo/pam do not understand uppercase, so sudo-A as a filename does NOT work!
λ  sudo cp /etc/pam.d/sudo-i /etc/pam.d/sudo-askpass
λ  sudo nano /etc/pam.d/sudo-askpass
```

This needs now a `pam_unix.so` line before including `common-auth`. Afterwards, in my case, it read:

```text
#%PAM-1.0

# Set up user limits from /etc/security/limits.conf.
session    required   pam_limits.so

# ADDED
# First try password authentication (= the askpass helper) and then anything else
auth    [success=1 default=ignore]      pam_unix.so nullok
# ADDED

@include common-auth
@include common-account
@include common-session
```

What's left is to tell sudo to use this file when using `sudo -A`:

```bash
# use visudo to get your changes validated
# -> don't get yourself a broken sudo which you cannot fix without sudo...
λ  sudo visudo /etc/sudoers.d/sudo-askpass
```

That file should afterwards contain:

```text
Defaults pam_askpass_service=sudo-askpass
```

And now it should work: `sudo <command>` should still behave as before but when using `sudo -A <command>`, it should not
ask for fingerprint authentication.

Tested be creating a sudo password helper `sudo_pass.sh`:

```shell
#!/bin/sh
echo mypassword
```

and then calling `sudo -A` with it,
like [pyinfra does](https://github.com/Fizzadar/pyinfra/blob/2fec4e38f32c6d86331bf7d58457e3b3a64fa69c/pyinfra/api/connectors/util.py#L294)

```bash
λ  SUDO_ASKPASS=./sudo_pass.sh sudo -H -A -k cat /etc/sudoers
```

### Sidenote

During my experimentation with `sudo` for the above, I noticed an interesting fact: At least my fingerprint reader in my
Lenovo X1 Carbon (7th Gen) seems to only support a single process asking for a password and any other process then
errors. This also makes the `pam_fprintd.so` pam module fail directly and pam then runs the password
module `pam_unix.so` next. Which is exactly what I want. So a workaround seems to be to start a `fprintd-verify` in one
terminal window and then start the `sudo` using script in another...

Another sidenote: At least once (`ctrl+c` during `fprintd-verify`?) I got the fingerprint reader in a bad state:

```bash
λ  fprintd-verify
Using device /net/reactivated/Fprint/Device/0
failed to claim device: GDBus.Error:net.reactivated.Fprint.Error.AlreadyInUse: Device was already claimed
```

I could only get it back to working by restarting the `fprintd` service:

```bash
λ  sudo systemctl restart fprintd.service
```

---
layout: post
title: "Using azure VPN under fedora 40-42"
comments: True
date: "2024-10-03"
description: "Converting the microsoft azure vpn ubuntu deb package to run under fedora 40-42"
---

[Microsoft recently released a linux client to access the VPN](https://learn.microsoft.com/en-us/azure/vpn-gateway/point-to-site-entra-vpn-client-linux),
but for now, there is only an ubuntu 22.04 package.

These are the steps to get it running under fedora 40-42. USE AT YOUR OWN RISK!

- Download the deb from
  the [MS repository](https://packages.microsoft.com/ubuntu/22.04/prod/pool/main/m/microsoft-azurevpnclient/)
- Install `alien` and run `alien -r -g -v microsoft-azurevpnclient_3.0.0_amd64.deb` to get the package unpacked
- Fix the spec file: remove the line `%dir "/var/lib/polkit-1/"` as that conflicts with `polkit-pkla-compat`
  (if you install the rpm, and it shows you any other conflict of a directory, just remove that line as well)
- If you vpn policy sets a DNS server: in `var/lib/polkit-1/localauthority/50-local.d/10-microsoft-azurevpnclient.pkla`
  change the `Identity=unix-group:sudo` to `Identity=unix-group:wheel`
- Create a resulting rpm with
  `sudo rpmbuild --target x86_64 --buildroot $(pwd)/microsoft-azurevpnclient-3.0.0 -bb
  $(pwd)/microsoft-azurevpnclient-3.0.0/microsoft-azurevpnclient-3.0.0-2.spec`
  (Note: the rpm will be build in `..`, so make sure that it's fine to have it there)
- Install the resulting rpm, overwriting the libcurl mismatch:
  `sudo rpm -Uhv --nodeps ../microsoft-azurevpnclient-3.0.0-2.x86_64.rpm`
- Fix the missing capability:
  `sudo setcap 'cap_net_admin=ep' /opt/microsoft/microsoft-azurevpnclient/microsoft-azurevpnclient`

Afterward, you can
[login as described](https://learn.microsoft.com/en-us/azure/vpn-gateway/point-to-site-entra-vpn-client-linux#download-and-install-the-azure-vpn-client)
by importing the downloaded connection file.

It works... But obviously, a native Fedora package would be nice.

**UPDATE, Fedora 42**: it broke, the "Certificate Information" was greyed out and connecting errored out.

![greyed out "certificate Information"](/uploads/2024/2024-10-03-azure-vpn-under-fedora-42-broke.png)

The error in the systemd journal:

```text
AzureVPNClient[1035536]: TId:[1039625] No cert verification callback from client
AzureVPNClient[1035536]: TId:[1039625] Invalid certificate data at index 0
AzureVPNClient[1035536]: TId:[1039625] Verification result for certificate chain: 0
AzureVPNClient[1035536]: TId:[1039625] [Primary] OPENVPNFRAMING: OpenVpnFraming hit error processing packet, initiating teardown of tunnel error: 610970100000012 from tls_openssl_common.cpp line 151, facility MobileAccess with detail: Root cert validation failed
```

A colleague at work found the culprit via some strace magic: Azure VPN for Linux does not follow the symlinks in
`/etc/pki/tls/certs` from some hash(?) to the actual `*.pem` file.

- On Fedora 42, I had to copy the actual `*.pem` file into `/etc/pki/tls/certs`:
  `sudo cp /etc/pki/ca-trust/extracted/pem/directory-hash/<the cert your need>.pem /etc/pki/tls/certs/`.
- On Debian it needs to be copied into `/etc/ssl/certs` (on Fedora that is a symlink to `/etc/pki/tls/certs`).

This lets the cert show up (might need a new import) and connecting works again.

**UPDATE, 2025-09-26**: A newer `alien` seems to generate some slightly different spec file, which does not
conflict with a second directory anymore, but now needs to be called from outside by `rpmbuild`.
Which means the resulting rpm is in a different place.
Also added a fix for not being able to set the DNS server by changing the unix group in the for the `.pkla` file.

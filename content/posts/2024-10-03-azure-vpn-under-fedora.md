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
- Fix the spec file and remove two lines which would give you problems (don't remember which lines, just run the 
  next two lines and install the rpm -> it will show two conflicts for polkit related directories)
- Create a resulting rpm with
  `cd microsoft-azurevpnclient-3.0.0 && sudo rpmbuild --target x86_64 --buildroot $(pwd)/microsoft-azurevpnclient-3.0.0 -bb microsoft-azurevpnclient-3.0.0-2.spec && cd ..`
- Install the resulting rpm, overwriting the libcurl mismatch:
  `sudo rpm -Uhv --nodeps microsoft-azurevpnclient-3.0.0-2.x86_64.rpm`
- Fix the missing capability:
  `sudo setcap 'cap_net_admin=ep' /opt/microsoft/microsoft-azurevpnclient/microsoft-azurevpnclient`

Afterward you can
[login as described](https://learn.microsoft.com/en-us/azure/vpn-gateway/point-to-site-entra-vpn-client-linux#download-and-install-the-azure-vpn-client)
by importing the downloaded connection file.

It works... But obviously a native Fedora package would be nice.

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

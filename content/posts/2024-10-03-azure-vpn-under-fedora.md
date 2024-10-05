---
layout: post
title: "Using azure VPN under fedora 40"
comments: True
date: "2024-10-03"
description: "Converting the microsoft azure vpn ubuntu deb package to run under fedora 40"
---

[Microsoft recently released a linux client to access the VPN](https://learn.microsoft.com/en-us/azure/vpn-gateway/point-to-site-entra-vpn-client-linux),
but for now, there is only an ubuntu 22.04 package.

These are the steps to get it running under fedora 40. USE AT YOUR OWN RISK!

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

It works... But obviously a native Fedora 40 package would be nice.

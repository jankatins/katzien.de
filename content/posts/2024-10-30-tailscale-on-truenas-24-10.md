---
layout: post
title: "Enabling Tailscale access on TrueNAS Electric Eel (24.10)"
comments: True
date: "2024-10-30"
description: "Enabling Tailscale access on TrueNAS electric eel (24.10, docker based apps)"
---

TrueNAS 24.10 (Electric Eel) switched from kubernetes based apps to docker based ones. One of the apps is tailscale. 
I want tailscale to access my home based network when I'm away from home (from printing to access to the files/media) 
and therefore want the subnet router feature enabled. 

Here are the steps to get it working:

- In Tailscale: Create an auth key via the Tailscale web UI -> "Settings" -> 
  "[Keys](https://login.tailscale.com/admin/settings/keys)" -> "Generate auth key" (keep everything at default). 
  Copy the auth key.
- In TrueNAS: add Tailscale (in the community section) as an app, add the auth key from tailscale, enable "exit node" 
  and add a "route" (e.g. `192.168.xx.0/24`). Click Install at the bottom: it will do that, but will be stuck in the 
  `Deploying` state.
- In [Tailscale admin UI](https://login.tailscale.com/admin/machines), approve the new host and approve the subnet 
  router and exit node in the "three dots" menu. Afterward, the tailscale app will be in state `Running`.

If you look now in [Tailscale admin UI](https://login.tailscale.com/admin/machines), it will show (at least after a 
bit of time) the new node as not properly configured: the `Subnets` and `Exit Node` flags have a little exclamation 
point and if you follow the hints it tells you have to 
[enabled IP forwarding](https://tailscale.com/kb/1019/subnets?tab=linux#enable-ip-forwarding). To do so:

- In TrueNAS: Go to `System -> Advanced Settings -> Sysctls` and add the required sysctl there: 
  `net.ipv4.ip_forward = 1` and `net.ipv6.conf.all.forwarding = 1`.

I needed to reboot the NAS to get it properly working (e.g. using the NAS as an exit node from my mobile phone).

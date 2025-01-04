---
layout: post
title: "Migrating to another google account"
comments: True
date: "2025-01-03"
description: "Migrating from one google account to another is a lot of manual work and you might leave behind some data 
and some features."
---

I changed names and wanted a google account to match the new name. Unfortunately, basically half my digital life was 
tied to the old google account :-( Migrating (or even better: renaming) accounts seems to be not possible if you 
are on the regular (non-workspace/Uni) google accounts, so this is completely manual.

And before anyone asks: I'm on android, I like gmail spam filters, I like not having to do backups for any sync 
solution I would need, ... In short: I do not want to migrate away from google.

The main benefit from moving everything into the new account is that I can do proper calendar acceptances from the 
mail account. That was a major headache before when I used a non-google account for job searching but accepted 
the interview invitations from gmail, as that exposed my old (strangely named) account to the company. I also didn't 
want to have multiple google accounts in the long run.

So I came up with a long list of stuff which had to be migrated over to take advantage of the new setup and then 
went to work. It took me a few evenings over a few weeks to basically get through most of the list, but some items 
lingered (gdrive: transferring ownership) and some are not as nice as in the old account (face grouping in google 
photos). Here are the details:

## Google account itself

Basically went through all the account settings: Enabled 2fa; Added a photo; Setup date formats and such things; 
Setup recovery email.

## Google Family group

Thankfully, this was already set up from a shared account and I only needed to add the new account.

This might get tricky when I remove the old account, as I have some bought apps in the old account, which I now use in 
the new account via family sharing. I guess I will just buy them again if I actually miss any of them.

## Mail

I've not yet migrated the mails out of the old account. I imagine that will be a big copy and paste in 
thunderbird or some script (google takeout and then upload the mboxes?). The last time I migrated an old mailaccount 
into google via c&p in thunderbird: it took ages. 

I setup forwarding on all my other email accounts I still expect to use. For the ones that could not be configured to 
forward, I used gmails "other accounts" feature to pull emails regularly. 

I also used that opportunity for some house cleaning: I disabled all old newsletter I didn't want anymore and 
centralize the rest to use gmails `name+something@g.c` feature for easier sorting into folders. So basically went 
through all regular emails, removed the old address, and added the new one with a '+suffix' when I wanted to keep 
the newsletter.

I also changed all my monitoring and notifications to send email to a specific `+suffix` address. This was a bit 
painful, as I needed to change some at my parents' house and there I needed access to the phone to change the email.

Figuring out all the places which had to be changed proved ... interesting. Basically monitoring the old address 
every few days for about a few months until no more new email arrived in the old account.

## Contacts

I think I exported a file from the old account and imported that file in the new one. Went without any problems if 
I remember correctly.

## Calendar

I shared the calendar of the old account with the new account and then went to work changing all future calendar 
entries (and a few pasts where I wanted to go back) to the new account. Took a bit to make sure I didn't miss any...

Every other shared calendar had to be reshared with the new account (work, family account, etc). And the new one 
shared with work and partner and integrated there...

## Android mobile phone

I ended up adding the new account and then removing the old account at least for a while. It took quite a while to 
re-setup all the backups (for android itself, and some apps like WhatsApp and Google Photos) and the proper 
(color/visibility) setup for all the calenders.

Eventually, I added back the old account, but basically disabled syncing for most of the items in that account.

## Google wallet

It seems the credit cards are tied to the google account, not the phone, so I had to re-setup them all, including 
the authentication call with the bank (tip: do this in the middle of the night, the waiting time in the hotline will 
be much shorter than during the day :-))

Moving the vanity cards to the new account was also painful: in the end, I took an old phone with the old account still 
on it, and added them from there to the new account. Taking photos of the barcodes and using that would probably 
also have worked...

## Google Keep

We use that for our shopping list, so that list had to be shared with the new account (or I had to set up a new 
list because I didn't want to leave the old account the owner).

I also took this opportunity to clean up the old content I still had there from years ago and moved that elsewhere 
when it was still interesting...

## Google assistent

We use google assistent to add items to the shopping list and switch the Christmas decoration on and off.
I basically had to re-setup the whole thing: from training the voice to creating a new "home" and readding all the 
items (plugs, chromecast, google mini).

## Google One (space for mail and google drive)

The old plan was shared with other family members via a family group. I canceled the old plan (thankfully, I was 
lucky, as that plan had just a few more days) and bought a new plan from the new account and shared that again with 
the family group. As the old account is still part of the family group, that new shared plan currently covers the old 
account as well until I clean it up.

## Google drive

Moving data to a new account is ugly: while you can share all items to the new account easily, transferring 
ownership only works for the folders itself not all items in it. And for files, it only works 100 files/items at a 
time. I tried that for a bit but gave up and used rclone to basically copy everything over to the new account 
and re-setup all needed sharing with my partner from there.

I sync/copy gdrive locally, so I had to re-setup the sync mechanism with the new account.

## YouTube

Thankfully, I have no content in youtube, so no content needed to be moved.

For commenting, I needed to change my nickname in the old account to free the nickname for the new account. If I 
remember correctly, it took a few days to make the name available again.

I subscribe to a few channels: I basically opened them all, copied the url to the other browser with the new account 
logged in and subscribed from there again.

## Google Maps

I don't have much in google maps and what I wanted, I migrated manually (a few stared places). 

I wanted to migrate location history because I like going back and see where I was on a specific date or when I was 
in a specific place. However, there is apparently no way to import such data at all. Given that location history now 
anyway moves off googles server to the local phone, I decided to take a "takeout" and leave it at that. I guess I will 
setup a self-hosted solution for that use case.

## Google movies

This turned out to be shitty: some movies are shared via family sharing (the ones bought ages ago?) and some are not.
We use google to buy some disney movies for the kids, now that they are not available anymore from netflix and co. 
It seems they will be gone when I remove the old account completely from my phone (again). Thankfully it's only a 
handfull of movies, so I can still live with that, and hopefully the kids will not be interested in them anymore when 
(or if) they need their own family shared account...

## Google Photos

I use Google Photos mainly as a backup for my photos on the mobile phone, so I don't lose them if I lose my
mobile phone. For that, I reset google photos on the mobile (clear data) and re-setup the backup with the new account.

Moving all the old photos was easy: disable my regular partner sharing, enable sharing with my new google account,
wait a bit, disable it again. I also shared a few relevant albums (I'm not a heavy user of that feature) from the 
old account with the new one. It means I have a few fotos multiple times in the new account, but I found that easier 
than recreating the old albums.

Setting up "face grouping" was on the other hand a painful experience: years ago, I used a VPN to enable "face 
grouping". Unfortunately, that way seems to be gone and just enabling it in the app does not result in the same 
experience as the old setup: I cannot configure partner sharing for just some specific faces and actual face editing 
features are also not available :-( It seems that these features are not available in the EU :-(.

Training the face grouping was also a lot of manual work (naming faces, grouping them, and correcting the wrong 
groupings). I didn't setup all the faces again which I had collected over the years in the old account, just the 
more important ones. It also took Google ages to find all the faces: I think it still goes through all the pictures 
and reprocesses them, as new old faces appear. I also still get a lot of notifications for "relive these old 
pictures" and stuff...

Overall, google photos without grouped faces for sharing with my partner is also a strong contender for a self-hosted 
solution.

## Google account settings

At last, I took some rummaging around in the account settings of the old account, just to see if I missed something. 
I did discover some leftover credits in my store.google.com account and emptied that out. I probably also adjusted some 
settings in the new account.

There were also a few external accounts affected (apart from the whole "changing mail addresses" in a lot 
of accounts):

## Newspaper subscription

I used "login with google" and paid via google. Ended up canceling the old plan and opening a new one with the new 
account. Given that I could cancel in the google UI, that was easy enough.

## Tailscale

I use tailscale and that account was registered under the old google account. Basically had register with the new
account and re-setup the whole tailnet (parents, NAS, mobiles, ...) from the new account.

## Ingress

It seems there is no way to transfer an ingress account to a different google account (there was some idea to switch to 
facebook as ID and then from there to the different google account, but other had not-so-good experiences with that 
and I anyway have no facebook account). As I haven't played in a long time, I guess that will be the end of that 
game for me.

There are probably still a few accounts where I used "login with google." But as I don't miss them, I simply do not 
care anymore :-)

## Summary

Overall, it was a lot of manual work but not as painful as I originally imagined. I guess the worst was not having 
all google fotos features as in the old account and losing my location history. For both I guess I will end up 
with a self-hosted solution at some point.

---
layout: post
title: "Adding birthday reminder for birthdays saved in google contacts if you are in Germany"
comments: True
date: "2025-08-30"
description: ""
---

(this is mostly here to help me find it again, if I need it in the future.)

It seems Google removed the sync of birthdays in Google Contacts to the Google Calendar app, 
if you are located in Germany.
I have a "birthday calendar" in my phone
(seems a locally created one? It seems phone specific, not google account specific),
I have it properly configured to pull birthdays from all relevant Google accounts,
I have ["linked" contacts](https://myactivity.google.com/linked-services) in my Google account,
but still, the calendar is empty for about a year.

[This help article](https://support.google.com/calendar/answer/13748346) states:

> Important: As part of an agreement with a German regulator, we are making changes to how we process personal data.
> As a result, this feature may be less complete or not available.

Thankfully there is
this [nice help article](https://support.google.com/calendar/community-guide/302081881/birthdays-from-contacts-no-longer-showing-in-google-calendar?sjid=13554797038714138193-EU)
which links to a [video](https://youtu.be/8GrGT8SWs-8?si=scFVlKczWUPUL9EW) which gives you a script which 
automatically syncs the birthdays from Google Contacts to a separate calendar. 
The description of the video basically tells it all, 
but at least for me, 
it was easier to follow along where to click in Google Calendar to find the info I had to configure. :-)

I created a separate calendar for it in Google Calendar (Settings -> Add calendar), 
mostly because I didn't even find a "real" birthday calendar in my Google account on my mobile.
You need the "Calendar ID" which is at the bottom of the page when you open the settings of that calendar.
That ID has to be added in the configuration section of the script. 
The header of the script should tell you the rest ...

And boom: a calendar you can view with all your contacts' birthdays, even in Germany...

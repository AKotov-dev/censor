# Censor - Scheduled Website Blocker
**Dependencies:** iptables, ipset, systemd, cronie, bind-utils, polkit, gtk2

`Censor` is designed to block sites from the black list according to the schedule: `days of the week`, `time`.

It has three blocking options that differ in their effectiveness:
+ normal; sites from the list are blocked using `ipset` + `iptables/ip6tables`
+ dictionary filtering method; useful for blocking "difficult" sites like `youtube.com`
+ only web-surfing; method allows you to disable VPN, Torrent, Skype and other services

![](https://github.com/AKotov-dev/censor/blob/main/ScreenShot4.png)

How to work
--
+ Add to the list addresses of sites without `http(s)` that you want to block
+ If necessary, specify the desired blocking method (the strongest - everything is included)
+ Specify the days of the week and the time interval during which the blocking will be active
+ Click the `Apply` button

Open a browser and check your work. If you changed the blocking rules again, **the browser needs to be reopened** and check the work again. The `Reset` button removes all locks and returns full access to the Internet.

In case the site is not blocked (eg `yotube.com` or similar), add another one of the same address with `www.` prefix at the beginning (`www.youtube.com`) and click `Apply`. Reopen your browser and check the blocking again.  
  
**Note:** I remind you that the time in the scheduler is set in a 24-hour format. For example, if it is 4:27 PM on your computer, then you need to specify 16:27 in the scheduler. PM is the time after noon, i.e. after 12:00. ;)  
  
**Similar program:** [SiteBlocker](https://github.com/AKotov-dev/siteblocker) - a small blocker of sites and other content by time (Linux-router).

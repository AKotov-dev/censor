# Censor - Scheduled Website Blocker (Parental Control)

`Censor` is designed to block sites from the black list according to the schedule: `days of the week`, `time`.

It has three blocking options that differ in their effectiveness:
+ normal; sites from the list are blocked using ipset + iptables/ip6tables
+ dictionary filtering method; useful for blocking "difficult" sites like `youtube.com`
+ only web-surfing; method allows you to disable VPN, Torrent, Skype and other services

How to work
--
+ Add to the list addresses of sites without `http(s)` that you want to block
+ If necessary, specify the desired blocking method (the strongest - everything is included)
+ Specify the days of the week and the time interval during which the blocking will be active
+ Click the `Apply` button

Open a browser and check your work. If you changed the blocking rules again, **the browser needs to be reopened** and check the work again. The `Reset` button removes all locks and returns full access to the Internet.

In case the site is not blocked (for example `yotube.com` or similar), add its address with `www.` prefix at the beginning (`www.youtube.com`) and click `Apply`. Reopen your browser and check the blocking again.

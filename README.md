# clipnetsync

Tiny Lua program that shares (synchronizes) X11 selections (clipboard) between remote hosts.

It requires [lua-socket][] and [xsel][] installed. I use it with [Barrier][] and [Xpra][]
on my multihost system. App realizes server-client model, so you should run `lua server.lua` on one host and
`lua client.lua <server ip address>` on another. Config placed in `config.lua`. I recommend to switch off Barrier
native clipboard sharing (but not Xpra yet) to avoid interference.

Enjoy.

![My home multihost system](https://github.com/Kirill-Bugaev/clipnetsync/blob/master/screenshots/my-home-system.jpg)

## TLS
If you are going to use it in secure mode (of course you should) then install [lua-sec][], create your own
PKI (see ArchWiki [Easy-RSA][] how to do this) and move generated keys and certificates to `./certs`
directory (there are mine by default, replace it).

## Daemonize
To run in background (both server and client) install [lua-posix][] and set `true` value to `forktobg`
variable in `config.lua`
```lua
local forktobg = true
```

## Start once at boot
I have written ugly systemd services for start at system boot. You can find it in `systemd` directory.
How to manage systemd units see ArchWiki [systemd][].
If you gonna to use it change `WorkingDirectory` entry to path where this app placed on your system
(I have created NFS share on my system, so all hosts run the same copy of app). For daemon mode
(if you done what said in [Daemonize][]) set `Type=forking`. Another entry which you could wanna to change
is `Environment=DISPLAY=:0`. E.g. if you run this app on virtual machine with VNC, you probably should
set `Environment=DISPLAY=:1` (or what X11 `DISPLAY` your VNC uses). And of course you should change IP
address in `ExecStart` entry of `clipnetsync-client.service` to IP address of machine where server module
of this app runs.

## Troubleshooting

### busy tcp port
```shell
$ lua server.lua
can't bind socket to port xxxxx
address already in use
```
You are trying to start server on busy tcp port. Change port number in `config.lua` (just try to increment
existing by 1)
```lua
local port = 46846
```

### wrong systemd service Type
```shell
$ systemctl --user status clipnetsync-server.service
...
... systemd[658]: clipnetsync-server.service: Control process exited, code=killed, status=15/TERM
... systemd[658]: clipnetsync-server.service: Failed with result 'timeout'.
... systemd[658]: Failed to start share X11 clipboard between remote hosts.
```
You probably set `forktobg = false` in `config.lua` and `Type=forking` in systemd unit. See [Daemonize][].
You should set one of two things: `forktobg = false` and `Type=simple` or `forktobg = true` and `Type=forking`. 

### "xsel -o ..." hangs on
Sometimes [xsel][] hangs on output pipe. In this case clipnetsync hangs on too, because it reads from pipe in
blocking mode. Killing `xsel -o ...` process solves the problem. I have added [poll][] pipe before read
([lua-posix][] required). Hope this helps.

### other issues 
You can switch off daemon and on debug mode in `config.lua` to watch program behaviour
```lua
local forktobg = false
local debug    = true
```
If you still have problems [welcome][New issues].


## TODO
* replace xsel by native clipboard routine
* add clipboard sharing for all X-DISPLAYS
* add man
* make AUR package

[lua-socket]: https://www.archlinux.org/packages/community/x86_64/lua-socket/
[lua-sec]: https://www.archlinux.org/packages/community/x86_64/lua-sec/
[lua-posix]: https://aur.archlinux.org/packages/lua-posix/
[xsel]: https://www.archlinux.org/packages/community/x86_64/xsel/
[Barrier]: https://github.com/debauchee/barrier      
[Xpra]: https://xpra.org/
[Easy-RSA]: https://wiki.archlinux.org/index.php/Easy-RSA
[systemd]: https://wiki.archlinux.org/index.php/Systemd 
[Daemonize]: #Daemonize
[poll]: https://luaposix.github.io/luaposix/modules/posix.poll.html#poll
[New issues]: https://github.com/Kirill-Bugaev/clipnetsync/issues/new

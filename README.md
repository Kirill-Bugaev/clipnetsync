# clipnetsync

Tiny Lua program that shares (synchronizes) X11 selections (clipboard) between remote hosts.

It requires [lua-socket][lua-socket] and [xsel][xsel] installed. I use it with [Barrier][Barrier] and [Xpra][Xpra]
on my multihost system. If you are going to use it in secure mode (of course you should) then install
[lua-sec][lua-sec], create PKI (see ArchWiki [Easy-RSA][Easy-RSA] how to do this) and move generated keys and
certificates to `./certs` directory (there are mine by default, replace it).

App uses server-client model, so you should run `lua server.lua` on one host and `lua client.lua <server ip address>` on another.
Config placed in `config.lua`.

I recommend to switch off Barrier native clipboard sharing (but not Xpra yet) to avoid interference.

Enjoy.

![My home multihost system](https://github.com/Kirill-Bugaev/clipnetsync/blob/master/screenshots/my-home-system.jpg)

## TODO
* replace xsel by native clipboard routine
* add clipboard sharing for all X-DISPLAYS
* add daemon mode
* add man
* add Windows support
* make AUR package

[lua-socket]: https://www.archlinux.org/packages/community/x86_64/lua-socket/
[lua-sec]: https://www.archlinux.org/packages/community/x86_64/lua-sec/
[xsel]: https://www.archlinux.org/packages/community/x86_64/xsel/
[Barrier]: https://github.com/debauchee/barrier      
[Xpra]: https://xpra.org/
[Easy-RSA]: https://wiki.archlinux.org/index.php/Easy-RSA

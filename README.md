# clipnetsync
It requires [lua-socket][lua-socket] and [xsel][xsel] installed. I use it with [Barrier][Barrier] and [Xpra][Xpra] on my multihost
system. Of course it is insecure. If you are going to use it anyway I recommend to switch off Barrier native clipboard sharing
(but not Xpra yet) to avoid interference.
App uses client-server model, so you should run `lua server.lua` on one host and `lua client.lua <server ip address>` on another.
Config placed in `config.lua`. Enjoy.

![My home multihost system](https://github.com/Kirill-Bugaev/clipnetsync/blob/master/screenshots/my-home-system.jpg)

## TODO
* add clipboard sharing for all X-DISPLAYS
* add ssl support
* add daemon mode

[lua-socket]: https://www.archlinux.org/packages/community/x86_64/lua-socket/
[xsel]: https://www.archlinux.org/packages/community/x86_64/xsel/
[Barrier]: https://github.com/debauchee/barrier      
[Xpra]: https://xpra.org/

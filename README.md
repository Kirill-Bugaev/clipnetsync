# clipnetsync
It requires [lua-socket][lua-socket] and [xsel][xsel] installed. I use it with Barrier and Xpra on my multihost system. Of course it is insecure.
If you are going to use it anyway I recommend to switch off Barrier clipboard sharing (but not Xpra yet) to avoid interference.
Config placed in `config.lua`. Client usage `lua client.lua <server ip address>`. Enjoy.

![My home multihost system](https://github.com/Kirill-Bugaev/clipnetsync/blob/master/screenshots/my-home-system.jpg)

## TODO
* add clipboard sharing for all X-DISPLAYS
* add ssl support
* add daemon mode

[lua-socket]: https://www.archlinux.org/packages/community/x86_64/lua-socket/
[xsel]: https://www.archlinux.org/packages/community/x86_64/xsel/

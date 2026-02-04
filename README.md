# SS-Cloak
Shadowsocks-Rust client (with GUI) and server (for VPS) with obfuscation.  
  
**Dependencies:** systemd qrencode gtk2 (libgtk2.0-0 for Ubuntu)  
  
**Work directories:**
+ Client: `~/.config/ss-cloak-client`; Service: `/etc/systemd/user/ss-cloak-client.service`
+ Server: `/etc/ss-cloak-server`; Service: `/etc/systemd/system/ss-cloak-server.service`

![](https://github.com/AKotov-dev/SS-Cloak/blob/main/Screenshot1.png)  
  
SS-Cloak-Server
--
Rent a VPS with a foreign IP address and install a package on it `ss-cloak-server` ([rpm/deb](https://github.com/AKotov-dev/SS-Cloak/releases))

SS-Cloak-Client
--
Install the `ss-cloak-client` package to your computer, launch the GUI, enter the IP address / Port of your server and click the `Create conf` button. The Client configuration files will be created and you will be prompted to save the `server-conf.tar.gz` archive in order to place the `config.json` and `ckserver.json` files on the server in the working directory `/etc/ss-cloak-server`. With each click of the `Create conf` button, new/unique Client and Server configurations are created with automatic change of `PublicKey`, `PrivateKey`, `Password`, `UID`, etc.  
  
After that, start the server: `systemctl restart ss-cloak-server` and the client (`Start` button). Set up a connection in your browser via the SOCKS5 proxy 127.0.0.1:1080. Also check the box `Send DNS requests via SOCKS5 proxy`. When using `SWP` (System-wide proxy) mode, `Chromium-based` browsers receive proxy settings `automatically`: the proxy is `enabled and disabled on the fly`, without the need for manual intervention. You can check your new location here: https://whoer.net

## System‑wide Proxy mode and DNS considerations

Starting with `ss-cloak-client v0.4`, a `System‑wide Proxy (SWP)` mode and `domain zone bypassing` were introduced (direct connections that bypass proxy, e.g. `.ru`, `.ir`, etc.).

The `System‑wide Proxy` mode hermetically seals the `GUI session`, including DNS resolution (browsers and other GUI applications). However, in desktop environments based on `gsettings + libproxy`, the `env/CLI` layer receives proxy variables as `all_proxy/ALL_PROXY=socks://…`. This results in `SOCKS4‑level usage`, meaning `DNS resolution is performed locally`, unlike `socks5h://`, where DNS is resolved through the proxy.

For `reliable use of System‑wide Proxy mode` in `XFCE`, `LXDE` (as well as `i3, IceWM, OpenBox`), it is strongly recommended to install [XDE‑Proxy‑GUI](https://github.com/AKotov-dev/xde-proxy-gui), which ensures correct and consistent proxy handling in GUI sessions.

For `robust DNS protection against MITM attacks` when a proxy is `not used`, it is `recommended` to use [DNSCrypt‑GUI](https://github.com/AKotov-dev/dnscrypt-gui).

If `System‑wide Proxy` is not feasible in your desktop environment, a practical alternative is to use `browser‑level proxy extensions`, such as `Socks5 Configurator`.
  
**Useful links:** [Shadowsocks-Rust](https://github.com/shadowsocks/shadowsocks-rust), [Cloak](https://github.com/cbeuw/Cloak), [GO Simple Tunnel](https://github.com/ginuerzh/gost). **Similar project:** [SS-Obfuscator](https://github.com/AKotov-dev/SS-Obfuscator).

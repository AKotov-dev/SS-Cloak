# SS-Cloak
Shadowsocks-Rust client (with GUI) and server (for VPS) with obfuscation.  
  
**Dependencies:** systemd qrencode gtk2  
  
**Work directories:**
+ Client: `~/.config/ss-cloak-client`; Service: `/etc/systemd/user/ss-cloak-client.service`
+ Server: `/etc/ss-cloak-server`; Service: `/etc/systemd/system/ss-cloak-server.service`
  
SS-Cloak-Server
--
Rent a VPS with a foreign IP address and install a package on it `ss-cloak-server` ([rpm/deb](https://github.com/AKotov-dev/SS-Cloak/releases))

SS-Cloak-Client
--
Install the `ss-cloak-client` package to your computer, launch the GUI, enter the IP address / Port of your server and click the `Create conf` button. The Client configuration files will be created and you will be prompted to save the `server-conf.tar.gz` archive in order to place the `config.json` and `ckserver.json` files on the server in the working directory `/etc/ss-cloak-server`. With each click of the `Create conf` button, new/unique Client and Server configurations are created with automatic change of `PublicKey`, `PrivateKey`, `Password`, `UID`, etc.  
  
After that, start the server: `systemctl restart ss-cloak-server` and the client (`Start` button). Set up a connection in your browser via the SOCKS5 proxy 127.0.0.1:1080. Also check the box `Send DNS requests via SOCKS5 proxy`. For the `Chrome` browser, it is convenient to use the `Socks5 Configurator` plugin. You can check your new location here: https://whoer.net   
  
![](https://github.com/AKotov-dev/SS-Cloak/blob/main/ScreenShots/ScreenShot3.png)  

**Useful links:** [Shadowsocks-Rust](https://github.com/shadowsocks/shadowsocks-rust), [Cloak](https://github.com/cbeuw/Cloak). **Similar project:** [SS-Obfuscator](https://github.com/AKotov-dev/SS-Obfuscator).

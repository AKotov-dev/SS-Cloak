# SS-Cloak
Shadowsocks-Rust client (with GUI) and server (for VPS) with obfuscation  
**Work directories:**
+ Client: ~/.config/ss-cloak-client; Service: /etc/systemd/user/ss-cloak-client.service
+ Server: /etc/ss-cloak-server; Service: /etc/systemd/ss-cloak-server.service
  
SS-Cloak-Server
--
Rent a VPS with a foreign IP address and install a package on it `ss-obfuscator-server` ([rpm/deb](https://github.com/AKotov-dev/SS-Cloak/releases))

SS-Cloak-Client
--
Install the `ss-cloak-client` package to your computer, launch the GUI, enter the IP address of your server (VPS) and click the `Save settings` button. The Client configuration files will be created and you will be prompted to save the `server-conf.tar.gz` archive in order to place the `config.json` and `ckserver.json` files on the server in the working directory `/etc/ss-cloak-server`.  
  
After that, start the server: `systemctl restart ss-cloak-server` and the client (the `Start` button). Set up a connection in your browser via the SOCKS5 proxy 127.0.0.1:1080. Also check the box `Send DNS requests via SOCKS5 proxy`. You can check your new location here: https://whoer.net   
  
![](https://github.com/AKotov-dev/SS-Cloak/blob/main/ScreenShots/Screenshot2.png)  


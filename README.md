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
  
After that, start the server: `systemctl restart ss-cloak-server` and the client (`Start` button). Set up a connection in your browser via the SOCKS5 proxy 127.0.0.1:1080. Also check the box `Send DNS requests via SOCKS5 proxy`. For the `Chrome` browser, it is convenient to use the `Socks5 Configurator` plugin. You can check your new location here: https://whoer.net 

## System-wide proxy, DNS, and limitations

Starting from `ss-cloak-client v0.4`, a `System-wide Proxy` (SWP) mode and domain zone bypass (direct connections outside the proxy, e.g. .ru, .ir, etc.) were introduced.

System-wide Proxy significantly improves traffic coverage for GUI applications (browsers, messengers, etc.), however it is NOT fully hermetic by itself.

### Important note about DNS

DNS resolution is not automatically tunneled through a system proxy.

In desktop environments based on `gsettings + libproxy`, proxy settings are exported into the environment as:
```
ALL_PROXY=socks://127.0.0.1:1080
```
This format implies local DNS resolution (SOCKS4-like behavior) and does not provide remote DNS resolution as in `socks5h://`.

**As a result:**
- TCP/HTTPS traffic is proxied
- DNS queries are still sent via the system resolver
- If the system DNS is unencrypted (e.g. 8.8.8.8), DNS traffic may be observable on the network

### Recommendations

- For reliable and secure usage of System-wide Proxy mode, it is strongly recommended to:
- Use a local encrypted DNS resolver, such as [DNSCrypt-GUI](https://github.com/AKotov-dev/dnscrypt-gui)
- This ensures DNS confidentiality even when DNS is not routed through the proxy.

In lightweight DEs or WMs (XFCE, LXDE, i3, IceWM, OpenBox), install [XDE-Proxy-GUI](https://github.com/AKotov-dev/xde-proxy-gui) for consistent proxy configuration across GUI applications.

If `System-wide Proxy` is unavailable in your DE, browser extensions (e.g. `Socks5 Configurator)` may be used as a fallback.

### Summary
- System-wide Proxy ≠ DNS protection
- DNS must be encrypted separately
- Proxy + encrypted DNS = predictable and clean behavior
  
**Useful links:** [Shadowsocks-Rust](https://github.com/shadowsocks/shadowsocks-rust), [Cloak](https://github.com/cbeuw/Cloak). **Similar project:** [SS-Obfuscator](https://github.com/AKotov-dev/SS-Obfuscator).

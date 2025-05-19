# Zetachain
ZetaChain is the first Universal Blockchain with native access to Bitcoin, Ethereum, Solana, and more, offering seamless UX and unified liquidity to the next billions of users.

# 🌟 Zetachain Setup & Upgrade Scripts

A collection of automated scripts for setting up and upgrading Zetachain nodes on **Mainnet (`zetachain_7000-1`)**.

---

### ⚙️ Validator Node Setup  
Install a Zetachain validator node with custom ports, snapshot download, and systemd service configuration.

~~~bash
source <(curl -s https://raw.githubusercontent.com/validexisinfra/Zetachain/main/installmain.sh)
~~~
---

### 🔄 Validator Node Upgrade 
Upgrade your Zetachain node binary and safely restart the systemd service.

~~~bash
source <(curl -s https://raw.githubusercontent.com/validexisinfra/Zetachain/main/upgrademain.sh)
~~~

---

### 🧰 Useful Commands

| Task            | Command                                 |
|-----------------|------------------------------------------|
| View logs       | `journalctl -u zetacored -f -o cat`        |
| Check status    | `systemctl status zetacored`              |
| Restart service | `systemctl restart zetacored`             |

#!/bin/bash

set -e

GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m"

print() {
  echo -e "${GREEN}$1${NC}"
}

print_error() {
  echo -e "${RED}$1${NC}"
}

read -p "Enter your node MONIKER: " MONIKER
read -p "Enter your custom port prefix (e.g. 16): " CUSTOM_PORT

print "Installing Zetachain Node with moniker: $MONIKER"
print "Using custom port prefix: $CUSTOM_PORT"

print "Updating system and installing dependencies..."
sudo apt update
sudo apt install -y curl git build-essential lz4 wget

sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.23.6.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)
echo "export PATH=$PATH:/usr/local/go/bin:/usr/local/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile

cd $HOME
wget -O $HOME/zetacored https://github.com/zeta-chain/node/releases/download/v29.1.2/zetacored-linux-amd64
chmod +x $HOME/zetacored 
mv $HOME/zetacored $HOME/go/bin

zetacored config set client chain-id zetachain_7000-1
zetacored config set client keyring-backend file
zetacored config set client node tcp://localhost:${CUSTOM_PORT}657
zetacored init $MONIKER --chain-id=zetachain_7000-1

curl -L https://snapshots.nodejumper.io/zetachain/genesis.json > $HOME/.zetacored/config/genesis.json
curl -L https://snapshots.nodejumper.io/zetachain/addrbook.json > $HOME/.zetacored/config/addrbook.json

sed -i -e 's|^seeds *=.*|seeds = "20e1000e88125698264454a884812746c2eb4807@seeds.lavenderfive.com:22556,1d41d344d3370d2ba54332de4967baa5cbd70a06@rpc.zetachain.nodestake.org:666,ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@seeds.polkachu.com:22556,8d93468c6022fb3b263963bdea46b0a131d247cd@34.28.196.79:26656,637077d431f618181597706810a65c826524fd74@zetachain.rpc.nodeshub.online:22556,11b86546b092e0645a91b32ca78e40c8bec54546@zetachain-m.peer.stavr.tech:17656"|' $HOME/.zetacored/config/config.toml
sed -i -e 's|^minimum-gas-prices *=.*|minimum-gas-prices = "20000000000azeta"|' $HOME/.zetacored/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.zetacored/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.zetacored/config/config.toml
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.zetacored/config/app.toml 
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.zetacored/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"19\"/" $HOME/.zetacored/config/app.toml
  
sed -i.bak -e "s%:26658%:${CUSTOM_PORT}658%g;
s%:26657%:${CUSTOM_PORT}657%g;
s%:26656%:${CUSTOM_PORT}656%g;
s%:6060%:${CUSTOM_PORT}060%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${CUSTOM_PORT}56\"%;
s%:26660%:${CUSTOM_PORT}660%g" $HOME/.zetacored/config/config.toml

sed -i.bak -e "s%:1317%:${CUSTOM_PORT}317%g;
s%:8080%:${CUSTOM_PORT}080%g;
s%:9090%:${CUSTOM_PORT}090%g;
s%:9091%:${CUSTOM_PORT}091%g;
s%:8545%:${CUSTOM_PORT}545%g;
s%:8546%:${CUSTOM_PORT}546%g" $HOME/.zetacored/config/app.toml

sudo tee /etc/systemd/system/zetacored.service > /dev/null <<EOF
[Unit]
Description=Zetachain node
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/.zetacored
ExecStart=$(which zetacored) start --home $HOME/.zetacored
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

print "Downloading snapshot..."
curl "https://snapshots.nodejumper.io/zetachain/zetachain_latest.tar.lz4" | lz4 -dc - | tar -xf - -C "$HOME/.zetacored"

sudo systemctl daemon-reload
sudo systemctl enable zetacored
sudo systemctl restart zetacored

print "✅ Setup complete. Use 'journalctl -u zetacored -f -o cat' to view logs"

#/bin/bash

echo "We will update your Highstakes Masternode right now" 
sudo apt-get -y install unzip
highstakes-cli stop
rm -rf /usr/local/bin/highstakes*
mkdir HISCUpdated_1.0.0.0
cd HISCUpdated_1.0.0.0
wget https://github.com/HighStakesCoin/HighStakes/releases/download/v1.0.0.0/Highstakes-1.0.0.0-daemon-ubuntu_16.04.tar.gz
tar xzvf Highstakes-1.0.0.0-daemon-ubuntu_16.04.tar.gz
mv highstakesd /usr/local/bin/highstakesd
mv highstakes-cli /usr/local/bin/highstakes-cli
chmod +x /usr/local/bin/highstakes*
rm -rf ~/.highstakes/blocks
rm -rf ~/.highstakes/chainstate
rm -rf ~/.highstakes/peers.dat
cd ~/.highstakes/
wget https://github.com/HighStakesCoin/HighStakes/releases/download/v1.0.0.0/bootstrap.zip
unzip bootstrap.zip
cd ..
cd HISCUpdated_1.0.0.0
highstakesd -daemon
sleep 10
highstakes-cli addnode 138.197.136.115 onetry
highstakes-cli addnode 178.62.76.63 onetry
highstakes-cli addnode 104.248.215.3 onetry
highstakes-cli addnode 138.197.156.244 onetry
highstakes-cli addnode 178.128.75.39 onetry
highstakes-cli addnode 178.62.244.69 onetry
highstakes-cli addnode 159.89.123.24 onetry
echo "Masternode Updated!"
echo "Please wait for few minutes and start your Masternode again on your Local Wallet"


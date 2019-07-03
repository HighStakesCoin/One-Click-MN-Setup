#!/bin/bash
# Highstakes Masternode Setup Script V1 for Ubuntu 16.04 LTS
#
# Script will attempt to autodetect primary public IP address
# and generate masternode private key unless specified in command line
#
# Usage:
# bash highstakes.autoinstall.sh
#

#Color codes
RED='\033[0;91m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#TCP port
PORT=12319
RPC=12318

#Clear keyboard input buffer
function clear_stdin { while read -r -t 0; do read -r; done; }

#Delay script execution for N seconds
function delay { echo -e "${GREEN}Sleep for $1 seconds...${NC}"; sleep "$1"; }

#Stop daemon if it's already running
function stop_daemon {
    if pgrep -x 'highstakesd' > /dev/null; then
        echo -e "${YELLOW}Attempting to stop highstakesd${NC}"
        highstakes-cli stop
        sleep 30
        if pgrep -x 'highstakesd' > /dev/null; then
            echo -e "${RED}highstakesd daemon is still running!${NC} \a"
            echo -e "${RED}Attempting to kill...${NC}"
            sudo pkill -9 highstakesd
            sleep 30
            if pgrep -x 'highstakesd' > /dev/null; then
                echo -e "${RED}Can't stop highstakesd! Reboot and try again...${NC} \a"
                exit 2
            fi
        fi
    fi
}
#Function detect_ubuntu

 if [[ $(lsb_release -d) == *16.04* ]]; then
   UBUNTU_VERSION=16
else
   echo -e "${RED}You are not running Ubuntu 16.04, Installation is cancelled.${NC}"
   exit 1

fi

#Process command line parameters
genkey=$1
clear

echo -e "${GREEN} ------- Highstakes MASTERNODE INSTALLER v1.0.0--------+
 |                                                  |
 |                                                  |::
 |       The installation will install and run      |::
 |        the masternode under a user highstakes.         |::
 |                                                  |::
 |        This version of installer will setup      |::
 |           fail2ban and ufw for your safety.      |::
 |                                                  |::
 +------------------------------------------------+::
   ::::::::::::::::::::::::::::::::::::::::::::::::::S${NC}"
echo "Do you want me to generate a masternode private key for you?[y/n]"
read DOSETUP

if [[ $DOSETUP =~ "n" ]] ; then
          read -e -p "Enter your private key:" genkey;
              read -e -p "Confirm your private key: " genkey2;
    fi

#Confirming match
  if [ $genkey = $genkey2 ]; then
     echo -e "${GREEN}MATCH! ${NC} \a" 
else 
     echo -e "${RED} Error: Private keys do not match. Try again or let me generate one for you...${NC} \a";exit 1
fi
sleep .5
clear

# Determine primary public IP address
dpkg -s dnsutils 2>/dev/null >/dev/null || sudo apt-get -y install dnsutils
publicip=$(dig +short myip.opendns.com @resolver1.opendns.com)

if [ -n "$publicip" ]; then
    echo -e "${YELLOW}IP Address detected:" $publicip ${NC}
else
    echo -e "${RED}ERROR: Public IP Address was not detected!${NC} \a"
    clear_stdin
    read -e -p "Enter VPS Public IP Address: " publicip
    if [ -z "$publicip" ]; then
        echo -e "${RED}ERROR: Public IP Address must be provided. Try again...${NC} \a"
        exit 1
    fi
fi
if [ -d "/var/lib/fail2ban/" ]; 
then
    echo -e "${GREEN}Packages already installed...${NC}"
else
    echo -e "${GREEN}Updating system and installing required packages...${NC}"

sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove
sudo apt-get -y install wget nano htop jq
sudo apt-get -y install libzmq3-dev
sudo apt-get -y install libevent-dev -y
sudo apt-get install unzip
sudo apt install unzip
sudo apt -y install software-properties-common
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get -y update
sudo apt-get -y install libdb4.8-dev libdb4.8++-dev -y
sudo apt-get -y install libminiupnpc-dev
sudo apt-get install -y unzip libzmq3-dev build-essential libssl-dev libboost-all-dev libqrencode-dev libminiupnpc-dev libboost-system1.58.0 libboost1.58-all-dev libdb4.8++ libdb4.8 libdb4.8-dev libdb4.8++-dev libevent-pthreads-2.0-5 -y
   fi

#Network Settings
echo -e "${GREEN}Installing Network Settings...${NC}"
{
sudo apt-get install ufw -y
} &> /dev/null
echo -ne '[##                 ]  (10%)\r'
{
sudo apt-get update -y
} &> /dev/null
echo -ne '[######             ] (30%)\r'
{
sudo ufw default deny incoming
} &> /dev/null
echo -ne '[#########          ] (50%)\r'
{
sudo ufw default allow outgoing
sudo ufw allow ssh
} &> /dev/null
echo -ne '[###########        ] (60%)\r'
{
sudo ufw allow $PORT/tcp
sudo ufw allow $RPC/tcp
} &> /dev/null
echo -ne '[###############    ] (80%)\r'
{
sudo ufw allow 22/tcp
sudo ufw limit 22/tcp
} &> /dev/null
echo -ne '[#################  ] (90%)\r'
{
echo -e "${YELLOW}"
sudo ufw --force enable
echo -e "${NC}"
} &> /dev/null
echo -ne '[###################] (100%)\n'

#Generating Random Password for  JSON RPC
rpcuser=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
rpcpassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

#Create 2GB swap file
if grep -q "SwapTotal" /proc/meminfo; then
    echo -e "${GREEN}Skipping disk swap configuration...${NC} \n"
else
    echo -e "${YELLOW}Creating 2GB disk swap file. \nThis may take a few minutes!${NC} \a"
    touch /var/swap.img
    chmod 600 swap.img
    dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
    mkswap /var/swap.img 2> /dev/null
    swapon /var/swap.img 2> /dev/null
    if [ $? -eq 0 ]; then
        echo '/var/swap.img none swap sw 0 0' >> /etc/fstab
        echo -e "${GREEN}Swap was created successfully!${NC} \n"
    else
        echo -e "${RED}Operation not permitted! Optional swap was not created.${NC} \a"
        rm /var/swap.img
    fi
fi
 
#Installing Daemon
cd ~
rm -rf /usr/local/bin/highstakes*
wget https://github.com/HighStakesCoin/HighStakes/releases/download/v1.0.0.0/Highstakes-1.0.0.0-daemon-ubuntu_16.04.tar.gz
tar -xzvf Highstakes-1.0.0.0-daemon-ubuntu_16.04.tar.gz
sudo chmod -R 755 highstakes-cli
sudo chmod -R 755 highstakesd
cp -p -r highstakesd /usr/local/bin
cp -p -r highstakes-cli /usr/local/bin

 highstakes-cli stop
 sleep 5
 #Create datadir
 if [ ! -f ~/.highstakes/highstakes.conf ]; then 
 	sudo mkdir ~/.highstakes
 fi
cd ~/.highstakes/ && wget https://github.com/HighStakesCoin/HighStakes/releases/download/v1.0.0.0/bootstrap.zip
cd ~/.highstakes/ && unzip bootstrap.zip
cd ~
clear
echo -e "${YELLOW}Creating highstakes.conf...${NC}"

# If genkey was not supplied in command line, we will generate private key on the fly
if [ -z $genkey ]; then
    cat <<EOF > ~/.highstakes/highstakes.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
EOF

    sudo chmod 755 -R ~/.highstakes/highstakes.conf

    #Starting daemon first time just to generate masternode private key
    highstakesd -daemon
sleep 7
while true;do
    echo -e "${YELLOW}Generating masternode private key...${NC}"
    genkey=$(highstakes-cli masternode genkey)
    if [ "$genkey" ]; then
        break
    fi
sleep 7
done
    fi
    
    #Stopping daemon to create highstakes.conf
    highstakes-cli stop
    sleep 5
# Create highstakes.conf
cat <<EOF > ~/.highstakes/highstakes.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
rpcallowip=127.0.0.1
rpcport=$RPC
port=$PORT
listen=1
server=1
daemon=1
logtimestamps=1
maxconnections=256
masternode=1
externalip=$publicip
bind=$publicip
masternodeaddr=$publicip
masternodeprivkey=$genkey
addnode=138.197.136.115
addnode=178.62.76.63
addnode=104.248.215.3
addnode=138.197.156.244
addnode=178.128.75.39
addnode=178.62.244.69
addnode=159.89.123.24
addnode=178.62.233.51
 
EOF
    highstakesd -daemon -reindex
#Finally, starting daemon with new highstakes.conf
printf '#!/bin/bash\nif [ ! -f "~/.highstakes/highstakes.pid" ]; then /usr/local/bin/highstakesd -daemon ; fi' > /root/highstakesauto.sh
chmod -R 755 highstakesauto.sh
#Setting auto start cron job for highstakes
if ! crontab -l | grep "highstakesauto.sh"; then
    (crontab -l ; echo "*/5 * * * * /root/highstakesauto.sh")| crontab -
fi

echo -e "========================================================================
${GREEN}Masternode setup is complete!${NC}
========================================================================
Masternode was installed with VPS IP Address: ${GREEN}$publicip${NC}
Masternode Private Key: ${GREEN}$genkey${NC}
Now you can add the following string to the masternode.conf file 
======================================================================== \a"
echo -e "${GREEN}highstakes_mn1 $publicip:$PORT $genkey TxId TxIdx${NC}"
echo -e "========================================================================
Use your mouse to copy the whole string above into the clipboard by
tripple-click + single-click (Dont use Ctrl-C) and then paste it 
into your ${GREEN}masternode.conf${NC} file and replace:
    ${GREEN}highstakes_mn1${NC} - with your desired masternode name (alias)
    ${GREEN}TxId${NC} - with Transaction Id from masternode outputs
    ${GREEN}TxIdx${NC} - with Transaction Index (0 or 1)
     Remember to save the masternode.conf and restart the wallet!
To introduce your new masternode to the highstakes network, you need to
issue a masternode start command from your wallet, which proves that
the collateral for this node is secured."

clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "Wait for the node wallet on this VPS to sync with the other nodes
on the network. Eventually the 'Is Synced' status will change
to 'true', which will indicate a comlete sync, although it may take
from several minutes to several hours depending on the network state.
Your initial Masternode Status may read:
    ${GREEN}Node just started, not yet activated${NC} or
    ${GREEN}Node  is not in masternode list${NC}, which is normal and expected.
"
clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "
${GREEN}...scroll up to see previous screens...${NC}
Here are some useful commands and tools for masternode troubleshooting:
========================================================================
To view masternode configuration produced by this script in highstakes.conf:
${GREEN}cat ~/.highstakes/highstakes.conf${NC}
Here is your highstakes.conf generated by this script:
-------------------------------------------------${GREEN}"
echo -e "${GREEN}highstakes_mn1 $publicip:$PORT $genkey TxId TxIdx${NC}"
cat ~/.highstakes/highstakes.conf
echo -e "${NC}-------------------------------------------------
NOTE: To edit highstakes.conf, first stop the highstakesd daemon,
then edit the highstakes.conf file and save it in nano: (Ctrl-X + Y + Enter),
then start the highstakesd daemon back up:
to stop:              ${GREEN}highstakes-cli stop${NC}
to start:             ${GREEN}highstakesd${NC}
to edit:              ${GREEN}nano ~/.highstakes/highstakes.conf${NC}
to check mn status:   ${GREEN}highstakes-cli masternode status${NC}
========================================================================
To monitor system resource utilization and running processes:
                   ${GREEN}htop${NC}
========================================================================
"
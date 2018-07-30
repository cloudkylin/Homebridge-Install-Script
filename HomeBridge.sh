#!/bin/bash
 
[ "$EUID" -ne '0' ] && echo "Error,This script must be run as root! " && exit 1
[ $# -gt '1' ] && [ "$1" == '-f' ] && [ "$2" == 'CN' ] && tmpMirror='CN' || tmpMirror='Official';
[ "$1" == '-f' ] && {
	echo "The mirror you choose is: $tmpMirror"
} || {
	read -p "Press choise mirror, 'CN' for China, others for official:" INP
if [ "$INP" == 'CN' ] ; then
	tmpMirror='CN'
else
	tmpMirror='Official'
fi
}
# Ready to install
apt-get -y install gcc g++ make
[ $? -ne '0' ] && echo 'Install gcc, g++, make failed!' && exit 1
# Install Node.js
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
[ $? -ne '0' ] && echo 'Add mirror failed!' && exit 1
[ $tmpMirror == 'CN' ] && sed -i 's/deb.nodesource.com/mirrors.ustc.edu.cn\/nodesource\/deb/g' /etc/apt/sources.list.d/nodesource.list && apt update
apt install -y nodejs libavahi-compat-libdnssd-dev
[ $? -ne '0' ] && echo 'Install node.js failed!' && exit 1
# Install HomeBridge
npm install node-gyp && npm install -g --unsafe-perm homebridge
[ $? -ne '0' ] && echo 'Install homebridge failed!' && exit 1
# Set HomeBridge
mkdir -p /var/lib/homebridge/
[ ! -f /var/lib/homebridge/config.json ] && touch /var/lib/homebridge/config.json
cat << _EOF_ >/var/lib/homebridge/config.json
{
    "bridge": {
        "name": "Homebridge",
        "username": "CC:22:3D:E3:CE:30",
        "port": 51826,
        "pin": "031-45-154"
    },

    "description": "My Homebridge on Raspberry Pi 3.",

    "platforms": []
}
_EOF_
# Running Homebridge on Bootup
useradd -M --system homebridge
chown -R homebridge:homebridge /var/lib/homebridge
wget -qP /etc/default 'https://gist.githubusercontent.com/johannrichard/0ad0de1feb6adb9eb61a/raw/1cf926e63e553c7cbfacf9970042c5ac876fadfa/homebridge' && wget -qP /etc/systemd/system 'https://gist.githubusercontent.com/johannrichard/0ad0de1feb6adb9eb61a/raw/1cf926e63e553c7cbfacf9970042c5ac876fadfa/homebridge.service'
[ $? -ne '0' ] && echo "Download set file failed!" && exit 1
sed -i "s%\/usr\/local\/bin\/homebridge%`which homebridge`%g" /etc/systemd/system/homebridge.service
[ $? -ne '0' ] && echo "Set PATH failed!" && exit 1
systemctl daemon-reload && systemctl enable homebridge && systemctl start homebridge
[ $? -ne '0' ] && echo "Start service failed!" && exit 1
[ "$1" == '-f' ] && {
	echo "It will exit and show QR..."
} || {
	read -n 1 -p "Press Enter to continue..." INP
if [ "$INP" != '' ] ; then
	echo -ne '\b \n'
fi
}
sleep 3 && journalctl -au homebridge

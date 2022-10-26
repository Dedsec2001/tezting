#!/bin/sh

#configure timezone to sri lanka standards

rm -rf /etc/localtime
cp /usr/share/zoneinfo/Asia/Colombo /etc/localtime
date -R

apt install ufw

#firewall rules
ufw allow 'OpenSSH'

ufw allow 80/tcp
ufw enable

#running xray install script for linux - systemd

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

#adding new configuration files

rm -rf /usr/local/etc/xray/config.json
cat << EOF > /usr/local/etc/xray/config.json

{

    "log": {

        "loglevel": "warning"

    },

    "routing": {

        "domainStrategy": "AsIs",

        "rules": [

            {

                "type": "field",

                "ip": [

                    "geoip:private"

                ],

                "outboundTag": "block"

            }

        ]

    },

    "inbounds": [

        {

            {
      "port": 80,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "ac477b09-9d17-41e0-9572-accc2198e650",
            "level": 0,
            "email": "love@example.com"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/vmessws"
        }

        }

    ],

    "outbounds": [

        {

            "protocol": "freedom",

            "tag": "direct"

        },

        {

            "protocol": "blackhole",

            "tag": "block"

        }

    ]

}
EOF

#accuring a ssl certificate (self-sigend openssl)

openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" \
    -keyout xray.key  -out xray.crt
mkdir /etc/xray
cp xray.key /etc/xray/xray.key
cp xray.crt /etc/xray/xray.crt
chmod 644 /etc/xray/xray.key

#starting xray core on sytem startup

systemctl enable xray
systemctl restart xray

#install bbr

mkdir ~/across
git clone https://github.com/teddysun/across ~/across
chmod 777 ~/across
bash ~/across/bbr.sh


cp server_manager.py /root/
echo python3 /root/server_manager.py >> /root/.bashrc

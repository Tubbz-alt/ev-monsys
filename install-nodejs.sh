#!/bin/sh -e
cd /usr/src &
sudo wget http://nodejs.org/dist/v10.7.0/node-v10.7.0.tar.gz
sudo tar xvzf node-v10.7.0.tar.gz

cd node-v10.7.0.tar.gz &
sudo ./configure
sudo make
sudo make install
sudo npm install forever -g
sudo mkdir /opt/piControl/
sudo apt-get uptdate -y
sudo apt-get install insserv

cd /opt &
sudo git clone git://github.com/saturngod/piControl.git piControl
sudo cp /opt/piControl/pictlnode /etc/init.d/pictlnode
sudo chmod +x /etc/init.d/pictlnode
update-rc.d pictlnode defaults
sudo insserv pictlnode
sudo reboot
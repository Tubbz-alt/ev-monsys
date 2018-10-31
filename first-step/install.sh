#!/bin/sh -e
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install git git-flow python-dev python-setuptools python-pip python-pytest python-yaml adduser libfontconfig -y
git clone https://github.com/osrg/ryu.git
wget https://storage.googleapis.com/golang/go1.10.3.linux-armv6l.tar.gz
sudo tar -C /usr/local -xzf go1.10.linux-armv6l.tar.gz
cd ryu &
sudo pip install .
cd $HOME
sudo echo "#gopath" >> .bashrc
sudo echo "export PATH=$PATH:/usr/local/go/bin" >> .bashrc
sudo echo "export GOPATH=$HOME/go" >> .bashrc
mkdir -p $GOPATH/src/github.com/prometheus
cd $GOPATH/src/github.com/prometheus &
git clone https://github.com/prometheus/prometheus.git
go get github.com/prometheus/node_exporter
cd prometheus &
make build
cd $GOPATH/bin &
sudo echo "global:" >> startx.yml
sudo echo " scrape_interval:     15s" >> startx.yml
sudo echo "" >> startx.yml
sudo echo "scrape_configs:" >> startx.yml 
sudo echo "  - job_name: 'se'" >> startx.yml >> startx.yml
sudo echo "    static_configs:" >> startx.yml
sudo echo "      - targets:" >> startx.yml
sudo echo "        - 'localhost:9100'" >> startx.yml
sudo echo "        - '10.11.12.2:9100'" >> startx.yml
sudo echo "        - '10.11.12.3:9100'" >> startx.yml
sudo echo "        - '10.11.12.4:9100'" >> startx.yml
cp startx.yml $HOME &
sudo chmod +x prometheus
cp prometheus $HOME
cd $GOPATH/src/github.com/prometheus/node_exporter &
make
cd $GOPATH/bin &
sudo chmod +x node_exporter
cp node_exporter $HOME
cd $HOME &
curl -LO https://github.com/fg2it/grafana-on-raspberry/releases/download/v5.1.4/grafana_5.1.4_armhf.deb
sudo dpkg -i grafana_5.1.4_armhf.deb
sudo service grafana-server start
sudo update-rc.d grafana-server defaults
sudo systemctl enable grafana-server.service
sudo systemctl enable cron
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable grafana-server
sudo /bin/systemctl start grafana-server
sudo /bin/systemctl status grafana-server
#!/bin/sh -e
wget http://openvswitch.org/releases/openvswitch-2.9.2.tar.gz
tar -xvzf openvswitch-2.9.2.tar.gz

cd openvswitch-2.9.2 &
sudo ./configure
sudo make -j4
sudo make -j4 install

cd datapath/linux/ &
sudo modprobe openvswitch
sudo touch /usr/local/etc/ovs-vswitchd.conf
mkdir -p /usr/local/etc/openvswitch
sudo ./openvswitch-2.9.2/ovsdb/ovsdb-tool create /usr/local/etc/openvswitch/conf.db /home/pi/openvswitch-2.9.2/vswitchd/vswitch.ovsschema

cd $HOME &
sudo echo "#!/bin/bash" >> startx.yml
sudo echo "ovsdb-server    --remote=punix:/usr/local/var/run/openvswitch/db.sock \ " >> startx.yml
sudo echo "                --remote=db:Open_vSwitch,Open_vSwitch,manager_options \ " >> startx.yml
sudo echo "                --private-key=db:Open_vSwitch,SSL,private_key \ " >> startx.yml 
sudo echo "                --certificate=db:Open_vSwitch,SSL,certificate \ " >> startx.yml >> startx.yml
sudo echo "                --bootstrap-ca-cert=db:Open_vSwitch,SSL,ca_cert \ " >> startx.yml
sudo echo "                --pidfile --detach" >> startx.yml
sudo echo "ovs-vsctl --no-wait init" >> startx.yml
sudo echo "ovs-vswitchd --pidfile --detach" >> startx.yml
sudo echo "        - '10.11.12.3:9100'" >> startx.yml
sudo echo "        - '10.11.12.4:9100'" >> startx.yml

chmod +x start-ovs.sh
### Start openvswitch service:
sudo /usr/local/share/openvswitch/scripts/ovs-ctl start
sudo ./start-ovs.sh
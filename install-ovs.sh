## Download and unarchive openvswitch:
wget http://openvswitch.org/releases/openvswitch-2.9.2.tar.gz
tar -xvzf openvswitch-2.9.2.tar.gz
cd openvswitch-2.9.2

### Build openvswitch:
./configure
sudo make -j4
sudo make -j4 install

### Set up local variables:
cd datapath/linux/
# restart
sudo modprobe openvswitch
sudo touch /usr/local/etc/ovs-vswitchd.conf
mkdir -p /usr/local/etc/openvswitch
sudo ./openvswitch-2.9.2/ovsdb/ovsdb-tool create /usr/local/etc/openvswitch/conf.db /home/pi/openvswitch-2.9.2/vswitchd/vswitch.ovsschema

### Create starting file:
sudo nano /home/pi/ev-monsys/start-ovs.sh
"""
#!/bin/bash

ovsdb-server    --remote=punix:/usr/local/var/run/openvswitch/db.sock \
                --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
                --private-key=db:Open_vSwitch,SSL,private_key \
                --certificate=db:Open_vSwitch,SSL,certificate \
                --bootstrap-ca-cert=db:Open_vSwitch,SSL,ca_cert \
                --pidfile --detach
ovs-vsctl --no-wait init
ovs-vswitchd --pidfile --detach
"""
cd /home/pi/ev-monsys
chmod +x start-ovs.sh
### Start openvswitch service:
sudo /usr/local/share/openvswitch/scripts/ovs-ctl start
sudo ./ev-monsys/start-ovs.sh

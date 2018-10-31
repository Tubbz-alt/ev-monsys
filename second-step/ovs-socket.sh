#!/bin/bash
sudo ovs-vsctl add-br nat-br
sudo ovs-vsctl add-port nat-br eth1
sudo ovs-vsctl add-port nat-br eth2
sudo ovs-vsctl set bridge nat-br other_config:datapath-id=0000000000000001
sudo ovs-vsctl set-controller nat-br tcp:10.11.12.1:6633
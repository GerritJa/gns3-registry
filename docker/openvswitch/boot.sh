#!/bin/sh
#
# Copyright (C) 2015 GNS3 Technologies Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


if [ ! -f "/etc/openvswitch/conf.db" ]
then
  ovsdb-tool create /etc/openvswitch/conf.db /usr/share/openvswitch/vswitch.ovsschema

  ovsdb-server --detach --remote=punix:/var/run/openvswitch/db.sock
  ovs-vswitchd --detach  
  ovs-vsctl --no-wait init
 
  x=0
  until [ $x = "4" ]; do
    ovs-vsctl add-br br$x
    ovs-vsctl set bridge br$x datapath_type=netdev
    x=$((x+1))
  done

  if [ $MANAGEMENT_INTERFACE == 1 ]
  then
    x=1
  else
    x=0
  fi

  until [ $x = "16" ]; do
    ovs-vsctl add-port br0 eth$x
    x=$((x+1))
  done
else
  ovsdb-server --detach --remote=punix:/var/run/openvswitch/db.sock
  ovs-vswitchd --detach
fi


x=0
until [ $x = "4" ]; do
  ip link set dev br$x up
  x=$((x+1))
done

## change the bandwidth of the interface (https://n40lab.wordpress.com/2013/05/04/openvswitch-setting-a-bandwidth-limit/)
if [ ! -z $ETH0_BANDWIDTH_BIT ]
then
ovs-vsctl -- set Port eth0 qos=@newqos -- \
	--id=@newqos create QoS type=linux-htb other-config:max-rate=$ETH0_BANDWIDTH_BIT queues=0=@q0 -- \
	--id=@q0   create   Queue   other-config:min-rate=$ETH0_BANDWIDTH_BIT other-config:max-rate=$ETH0_BANDWIDTH_BIT
fi


if [ $LLDP == 1 ]
then
	# apply lldp forwarding for eth0-eth15
	# eth0 only outputs lldp frames from eth1-eth14 but does not forward packages that are received on eth0
	# eth1-eth14 broadcasts the lldp frames between device ports (eth1-eth14) and eth0
	# eth15 (in_port=14) accepts only incomming lldp frames and forward them to devices eth1-eth14
	ovs-ofctl add-flow br0 in_port=2,dl_dst=01:80:c2:00:00:0e,dl_type=0x88cc,actions=output:1,3,4,5,6,7,8,9,10,11,12,13,14,15
	ovs-ofctl add-flow br0 in_port=3,dl_dst=01:80:c2:00:00:0e,dl_type=0x88cc,actions=output:1,2,4,5,6,7,8,9,10,11,12,13,14,15
	ovs-ofctl add-flow br0 in_port=4,dl_dst=01:80:c2:00:00:0e,dl_type=0x88cc,actions=output:1,2,3,5,6,7,8,9,10,11,12,13,14,15
	ovs-ofctl add-flow br0 in_port=5,dl_dst=01:80:c2:00:00:0e,dl_type=0x88cc,actions=output:1,2,3,4,6,7,8,9,10,11,12,13,14,15
	ovs-ofctl add-flow br0 in_port=6,dl_dst=01:80:c2:00:00:0e,dl_type=0x88cc,actions=output:1,2,3,4,5,7,8,9,10,11,12,13,14,15
	ovs-ofctl add-flow br0 in_port=7,dl_dst=01:80:c2:00:00:0e,dl_type=0x88cc,actions=output:1,2,3,4,5,6,8,9,10,11,12,13,14,15
	ovs-ofctl add-flow br0 in_port=8,dl_dst=01:80:c2:00:00:0e,dl_type=0x88cc,actions=output:1,2,3,4,5,6,7,9,10,11,12,13,14,15
	ovs-ofctl add-flow br0 in_port=9,dl_dst=01:80:c2:00:00:0e,dl_type=0x88cc,actions=output:1,2,3,4,5,6,7,8,10,11,12,13,14,15
	ovs-ofctl add-flow br0 in_port=10,dl_dst=01:80:c2:00:00:0e,dl_type=0x88cc,actions=output:1,2,3,4,5,6,7,8,9,11,12,13,14,15
	ovs-ofctl add-flow br0 in_port=11,dl_dst=01:80:c2:00:00:0e,dl_type=0x88cc,actions=output:1,2,3,4,5,6,7,8,9,10,12,13,14,15
	ovs-ofctl add-flow br0 in_port=12,dl_dst=01:80:c2:00:00:0e,dl_type=0x88cc,actions=output:1,2,3,4,5,6,7,8,9,10,11,13,14,15
	ovs-ofctl add-flow br0 in_port=13,dl_dst=01:80:c2:00:00:0e,dl_type=0x88cc,actions=output:1,2,3,4,5,6,7,8,9,10,11,12,14,15
	ovs-ofctl add-flow br0 in_port=14,dl_dst=01:80:c2:00:00:0e,dl_type=0x88cc,actions=output:1,2,3,4,5,6,7,8,9,10,11,12,13,15
	ovs-ofctl add-flow br0 in_port=15,dl_dst=01:80:c2:00:00:0e,dl_type=0x88cc,actions=output:1,2,3,4,5,6,7,8,9,10,11,12,13,14
	## eth15 only forward to device interfaces
	ovs-ofctl add-flow br0 in_port=16,dl_dst=01:80:c2:00:00:0e,dl_type=0x88cc,actions=output:2,3,4,5,6,7,8,9,10,11,12,13,14,15
fi

/bin/sh

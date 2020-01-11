#!/bin/bash
NETWORK_NAME="selfservice"
SUBNET_NAME="subred"
SUBNET_RANGE="10.2.0.0/24"
SECURITY_GROUP_NAME="lab1"
VOLUME_NAME="new-volume"
FLAVOR="lab1"
KEYPAIR_NAME="keypair"
VMTOMCAT="vmtomcat"
VMMYSQL="vmmysql"
EXTERNAL_NETWORK="external-network"
openstack network create $NETWORK_NAME
openstack subnet create --subnet-range $SUBNET_RANGE --network $NETWORK_NAME --dns-nameserver 8.8.4.4 $SUBNET_NAME
openstack router create router
openstack router add subnet router $SUBNET_NAME
openstack router set router --external-gateway $EXTERNAL_NETWORK
openstack security group create $SECURITY_GROUP_NAME
openstack security group rule create --proto icmp $SECURITY_GROUP_NAME
openstack security group rule create --proto tcp --dst-port 22 $SECURITY_GROUP_NAME
openstack security group rule create --proto tcp --dst-port 8080 $SECURITY_GROUP_NAME
openstack security group rule create --proto tcp --dst-port 3306 --remote-ip $SUBNET_RANGE $SECURITY_GROUP_NAME
openstack security group rule create --proto tcp --dst-port 5001 --remote-ip $SUBNET_RANGE $SECURITY_GROUP_NAME
openstack volume create --size 1 $VOLUME_NAME
NETWORK_ID=$(openstack network list -f value | grep $NETWORK_NAME | cut -d' ' -f1)
openstack server create --image ubuntu-xenial --flavor $FLAVOR --security-group $SECURITY_GROUP_NAME --key-name $KEYPAIR_NAME --nic net-id=$NETWORK_ID --user-data tomcat.yml $VMTOMCAT
openstack server create --image ubuntu-xenial --flavor $FLAVOR --security-group $SECURITY_GROUP_NAME --key-name $KEYPAIR_NAME --nic net-id=$NETWORK_ID --user-data mysql.yml $VMMYSQL
openstack floating ip create $EXTERNAL_NETWORK
sleep 1
FLOATING_IP=$(openstack floating ip list -f value -c "Floating IP Address")
openstack server add floating ip $VMTOMCAT $FLOATING_IP
while true; do
    VALUE=$(openstack server show $VMMYSQL -f value -c status)
    echo $VALUE
    if [ $VALUE = "ACTIVE" ]; then
        openstack server add volume $VMMYSQL $VOLUME_NAME
        break
    fi
done

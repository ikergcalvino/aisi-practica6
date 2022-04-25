#!/bin/bash

# Format and mount disks to be used with Hadoop HDFS
if [ ! -d "/data/disk0" ]; then
    mkdir -p /data/disk0 >& /dev/null
    mkfs.ext4 -F /dev/sdb
    mount /dev/sdb /data/disk0
    chmod 1777 /data/disk0
else
    mount /dev/sdb /data/disk0 >& /dev/null
    chmod 1777 /data/disk0
fi

if [ ! -d "/data/disk1" ]; then
    mkdir -p /data/disk1 >& /dev/null
    mkfs.ext4 -F /dev/sdc
    mount /dev/sdc /data/disk1
    chmod 1777 /data/disk1
else
    mount /dev/sdc /data/disk1 >& /dev/null
    chmod 1777 /data/disk1
fi

if ! grep -Fq /dev/sdb /etc/fstab ; then
    echo -e "/dev/sdb        /data/disk0     ext4    defaults,relatime       0       0" >> /etc/fstab
fi

if ! grep -Fq /dev/sdc /etc/fstab ; then
    echo -e "/dev/sdc        /data/disk1     ext4    defaults,relatime       0       0" >> /etc/fstab
fi

# SSH config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i '/127.0.1.1/d' /etc/hosts >& /dev/null
systemctl restart sshd

SSH_PUBLIC_KEY=/vagrant/provisioning/id_rsa.pub
USER_DIR=/home/vagrant/.ssh

if [[ "$HOSTNAME" == *"-master" ]]; then
	mkdir -p /etc/ansible
	cp /vagrant/ansible.inventory /etc/ansible/hosts
	cp /vagrant/ansible.cfg /etc/ansible
	chmod 0644 /etc/ansible/hosts
	chmod 0644 /etc/ansible/ansible.cfg

	# Create ssh keys
	echo -e 'y\n' | sudo -u vagrant ssh-keygen -t rsa -f $USER_DIR/id_rsa -q -N ''

	if [ ! -f $USER_DIR/id_rsa.pub ]; then
		echo "SSH public key could not be created"
		exit -1
	fi

	chown vagrant:vagrant $USER_DIR/id_rsa*
	cp $USER_DIR/id_rsa.pub /vagrant/provisioning
fi

if [ ! -f $SSH_PUBLIC_KEY ]; then
	echo "SSH public key does not exist"
	exit -1
fi

sed -i "/-aisi/d" $USER_DIR/authorized_keys >& /dev/null
cat $SSH_PUBLIC_KEY >> $USER_DIR/authorized_keys
chown vagrant:vagrant $USER_DIR/authorized_keys
chmod 0600 $USER_DIR/authorized_keys


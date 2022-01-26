#!/bin/sh

# wait for disk to be mounted TODO - add better logic
sleep 90

# at this point if an extra disk is ready, use it for /home
# some partitioning and mounting magick
if [[ -b "/dev/vdd"  ]]
then
/sbin/sfdisk /dev/vdd << EOF
1,;
EOF
  
/sbin/mkfs -t ext4 /dev/vdd1
/bin/mkdir -p /mnt/home
/bin/mount /dev/vdd1 /mnt/home

/bin/cp -ap /home/* /mnt/home
/bin/umount /mnt/home
/bin/mount /dev/vdd1 /home

/usr/sbin/restorecon -RFv /home

/bin/echo "/dev/vdd1    /home    ext4    defaults    0  2" >> /etc/fstab
fi

#
# apply latest
dnf update -y

# fix sshd_config that IBM Cloud breaks
sed -i 's/^AllowTcpForwarding no/AllowTcpForwarding yes/' /etc/ssh/sshd_config
systemctl restart sshd 

# code to set up the end-user (run in terraform)
useradd -m crcuser
mkdir -p ~crcuser/.ssh
cp /root/.ssh/authorized_keys ~crcuser/.ssh
chown -R crcuser.crcuser ~crcuser/.ssh
chmod -R g-rx,o-rx ~crcuser/.ssh

cat > /etc/sudoers.d/crcuser <<-EOF
## let crcuser do whatever
crcuser    ALL=(ALL)	NOPASSWD: ALL
EOF

# TODO - move to playbook?.. as this won't work b/c vnc is not yet installed
# mkdir -p ~crcuser/.vnc
# echo "Vncp8ss#" | vncpasswd -f > ~crcuser/.vnc/passwd
# chmod 600 ~crcuser/.vnc/passwd
# chown -R crcuser.crcuser ~crcuser/.vnc

# touch done file in /root
touch /root/cloudinit.done



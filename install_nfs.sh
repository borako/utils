yum install -y rpcbind nfs-utils
service rpcbind start
service nfs start
chkconfig rpcbind on
chkconfig nfs on
mkdir -p /mnt/tmp
mount -t nfs 192.168.2.220:/volume1/homes /mnt/tmp

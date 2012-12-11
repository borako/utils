
#! /bin/bash 
unalias cp

echo Turning iptables off...
service iptables stop
chkconfig iptalbes off

echo Installing wget...
yum install -y wget

INSTALL_FILE="windmillinstall_0.9.tar.gz"

echo "Mount and copy installation file" $INSTALL_FILE 
mkdir /mnt/tmp
mount -t nfs 192.168.2.220:/volume1/homes /mnt/tmp
echo "Copying" $INSTALL_FILE "......."
cp -f /mnt/tmp/bora/$INSTALL_FILE /root/

echo "Uncompressing" $INSTALL_FILE
tar xzf $INSTALL_FILE

echo Creating users...
useradd -m mongo
useradd -m tomcat
useradd -m elasticsearch

echo Moving bash profiles into places... 
cp -f ~root/windmill/tomcat.bash_profile ~tomcat/.bash_profile
cp -f ~root/windmill/elasticsearch.bash_profile ~elasticsearch/.bash_profile

echo Installing java 1.6.... 

yum install -y java-1.6.0

echo Java installed: 
java -version
echo
echo

echo Installing tomcat...
cd ~tomcat
tar xzf ~root/windmill/apache-tomcat-7.0.32.tar.gz
cp -f ~root/windmill/tomcatconf/context.xml ~tomcat/apache-tomcat-7.0.32/conf/context.xml
cp -f ~root/windmill/tomcatconf/tomcat-users.xml ~tomcat/apache-tomcat-7.0.32/conf/tomcat-users.xml
cp -f ~root/windmill/tomcat /etc/init.d

cp -f ~root/windmill/tomcatconf/mysql-connector-java-5.1.18-bin.jar ~tomcat/apache-tomcat-7.0.32/lib/

chmod +x /etc/init.d/tomcat
chown -R tomcat ~tomcat/*
chkconfig tomcat on
service tomcat start

echo Tomcat installation finished. 
echo 
echo

wget http://localhost:8080

echo Installing MySQL...

yum install -y mysql-server
cp -f ~root/windmill/my.cnf /etc/
chkconfig mysqld on
service mysqld start

echo "Setting mySQL password..."
MQPWD="root78()"
/usr/bin/mysqladmin -u root password "$MQPWD"

echo "Populating mySQL database..."
cd ~root/windmill
mysql -u root --password="$MQPWD" < windmill.mysql


echo Installing MongoDB...
cp -f ~root/windmill/mongo.tgz ~mongo/
cd ~mongo
tar xzf mongo.tgz
cp -f ~root/windmill/mongod /etc/init.d
chkconfig mongod on

echo Starting MongoDB...
service mongod start

echo Installing ElasticSearch...
cp -f ~root/windmill/elasticsearch.tgz ~elasticsearch/
cd ~elasticsearch
tar xzf elasticsearch.tgz
~elasticsearch/elasticsearch/bin/service/elasticsearch install
service elasticsearch start

echo Checking ElasticSearch install...
wget localhost:9200

echo Installing RabbitMQ...

rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-7.noarch.rpm
yum install -y erlang
rpm --import http://www.rabbitmq.com/rabbitmq-signing-key-public.asc
wget http://www.rabbitmq.com/releases/rabbitmq-server/v2.7.1/rabbitmq-server-2.7.1-1.noarch.rpm
yum install -y rabbitmq-server-2.7.1-1.noarch.rpm
chkconfig rabbitmq-server on
service rabbitmq-server start

echo Deploying war files...

mkdir ~tomcat/.windmill
cp -f ~root/windmill/tomcatconf/webapps/windmill.properties ~tomcat/.windmill/
cp -f ~root/windmill/tomcatconf/webapps/*.war ~tomcat/apache-tomcat-7.0.32/webapps/
service tomcat restart

echo Verifying war files...
wget http://windmill.alticast.com:8080/acms/api1/categories?type=vod&access_token=__touchme__
wget http://windmill.alticast.com:8080/userprofile/api1/accounts?id=1000000000
wget http://windmill.alticast.com:8080/search/api1/search?q=avatar


echo Installing RTSP...
mkdir /home/data
mkdir /home/data/video
cp ~root/streamserver/rtsp/* /home/data/video/
cd /home/data/video/Movie
ln -s ../live555MediaServer
echo 'cd /home/data/video/Movie; ./live555MediaServer &' >> /etc/rc3.d/S99local

echo Installring Nginx...
cd ~root/streamserver
wget http://nginx.org/packages/centos/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm
yum install -y nginx-release-centos-6-0.el6.ngx.noarch.rpm 
yum install -y nginx
cp ~root/streamserver/http/default.conf /etc/nginx/conf.d/
service nginx start
/etc/rc3.d/S99local

echo Installing NTP...

yum install -y ntp
chkconfig ntpd on

echo Installing xinetd...
yum install -y xinetd
chkconfig xinetd on
service xinetd start
chkconfig time-stream on
chkconfig time-dgram on 

echo Finished. If you are running stream server on this machine, copy the movie files in /home/data/video/Movie manually. 

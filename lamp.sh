#!/bin/bash
####################################################################################################
#
#         FILE:  LAMP_install.sh
#
#        Usage:  $(basename $0)
#
#  DESCRIPTION:  Script to perform LAMP installation in Linux.
#
#      FLAVORS:  Linux flavours ( redhat, Suse, CentOS )
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Cloud4C
#      COMPANY:  Cloud4C
#      VERSION:  1.0
#      CREATED:  25/07/2017
#     REVISION:  ---
##################################################################################################


##################################################################################################
#
#
#  Setup Initial Global Parameters
#
#
##################################################################################################

MYSQL_PASS='RooT!23$%5'					; export MYSQL_PASS
USER_NAME="root"						; export USER_NAME
OS=`uname`								; export OS

# INSTALL lAMP stack

# install Apache and make it on permanently 
yum -y install httpd
cat /etc/*-release | grep -q "^VERSION=\"7"
if [ $? -eq 0 ] ; then
	systemctl start httpd
	systemctl enable httpd
else
	service httpd start
	chkconfig httpd on
fi


# install PHP 
yum -y install php php-mysql

#insatll mysql

cat /etc/*-release | grep -q "^VERSION=\"7"
if [ $? -eq 0 ] ; then
	yum -y install wget
	wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
	rpm -ivh mysql-community-release-el7-5.noarch.rpm
	yum -y install mysql-server
	systemctl start mysqld
	systemctl enable mysqld
else
	yum -y install mysql-server
	service mysqld start
	chkconfig mysqld on
fi

yum -y install expect



# Install MySQL
# Build Expect script
expect -f - <<-EOF
  set timeout 10
  spawn mysql_secure_installation
  expect "Enter current password for root (enter for none):"
  send -- "\r"
  expect "Set root password?"
  send -- "y\r"
  expect "New password:"
  send -- "${MYSQL_PASS}\r"
  expect "Re-enter new password:"
  send -- "${MYSQL_PASS}\r"
  expect "Remove anonymous users?"
  send -- "y\r"
  expect "Disallow root login remotely?"
  send -- "y\r"
  expect "Remove test database and access to it?"
  send -- "y\r"
  expect "Reload privilege tables now?"
  send -- "y\r"
  expect eof
EOF

# Cleanup
# yum -y remove expect > /dev/null # Uninstall Expect, commented out in case you need Expect

echo "Mysql root password is: ${MYSQL_PASS}"
echo "LAMP stack is isntalled successfully"


#Download Wordpress
wget http://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz

wp_admin="fruit"
wp_db="apple"
wp_pass='ctrls@123'

mysql -u "$MYSQL_ROOT" -p"$MYSQL_PASS" <<EOF
SHOW DATABASES;
CREATE DATABASE IF NOT EXISTS $wp_db;
CREATE USER  $wp_admin@localhost;
SET PASSWORD FOR $wp_admin@localhost= PASSWORD("$wp_pass");
GRANT ALL PRIVILEGES ON $wp_db.* TO $wp_admin@localhost IDENTIFIED BY '$wp_pass';
SHOW DATABASES;
exit
EOF

#Setup the WordPress Configuration
cp ~/wordpress/wp-config-sample.php ~/wordpress/wp-config.php
sed -i -e "s/username_here/$wp_admin/g; s/database_name_here/$wp_db/g; s/password_here/$wp_pass/g" wordpress/wp-config.php

#Copy the Files
sudo cp -r ~/wordpress/* /var/www/html

sudo service httpd restart

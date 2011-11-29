#!/bin/bash

DIR_ME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

BACKUP_PATH="/backup/mysql"
PASSPHRASE="`tr -dc A-Za-z0-9_ < /dev/urandom | head -c 15 | xargs`"

BUCKET="`hostname -f`"

wget -O /etc/yum.repos.d/s3tools.repo http://s3tools.org/repo/CentOS_5/s3tools.repo
yum install -y s3cmd

cp "$DIR_ME"/.s3cfg /root
chmod 600 /root/.s3cfg

echo "Access Key: "
read access_key

echo "Secret Key: "
read secret_key

echo "access_key=$access_key" >> /root/.s3cfg
echo "secret_key=$secret_key" >> /root/.s3cfg
echo "gpg_passphrase=`tr -dc A-Za-z0-9_ < /dev/urandom | head -c 15 | xargs`"  >> /root/.s3cfg

s3cmd mb s3://`hostname -f`

if [ -d "$BACKUP_PATH" ]; then
	for i in "$BACKUP_PATH"/*; do
		gpg --yes --passphrase "$PASSPHRASE" -c $i
		rm -rf $i
	done	
else
	mkdir -p "$BACKUP_PATH"
	chmod -R 700 "$BACKUP_PATH"
fi

if [ -d "/root/mysql_backup" ]; then
	mv /root/mysql_backup{,.old}
fi

cp "$DIR_ME"/mysql_backup /root
chmod 700 /root/mysql_backup

echo "Your MySQL root password: "
read mysql_root_pass

echo $mysql_root_pass > /root/.mysqlpass

sed -i s~BACKUP_PATH=~BACKUP_PATH=\""$BACKUP_PATH"\"~ /root/mysql_backup
sed -i s/PASSPHRASE=/PASSPHRASE=\""$PASSPHRASE"\"/ /root/mysql_backup

echo "Add to crontab '$(($RANDOM%26)) $(($RANDOM%26)) * * * /root/mysql_backup'"
echo -e "\033[1mYour passphrase: $PASSPHRASE\033[0m"

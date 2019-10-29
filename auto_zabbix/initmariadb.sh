#!/usr/bin/expect
sleep 1
spawn mysql_secure_installation
sleep 1
expect "Enter current password for root (enter for none):"
sleep 1
send "\r"
expect "Set root password? "
send "Y\r"
expect "New password:"
send "zhangcan\r"
expect "Re-enter new password:"
send "zhangcan\r"
expect "Remove anonymous users? "
send "y\r"
expect "Disallow root login remotely? "
send "y\r"
expect "Remove test database and access to it? "
send "y\r"
expect "Reload privilege tables now? "
send "y\r"
expect eof
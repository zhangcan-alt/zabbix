#!/bin/bash
echo "########### 从##########这#########里###### 开#######始"
basedir=$(cd $(dirname "$0");pwd)
filepath=`echo "${basedir}/myzabbix"`
echo $filepath
sed -i "s#/opt/usb/zabbix#$filepath#g" myzabbix.repo
echo "################ 所有操作在ROOT用户下进行 ####################"
echo "=================================================="
echo "################# 适用于CentOS7系列 #########################"
cat myzabbix.repo
echo "##################################################"
#关闭防火墙
function set_firewall(){
	systemctl stop firewalld
	systemctl disable firewalld
	#selinux设置为disabled /enforcing
	sed -i '/SELINUX=/s/enforcing/disabled/g' /etc/selinux/config
	setenforce 0
}

#备份原repo文件
function set_repo(){
	mkdir -p /etc/yum.repos.d/bak
	#备份原repo文件
	mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak/
	#配置本地Yum仓库
	cp myzabbix.repo /etc/yum.repos.d/
	sleep 1
	yum clean all
	sleep 1
	yum -y install expect >> /dev/null 
	if [ $? -ne 0 ];then
		echo "配置出错"
		exit_return
		exit 0
	fi
        echo "---------configure-ok----------"
}
#[安装]httpd2.4.6
function install_httpd(){
	yum install httpd -y
	echo "---------httpd-install-ok----------"
}
#[安装]php5.4.16
function install_php(){
	yum -y install php php-mysql
	echo "---------php-install-ok----------"
}
#[安装]mariadb5.5.64
function install_mariadb(){
	yum -y install mariadb-server
	echo "---------mariaDB-install-ok----------"
}
#[安装]zabbix4.2.7
function install_zabbix_server(){
	yum -y install zabbix-server-mysql zabbix-web-mysql
	echo "---------zabbix-server-install-ok----------"
}
#[安装]zabbix-agent
function install_zabbix_agent(){
	yum -y install zabbix-agent
	sleep 1
	systemctl start zabbix-agent
	sleep 2
	systemctl stop zabbix-agent
	echo "---------zabbix-agent-install-ok----------"
}

#[配置]httpd
function conf_httpd(){
	echo 'httpd nothing need to do'
}
#[配置]php
function conf_php(){
	sed -i s/'^;date.timezone.*'/'date.timezone = Asia\/Shanghai'/g /etc/php.ini
	echo "---------php-conf-ok----------"
}
#[配置]mariaDB
function conf_mariadb(){
	chmod +x $basedir/initmariadb.sh
	$basedir/initmariadb.sh
	echo "---------mariaDB-conf-ok----------"
}
#[配置]zabbix数据库
function conf_zabbixdb(){
	mysql -uroot -pzhangcan -e "create database zabbix character set utf8 collate utf8_bin;"
	mysql -uroot -pzhangcan -e "grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';"
	mysql -uroot -pzhangcan -e "flush privileges;"
	cd /usr/share/doc/zabbix-server-mysql-4.2.7/
	sleep 1
	gunzip -c create.sql.gz > create.sql
	sleep 1
	mysql -uzabbix -pzabbix zabbix < create.sql
	echo "---------zabbixdb-create-ok----------"
}
#[配置]zabbix_server
function conf_zabbix_server(){
	echo "starting....."
	sed -i 's/# php_value date.timezone/php_value date.timezone/g' /etc/httpd/conf.d/zabbix.conf
	sed -i 's#Europe/Riga#Asia/Shanghai#g' /etc/httpd/conf.d/zabbix.conf
	conf_zabbixdb
	sed -i s/'# DBPassword='/'DBPassword=zabbix'/g /etc/zabbix/zabbix_server.conf
	echo "---------zabbix-server.conf-conf-ok----------"
}
#[配置]zabbix_agent
function conf_zabbix_agent(){
	echo '功能未完善'
	echo "-----nothing-to-do------------"
}

#[启动]httpd
function start_httpd(){
	systemctl start httpd
	echo "---------start httpd-ok----------"
}
#[启动]mariadb
function start_mariadb(){
	systemctl start mariadb
	echo "---------start mariaDB-ok----------"
}
#[启动]zabbix-server
function start_zabbix_server(){
	systemctl start zabbix-server
	echo "---------start zabbix-server-ok----------"
}
#[启动]zabbix-agent
function start_zabbix_agent(){
	systemctl start zabbix-agent
	echo "---------start zabbix-agent-ok----------"
}

#####安装所有#####
function install_all(){
	install_httpd
	install_php
	install_mariadb
	install_zabbix_server
	install_zabbix_agent
	echo "---------install-all-ok----------"
}

#####配置所有#####
function conf_all(){
	conf_httpd
	conf_php
	conf_mariadb
	conf_zabbix_server
	conf_zabbix_agent
	echo "---------conf-all-ok----------"
}

#####启动所有#####
function start_all(){
	start_httpd
	start_mariadb
	start_zabbix_server
	start_zabbix_agent
	echo "---------start-all-ok----------"
}

#####停止所有###
function stop_all(){
	systemctl stop httpd mariadb zabbix-agent zabbix-server
	echo "---------stop-all-ok----------"
}

#####添加开机启动####
function service_enable(){
	systemctl enable httpd mariadb zabbix-server zabbix-agent
	echo "---------add-runnig-start-ok----------"
}

#退出并还原repo文件
function exit_return(){
	mv /etc/yum.repos.d/bak/* /etc/yum.repos.d/
	rm -f /etc/yum.repos.d/myzabbix.repo
	echo "-------exit-and-recover-org-repo-ok----------"
}

####一键安装LAMP-zabbix ###
function auto_install(){
	set_firewall
	set_repo
	install_all
	conf_all
	start_all
	service_enable
	exit_return
	echo "---------auto-install-ok----------"
}



if [ 0 -eq 0 ];then
	while true ; do
		#statements
		echo -e "0).关闭防火墙\n1).手动安装\n2).手动配置\n3).启动服务\n4).停止服务\n5).添加开机启动\n6).一键全自动安装\nq).退出"
		read -p "请选择配置项:" ias
		case $ias in
			0)
				while true ; do
					#statements
					echo -e "1).确认关闭\nq).退出"
					read -p "请选择配置项:" iaas
					case $iaas in
						1)
							set_firewall
							;;
						q|Q)
							break
							;;
						*) 
							echo "请[重新]选择配置项"
					esac
				done
				;;
			1)
				while true ; do
					#statements
					echo -e "1).配置依赖包位置(离线安装操作必选)\n2).安装MariaDB\n3).安装Httpd\n4).安装Php\n5).安装Zabbix-server\n6).安装zabbix-agent\n7).安装所有\nq)返回菜单"
					read -p "请选择配置项:" ibs
					case $ibs in
						1)
							set_repo
							;;
						2)
							install_mariadb
							;;
						3)
							install_httpd
							;;
						4)
							install_php
							;;
						5)
							install_zabbix_server
							;;
						6)
							install_zabbix_agent
							;;
						7)
							install_all
							;;
						q|Q)
							#还原repo文件
							exit_return
							break
							;;
						*)
							echo "请[重新]选择配置项"
					esac
				done
				;;
			2)
				while [[ true ]]; do
					#statements
					echo -e "1).配置httpd\n2).配置php\n3).配置MariaDB数据库\n4).配置Zabbix-server\n5).配置zabbix-agent\n6).配置所有\nq).返回菜单"
					read -p "请选择配置项:" ics
					case $ics in
						1)
							conf_httpd
							;;
						2)
							conf_php
							;;
						3)
							conf_mariadb
							;;
						4)
							conf_zabbix_server
							;;
						5)
							conf_zabbix_agent
							;;
						6)
							conf_all
							;;
						q|Q)
							break
							;;
						*)
							echo "请[重新]选择配置项"
					esac
				done
				;;
			3)
				while [[ true ]]; do
					#statements
					echo -e "1).启动httpd\n2).启动MariaDB\n3).启动Zabbix_Server\n4).启动zabbix_agent\n5).启动所有\nq).返回菜单"
					read -p "请选择配置项:" ids
					case $ids in
						1)
							start_httpd
							;;
						2)
							start_mariadb
							;;
						3)
							start_zabbix_server
							;;
						4)
							start_zabbix_agent
							;;
						5)
							start_all
							;;
						q|Q)
							break
							;;
						*)
							echo "请[重新]选择配置项"
					esac
				done
				;;
			4)
				while [[ true ]]; do
					#statements
					echo -e "1).停止httpd\n2).停止MariaDB\n3).停止Zabbix_Server\n4).停止Zabbix_Agent\n5).停止所有\nq).返回菜单"
					read -p "请选择配置项:" ies
					case $ies in
						1)
							systemctl stop httpd
							;;
						2)
							systemctl stop mariadb
							;;
						3)
							systemctl stop zabbix-server
							;;
						4)
							systemctl stop zabbix-agent
							;;
						5)
							stop_all
							;;
						q|Q)
							break
							;;
						*)
							echo "请[重新]选择配置项"
					esac
				done
				;;
			5)
				while [[ true ]]; do
					#statements
					echo -e "1).添加开机启动Httpd服务\n2).添加开机启动MariaDB服务\n3).添加开机启动Zabbix_Server服务\n4).添加开机启动Zabbix_Agent服务\nq).返回菜单"
					read -p "请选择配置项:" ifs
					case $ifs in
						1)
							systemctl enable httpd
							;;
						2)
							systemctl enable mariadb
							;;
						3)
							systemctl enable zabbix-server
							;;
						4)
							systemctl enable zabbix-agent
							;;
						q|Q)
							break
							;;
						*)
							echo "请[重新]选择配置项"
					esac
				done
				;;
			6)
				while [[ true ]]; do
					#statements
					echo -e "1).确认要一键安装LAMP-Zabbix吗?\nq).返回菜单"
					read -p "请选择配置项" iais
					case $iais in
						1)
							auto_install
							;;
						q|Q)
							break
							;;
						*)
							echo "请[重新]选择配置项"
					esac
				done
				;;
			q|Q)
				break
				;;
			*)
				echo "请[重新]选择配置项"
		esac
	done
fi

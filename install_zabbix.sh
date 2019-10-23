#!/bin/bash
basedir=$(cd $(dirname "$0");pwd)
confdir=$basedir/templates
pcksdir=$basedir/packages
backdir=$basedir/backup
logsdir=$basedir/logs
tempdir=$basedir/tmp
time=$(date +%Y%m%d%H%M%S)
logfile=$logsdir/log.log_$(date +%F)

#服务配置文件
rclocal_file="/etc/rc.local"

#是否是静默模式安装,默认否
silent=0
#type类型[0 安装,1 启动,2 停止]
is_type=0
#统一安装路径
install_dir="/usr/local/viom"
#默认解压缩路径
xtar_dir=$tempdir

do_makedir() {
if test ! -d "${1}";then
	if test -e "${1}";then
		if test ! -e "$backdir";then
			mkdir -p $backdir
		fi
		mv ${1} $backdir/${1}_${time}
		mkdir -p ${1}
	else
		mkdir -p ${1}
	fi
fi
}
do_makedir $pcksdir
do_makedir $backdir
do_makedir $logsdir
do_makedir $tempdir
do_makedir $confdir

#统一接收外部参数函数
do_ins_argv() {
while getopts "d:x:t:sh" opts;do
	case $opts in
		d|D)
			ins_dir=$OPTARG
			;;
		x|X)
			ins_tar=$OPTARG
			;;
		s|S)
			silent=1
			;;
		t|T)
			ins_type=$OPTARG
			;;
		h|H)
			echo "USAGE: bash $0 (-d 安装路径) (-x 解压缩路径) (-s 打开静默安装模式) (-t 0|1|2|其它)"
			exit 0
			;;
		\?)
			echo "请输入合理参数"
			esac
done
}

do_ins_argv $@

if test -n "$ins_dir";then
	install_dir=$ins_dir
fi
if test -n "$ins_tar";then
	xtar_dir=$ins_tar
fi

if [ $(echo $install_dir|egrep -c ".*?/$") -eq 1 ];then
	install_dir=${install_dir%/*}
fi

if [ $(echo $xtar_dir|egrep -c ".*?/$") -eq 1 ];then
	xtar_dir=${xtar_dir%/*}
fi

do_makedir $install_dir
do_makedir $xtar_dir

#安装版本记录
ins_version_file=$install_dir/installed-versions.txt

do_write_ins_version() {
	if test ! -f "$ins_version_file";then
		touch $ins_version_file
	fi
	if [ $(egrep -c -w "$1" $ins_version_file) -eq 0 ];then
		printf "%-30s %-30s %-30s\n" ${1} $(date +%Y-%m-%d) ${2} >>$ins_version_file
	else
		sed -i "/${1}/d" $ins_version_file
		printf "%-30s %-30s %-30s\n" ${1} $(date +%Y-%m-%d) ${2} >>$ins_version_file
	fi
}


#Php参数配置
php_version="php-5.6.36"
php_file=$pcksdir/${php_version}.tar.gz
php_dir="$install_dir/php"
fastcgi_port=9000

#Nginx参数配置
nginx_user="nginx"
nginx_group="nginx"
nginx_port=8090
nginx_websitedir="$install_dir/website"
nginx_fastcgi_port=$fastcgi_port
nginx_version="nginx-1.12.2"
nginx_file=$pcksdir/${nginx_version}.tar.gz
nginx_dir="$install_dir/nginx"

#Pcre参数配置
pcre_version="pcre-8.20"
pcre_file=$pcksdir/${pcre_version}.tar.bz2
pcre_dir="$install_dir/pcre"

#Libpng参数配置
libpng_version="libpng-1.2.40"
libpng_file=$pcksdir/${libpng_version}.tar.bz2
libpng_dir="$install_dir/libpng"

#Freetype参数配置
freetype_version="freetype-2.3.4"
freetype_file=$pcksdir/${freetype_version}.tar.bz2
freetype_dir="$install_dir/freetype"

#Jpeg参数配置
jpeg_version="jpeg-8b"
jpeg_file=$pcksdir/jpegsrc.v8b.tar.gz
jpeg_dir="$install_dir/jpeg"

#Gd参数配置
gd_version="libgd-2.1.1"
gd_file=$pcksdir/${gd_version}.tar.gz
gd_dir="$install_dir/gd"

#Simkai字体文件
simkai_file=$confdir/simkai.ttf

#Libmcrypt参数配置
libmcrypt_version="libmcrypt-2.5.7"
libmcrypt_file=$pcksdir/${libmcrypt_version}.tar.gz
libmcrypt_dir="$install_dir/libmcrypt"

#Cmake参数配置
cmake_version="cmake-2.8.9"
cmake_file=$pcksdir/${cmake_version}.tar.gz
cmake_dir="$install_dir/cmake"

#Mysql参数配置
mysql_version="mysql-5.6.14"
mysql_file=$pcksdir/${mysql_version}.tar.gz
mysql_dir="$install_dir/mysql"
mysql_user="mysql"
root_user="root"
root_password="12345678"
mysql_port=3306
mysql_group="mysql"
mysql_datadir=$mysql_dir/data
mysql_logsdir=$mysql_dir/logs
mysql_confdir=$mysql_dir/etc
mysql_pidfile=$mysql_logsdir/mysql.pid
mysql_logsfile=$mysql_logsdir/error.log
mysql_tmpdir=$mysql_dir/tmp
mysql_socket=$mysql_tmpdir/mysql.sock
mysql_template_file=$confdir/my.cnf

#Zabbix参数配置
zabbix_version="zabbix-3.2.3"
zabbix_file=$pcksdir/${zabbix_version}.tar.gz
zabbix_dir="$install_dir/zabbix"
zabbix_logdir=$zabbix_dir/logs
zabbix_piddir=$zabbix_dir/pid
#Zabbix数据库参数配置
zabbix_host="127.0.0.1"
zabbix_port=$mysql_port
zabbix_db="zabbix"
zabbix_user=$root_user
zabbix_password=$root_password
zabbix_server="127.0.0.1"
zabbix_server_user="zabbix"
zabbix_server_group="zabbix"
zabbix_server_port=10051
zabbix_agent_port=10050
zabbix_server_name=$HOSTNAME
zabbix_template_file=$confdir/zabbix.conf.php
zabbix_server_file=$confdir/zabbix_server.conf
zabbix_agent_file=$confdir/zabbix_agentd.conf


#Web参数配置
website_dir=$nginx_websitedir/zabbix

#Libevent参数配置
libevent_version="libevent-2.1.8-stable"
libevent_file=$pcksdir/${libevent_version}.tar.gz
libevent_dir="$install_dir/libevent"

do_write_log() {
	echo "$(date +%Y-%m-%d) $(date +%H:%M:%S)|$@" >>$logfile
}


do_make_user() {
	if [ $(egrep -c -w "${2}" /etc/group) -eq 0 ];then
		groupadd ${2}
	fi
	
	if [ $(egrep -c -w "${2}" /etc/passwd) -eq 0 ];then
		if [ ${3} -eq 0 ];then
			useradd -M -s /sbin/nologin -g ${2} ${1}
		else
			useradd -g ${2} ${1}
			echo "!@${1}$(date +%Y)"|passwd --stdin ${1}
		fi
	fi
}

do_install_env() {
yum -y install ntp vim-enhanced gcc gcc-c++ flex bison autoconf automake bzip2 gzip zip bzip2-devel ncurses-devel zlib-devel libjpeg-devel libpng-devel libtiff-devel unzip net-snmp-devel libXpm-devel gettext-devel  pam-devel libtool libtool-ltdl openssl openssl-devel fontconfig-devel libxml2-devel curl-devel  libicu libicu-devel libevent &>/dev/null
}

do_check_file() {
	if test ! -f "${1}";then
		echo "${1}不存在,退出执行"
		exit 1
	fi
}

do_install_nginx() {
	do_make_user $nginx_user $nginx_group 0
	do_check_file $pcre_file
	if test ! -e "$xtar_dir/$pcre_version/configure";then
		tar -jxf $pcre_file -C $xtar_dir/
	fi
	if test ! -e "$pcre_dir/bin/pcre-config";then
		cd $xtar_dir/$pcre_version;./configure --prefix=$pcre_dir && make && make install
		if [ $? -ne 0 ];then
			echo "${pcre_file##*/}安装失败"
			exit 1
		fi
		do_write_ins_version $pcre_version pcre
	else
		do_write_ins_version $pcre_version pcre
	fi
	do_check_file $nginx_file
	if test ! -e "$xtar_dir/$nginx_version/configure";then
		tar -zxf $nginx_file -C $xtar_dir/
	fi
	if test ! -e "$nginx_dir/sbin/nginx";then
		cd $xtar_dir/$nginx_version; ./configure --prefix=$nginx_dir --user=$nginx_user --group=$nginx_group --with-select_module --with-poll_module --with-http_ssl_module --with-http_stub_status_module --with-http_dav_module --with-pcre=$xtar_dir/$pcre_version && make && make install
		if [ $? -ne 0 ];then
			echo "${nginx_file##*/}安装失败"
			exit 1
		fi
		do_write_ins_version $nginx_version nginx
		chown -R $nginx_user.$nginx_group $nginx_dir
	else
		do_write_ins_version $nginx_version nginx
	fi
	do_check_file $libpng_file
	if test ! -e "$xtar_dir/$libpng_version";then
		tar -jxf $libpng_file -C $xtar_dir/
	fi
	if test ! -e "$libpng_dir/bin/libpng12-config";then
		cd $xtar_dir/$libpng_version;./configure --prefix=$libpng_dir && make && make install
		if [ $? -ne 0 ];then
			echo "${libpng_file##*/}安装失败"
			exit 1
		fi
		do_write_ins_version $libpng_version libpng
	else
		do_write_ins_version $libpng_version libpng
	fi
	do_check_file $freetype_file
	if test ! -e "$xtar_dir/$freetype_version";then
		tar -jxf $freetype_file -C $xtar_dir/
	fi
	if test ! -e "$freetype_dir/bin/freetype-config";then
		mkdir -p /usr/local/freetype/include/freetype2/freetype/internal
		cd $xtar_dir/$freetype_version;./configure --prefix=$freetype_dir && make && make install
		if [ $? -ne 0 ];then
			if test -e "$freetype_dir";then
				rm -rf $freetype_dir
			fi
			echo "${freetype_file##*/}安装失败"
			exit 1
			
		fi
		do_write_ins_version $freetype_version freetype
	else
		do_write_ins_version $freetype_version freetype
	fi
	do_check_file $jpeg_file
	if test ! -e "$xtar_dir/$jpeg_version";then
		tar -zxf $jpeg_file -C $xtar_dir/
	fi
	if test ! -e "$jpeg_dir/bin/cjpeg";then
		cd $xtar_dir/$jpeg_version;./configure --prefix=$jpeg_dir --enable-shared && make && make install
		if [ $? -ne 0 ];then
			if test -e "$jpeg_dir";then
				rm -rf $jpeg_dir
			fi
			echo "${jpeg_file##*/}安装失败"
			exit 1
		fi
		do_write_ins_version $jpeg_version jpeg
	else
		do_write_ins_version $jpeg_version jpeg
	fi
	do_check_file $gd_file
	if test ! -e "$xtar_dir/$gd_version";then
		tar -zxf $gd_file -C $xtar_dir/
	fi
	if test ! -e "$gd_dir/bin/gdlib-config";then
		cd $xtar_dir/$gd_version;./configure --prefix=$gd_dir --with-png=$libpng_dir --with-freetype=$freetype_dir --with-jpeg=$jpeg_dir && make && make install
		if [ $? -ne 0 ];then
			echo "${gd_file##*/}安装失败"
			exit 1
		fi
		do_write_ins_version $gd_version gd
	else
		do_write_ins_version $gd_version gd
	fi
}

do_install_php() {
	do_check_file $libmcrypt_file
	if test ! -e "$xtar_dir/$libmcrypt_version";then
		tar -zxf $libmcrypt_file -C $xtar_dir/
	fi
	if test ! -e "$libmcrypt_dir/bin/libmcrypt-config";then
		cd $xtar_dir/$libmcrypt_version;./configure --prefix=$libmcrypt_dir && make && make install
		if [ $? -ne 0 ];then
			echo "${libmcrypt_file##*/}安装失败"
			exit 1
		fi
		do_write_ins_version $libmcrypt_version libmcrypt
	else
		do_write_ins_version $libmcrypt_version libmcrypt
	fi
	do_check_file $php_file
	if test ! -e "$xtar_dir/$php_version";then
		tar -zxf $php_file -C $xtar_dir/
	fi
	if test ! -e "$php_dir/sbin/php-fpm";then
		libxml2_dir=$(find /usr/share/doc/ -type d -name "libxml2-2*")
		if test -z "$libxml2_dir";then
			echo "libxml2没有安装"
			exit 1
		fi
		cd $xtar_dir/$php_version;./configure --prefix=$php_dir --with-config-file-path=$php_dir/etc --with-freetype-dir=$freetype_dir --with-jpeg-dir=$jpeg_dir --with-png-dir=$libpng_dir --with-zlib --with-libxml-dir=$libxml2_dir --enable-xml --disable-rpath --enable-discard-path --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --with-curlwrappers --enable-mbregex --enable-fastcgi --enable-fpm --enable-force-cgi-redirect --enable-mbstring --with-gd=$gd_dir --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --enable-opcache=no --with-mcrypt=$libmcrypt_dir  --with-mysql=$mysql_dir  --with-mysqli=$mysql_dir/bin/mysql_config && make && make install
		if [ $? -ne 0 ];then
			echo "${php_file##*/}安装失败"
			exit 1
		fi
		do_write_ins_version $php_version php
	else
		do_write_ins_version $php_version php
	fi
	sofile=$(find $php_dir -type f -name "gettext.so")
	if [ -z "$sofile" ];then
		cd $xtar_dir/$php_version/ext/gettext;$php_dir/bin/phpize && ./configure --with-php-config=$php_dir/bin/php-config && make && make install
		if [ $? -ne 0 ];then
			echo "Php拓展gettext失败"
			exit 1
		fi
		do_write_ins_version gettext gettext
	else
		do_write_ins_version gettext gettext
	fi
}

do_install_mysql() {
	do_check_file $cmake_file
	if test ! -e "$xtar_dir/$cmake_version";then
		tar -zxf $cmake_file -C $xtar_dir/
	fi
	if test ! -e "$cmake_dir/bin/cmake";then
		cd $xtar_dir/$cmake_version;./configure --prefix=$cmake_dir && make && make install
		if [ $? -ne 0 ];then
			echo "${cmake_file##*/}安装失败"
			exit 1
		fi
		do_write_ins_version $cmake_version cmake
	else
		do_write_ins_version $cmake_version cmake
	fi
	do_check_file $mysql_file
	do_makedir $mysql_datadir
	do_makedir $mysql_logsdir
	do_make_user $mysql_user $mysql_group 0
	if test ! -e "$xtar_dir/$mysql_version";then
		tar -zxf $mysql_file -C $xtar_dir/
	fi
	if test ! -e "$mysql_dir/bin/mysql";then
		cd $xtar_dir/$mysql_version;$cmake_dir/bin/cmake -DCMAKE_INSTALL_PREFIX=$mysql_dir -DMYSQL_DATADIR=$mysql_datadir -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_unicode_ci -DWITH_READLINE=1 -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_DEBUG=0 && make && make install
		if [ $? -ne 0 ];then
			echo "${mysql_file##*/}安装失败"
			exit 1
		fi
		do_write_ins_version $mysql_version mysql
	else
		do_write_ins_version $mysql_version mysql
	fi
}

do_install_zabbix() {
	do_make_user $zabbix_server_user $zabbix_server_group 0
	do_check_file $libevent_file
	if test ! -e "$xtar_dir/$libevent_version";then
		tar -zxf $libevent_file -C $xtar_dir/
	fi
	if test ! -e "$libevent_dir/bin/event_rpcgen.py";then
		cd $xtar_dir/$libevent_version;./configure --prefix=$libevent_dir && make && make install
		if [ $? -ne 0 ];then
			echo "${libevent_file##*/}安装失败"
			exit 1
		fi
		do_write_ins_version $libevent_version libevent
	else
		do_write_ins_version $libevent_version libevent
	fi
	do_check_file $zabbix_file
	if test ! -e "$xtar_dir/$zabbix_version";then
		tar -zxf $zabbix_file -C $xtar_dir/
	fi
	if test ! -e "$zabbix_dir/sbin/zabbix_server";then
		cd $xtar_dir/$zabbix_version;./configure --with-mysql=$mysql_dir/bin/mysql_config --with-libevent=$libevent_dir --with-libevent-include=$libevent_dir/include --with-libevent-lib=$libevent_dir/lib --with-net-snmp --with-libcurl --enable-server --enable-agent --enable-proxy --prefix=$zabbix_dir && make clean && make && make install
		if [ $? -ne 0 ];then
			echo "${zabbix_file##*/}安装失败"
			exit 1
		fi
		do_write_ins_version $zabbix_version zabbix
	else
		do_write_ins_version $zabbix_version zabbix
	fi
	if test ! -d "$nginx_websitedir";then
		do_makedir $nginx_websitedir
	fi
	if test ! -d "$nginx_websitedir/zabbix";then
		if test -d "$xtar_dir/$zabbix_version/frontends/php";then
			cp -ar $xtar_dir/$zabbix_version/frontends/php $nginx_websitedir/zabbix
		fi
	fi
	chown -R $zabbix_server_user.$zabbix_server_group $nginx_websitedir
	chown -R $zabbix_server_user.$zabbix_server_group $zabbix_dir
}

do_install_all() {
do_install_env
do_install_mysql
do_install_nginx
do_install_php
do_install_zabbix
}

do_conf_nginx() {
	if test -d "$nginx_dir/conf";then
		if test -e "$confdir/nginx.conf";then
			do_makedir $nginx_websitedir
			sed "s#{{user}}#$nginx_user#;s#{{nginx_port}}#$nginx_port#;s#{{website}}#$nginx_websitedir#;s#{{fastcgi_port}}#$nginx_fastcgi_port#" $confdir/nginx.conf >$nginx_dir/conf/nginx.conf
		fi
		chown $nginx_user.$nginx_group $nginx_dir/conf/nginx.conf
	fi
	$nginx_dir/sbin/nginx -t &>/dev/null
	if [ $? -ne 0 ];then
		echo "Nginx配置文件校验失败"
		exit 1
	fi
}

do_conf_php() {
	if test -d "$php_dir/etc";then
		if test -e "$confdir/php-fpm.conf";then
			sed "s#{{phpdir}}#$php_dir#" $confdir/php-fpm.conf >$php_dir/etc/php-fpm.conf
		fi
	fi
	if test ! -d "$php_dir/etc/php-fpm.d";then
		do_makedir $php_dir/etc/php-fpm.d
	fi
	if test -e "$confdir/www.conf";then
			sed "s#{{nginx_user}}#$nginx_user#;s#{{nginx_group}}#$nginx_group#;s#{{fastcgi_port}}#$fastcgi_port#" $confdir/www.conf >$php_dir/etc/php-fpm.d/www.conf
	fi
	sofile=$(find $php_dir -type f -name "gettext.so")
	sodir=${sofile%/*}
	if test -d  "$php_dir/etc";then
		if test -e "$confdir/php.ini";then
			sed "s#{{extension_dir}}#$sodir#" $confdir/php.ini >$php_dir/etc/php.ini
		fi
	fi
}

do_conf_mysql() {
if test ! -e "$mysql_dir/bin/mysql";then
	echo "配置数据库失败"
	exit 1
fi
do_makedir $mysql_confdir
do_makedir $mysql_logsdir
do_makedir $mysql_tmpdir
chmod +x $mysql_dir
chown -R $mysql_user:$mysql_group $mysql_dir
if test -d "$mysql_confdir";then
	sed "s#{{socket}}#$mysql_socket#;s#{{datadir}}#$mysql_datadir#;s#{{port}}#$mysql_port#;s#{{logerror}}#$mysql_logsfile#;s#{{pidfile}}#$mysql_pidfile#;s#{{user}}#$mysql_user#;s#{{tmpdir}}#$mysql_tmpdir#" $mysql_template_file >$mysql_confdir/my.cnf
else
	echo "my.cnf数据库配置生成失败"
	exit 1
fi
if test ! -e "$mysql_datadir/ibdata1";then
	$mysql_dir/scripts/mysql_install_db --user=$mysql_user --basedir=$mysql_dir --datadir=$mysql_datadir --defaults-file=$mysql_confdir/my.cnf
	if [ $? -ne 0 ];then
		echo "MySql初始化失败"
		exit 1
	fi
	$mysql_dir/bin/mysqld_safe --defaults-file=$mysql_confdir/my.cnf &
	while true;do
		sleep 5
		$mysql_dir/bin/mysqladmin -S $mysql_socket -u $root_user password "$root_password"
		if [ $? -eq 0 ];then
			break
		fi
	done
fi
if test -d "$xtar_dir/$zabbix_version/database/mysql";then
		if [ $(netstat -lntp|grep -c -w $mysql_port) -eq 0 ];then
			$mysql_dir/bin/mysqld_safe --defaults-file=$mysql_confdir/my.cnf &
		fi
		sleep 5
		check_db=$($mysql_dir/bin/mysql -u$root_user -p"$root_password" -S $mysql_socket -e "show databases;"|grep -w "$zabbix_db")
		if test -z "$check_db";then
			$mysql_dir/bin/mysql -u$root_user -p"$root_password" -S $mysql_socket -e "create database $zabbix_db;commit;"
			if [ $? -ne 0 ];then
				echo "Zabbix数据库创建失败"
				exit 1
			fi
		fi	
		if test -e "$xtar_dir/$zabbix_version/database/mysql";then
			check_tb=$($mysql_dir/bin/mysql -u$root_user -p"$root_password" -S $mysql_socket -e "use $zabbix_db;show tables;"|wc -l)			
			if [ $check_tb -eq 0 ];then
				if test -e "$xtar_dir/$zabbix_version/database/mysql/schema.sql";then
					$mysql_dir/bin/mysql -u$root_user -p"$root_password" -S $mysql_socket  $zabbix_db < $xtar_dir/$zabbix_version/database/mysql/schema.sql
					if [ $? -ne 0 ];then
						echo "Zabbix数据schema导入失败"
						exit 1
					fi
				fi
				if test -e "$xtar_dir/$zabbix_version/database/mysql/images.sql";then
					$mysql_dir/bin/mysql -u$root_user -p"$root_password" -S $mysql_socket  $zabbix_db < $xtar_dir/$zabbix_version/database/mysql/images.sql
					if [ $? -ne 0 ];then
						echo "Zabbix数据images导入失败"
						exit 1
					fi
				fi
				if test -e "$xtar_dir/$zabbix_version/database/mysql/data.sql";then
					$mysql_dir/bin/mysql -u$root_user -p"$root_password" -S $mysql_socket $zabbix_db < $xtar_dir/$zabbix_version/database/mysql/data.sql
					if [ $? -ne 0 ];then
						echo "Zabbix数据data导入失败"
						exit 1
					fi
				fi
			fi
			$mysql_dir/bin/mysql -u$root_user -p"$root_password" -S $mysql_socket -e "use $zabbix_db;update users set lang='zh_CN';commit;"
			if [ $? -ne 0 ];then
				echo "Zabbix语言设置失败"
				exit 1
			fi
		fi
fi
}

do_conf_zabbix() {
	
	if test -e "$zabbix_template_file";then
		if test -d "$website_dir/conf";then
			sed "s#{{db_host}}#$zabbix_host#;s#{{db_port}}#$zabbix_port#;s#{{db_base}}#$zabbix_db#;s#{{db_user}}#$zabbix_user#;s#{{db_password}}#$zabbix_password#;s#{{zabbix_server}}#$zabbix_server#;s#{{zabbix_server_port}}#$zabbix_server_port#;s#{{zabbix_server_name}}#$zabbix_server_name#" $zabbix_template_file >$website_dir/conf/zabbix.conf.php
		fi
	fi
	if test -e "$simkai_file";then
		sk_name=${simkai_file##*/}
		if test -d "$website_dir/fonts";then
			if test ! -e "$website_dir/fonts/$sk_name";then
				cp $simkai_file $website_dir/fonts/
				sed -i "s#DejaVuSans#simkai#g" $website_dir/include/defines.inc.php
				chown -R $zabbix_server_user.$zabbix_server_grou $website_dir/fonts/$sk_name
			fi
		fi
	else
		echo "$simkai_file字体库文件不存在"
	fi
	if test -e "$zabbix_server_file";then
		if test -d "$zabbix_dir/etc";then
			do_makedir $zabbix_logdir
			do_makedir $zabbix_piddir
			chown -R $zabbix_server_user.$zabbix_server_grou $zabbix_logdir
			chown -R $zabbix_server_user.$zabbix_server_grou $zabbix_piddir
			sed "s#{{zabbix_logdir}}#$zabbix_logdir#;s#{{zabbix_piddir}}#$zabbix_piddir#;s#{{db_name}}#$zabbix_db#;s#{{db_user}}#$zabbix_user#;s#{{db_password}}#$zabbix_password#;s#{{db_socket}}#$mysql_socket#;s#{{db_port}}#$mysql_port#;s#{{install_dir}}#$zabbix_dir#" $zabbix_server_file > $zabbix_dir/etc/${zabbix_server_file##*/}
		fi
	fi
	if test -e "$zabbix_agent_file";then
		if test -d "$zabbix_dir/etc";then
			do_makedir $zabbix_logdir
			do_makedir $zabbix_piddir
			chown -R $zabbix_server_user.$zabbix_server_grou $zabbix_logdir
			chown -R $zabbix_server_user.$zabbix_server_grou $zabbix_piddir
			sed "s#{{zabbix_logdir}}#$zabbix_logdir#;s#{{zabbix_piddir}}#$zabbix_piddir#;s#{{zabbix_host}}#$zabbix_server#g;s#{{hostname}}#$zabbix_server_name#" $zabbix_agent_file > $zabbix_dir/etc/${zabbix_agent_file##*/}
		fi
	fi
		
}

do_conf_all() {
do_conf_mysql
do_conf_php
do_conf_nginx
do_conf_zabbix
}

do_start_nginx() {
	if [ $(netstat -lntp|grep -c -w "$nginx_port") -eq 0 ];then
		if test -e "$nginx_dir/sbin/nginx";then
			$nginx_dir/sbin/nginx
			if [ $? -ne 0 ];then
				echo "Nginx启动失败"
				exit 1
			fi
		else
			echo "Nginx启动失败"
			exit 1
		fi
	fi
}

do_start_php() {
	if [ $(netstat -lntp|grep -c -w "$fastcgi_port") -eq 0 ];then
		if test -e "$php_dir/sbin/php-fpm";then
			$php_dir/sbin/php-fpm
			if [ $? -ne 0 ];then
				echo "Php启动失败"
				exit 1
			fi
		else
			echo "Php启动失败"
			exit 1
		fi
	fi
}

do_start_mysql() {
if [ $(netstat -lntp|grep -w -c "$mysql_port") -eq 0 ];then
	if test -e "$mysql_dir/bin/mysqld_safe";then
		$mysql_dir/bin/mysqld_safe --defaults-file=$mysql_confdir/my.cnf &
		if [ $? -ne 0 ];then
			echo "MySQL启动失败"
			exit 1
		fi
	else
		echo "MySql启动失败"
		exit 1
	fi
fi
}

do_start_zabbix_server() {
	if [ $(netstat -lntp|grep -c -w "$zabbix_server_port") -eq 0 ];then
		if test -e "$zabbix_dir/sbin/zabbix_server";then
			$zabbix_dir/sbin/zabbix_server -c $zabbix_dir/etc/zabbix_server.conf
			if [ $? -ne 0 ];then
				echo "Zabbix Server启动失败"
				exit 1
			fi
		else
			echo "Zabbix Server启动失败"
			exit 1
		fi
	fi
}
do_start_zabbix_agent() {
	if [ $(netstat -lntp|grep -c -w "$zabbix_agent_port") -eq 0 ];then
		if test -e "$zabbix_dir/sbin/zabbix_agentd";then
			$zabbix_dir/sbin/zabbix_agentd -c $zabbix_dir/etc/zabbix_agentd.conf
			if [ $? -ne 0 ];then
				echo "Zabbix Agent启动失败"
				exit 1
			fi
		else
			echo "Zabbix Agent启动失败"
			exit 1
		fi
	fi
}
do_stop_zabbix_server() {
	if [ $(netstat -lntp|grep -c -w "$zabbix_server_port") -eq 1 ];then
		if test -e "$zabbix_piddir/zabbix_server.pid";then
			kill -QUIT `cat $zabbix_piddir/zabbix_server.pid`
			if [ $? -ne 0 ];then
				echo "Zabbix Server停止失败"
				exit 1
			fi
		else
			echo "Zabbix Server停止失败"
			exit 1
		fi
	fi
}
do_stop_zabbix_agent() {
	if [ $(netstat -lntp|grep -c -w "$zabbix_agent_port") -eq 1 ];then
		netstat -lntp|grep -w $zabbix_agent_port|egrep -o '[0-9]{1,}/zabbix_agentd'|cut -d '/' -f1|xargs kill -QUIT
		if [ $? -ne 0 ];then
			echo "Zabbix Agent停止失败"
			exit 1
		fi
	fi
}


do_start_all() {
do_start_mysql
do_start_php
do_start_nginx
do_start_zabbix_server
do_start_zabbix_agent
}


do_stop_nginx() {
	if [ $(netstat -lntp|grep -c -w "$nginx_port") -eq 1 ];then
		if test -e "$nginx_dir/sbin/nginx";then
			$nginx_dir/sbin/nginx -s stop
			if [ $? -ne 0 ];then
				echo "Nginx停止失败"
				exit 1
			fi
		else
			echo "Nginx停止失败"
			exit 1
		fi
	fi
}

do_stop_php() {
	if [ $(netstat -lntp|grep -c -w "$fastcgi_port") -eq 1 ];then
			if test -e "$php_dir/var/run/php-fpm.pid";then
				kill -QUIT `cat $php_dir/var/run/php-fpm.pid`
				if [ $? -ne 0 ];then
					echo "Php停止失败"
					exit 1
				fi
			else
				echo "Php停止失败"
				exit 1
			fi
	fi
}

do_stop_mysql() {
if [ $(netstat -lntp|grep -w -c "$mysql_port") -eq 1 ];then
	if test -e "$mysql_dir/bin/mysqladmin";then
        	$mysql_dir/bin/mysqladmin -u$root_user -p"$root_password" -S $mysql_socket shutdown
		if [ $? -ne 0 ];then
			echo "MySql停止失败"
			exit 1
		fi
	else
		echo "MySql停止失败"
		exit 1
	fi
fi
}

do_stop_all() {
	do_stop_nginx
	do_stop_php
	do_stop_mysql
	do_stop_zabbix_server
	do_stop_zabbix_agent
}

do_service_nginx() {
if [ $(egrep -w -c "^$nginx_dir/sbin/nginx" $rclocal_file) -eq 0 ];then
	echo "$nginx_dir/sbin/nginx" >>$rclocal_file
fi
}

do_service_php() {
if [ $(egrep -w -c "^$php_dir/sbin/php-fpm" $rclocal_file) -eq 0 ];then
	echo "$php_dir/sbin/php-fpm" >>$rclocal_file
fi
}
do_service_zabbix_server() {
if [ $(egrep -w -c "^$zabbix_dir/sbin/zabbix_server" $rclocal_file) -eq 0 ];then
	echo "$zabbix_dir/sbin/zabbix_server -c $zabbix_dir/etc/zabbix_server.conf" >>$rclocal_file
fi
}
do_service_zabbix_agent() {
if [ $(egrep -w -c "^$zabbix_dir/sbin/zabbix_agentd" $rclocal_file) -eq 0 ];then
	echo "$zabbix_dir/sbin/zabbix_agentd -c $zabbix_dir/etc/zabbix_agentd.conf" >>$rclocal_file
fi
}
do_service_mysql() {
if [ $(egrep -w -c "^$mysql_dir/bin/mysqld_safe.*?--defaults-file=$mysql_confdir/my.cnf" $rclocal_file) -eq 0 ];then
	echo "$mysql_dir/bin/mysqld_safe --defaults-file=$mysql_confdir/my.cnf &" >>$rclocal_file
fi
}

do_service_all() {
do_service_mysql
do_service_php
do_service_nginx
do_service_zabbix_server
do_service_zabbix_agent
}
if [ $silent -eq 0 ];then
	while true;do
		echo -e "1).安装\n2).配置\n3).启动\n4).停止\n5).服务\nq).退出"
		read -p "请选择配置项:" ias
		case $ias in
			1)
				while true;do
					echo -e "1).基础环境配置\n2).安装MySQL\n3).安装Nginx\n4).安装Php\n5).安装Zabbix\n6).安装所有\nq).返回菜单"
					read -p "请选择配置项:" ibs
					case $ibs in
					1)
						do_install_env
						;;
					2)
						do_install_mysql
						;;
					3)
						do_install_nginx
						;;
					4)
						do_install_php
						;;
					5)
						do_install_zabbix
						;;
					6)
						do_install_all
						;;
					q|Q)
						break
						;;
					*)
						echo "请选择配置项"
						esac
				done
				;;
			2)
				while true;do
					echo -e "1).配置Nginx\n2).配置Php\n3).配置MySQL\n4).配置Zabbix\n5).配置所有\nq).返回菜单"
					read -p "请选择配置项:" ics
					case $ics in
					1)
						do_conf_nginx
						;;
					2)
						do_conf_php
						;;
					3)
						do_conf_mysql
						;;
					4)
						do_conf_zabbix
						;;
					5)
						do_conf_all
						;;
					q|Q)
						break
						;;
					*)
						echo "请选择配置项"
						esac
				done
				;;
			3)
				while true;do
					echo -e "1).启动Nginx\n2).启动Php\n3).启动MySQL\n4).启动Zabbix_Server\n5).启动Zabbix_Agent\n6).启动所有\nq).返回菜单"
					read -p "请选择配置项:" ids
					case $ids in
					1)
						do_start_nginx
						;;
					2)
						do_start_php
						;;
					3)
						do_start_mysql
						;;
					4)
						do_start_zabbix_server
						;;
					5)
						do_start_zabbix_agent
						;;
					6)
						do_start_all
						;;
					q|Q)
						break
						;;
					*)
						echo "请选择配置项"
						esac
				done
				;;
			4)
				while true;do
					echo -e "1).停止Nginx\n2).停止Php\n3).停止MySQL\n4).停止Zabbix_Server\n5).停止Zabbix_Agent\n6).停止所有\nq).返回菜单"
					read -p "请选择配置项:" ies
					case $ies in
					1)
						do_stop_nginx
						;;
					2)
						do_stop_php
						;;
					3)
						do_stop_mysql
						;;
					4)
						do_stop_zabbix_server
						;;
					5)
						do_stop_zabbix_agent
						;;
					6)
						do_stop_all
						;;
					q|Q)
						break
						;;
					*)
						echo "请选择配置项"
						esac
				done
				;;
			5)
				while true;do
					echo -e "1).添加Nginx服务\n2).添加Php服务\n3).添加MySQL服务\n4).添加Zabbix_Server服务\n5).添加Zabbix_Agent服务\n6).添加所有\nq).返回菜单"
					read -p "请选择配置项:" ifs
					case $ifs in
					1)
						do_service_nginx
						;;
					2)
						do_service_php
						;;
					3)
						do_service_mysql
						;;
					4)
						do_service_zabbix_server
						;;
					5)
						do_service_zabbix_agent
						;;
					6)
						do_service_all
						;;
					q|Q)
						break
						;;
					*)
						echo "请选择配置项"
						esac
				done
				;;
			q|Q)
				break
				;;
			*)
				echo "请选择配置项"
				esac
	done
else
	if test -n "$ins_type";then
		expr $ins_type + 0 &>/dev/null
		if [ $? -ne 0 ];then
			ins_type=$is_type
		fi
	else
		ins_type=$is_type
	fi
	case $ins_type in
	0)
		do_install_all
		do_conf_all
		do_start_all
		do_service_all
		;;
	1)
		do_start_all
		;;
	2)
		do_stop_all	
		;;
	*)
		do_service_all
		esac
fi

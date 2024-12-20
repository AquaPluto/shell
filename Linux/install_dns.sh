#!/bin/bash
#
#*******************************************#
#Author:                AquaPluto
#Email:                 wujunlinq@163.com
#Date:                  2023-3-25
#FileName:              install_dns.sh
#Blog:                  https://blog.csdn.net/m0_75233142
#Github:                https://github.com/AquaPluto
#Description:           安装DNS
#******************************************#
DOMAIN=wu.org
HOST=www
HOST_IP=10.0.0.100
LOCALHOST=`hostname -I | awk '{print $1}'`

. /etc/os-release

color () {
    RES_COL=60
    MOVE_TO_COL="echo -en \\033[${RES_COL}G"
    SETCOLOR_SUCCESS="echo -en \\033[1;32m"
    SETCOLOR_FAILURE="echo -en \\033[1;31m"
    ETCOLOR_WARNING="echo -en \\033[1;33m"
    SETCOLOR_NORMAL="echo -en \E[0m"
    echo -n "$1" && $MOVE_TO_COL
    echo -n "["
    if [ $2 = "success" -o $2 = "0" ] ;then
        ${SETCOLOR_SUCCESS}
        echo -n $"  OK  "    
    elif [ $2 = "failure" -o $2 = "1"  ] ;then
        ${SETCOLOR_FAILURE}
        echo -n $"FAILED"
    else
        ${SETCOLOR_WARNING}
         echo -n $"WARNING"
    fi
    ${SETCOLOR_NORMAL}
    echo -n "]"
    echo 
}

install_dns() {
    if [[ $ID =~ centos|rocky ]];then
        yum install -y bind bind-utils
    elif [[ $ID =~ ubuntu ]];then
        apt update && apt install -y bind9 bind9-utils
    else
        color "不支持操作系统" 1
        exit
    fi
}

config_dns() {
    if [[ $ID =~ centos|rocky ]];then
        sed -i -e 's#listen-on port#//listen-on port#' -e 's#allow-query#//allow-query#' -e 's/dnssec-enable yes/dnssec-enable no/' -e 's/dnssec-validation yes/dnssec-validation no/' /etc/named.conf
        cat >> /etc/named.rfc1912.zones <<EOF
zone "$DOMAIN" IN {
    type master;
    file "$DOMAIN.zone";
};
EOF
        cat > /var/named/$DOMAIN.zone <<EOF
\$TTL 1D
@   IN  SOA $DOMAIN. admin.wu.com. (1 3H 1M 1D 1W)
        NS  master
master       A   $LOCALHOST
$HOST        A   $HOST_IP
EOF
        chmod 640 /var/named/$DOMAIN.zone
        chgrp named /var/named/$DOMAIN.zone
        named-checkconf;named-checkzone $DOMAIN /var/named/$DOMAIN.zone
        [ $? -eq 0 ] && color "配置文件没问题" 0 || { color "配置文件有问题!" 1 ;exit 1; }
    elif [[ $ID =~ ubuntu ]];then
        sed -i 's/dnssec-validation auto/dnssec-validation no/' /etc/bind/named.conf.options
        cat >> /etc/bind/named.conf.default-zones <<EOF
zone "$DOMAIN" IN {
    type master;
    file "$DOMAIN.zone";
};
EOF
        cat > /etc/bind/db.$DOMAIN <<EOF
\$TTL 1D
@   IN  SOA $DOMAIN. admin.wu.com. (1 3H 1M 1D 1W)
        NS  master
master       A   $LOCALHOST
$HOST        A   $HOST_IP
EOF
        chmod 640 /etc/bind/db.$DOMAIN
        chgrp bind /etc/bind/db.$DOMAIN
        named-checkconf;named-checkzone $DOMAIN /etc/bind/db.$DOMAIN
        [ $? -eq 0 ] && color "配置文件没问题" 0 || { color "配置文件有问题!" 1 ;exit 1; }
    else
        color "不支持此操作系统，退出!" 1
        exit
    fi
}

start_dns() {
    systemctl enable --now named
    systemctl restart named
    systemctl is-active named
    [ $? -eq 0 ] && color "DNS 服务安装成功!" 0 || { color "DNS 服务安装失败!" 1 ;exit 1; }
}

install_dns
config_dns
start_dns

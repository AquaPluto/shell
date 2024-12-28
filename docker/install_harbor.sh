#!/bin/bash
#
#*******************************************#
#Author:                AquaPluto
#Email:                 wujunlinq@163.com
#Date:                  2024-12-28
#FileName:              install_harbor.sh
#Blog:                  https://blog.csdn.net/m0_75233142
#Github:                https://github.com/AquaPluto
#Description:           安装harbor
#******************************************#

#建议提前下载Harbor文件进行离线安装,也支持在线下载安装
#docker和docker-compose无需下载,在线安装即可

HARBOR_VERSION=2.12.1
HARBOR_BASE=/apps

#HARBOR_NAME=harbor.wang.org
HARBOR_NAME=`hostname -I|awk '{print $1}'`
#HARBOR_NAME=10.0.0.200

DOCKER_VERSION="27.4.0"   # ubuntu20.04最新为27.4.1
#DOCKER_VERSION="26.1.3"  # Rocky8最新
DOCKER_URL="http://mirrors.ustc.edu.cn"
#DOCKER_URL="https://mirrors.aliyun.com"
#DOCKER_URL="https://mirrors.tuna.tsinghua.edu.cn"

DOCKER_COMPOSE_VERSION=2.32.1
DOCKER_COMPOSE_FILE=docker-compose-linux-x86_64


HARBOR_ADMIN_PASSWORD=123456
HARBOR_IP=`hostname -I|awk '{print $1}'`


COLOR_SUCCESS="echo -e \\033[1;32m"
COLOR_FAILURE="echo -e \\033[1;31m"
END="\033[m"

. /etc/os-release
UBUNTU_DOCKER_VERSION="5:${DOCKER_VERSION}-1~${ID}.${VERSION_ID}~${UBUNTU_CODENAME}"
CENTOS_DOCKER_CE_VERSION="3:${DOCKER_VERSION}-1.el8"
CENTOS_DOCKER_CE_CLI_VERSION="1:${DOCKER_VERSION}-1.el8"

color () {
    RES_COL=60
    MOVE_TO_COL="echo -en \\033[${RES_COL}G"
    SETCOLOR_SUCCESS="echo -en \\033[1;32m"
    SETCOLOR_FAILURE="echo -en \\033[1;31m"
    SETCOLOR_WARNING="echo -en \\033[1;33m"
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


install_docker(){
    if [ $ID = "centos" -o $ID = "rocky" ];then
        if [ $VERSION_ID = "7" ];then
            cat >  /etc/yum.repos.d/docker.repo  <<EOF
[docker]
name=docker
gpgcheck=0
#baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7/x86_64/stable/
baseurl=${DOCKER_URL}/docker-ce/linux/centos/7/x86_64/stable/
EOF
        else     
            cat >  /etc/yum.repos.d/docker.repo  <<EOF
[docker]
name=docker
gpgcheck=0
#baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/8/x86_64/stable/
baseurl=${DOCKER_URL}/docker-ce/linux/centos/8/x86_64/stable/
EOF
        fi
	    yum clean all
        ${COLOR_FAILURE} "Docker有以下版本"${END}
        yum list docker-ce --showduplicates
        ${COLOR_FAILURE}"5秒后即将安装: docker-"${CENTOS_DOCKER_VERSION}" 版本....."${END}
        ${COLOR_FAILURE}"如果想安装其它Docker版本，请按ctrl+c键退出，修改版本再执行"${END}
        sleep 5
        yum -y install docker-ce-$CENTOS_DOCKER_CE_VERSION docker-ce-cli-$CENTOS_DOCKER_CE_CLI_VERSION --allowerasing  \
            || { color "Base,Extras的yum源失败,请检查yum源配置" 1;exit; }
    else
        dpkg -s docker-ce &> /dev/null && $COLOR"Docker已安装，退出" 1 && exit
        apt update || { color "更新包索引失败" 1 ; exit 1; }
        apt  -y install apt-transport-https ca-certificates curl software-properties-common || \
            { color "安装相关包失败" 1 ; exit 2;  }
        curl -fsSL ${DOCKER_URL}/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
        add-apt-repository "deb [arch=amd64] ${DOCKER_URL}/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
        apt update
        ${COLOR_FAILURE} "Docker有以下版本"${END}
        apt-cache madison docker-ce
        ${COLOR_FAILURE}"5秒后即将安装: docker-"${UBUNTU_DOCKER_VERSION}" 版本....."${END}
        ${COLOR_FAILURE}"如果想安装其它Docker版本，请按ctrl+c键退出，修改版本再执行"${END}
        sleep 5
        apt -y  install docker-ce=${UBUNTU_DOCKER_VERSION} docker-ce-cli=${UBUNTU_DOCKER_VERSION}
    fi
    if [ $? -eq 0 ];then
        color "安装软件包成功"  0
    else
        color "安装软件包失败，请检查网络配置" 1
        exit
    fi
        
    mkdir -p /etc/docker
    tee /etc/docker/daemon.json <<-'EOF'
{
	  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn","https://hub-mirror.c.163.com","https://docker.m.daocloud.io"],
	  "live-restore": true
}
EOF
    systemctl daemon-reload
    systemctl enable docker
    systemctl restart docker
    docker version && color "Docker 安装成功" 0 ||  color "Docker 安装失败" 1
    echo 'alias rmi="docker images -qa|xargs docker rmi -f"' >> ~/.bashrc
    echo 'alias rmc="docker ps -qa|xargs docker rm -f"' >> ~/.bashrc
}



install_docker_compose(){
    ${COLOR_SUCCESS}"开始安装 Docker compose....."${END}
    sleep 1
    if [ ! -e  ${DOCKER_COMPOSE_FILE} ];then
        curl -L https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/${DOCKER_COMPOSE_FILE} -o /usr/bin/docker-compose
    else
        mv ${DOCKER_COMPOSE_FILE} /usr/bin/docker-compose
    fi
    chmod +x /usr/bin/docker-compose
    if docker-compose --version ;then
        ${COLOR_SUCCESS}"Docker Compose 安装完成"${END} 
    else
        ${COLOR_FAILURE}"Docker compose 安装失败"${END}
        exit
    fi
}

install_harbor(){
    ${COLOR_SUCCESS}"开始安装 Harbor....."${END}
    sleep 1
    if  [ ! -e  harbor-offline-installer-v${HARBOR_VERSION}.tgz ] ;then
        wget https://github.com/goharbor/harbor/releases/download/v${HARBOR_VERSION}/harbor-offline-installer-v${HARBOR_VERSION}.tgz || ${COLOR_FAILURE} "下载失败!" ${END}
    fi
    [ -d ${HARBOR_BASE} ] ||  mkdir ${HARBOR_BASE}
    tar xvf harbor-offline-installer-v${HARBOR_VERSION}.tgz  -C ${HARBOR_BASE}
    cd ${HARBOR_BASE}/harbor
    cp harbor.yml.tmpl harbor.yml
    sed -ri "/^hostname/s/reg.mydomain.com/${HARBOR_NAME}/" harbor.yml
    sed -ri "/^https/s/(https:)/#\1/" harbor.yml
    sed -ri "s/(port: 443)/#\1/" harbor.yml
    sed -ri "/certificate:/s/(.*)/#\1/" harbor.yml
    sed -ri "/private_key:/s/(.*)/#\1/" harbor.yml
    sed -ri "s/Harbor12345/${HARBOR_ADMIN_PASSWORD}/" harbor.yml
    sed -i 's#^data_volume: /data#data_volume: /data/harbor#' harbor.yml
    mkdir -p /data/harbor
    ${HARBOR_BASE}/harbor/install.sh && ${COLOR_SUCCESS}"Harbor 安装完成"${END} ||  ${COLOR_FAILURE}"Harbor 安装失败"${END}
    cat > /lib/systemd/system/harbor.service <<EOF
[Unit]
Description=Harbor
After=docker.service systemd-networkd.service systemd-resolved.service
Requires=docker.service
Documentation=http://github.com/vmware/harbor

[Service]
Type=simple
Restart=on-failure
RestartSec=5
ExecStart=/usr/bin/docker-compose -f  ${HARBOR_BASE}/harbor/docker-compose.yml up
ExecStop=/usr/bin/docker-compose -f ${HARBOR_BASE}/harbor/docker-compose.yml down

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload 
    systemctl enable  harbor &>/dev/null ||  ${COLOR}"Harbor已配置为开机自动启动"${END}
    if [ $?  -eq 0 ];then  
        echo 
        color "Harbor安装完成!" 0
        echo "-------------------------------------------------------------------"
        echo -e "请访问链接: \E[32;1mhttp://${HARBOR_IP}/\E[0m" 
		echo -e "用户和密码: \E[32;1madmin/${HARBOR_ADMIN_PASSWORD}\E[0m" 
    else
        color "Harbor安装失败!" 1
        exit
    fi
    echo "$HARBOR_IP     $HARBOR_NAME"   >> /etc/hosts
}



docker info  &> /dev/null  && ${COLOR_FAILURE}"Docker已安装"${END} || install_docker

docker-compose --version &> /dev/null && ${COLOR_FAILURE}"Docker Compose已安装"${END} || install_docker_compose

install_harbor


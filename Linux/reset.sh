#!/bin/bash
#
#*******************************************#
#Author:                AquaPluto
#Email:                 wujunlinq@163.com
#Date:                  2023-1-20
#FileName:              reset.sh
#Blog:                  https://blog.csdn.net/m0_75233142
#Github:                https://github.com/AquaPluto
#Description:           系统初始化
#******************************************#

menu(){
	while true ; do	
		echo -en "\E[$[RANDOM%7+31];1m"
		cat <<-EOF
		请选择需要功能，只支持centos7，centos8，rocky8，ubuntu20.04：
		1)关闭防火墙
		2)关闭SElinux
		3)修改提示符
		4)配置网卡且默认名称为eth0
		5)配置centos8的yum源
		6)配置yum源，apt源（centos8不适用）
		7)centos系列自动挂载光盘
		8)初始化shell格式
		0)退出
		EOF
		echo -en '\E[0m'
		read -p "请选择你要做的操作:" menu
		case $menu in 
			1)
				disable_firewalld
				;;
			2)
				disable_selinux
				;;
			3)
				change_ps1
				;;
			4)
				change_eth0
				;;
			5)
				set_centos8_yum
				;;
			6)	
				set_yum
				;;
			7)	
				set_autofs
				;;
			8)
				init_shell
				;;
			0|q|exit|quite)      
				exit
				;;
			*)echo "选择无效，请重选"
				;;
		esac
	done
}

release (){
	. /etc/os-release
	if [[ $ID =~ rocky|centos|ubuntu ]]; then
		echo "尊贵的 $ID 用户，您好"
	else
		echo "另请高明"
        	exit 
	fi
}

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

main(){
	release
	menu  
}

disable_firewalld(){
	systemctl disable --now firewalld >& /dev/null
	color "防火墙关闭成功" 0 
}

disable_selinux(){
	while [[ $ID =~ rocky|centos ]] ;do
		sed -ri "/^SELINUX=/s/(SELINUX=).*/\1disabled/" /etc/selinux/config >& /dev/null
		color "SELINUX已关闭" 0
		break
	done
        while [[ $ID == ubuntu ]] ;do
                color "SELINUX默认未安装，无需更改" 2
                break
        done
}

change_ps1(){
	echo "PS1='\[\e[1;35m\][\u@\h \w]\\$\[\e[0m\]'" > ~/.bashrc
	color "提示符已修改成功,请重新登录生效" 0
}

set_yum(){
	if [[ $ID == rocky ]] ;then
		[ -d /etc/yum.repos.d/backup ] || mkdir /etc/yum.repos.d/backup 
		mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup ;
		cat > /etc/yum.repos.d/base.repo <<EOF
[BaseOS]
name=BaseOS
baseurl=http://mirrors.163.com/rocky/\$releasever/BaseOS/\$basearch/os/
		https://mirrors.aliyun.com/rockylinux/\$releasever/BaseOS/\$basearch/os/
		https://mirrors.nju.edu.cn/rocky/\$releasever/BaseOS/\$basearch/os/
gpgcheck=0

[AppStream]
name=AppStream
baseurl=http://mirrors.163.com/rocky/\$releasever/AppStream/\$basearch/os/
		https://mirrors.aliyun.com/rockylinux/\$releasever/AppStream/\$basearch/os/
		https://mirrors.nju.edu.cn/rocky/\$releasever/AppStream/\$basearch/os/
gpgcheck=0

[extras]
name=extras
baseurl=http://mirrors.163.com/rocky/\$releasever/extras/\$basearch/os/
		https://mirrors.aliyun.com/rockylinux/\$releasever/extras/\$basearch/os/
		https://mirrors.nju.edu.cn/rocky/\$releasever/extras/\$basearch/os/
gpgcheck=0
enabled=1

[epel]
name=EPEL
baseurl=https://mirror.tuna.tsinghua.edu.cn/epel/\$releasever/Everything/\$basearch
        https://mirrors.cloud.tencent.com/epel/\$releasever/Everything/\$basearch
        https://mirrors.huaweicloud.com/epel/\$releasever/Everything/\$basearch
        https://mirrors.aliyun.com/epel/\$releasever/Everything/\$basearch
gpgcheck=0
enabled=1
EOF
        yum clean all >& /dev/null
		yum repolist  &> /dev/null
		yum makecache  
		[ $? -eq 0 ] && color "$ID yum源配置完成" 0 || color "$ID yum源配置失败，请查找原因" 1
	elif [[ $ID == centos ]] ;then
        mkdir /etc/yum.repos.d/backup &> /dev/null
        mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup
        cat > /etc/yum.repos.d/base.repo <<EOF
[base]
name=CentOS
baseurl=https://mirrors.aliyun.com/centos/\$releasever/os/\$basearch/
		https://mirror.tuna.tsinghua.edu.cn/centos/\$releasever/os/\$basearch/
		http://mirrors.163.com/centos/\$releasever/os/\$basearch/
gpgcheck=0

[extras]
name=extras
baseurl=https://mirrors.aliyun.com/centos/\$releasever/extras/\$basearch/
		https://mirror.tuna.tsinghua.edu.cn/centos/\$releasever/extras/\$basearch/
		http://mirrors.163.com/centos/\$releasever/extras/\$basearch/
gpgcheck=0
enabled=1


[epel]
name=EPEL
baseurl=https://mirror.tuna.tsinghua.edu.cn/epel/\$releasever/\$basearch
        https://mirrors.cloud.tencent.com/epel/\$releasever/\$basearch/
        https://mirrors.huaweicloud.com/epel/\$releasever/\$basearch 
gpgcheck=0
enabled=1
EOF
		yum clean all >& /dev/null
        yum repolist  &> /dev/null
		yum makecache 
		[ $? -eq 0 ] && color "$ID yum源配置完成" 0 || color "$ID yum源配置失败，请查找原因" 1
	elif [ $ID == ubuntu ]; then
		local source=$1
		[ -z $source ] && read -p "请输入要配置的源，1,阿里，2，清华，3，北大:" source || echo "配置默认源为阿里"
		case $source  in
			1)
				cat >/etc/apt/sources.list <<EOF
# See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
# newer versions of the distribution.
deb https://mirrors.aliyun.com/ubuntu/ focal main restricted
# deb-src https://mirrors.aliyun.com/ubuntu/ focal main restricted

## Major bug fix updates produced after the final release of the
## distribution.
deb https://mirrors.aliyun.com/ubuntu/ focal-updates main restricted
# deb-src https://mirrors.aliyun.com/ubuntu/ focal-updates main restricted

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team. Also, please note that software in universe WILL NOT receive any
## review or updates from the Ubuntu security team.
deb https://mirrors.aliyun.com/ubuntu/ focal universe
# deb-src https://mirrors.aliyun.com/ubuntu/ focal universe
deb https://mirrors.aliyun.com/ubuntu/ focal-updates universe
# deb-src https://mirrors.aliyun.com/ubuntu/ focal-updates universe

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team, and may not be under a free licence. Please satisfy yourself as to
## your rights to use the software. Also, please note that software in
## multiverse WILL NOT receive any review or updates from the Ubuntu
## security team.
deb https://mirrors.aliyun.com/ubuntu/ focal multiverse
# deb-src https://mirrors.aliyun.com/ubuntu/ focal multiverse
deb https://mirrors.aliyun.com/ubuntu/ focal-updates multiverse
# deb-src https://mirrors.aliyun.com/ubuntu/ focal-updates multiverse

## N.B. software from this repository may not have been tested as
## extensively as that contained in the main release, although it includes
## newer versions of some applications which may provide useful features.
## Also, please note that software in backports WILL NOT receive any review
## or updates from the Ubuntu security team.
deb https://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
# deb-src https://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse

## Uncomment the following two lines to add software from Canonical's
## 'partner' repository.
## This software is not part of Ubuntu, but is offered by Canonical and the
## respective vendors as a service to Ubuntu users.
# deb http://archive.canonical.com/ubuntu focal partner
# deb-src http://archive.canonical.com/ubuntu focal partner

deb https://mirrors.aliyun.com/ubuntu/ focal-security main restricted
# deb-src https://mirrors.aliyun.com/ubuntu/ focal-security main restricted
deb https://mirrors.aliyun.com/ubuntu/ focal-security universe
# deb-src https://mirrors.aliyun.com/ubuntu/ focal-security universe
deb https://mirrors.aliyun.com/ubuntu/ focal-security multiverse
# deb-src https://mirrors.aliyun.com/ubuntu/ focal-security multiverse
EOF
				apt clean all &>/dev/null
				apt update
				[ $? -eq 0 ] && color "$ID apt源配置完成" 0 || color "$ID apt源配置失败，请查找原因" 1
				;;
			2)
				 cat >/etc/apt/sources.list <<EOF
# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security main restricted universe multiverse

# 预发布软件源，不建议启用
# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-proposed main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-proposed main restricted universe multiverse
EOF
				apt clean all &>/dev/null
                apt update
                [ $? -eq 0 ] && color "$ID apt源配置完成" 0 || color "$ID apt源配置失败，请查找原因" 1
				;;
			3)
				cat >/etc/apt/sources.list <<EOF
deb https://mirrors.cloud.tencent.com/ubuntu/ focal main restricted universe multiverse
deb-src https://mirrors.cloud.tencent.com/ubuntu/ focal main restricted universe multiverse

deb https://mirrors.cloud.tencent.com/ubuntu/ focal-security main restricted universe multiverse
deb-src https://mirrors.cloud.tencent.com/ubuntu/ focal-security main restricted universe multiverse

deb https://mirrors.cloud.tencent.com/ubuntu/ focal-updates main restricted universe multiverse
deb-src https://mirrors.cloud.tencent.com/ubuntu/ focal-updates main restricted universe multiverse

deb https://mirrors.cloud.tencent.com/ubuntu/ focal-backports main restricted universe multiverse
deb-src https://mirrors.cloud.tencent.com/ubuntu/ focal-backports main restricted universe multiverse

## Not recommended
# deb https://mirrors.cloud.tencent.com/ubuntu/ focal-proposed main restricted universe multiverse
# deb-src https://mirrors.cloud.tencent.com/ubuntu/ focal-proposed main restricted universe multiverse
EOF
	 			apt clean all &>/dev/null
                apt update
                [ $? -eq 0 ] && color "$ID apt源配置完成" 0 || color "$ID apt源配置失败，请查找原因" 1
				;;
			*)	
				echo "weqweqweqw"
				;;
		esac
	else
		echo "无能为力" 
		exit
	fi
}

set_centos8_yum(){
	[ -d /etc/yum.repos.d/backup ] || mkdir /etc/yum.repos.d/backup
	mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup
	cat > /etc/yum.repos.d/centos8.repo <<EOF
[BaseOS]
name=BaseOS
baseurl=https://mirrors.aliyun.com/centos/\$releasever/BaseOS/\$basearch/os/
gpgcheck=0

[AppStream]
name=AppStream
baseurl=https://mirrors.aliyun.com/centos/\$releasever/AppStream/\$basearch/os/
gpgcheck=0

[extras]
name=extras
baseurl=https://mirrors.aliyun.com/centos/\$releasever/extras/\$basearch/os/
		https://mirror.tuna.tsinghua.edu.cn/centos/\$releasever/extras/\$basearch/os/
		http://mirrors.163.com/centos/\$releasever/extras/\$basearch/os/
		https://mirrors.nju.edu.cn/centos/\$releasever/extras/\$basearch/os/
gpgcheck=0
enabled=1

[epel]
name=EPEL
baseurl=hhttps://mirror.tuna.tsinghua.edu.cn/epel/\$releasever/Everything/\$basearch
        https://mirrors.cloud.tencent.com/epel/\$releasever/Everything/\$basearch
        https://mirrors.huaweicloud.com/epel/\$releasever/Everything/\$basearch
        https://mirrors.aliyun.com/epel/\$releasever/Everything/\$basearch
gpgcheck=0
enabled=1
EOF
	yum clean all &> /dev/null
	yum repolist  &> /dev/null
	yum makecache
	[ $? -eq 0 ] && color "$ID 配置yum源成功" 0 || color "失败，请查找原因" 1
}

change_eth0(){
	while [[ $ID =~ rocky|centos ]] ;do
		grep "net.ifnames=0" /etc/default/grub >& /dev/null
		if [ $? -eq 0 ] ; then
            color "$ID 网卡默认名称改过了，不要再改了" 2
        else
            sed -ri "/^GRUB_CMDLINE_LINUX=/s/^(.*)\"/\1 net.ifnames=0\"/" /etc/default/grub;
            grub2-mkconfig -o /boot/grub2/grub.cfg &>/dev/null
            color "网卡默认名称修改成功" 0
        fi
		ipaddr=`hostname -I |awk '{print $1}'`
		cat > /etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
DEVICE=eth0
NAME=eth0
BOOTPROTO=none
IPADDR=${ipaddr}
PREFIX=24
GATEWAY=10.0.0.2
DNS1=10.0.0.2
DNS2=100.76.76.76
ONBOOT=yes
EOF
		color "网卡配置成功，请重启生效" 0
	break
	done
	while [[ $ID == ubuntu ]] ;do
		grep "net.ifnames=0" /etc/default/grub >& /dev/null
		if [ $? -eq 0 ] ; then 
		    color "$ID 网卡默认名称改过了，不要再改了" 2 
		else
            sed -ri "/^GRUB_CMDLINE_LINUX=/s/^(.*)\"/\1 net.ifnames=0\"/" /etc/default/grub;
            update-grub  &> /dev/null;
			color "网卡默认名称修改成功" 0
		fi
		ipaddr=`hostname -I |awk '{print $1}'`
		cat > /etc/netplan/eth0.yaml <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses: 
      - ${ipaddr}/24
      gateway4: 10.0.0.2
      nameservers:
        search: [baidu.com]
        addresses: [10.0.0.2, 180.76.76.76]
EOF
		color "网卡配置成功，请重启生效" 0
	break
	done

}

set_autofs(){
    if [[ $ID =~ rocky|centos ]] ;then
        rpm -q autofs &> /dev/null && { color "autofs 已安装，请勿重复操作" 2 ; systemctl start autofs;} || { yum -y install autofs &> /dev/null ;systemctl enable --now autofs;color "autofs 已安装" 0; }
    else
		color "Ubuntu不会配autofs" 2
	fi
}

init_shell(){
	if [[ $ID =~ rocky|centos|ubuntu ]] ;then
		cat > /root/.vimrc <<EOF
set ts=4
set expandtab
set ignorecase
syntax on
set shiftwidth=4
autocmd BufNewFile *.sh exec ":call SetTitle()"
func SetTitle()
    if expand("%:e") == 'sh'
    call setline(1,"#!/bin/bash")
    call setline(2,"#")
    call setline(3,"#*******************************************#")
    call setline(4,"#Author:                AquaPluto")
    call setline(5,"#Email:                 wujunlinq@163.com")
    call setline(6,"#Date:                  ".strftime("%Y-%m-%d"))
    call setline(7,"#FileName:              ".expand("%"))
    call setline(8,"#Blog:                  https://blog.csdn.net/m0_75233142")
    call setline(9,"#Github:                https://github.com/AquaPluto")
    call setline(10,"#Description:           The test script")
    call setline(11,"#******************************************#")
    call setline(12,"")
    endif
endfunc
autocmd BufNewFile * normal G
EOF
		color "配置成功" 0
	else
		echo "无能为力"
	fi
}
main

#!/bin/bash
#
#*******************************************#
#Author:                AquaPluto
#Email:                 wujunlinq@163.com
#Date:                  2023-3-26
#FileName:              key_verify.sh
#Blog:                  https://blog.csdn.net/m0_75233142
#Github:                https://github.com/AquaPluto
#Description:           基于key验证多主机ssh访问
#******************************************#

PASS=zjwjl2004
# 设置网段最后的地址，4-255之间，越小扫描越快
END=254

IP=`ip a s eth0 | awk -F'[ /]+' 'NR==3{print $3}'`  # 获取当前主机的 IP 地址
NET=${IP%.*}.  # 提取 IP 的网络部分

. /etc/os-release

rm -f /root/.ssh/id_rsa{,.pub}
[ -e ./SCANIP.log ] && rm -f SCANIP.log

# 扫描存活 IP 地址
for((i=3;i<="$END";i++));do
    ping -c 1 -w 1  ${NET}$i &> /dev/null  && echo "${NET}$i" >> SCANIP.log &
done
wait

ssh-keygen -P "" -f /root/.ssh/id_rsa

if [ $ID = "centos" -o $ID = "rocky" ];then
    rpm -q sshpass || yum -y install sshpass
else
    dpkg -i sshpass &> /dev/null ||{ apt update; apt -y install sshpass; }
fi

# 分发 SSH 公钥
sshpass -p $PASS ssh-copy-id -o StrictHostKeyChecking=no $IP  # 将当前主机的 SSH 公钥添加到自身
AliveIP=(`cat SCANIP.log`)
for n in ${AliveIP[*]};do
    sshpass -p $PASS scp -o StrictHostKeyChecking=no -r /root/.ssh root@${n}:  # 将生成的 SSH 密钥对复制到每个存活主机上
done

#把.ssh/known_hosts拷贝到所有主机，使它们第一次互相访问时不需要输入回车
for n in ${AliveIP[*]};do
    scp /root/.ssh/known_hosts ${n}:.ssh/
done

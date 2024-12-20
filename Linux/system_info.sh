#!/bin/bash
#
#*******************************************#
#Author:                AquaPluto
#Email:                 wujunlinq@163.com
#Date:                  2023-2-20
#FileName:              system_info.sh
#Blog:                  https://blog.csdn.net/m0_75233142
#Github:                https://github.com/AquaPluto
#Description:           显示系统部分硬件信息
#******************************************#

# 定义颜色变量
GREEN="\e[1;32m"       # 绿色
BLUE="\e[1;34m"        # 蓝色
PURPLE="\e[1;35m"      # 紫色
END="\e[0m"            # 结束颜色

# 加载操作系统信息
. /etc/os-release

# 打印标题
echo -e "${PURPLE}---------------------- Host system info --------------------${END}"
echo -e "Hostname:     ${BLUE}$(hostname)${END}"
echo -e "IP Address:   ${BLUE}$(ip -4 addr show scope global | awk '/inet/ {print $2}')${END}"
echo -e "OS Version:   ${BLUE}$PRETTY_NAME${END}"
echo -e "Kernel:       ${BLUE}$(uname -r)${END}"
echo -e "CPU Model:   ${BLUE}$(lscpu | grep '^Model name' | awk -F":" '{print $2}' | tr -s ' ')${END}"
echo -e "CPU(s):      ${BLUE}$(lscpu | grep '^CPU(s)' | awk -F":" '{print $2}' | tr -s ' ')${END}"
echo -e "Memory:       ${BLUE}$(free -h | awk '/Mem:/ {print $2}')${END}"

# 获取所有以 sd 开头的磁盘及其大小的信息
echo -e "Disks starting with 'sd':"
lsblk -dno NAME,SIZE | grep '^sd' | while read -r line; do
    device=$(echo "$line" | awk '{print $1}')
    size=$(echo "$line" | awk '{print $2}')
    echo -e "${BLUE}\t\tDevice: /dev/$device${END}"
    echo -e "${BLUE}\t\tSize:   $size${END}"
    echo -e "${GREEN}\t\t----------------${END}"
done

echo -e "${PURPLE}-------------------------------------------------------------${END}"

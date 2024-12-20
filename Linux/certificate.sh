#!/bin/bash
#
#*******************************************#
#Author:                AquaPluto
#Email:                 wujunlinq@163.com
#Date:                  2023-2-25
#FileName:              certificate.sh
#Blog:                  https://blog.csdn.net/m0_75233142
#Github:                https://github.com/AquaPluto
#Description:           颁发证书
#******************************************#

# 证书存放目录
DIR=/etc/pki/CA

# subjectX：定义了 X 号证书的主题信息，如国家、省份、城市、组织和通用名（0号是自签名证书的信息）
# keyfileX：指定 X 号证书私钥文件的路径。
# crtfileX：指定 X 号证书文件的路径。
# keyX：定义 X 号证书使用的密钥长度（如 2048 位）。
# expireX：定义 X 号证书的有效期（以天为单位）。
# serialX：定义 X 号证书的序列号。
# csrfileX：定义 X 号证书签名请求（CSR）文件的路径（仅适用于非根证书）。
declare -A CERT_INFO
CERT_INFO=([subject0]="/C=CN/ST=hubei/L=wuhan/O=Central.Hospital/CN=ca.god.com" \
           [keyfile0]="private/cakey.pem" \
           [crtfile0]="cacert.pem" \
           [key0]=2048 \
           [expire0]=3650 \
           [serial0]=0    \
           [subject1]="/C=CN/ST=hubei/L=wuhan/O=Central.Hospital/CN=master.liwenliang.org" \
           [keyfile1]="private/master.key" \
           [crtfile1]="certs/master.crt" \
           [key1]=2048 \
           [expire1]=365
           [serial1]=1 \
           [csrfile1]="master.csr" \
           [subject2]="/C=CN/ST=hubei/L=wuhan/O=Central.Hospital/CN=slave.liwenliang.org" \
           [keyfile2]="private/slave.key" \
           [crtfile2]="certs/slave.crt" \
           [key2]=2048 \
           [expire2]=365 \
           [serial2]=2 \
           [csrfile2]="slave.csr"   )

COLOR="echo -e \\E[1;32m"
END="\\E[0m"

#证书编号最大值
N=`echo ${!CERT_INFO[*]} |grep -o subject|wc -l`

. /etc/os-release

if [ $ID = "ubuntu" ];then
    sed -i 's@^dir\s*=\s*\.\/demoCA@dir = /etc/pki/CA@' /usr/lib/ssl/openssl.cnf
fi


[ -d $DIR ] || mkdir $DIR
cd $DIR
mkdir certs crl newcerts private
touch index.txt  # 创建索引文件，记录已签发的证书
echo 0F > /etc/pki/CA/serial  # 初始化序列号文件


for((i=0;i<N;i++));do
    if [ $i -eq 0 ] ;then
        # 生成自签名的根证书
        openssl req  -x509 -newkey rsa:${CERT_INFO[key${i}]} -subj ${CERT_INFO[subject${i}]} \
            -set_serial ${CERT_INFO[serial${i}]} -keyout ${CERT_INFO[keyfile${i}]} -nodes \
	    -days ${CERT_INFO[expire${i}]}  -out ${CERT_INFO[crtfile${i}]} &>/dev/null
        
    else
        # 生成客户端或服务器证书
        openssl req -newkey rsa:${CERT_INFO[key${i}]} -nodes -subj ${CERT_INFO[subject${i}]} \
            -keyout ${CERT_INFO[keyfile${i}]}   -out ${CERT_INFO[csrfile${i}]} \
        -days ${CERT_INFO[expire${i}]} -set_serial ${CERT_INFO[serial${i}]} &>/dev/null
    fi

    openssl ca -in ${CERT_INFO[csrfile${i}]} -out ${CERT_INFO[crtfile${i}]} -days ${CERT_INFO[expire${i}]} -batch &>/dev/null  # 签发证书
done

for((i=0;i<N;i++));do
    $COLOR"**************************************生成证书信息**************************************"$END
    openssl x509 -in ${CERT_INFO[crtfile${i}]} -noout -subject -dates -serial
    echo 
done

chmod 600 /etc/pki/CA/private/*.key
echo  "证书生成完成"
$COLOR"**************************************生成证书文件如下**************************************"$END
echo "证书存放目录: "$DIR
echo "证书文件列表: "`ls $DIR`


#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
导出路径
#=======================================================================#
# 支持的系统：CentOS 6+ / Debian 7+ / Ubuntu 12+ #
# 描述：L2TP VPN 自动安装程序 #
# 作者：Teddysun <i@teddysun.com> #
# 简介：https://teddysun.com/448.html #
#=======================================================================#
cur_dir=`pwd`

libreswan_filename="libreswan-3.27"
download_root_url="https://dl.lamp.sh/files"

根性（）{
    如果[[$EUID -ne 0]];那么
       echo“错误：此脚本必须以root身份运行！”1>＆2
       1号出口
    菲
}

tunavailable(){
    如果 [[ ！ -e /dev/net/tun ]];然后
        echo "错误：TUN/TAP 不可用！" 1>&2
        1号出口
    菲
}

disable_selinux(){
如果 [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; 然后
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
菲
}

获取opsy()
    [ -f /etc/redhat-release ] && awk '{打印 ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && 返回
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && 返回
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && 返回
}

获取操作系统信息（）{
    IP = $（ip地址| egrep -o'[0-9]{1,3} \.[0-9]{1,3} \.[0-9]{1,3} \.[0-9]{1,3}'| egrep -v“^192 \.168|^172 \.1[6-9] \.|^172 \.2[0-9] \.|^172 \.3[0-2] \.|^10 \.|^127 \.|^255 \.|^0 \."| head -n 1）
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )

    本地 cname=$( awk -F: '/型号名称/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
    本地核心=$（awk -F：'/型号名称/ {core++} END {print core}' /proc/cpuinfo ）
    本地频率 = $（awk -F：'/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//'）
    本地电车=$（免费-m | awk'/Mem/{print $2}'）
    本地交换 = $（免费 -m | awk'/Swap/{print $2}'）
    本地启动 = $（awk'{a = $1/86400; b =（$1%86400）/3600; c =（$1%3600）/60; d = $1%60} {printf（"％ddays，％d：％d：％d \ n"，a，b，c，d）}'/ proc / uptime）
    本地负载=$（w | head -1 | awk -F'平均负载：' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//'）
    本地 opsy=$( get_opsy )
    本地 arch=$(uname -m)
    本地 lbit=$( getconf LONG_BIT )
    本地主机=$(主机名)
    本地内核=$(uname -r)

    echo "########## 系统信息 ##########"
    回声
    echo "CPU型号：${cname}"
    echo "核心数：${cores}"
    echo "CPU频率：${freq} MHz"
    echo "总内存量：${tram} MB"
    echo "交换总量：${swap} MB"
    echo“系统正常运行时间：${up}”
    echo“平均负载：${load}”
    echo "操作系统：${opsy}"
    echo "Arch : ${arch} (${lbit} 位)"
    echo“内核：${kern}”
    echo“主机名：${host}”
    echo "IPv4 地址：${IP}"
    回声
    回显“#############################################”
}

check_sys(){
    本地检查类型=$1
    当地价值=$2

    本地发布=''
    本地系统包=''

    如果 [[ -f /etc/redhat-release ]]; 那么
        发布=“centos”
        系统包=“yum”
    elif cat /etc/issue | grep -Eqi“debian”；然后
        发布=“debian”
        系统包=“apt”
    elif 猫 /etc/issue | grep -Eqi“ubuntu”；然后
        发布=“ubuntu”
        系统包=“apt”
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; 然后
        发布=“centos”
        系统包=“yum”
    elif cat /proc/版本 | grep -Eqi "debian";然后
        发布=“debian”
        系统包=“apt”
    elif cat /proc/version | grep -Eqi“ubuntu”；然后
        发布=“ubuntu”
        系统包=“apt”
    elif cat /proc/version | grep -Eqi“centos|red hat|redhat”；然后
        发布=“centos”
        系统包=“yum”
    菲

    如果 [[ ${checkType} == "sysRelease" ]]; 那么
        如果 [ “$value” == “$release” ];那么
            返回 0
        别的
            返回 1
        菲
    elif [[ ${checkType} == "packageManager" ]]; 然后
        如果 [ “$value” == “$systemPackage” ];那么
            返回 0
        别的
            返回 1
        菲
    菲
}

rand(){
    索引=0
    字符串=""
    对于 {a..z} 中的 i；执行 arr[index]=${i}；index=`expr ${index} + 1`；完成
    对于 {A..Z} 中的 i；执行 arr[index]=${i}；index=`expr ${index} + 1`；完成
    对于 {0..9} 中的 i；执行 arr[index]=${i}；index=`expr ${index} + 1`；完成
    对于 {1..10} 中的 i；执行 str="$str${arr[$RANDOM%$index]}"；完成
    回显 ${str}
}

is_64bit(){
    如果 [`getconf WORD_BIT` = '32'] && [`getconf LONG_BIT` = '64'] ; 然后
        返回 0
    别的
        返回 1
    菲
}

下载文件（）{
    如果 [ -s ${1} ]; 那么
        echo "$1 [找到]"
    别的
        echo "未找到$1!!!立即下载..."
        如果 !wget -c -t3 -T60 ${download_root_url}/${1}; 那么
            echo "下载$1失败，请手动下载至${cur_dir}目录后重试。"
            1号出口
        菲
    菲
}

版本获取（）{
    如果[[-s /etc/redhat-release]]；那么
        grep -oE “[0-9.]+” /etc/redhat-release
    别的
        grep -oE “[0-9.]+” /etc/issue
    菲
}

centosversion(){
    如果 check_sys sysRelease centos;那么
        本地代码=${1}
        本地版本=“`versionget`”
        本地 main_ver=${版本%%.*}
        如果[“${main_ver}”==“${code}”]；那么
            返回 0
        别的
            返回 1
        菲
    别的
        返回 1
    菲
}

debianversion(){
    如果 check_sys sysRelease debian；那么
        本地版本=$(get_opsy)
        本地代码=${1}
        本地 main_ver=$( echo ${version} | sed 's/[^0-9]//g')
        如果[“${main_ver}”==“${code}”]；那么
            返回 0
        别的
            返回 1
        菲
    别的
        返回 1
    菲
}

版本检查（）{
    如果 check_sys packageManager yum；那么
        如果是 centosversion 5；那么
            echo“错误：不支持 CentOS 5，请重新安装操作系统并重试。”
            1号出口
        菲
    菲
}

获取字符（）{
    SAVEDSTTY=`stty -g`
    stty-echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty-raw
    stty回显
    stty $SAVEDSTTY
}

预安装_l2tp(){

    回声
    如果[-d“/proc/vz”]；那么
        echo -e "\033[41;37m 警告：\033[0m 您的 VPS 基于 OpenVZ，内核可能不支持 IPSec。"
        echo“继续安装？（y/n）”
        read -p“（默认值：n）”同意
        [ -z ${同意} ] && 同意="n"
        如果 [ "${agree}" == "n" ]; 那么
            回声
            echo“L2TP 安装已取消。”
            回声
            出口 0
        菲
    菲
    回声
    echo "请输入 IP 范围："
    read -p“（默认范围：192.168.18）：”iprange
    [ -z ${iprange} ] && iprange="192.168.18"

    echo "请输入PSK："
    read -p "(默认PSK: teddysun.com):" mypsk
    [ -z ${mypsk} ] && mypsk="teddysun.com"

    echo "请输入用户名："
    read -p“（默认用户名：teddysun）：”用户名
    [ -z ${用户名} ] && 用户名=“teddysun”

    密码=`rand`
    echo "请输入${username}的密码："
    read -p“（默认密码：${password}）：”tmppassword
    [ !-z ${tmppassword} ] && 密码=${tmppassword}

    回声
    echo "服务器IP:${IP}"
    echo "服务器本地IP:${iprange}.1"
    echo "客户端远程 IP 范围：${iprange}.2-${iprange}.254"
    回显“PSK：${mypsk}”
    回声
    echo“按任意键开始...或按 Ctrl + C 取消。”
    char=`get_char`

}

安装_l2tp(){

    mknod /dev/random c 1 9

    如果 check_sys packageManager apt; 那么
        apt-get -y 更新

        如果 debianversion 7；那么
            如果是 64 位；那么
                本地 libnspr4_filename1="libnspr4_4.10.7-1_amd64.deb"
                本地 libnspr4_filename2="libnspr4-0d_4.10.7-1_amd64.deb"
                本地 libnspr4_filename3="libnspr4-dev_4.10.7-1_amd64.deb"
                本地 libnspr4_filename4="libnspr4-dbg_4.10.7-1_amd64.deb"
                本地 libnss3_filename1="libnss3_3.17.2-1.1_amd64.deb"
                本地 libnss3_filename2="libnss3-1d_3.17.2-1.1_amd64.deb"
                本地 libnss3_filename3="libnss3-tools_3.17.2-1.1_amd64.deb"
                本地 libnss3_filename4="libnss3-dev_3.17.2-1.1_amd64.deb"
                本地 libnss3_filename5="libnss3-dbg_3.17.2-1.1_amd64.deb"
            别的
                本地 libnspr4_filename1="libnspr4_4.10.7-1_i386.deb"
                本地 libnspr4_filename2="libnspr4-0d_4.10.7-1_i386.deb"
                本地 libnspr4_filename3="libnspr4-dev_4.10.7-1_i386.deb"
                本地 libnspr4_filename4="libnspr4-dbg_4.10.7-1_i386.deb"
                本地 libnss3_filename1="libnss3_3.17.2-1.1_i386.deb"
                本地 libnss3_filename2="libnss3-1d_3.17.2-1.1_i386.deb"
                本地 libnss3_filename3="libnss3-tools_3.17.2-1.1_i386.deb"
                本地 libnss3_filename4="libnss3-dev_3.17.2-1.1_i386.deb"
                本地 libnss3_filename5="libnss3-dbg_3.17.2-1.1_i386.deb"
            菲
            rm -rf ${cur_dir}/l2tp
            mkdir -p ${cur_dir}/l2tp
            cd ${cur_dir}/l2tp
            下载文件“${libnspr4_filename1}”
            下载文件“${libnspr4_filename2}”
            下载文件“${libnspr4_filename3}”
            下载文件“${libnspr4_filename4}”
            下载文件“${libnss3_filename1}”
            下载文件“${libnss3_filename2}”
            下载文件“${libnss3_filename3}”
            下载文件“${libnss3_filename4}”
            下载文件“${libnss3_filename5}”
            dpkg -i ${libnspr4_filename1} ${libnspr4_filename2} ${libnspr4_filename3} ${libnspr4_filename4}
            dpkg -i ${libnss3_filename1} ${libnss3_filename2} ${libnss3_filename3} ${libnss3_filename4} ${libnss3_filename5}

            apt-get -y 安装 wget gcc ppp flex bison make pkg-config libpam0g-dev libcap-ng-dev iptables \
                               libcap-ng-utils libunbound-dev libevent-dev libcurl4-nss-dev libsystemd-daemon-dev
        别的
            apt-get -y 安装 wget gcc ppp flex bison make python libnss3-dev libnss3-tools libselinux-dev iptables \
                               libnspr4-dev pkg-config libpam0g-dev libcap-ng-dev libcap-ng-utils libunbound-dev \
                               libevent-dev libcurl4-nss-dev libsystemd-dev
        菲
        apt-get -y --no-install-recommends 安装 xmlto
        apt-get -y 安装 xl2tpd

        编译安装
    elif check_sys packageManager yum; 然后
        echo“添加 EPEL 存储库...”
        yum -y 安装 epel-release yum-utils
        [ !-f /etc/yum.repos.d/epel.repo ] && echo "安装 EPEL 仓库失败，请检查。" && exit 1
        yum-config-manager——启用epel
        echo“添加 EPEL 存储库完成...”

        如果是 centosversion 7；那么
            yum -y 安装 ppp libreswan xl2tpd 防火墙
            yum_安装
        elif centosversion 6; 然后
            yum -y 删除 libevent-devel
            yum -y 安装 libevent2-devel
            yum -y 安装 nss-devel nspr-devel pkgconfig pam-devel \
                           libcap-ng-devel libselinux-devel lsof \
                           curl-devel flex bison gcc ppp make iptables gmp-devel \
                           fipscheck-devel unbound-devel xmlto libpcap-devel xl2tpd

            编译安装
        菲
    菲

}

config_install(){

    猫> /etc/ipsec.conf << EOF
版本 2.0

配置设置
    protostack=netkey
    nhelpers=0
    uniqueids=否
    接口=％默认路由
    virtual_private=%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12,%v4:!${iprange}.0/24

连接 l2tp-psk
    rightsubnet=vhost:%priv
    也=l2tp-psk-nonat

conn l2tp-psk-nonat
    authby=秘密
    pfs=否
    自动=添加
    键入尝试=3
    重新密钥=否
    ikelifetime=8h
    密钥寿命=1小时
    类型=运输
    左=％默认路由
    leftid=${IP}
    左协议端口=17/1701
    右=％任意
    rightprotoport=17/%任意
    dpddelay=40
    dpd超时=130
    dpdaction=清除
    sha2-truncbug=yes
结束

    猫> /etc/ipsec.secrets<<EOF
%any %any : PSK“${mypsk}”
结束

    猫> /etc/xl2tpd/xl2tpd.conf<<EOF
[全球的]
端口 = 1701

[lns 默认]
IP 范围 = ${iprange}.2-${iprange}.254
本地 IP = ${iprange}.1
需要 chap = 是
拒绝pap=是
需要身份验证 = 是
名称 = l2tpd
ppp 调试 = 是
pppoptfile = /etc/ppp/options.xl2tpd
长度位 = 是
结束

    猫> /etc/ppp/options.xl2tpd<<EOF
ipcp-接受本地
ipcp-接受-远程
需要 mschap-v​​2
ms-dns 8.8.8.8
ms-dns 8.8.4.4
诺克普
授权
隐藏密码
闲置 1800
MTU 1410
mru 1410
无默认路由
调试
代理ARP
连接延迟 5000
结束

    rm -f /etc/ppp/chap-secrets
    猫> / etc / ppp / chap-secrets << EOF
# 使用 CHAP 进行身份验证的秘密
# 客户端服务器秘密 IP 地址
${用户名} l2tpd ${密码} *
结束

}

编译安装（）{

    rm -rf ${cur_dir}/l2tp
    mkdir -p ${cur_dir}/l2tp
    cd ${cur_dir}/l2tp
    下载文件“${libreswan_filename}.tar.gz”
    tar -zxf ${libreswan文件名}.tar.gz

    cd ${cur_dir}/l2tp/${libreswan_filename}
        cat > Makefile.inc.local <<'EOF'
错误标志位 =
USE_DNSSEC = false
USE_DH31 = false
USE_GLIBC_KERN_FLIP_HEADERS = true
结束
    制作程序&&进行安装

    /usr/local/sbin/ipsec --version >/dev/null 2>&1
    如果 [ $? -ne 0 ]; 那么
        echo“${libreswan_filename} 安装失败。”
        1号出口
    菲

    配置安装

    cp -pf /etc/sysctl.conf /etc/sysctl.conf.bak

    sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf

    对于 `ls /proc/sys/net/ipv4/conf/` 中的每个；执行
        echo "net.ipv4.conf.${each}.accept_source_route=0" >> /etc/sysctl.conf
        回显“net.ipv4.conf.${each}.accept_redirects=0”>> /etc/sysctl.conf
        回显“net.ipv4.conf.${each}.send_redirects=0”>> /etc/sysctl.conf
        echo "net.ipv4.conf.${each}.rp_filter=0" >> /etc/sysctl.conf
    完毕
    sysctl -p

    如果是 centosversion 6；那么
        [ -f /etc/sysconfig/iptables ] && cp -pf /etc/sysconfig/iptables /etc/sysconfig/iptables.old.`日期+%Y%m%d`

        如果 [“`iptables -L -n | grep -c '\-\-'`” ==“0”]; 然后
            猫> / etc / sysconfig / iptables << EOF
# 由 L2TP VPN 脚本添加
*筛选
:输入接受[0:0]
:转发接受 [0:0]
:输出接受[0:0]
-A 输入 -m 状态 --状态相关，已建立 -j 接受
-A 输入 -p icmp -j 接受
-A 输入 -i lo -j 接受
-A 输入 -p tcp --dport 22 -j 接受
-A 输入 -p udp -m 多端口 --dports 500,4500,1701 -j 接受
-A 转发 -m 状态 --状态 RELATED,ESTABLISHED -j 接受
-A 转发 -s ${iprange}.0/24 -j 接受
犯罪
*nat
:预路由接受 [0:0]
:输出接受[0:0]
:后路由接受 [0:0]
-A POSTROUTING -s ${iprange}.0/24 -j SNAT --to-source ${IP}
犯罪
结束
        别的
            iptables -I 输入 -p udp -m 多端口 --dports 500,4500,1701 -j 接受
            iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
            iptables -I 转发 -s ${iprange}.0/24 -j 接受
            iptables -t nat -A POSTROUTING -s ${iprange}.0/24 -j SNAT --to-source ${IP}
            /etc/init.d/iptables 保存
        菲

        如果 [ !-f /etc/ipsec.d/cert9.db ]; 那么
           echo > /var/tmp/libreswan-nss-pwd
           certutil -N -f /var/tmp/libreswan-nss-pwd -d /etc/ipsec.d
           rm -f /var/tmp/libreswan-nss-pwd
        菲

        chkconfig --添加 iptables
        chkconfig iptables 开启
        chkconfig --add ipsec
        chkconfig ipsec on
        chkconfig --add xl2tpd
        chkconfig xl2tpd 打开

        /etc/init.d/iptables 重启
        /etc/init.d/ipsec启动
        /etc/init.d/xl2tpd启动

    别的
        [ -f /etc/iptables.rules ] && cp -pf /etc/iptables.rules /etc/iptables.rules.old.`date +%Y%m%d`

        如果 [“`iptables -L -n | grep -c '\-\-'`” ==“0”]; 然后
            猫> /etc/iptables.rules <<EOF
# 由 L2TP VPN 脚本添加
*筛选
:输入接受[0:0]
:转发接受 [0:0]
:输出接受[0:0]
-A 输入 -m 状态 --状态相关，已建立 -j 接受
-A 输入 -p icmp -j 接受
-A 输入 -i lo -j 接受
-A 输入 -p tcp --dport 22 -j 接受
-A 输入 -p udp -m 多端口 --dports 500,4500,1701 -j 接受
-A 转发 -m 状态 --状态 RELATED,ESTABLISHED -j 接受
-A 转发 -s ${iprange}.0/24 -j 接受
犯罪
*nat
:预路由接受 [0:0]
:输出接受[0:0]
:后路由接受 [0:0]
-A POSTROUTING -s ${iprange}.0/24 -j SNAT --to-source ${IP}
犯罪
结束
        别的
            iptables -I 输入 -p udp -m 多端口 --dports 500,4500,1701 -j 接受
            iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
            iptables -I 转发 -s ${iprange}.0/24 -j 接受
            iptables -t nat -A POSTROUTING -s ${iprange}.0/24 -j SNAT --to-source ${IP}
            /sbin/iptables-save > /etc/iptables.rules
        菲

        猫> /etc/network/if-up.d/iptables <<EOF
/bin/sh
/sbin/iptables-restore < /etc/iptables.rules
结束
        chmod +x /etc/network/if-up.d/iptables

        如果 [ !-f /etc/ipsec.d/cert9.db ]; 那么
           echo > /var/tmp/libreswan-nss-pwd
           certutil -N -f /var/tmp/libreswan-nss-pwd -d /etc/ipsec.d
           rm -f /var/tmp/libreswan-nss-pwd
        菲

        更新-rc.d -f xl2tpd 默认值

        cp -f /etc/rc.local /etc/rc.local.old.`日期 +%Y%m%d`
        sed --follow-symlinks -i -e '/^exit 0/d' /etc/rc.local
        cat >> /etc/rc.local <<EOF

# 由 L2TP VPN 脚本添加
echo 1 > /proc/sys/net/ipv4/ip_forward
/usr/sbin/service ipsec 启动
出口 0
结束
        chmod +x /etc/rc.local
        echo 1 > /proc/sys/net/ipv4/ip_forward

        /sbin/iptables-restore < /etc/iptables.rules
        /usr/sbin/service ipsec 启动
        /usr/sbin/service xl2tpd 重启

    菲

}

yum_install(){

    配置安装

    cp -pf /etc/sysctl.conf /etc/sysctl.conf.bak

    echo "# 由 L2TP VPN 添加" >> /etc/sysctl.conf
    回显“net.ipv4.ip_forward=1”>> /etc/sysctl.conf
    回显“net.ipv4.tcp_syncookies = 1”>> /etc/sysctl.conf
    回显“net.ipv4.icmp_echo_ignore_broadcasts = 1”>> /etc/sysctl.conf
    回显“net.ipv4.icmp_ignore_bogus_error_responses = 1”>> /etc/sysctl.conf

    对于 `ls /proc/sys/net/ipv4/conf/` 中的每个；执行
        echo "net.ipv4.conf.${each}.accept_source_route=0" >> /etc/sysctl.conf
        回显“net.ipv4.conf.${each}.accept_redirects=0”>> /etc/sysctl.conf
        回显“net.ipv4.conf.${each}.send_redirects=0”>> /etc/sysctl.conf
        echo "net.ipv4.conf.${each}.rp_filter=0" >> /etc/sysctl.conf
    完毕
    sysctl -p

    猫> /etc/firewalld/services/xl2tpd.xml<<EOF
<?xml version="1.0" encoding="utf-8"?>
<服务>
  <short>xl2tpd</short>
  <description>L2TP IPSec</description>
  <port 协议="udp" 端口="4500"/>
  <port 协议="udp" 端口="1701"/>
</服务>
结束
    chmod 640 /etc/firewalld/services/xl2tpd.xml

    systemctl 启用 ipsec
    systemctl 启用 xl2tpd
    systemctl 启用防火墙

    systemctl 状态防火墙 > /dev/null 2>&1
    如果 [ $? -eq 0 ]; 那么
        防火墙命令——重新加载
        echo“检查防火墙状态...”
        防火墙命令——列出所有
        echo“添加防火墙规则...”
        防火墙命令——永久——添加服务=ipsec
        防火墙命令——永久——添加服务=xl2tpd
        防火墙命令——永久——添加伪装
        防火墙命令——重新加载
    别的
        echo“Firewalld 看起来没有运行，正在尝试启动……”
        systemctl 启动防火墙
        如果 [ $? -eq 0 ]; 那么
            echo“Firewalld启动成功……”
            防火墙命令——重新加载
            echo“检查防火墙状态...”
            防火墙命令——列出所有
            echo“添加防火墙规则...”
            防火墙命令——永久——添加服务=ipsec
            防火墙命令——永久——添加服务=xl2tpd
            防火墙命令——永久——添加伪装
            防火墙命令——重新加载
        别的
            echo "无法启动firewalld。如有必要，请手动启用udp端口500 4500 1701。"
        菲
    菲

    systemctl 重启 ipsec
    systemctl 重启 xl2tpd
    echo“检查 ipsec 状态...”
    systemctl -a | grep ipsec
    echo“检查 xl2tpd 状态...”
    systemctl -a | grep xl2tpd
    echo“检查防火墙状态...”
    防火墙命令——列出所有

}

最后（）{

    cd ${cur_dir}
    rm -fr ${cur_dir}/l2tp
    #创建l2tp命令
    cp -f ${cur_dir}/`basename $0` /usr/bin/l2tp

    echo“请稍等片刻……”
    睡5
    ipsec验证
    回声
    回声“########################################################################”
    echo "# L2TP VPN 自动安装程序 #"
    echo "# 支持的系统: CentOS 6+ / Debian 7+ / Ubuntu 12+ #"
    echo "# 简介：https://teddysun.com/448.html #"
    echo "# 作者：Teddysun <i@teddysun.com> #"
    回声“########################################################################”
    echo "如果上面没有 [FAILED]，您可以连接到您的 L2TP "
    echo“VPN 服务器的默认用户名/密码如下：”
    回声
    echo "服务器IP:${IP}"
    回显“PSK：${mypsk}”
    echo "用户名：${username}"
    echo "密码：${password}"
    回声
    echo“如果您想修改用户设置，请使用以下命令：”
    echo“l2tp -a（添加用户）”
    echo "l2tp -d (删除用户)"
    echo“l2tp -l（列出所有用户）”
    echo "l2tp -m (修改用户密码)"
    回声
    echo "欢迎访问我们的网站：https://teddysun.com/448.html"
    回声“享受它！”
    回声
}


l2tp(){
    清除
    回声
    回声“########################################################################”
    echo "# L2TP VPN 自动安装程序 #"
    echo "# 支持的系统: CentOS 6+ / Debian 7+ / Ubuntu 12+ #"
    echo "# 简介：https://teddysun.com/448.html #"
    echo "# 作者：Teddysun <i@teddysun.com> #"
    回声“########################################################################”
    回声
    根性
    不可用
    禁用selinux
    版本检查
    获取操作系统信息
    预安装_l2tp
    安装_l2tp
    最后
}

列出用户（）{
    如果 [ !-f /etc/ppp/chap-secrets ];那么
        echo“错误：未找到/etc/ppp/chap-secrets 文件。”
        1号出口
    菲
    本地线路=“+----------------------------------------------------------+\n”
    本地字符串=％20s
    printf "${line}|${string} |${string} |\n${line}" 用户名 密码
    grep -v“^#”/etc/ppp/chap-secrets | awk'{printf“|'${string}'|'${string}'|\n",$1,$3}'
    printf ${line}
}

添加用户（）{
    尽管 ：
    做
        read -p“请输入您的用户名：”用户
        如果[-z $ {user}]；那么
            echo "用户名不能为空"
        别的
            grep -w "${user}" /etc/ppp/chap-secrets > /dev/null 2>&1
            如果 [ $? -eq 0 ];那么
                echo "用户名 (${user}) 已存在。请重新输入您的用户名。"
            别的
                休息
            菲
        菲
    完毕
    pass=`rand`
    echo "请输入${user}的密码:"
    read -p "(默认密码：${pass})：" tmppass
    [ !-z ${tmppass} ] && pass=${tmppass}
    echo "${user} l2tpd ${pass} *" >> /etc/ppp/chap-secrets
    echo "用户名 (${user}) 添加完成。"
}

删除用户（）{
    尽管 ：
    做
        read -p "请输入您要删除的用户名：" user
        如果[-z $ {user}]；那么
            echo "用户名不能为空"
        别的
            grep -w "${user}" /etc/ppp/chap-secrets >/dev/null 2>&1
            如果 [ $? -eq 0 ];那么
                休息
            别的
                echo "用户名 (${user}) 不存在。请重新输入您的用户名。"
            菲
        菲
    完毕
    sed -i“/^\<${user}\>/d”/etc/ppp/chap-secrets
    echo "用户名 (${user}) 删除完成。"
}

mod_user(){
    尽管 ：
    做
        read -p "请输入您要更改密码的用户名：" user
        如果[-z $ {user}]；那么
            echo "用户名不能为空"
        别的
            grep -w "${user}" /etc/ppp/chap-secrets >/dev/null 2>&1
            如果 [ $? -eq 0 ];那么
                休息
            别的
                echo "用户名 (${user}) 不存在。请重新输入您的用户名。"
            菲
        菲
    完毕
    pass=`rand`
    echo "请输入${user}的新密码："
    read -p "(默认密码：${pass})：" tmppass
    [ !-z ${tmppass} ] && pass=${tmppass}
    sed -i“/^\<${user}\>/d”/etc/ppp/chap-secrets
    echo "${user} l2tpd ${pass} *" >> /etc/ppp/chap-secrets
    echo "用户名${user} 的密码已更改。"
}

# 主流程
行动=$1
如果 [ -z ${action} ] && [ "`basename $0`" != "l2tp" ]; 然后
    操作=安装
菲

案例 ${action} 在
    安装）
        l2tp 2>&1 | tee ${cur_dir}/l2tp.log
        ；；
    -l|--列表）
        列出用户
        ；；
    -a|--添加）
        添加用户
        ；；
    -d|--删除)
        删除用户
        ；；
    -m|--修改)
        mod_user
        ；；
    -h|--帮助)
        echo "用法：`basename $0` -l,--list 列出所有用户"
        echo "`basename $0` -a,--add 添加用户"
        echo " `basename $0` -d,--del 删除用户"
        echo "`basename $0` -m,--mod 修改用户密码"
        echo "`basename $0` -h,--help 打印此帮助信息"
        ；；
    *）
        echo "用法：`basename $0` [-l,--list|-a,--add|-d,--del|-m,--mod|-h,--help]" && 退出
        ；；
埃萨克

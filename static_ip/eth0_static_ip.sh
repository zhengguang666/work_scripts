#!/bin/sh

eth_ip_str=`grep eth_ipaddr /etc/norco/norco_cfg.ini`
eth_ip=${eth_ip_str#*=}
echo "[ADV] eth_ip=$eth_ip"

eth_netmask_str=`grep eth_netmask /etc/norco/norco_cfg.ini`
eth_netmask=${eth_netmask_str#*=}
echo "[ADV] eth_netmask=$eth_netmask"

eth0_line_list=`cat -n /etc/network/interfaces |grep "iface eth0 inet static" |awk '{print $1}'`
for line in ${eth0_line_list[@]}
do
    echo "[ADV] line=${line}"
    sed -n ''${line}'p' /etc/network/interfaces |grep "^\#" > /dev/zero 2>&1
    if [ $? -eq 0 ]; then
        sed -i ''${line}'d' /etc/network/interfaces
    fi
done

eth0_line_list=`cat -n /etc/network/interfaces |grep "iface eth0 inet static" |awk '{print $1}'`
valid_line_count=0
final_line=0
for line in ${eth0_line_list[@]}
do
    echo "[ADV] line=${line}"
    sed -n ''${line}'p' /etc/network/interfaces |grep "^\#" > /dev/zero 2>&1
    if [ $? -eq 1 ]; then
        valid_line_count=`expr ${valid_line_count} + 1`
        echo "[ADV] valid_line_count=${valid_line_count}"
        final_line=${line}
        echo "[ADV] final_line=${final_line}"
    fi
done

eth0_line=${final_line}

if [ ${eth0_line} -gt 0 ];then
    iface_list=`cat -n /etc/network/interfaces |grep "iface" |awk '{print $1}'`
    for line in ${iface_list[@]}
    do
        line_diff=0
        if [ "$line" -gt "$eth0_line" ];then
            iface_next_line=$line
            line_diff=`expr $iface_next_line - $eth0_line`
            echo "[ADV] iface_next_line=$line"
            echo "[ADV] line_diff=$line_diff"
            break
        fi
    done

    if [ $line_diff -gt 1 ];then
        del_start=`expr ${eth0_line} + 1`
        del_end=`expr ${iface_next_line} - 1`
        echo "[ADV] del_start=$del_start"
        echo "[ADV] del_end=$del_end"
        sed -i ''${del_start}','${del_end}'d' /etc/network/interfaces
    fi

    sed -i ''${eth0_line}' a\	netmask '${eth_netmask}'' /etc/network/interfaces
    sed -i ''${eth0_line}' a\	address '${eth_ip}'' /etc/network/interfaces

fi

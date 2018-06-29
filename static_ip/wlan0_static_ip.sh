#!/bin/sh

wlan_ip_str=`grep wlan_ipaddr /etc/norco/norco_cfg.ini`
wlan_ip=${wlan_ip_str#*=}
echo "[ADV] wlan_ip=$wlan_ip"

wlan_netmask_str=`grep wlan_netmask /etc/norco/norco_cfg.ini`
wlan_netmask=${wlan_netmask_str#*=}
echo "[ADV] wlan_netmask=$wlan_netmask"

wlan_gateway_str=`grep wlan_gateway /etc/norco/norco_cfg.ini`
wlan_gateway=${wlan_gateway_str#*=}
echo "[ADV] wlan_gateway=$wlan_gateway"

wlan_firstdns_str=`grep wlan_firstdns /etc/norco/norco_cfg.ini`
wlan_firstdns=${wlan_firstdns_str#*=}
echo "[ADV] wlan_firstdns=$wlan_firstdns"

wlan_backdns_str=`grep wlan_backdns /etc/norco/norco_cfg.ini`
wlan_backdns=${wlan_backdns_str#*=}
echo "[ADV] wlan_backdns=$wlan_backdns"
wlan_dns="${wlan_firstdns} ${wlan_backdns}"
echo "[ADV] wlan_dns=$wlan_dns"

wlan_ssid_str=`grep wlan_ssid /etc/norco/norco_cfg.ini`
wlan_ssid=${wlan_ssid_str#*=}
echo "[ADV] wlan_ssid=$wlan_ssid"

wlan_password_str=`grep wlan_password /etc/norco/norco_cfg.ini`
wlan_password=${wlan_password_str#*=}
echo "[ADV] wlan_password=$wlan_password"

network_line_list=`cat -n /etc/wpa_supplicant.conf |grep "network" |awk '{print $1}'`
for line in ${network_line_list[@]}
do
    echo "[ADV] line=${line}"
    sed -i ''${line}',$d' /etc/wpa_supplicant.conf
    break
done

wpa_passphrase "${wlan_ssid}"  "${wlan_password}" >> /etc/wpa_supplicant.conf

wlan0_line_list=`cat -n /etc/network/interfaces |grep "iface wlan0 inet static" |awk '{print $1}'`
for line in ${wlan0_line_list[@]}
do
    echo "[ADV] line=${line}"
    sed -n ''${line}'p' /etc/network/interfaces |grep "^\#" > /dev/zero 2>&1
    if [ $? -eq 0 ]; then
        sed -i ''${line}'d' /etc/network/interfaces
    fi
done

wlan0_line_list=`cat -n /etc/network/interfaces |grep "iface wlan0 inet static" |awk '{print $1}'`
valid_line_count=0
final_line=0
for line in ${wlan0_line_list[@]}
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

wlan0_line=${final_line}

if [ ${wlan0_line} -gt 0 ];then
    iface_list=`cat -n /etc/network/interfaces |grep "iface" |awk '{print $1}'`
    for line in ${iface_list[@]}
    do
        line_diff=0
        if [ "$line" -gt "$wlan0_line" ];then
            iface_next_line=$line
            line_diff=`expr $iface_next_line - $wlan0_line`
            echo "[ADV] iface_next_line=$line"
            echo "[ADV] line_diff=$line_diff"
            break
        fi
    done
    
    addr_list=`cat -n /etc/network/interfaces |grep "address" |awk '{print $1}'`
    for addr in ${addr_list[@]}
    do
        if [ ${addr} -gt ${wlan0_line} ] && [ ${addr} -lt ${iface_next_line} ];then
        sed -i ''${addr}'d' /etc/network/interfaces
        fi
    done

    mask_list=`cat -n /etc/network/interfaces |grep "netmask" |awk '{print $1}'`
    for mask in ${mask_list[@]}
    do
        if [ ${mask} -gt ${wlan0_line} ] && [ ${mask} -lt ${iface_next_line} ];then
        sed -i ''${mask}'d' /etc/network/interfaces
        fi
    done

    dns_list=`cat -n /etc/network/interfaces |grep "dns-nameservers" |awk '{print $1}'`
    for dns in ${dns_list[@]}
    do
        if [ ${dns} -gt ${wlan0_line} ] && [ ${dns} -lt ${iface_next_line} ];then
        sed -i ''${dns}'d' /etc/network/interfaces
        fi
    done

    gate_list=`cat -n /etc/network/interfaces |grep "gateway" |awk '{print $1}'`
    for gate in ${gate_list[@]}
    do
        if [ ${gate} -gt ${wlan0_line} ] && [ ${gate} -lt ${iface_next_line} ];then
        sed -i ''${gate}'d' /etc/network/interfaces
        fi
    done

    sed -i ''${wlan0_line}' a\	dns-nameservers '${wlan_firstdns}' '${wlan_backdns}'' /etc/network/interfaces
    sed -i ''${wlan0_line}' a\	gateway '${wlan_gateway}'' /etc/network/interfaces
    sed -i ''${wlan0_line}' a\	netmask '${wlan_netmask}'' /etc/network/interfaces
    sed -i ''${wlan0_line}' a\	address '${wlan_ip}'' /etc/network/interfaces

fi

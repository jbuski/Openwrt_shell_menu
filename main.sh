#!/bin/bash

#######################################################################
# Title      :    main
# Author     :    Jacek Buski {kecajtop@gmail.com}
# Date       :    2021-09-11
# Requires   :    whiptail
# Category   :    Shell menu tools
#######################################################################

DIR=/root

source $DIR/backup.sh
source $DIR/update.sh

ip=192.168.1.1

function main_menu()
{
choise=$(whiptail --title "Operative Systems" --menu "Make your choice" 16 100 10\
	"1)" "WiFi"   \
	"2)" "Webpage SSL cert fix"  \
	"3)" "" \
	"4)" "" \
	"5)" "" \
	"6)" "Package updates" \
	"7)" "Backup to Docker" \
	"8)" "Backup to GIT" \
	"9)" "Backup to NAS"\
	"10)" "Exit"\
	3>&2 2>&1 1>&3)

echo $choise
	case $choise in
	"1)")
		wifi_menu
	;;
	"2)")
		opkg update && opkg install openssl-util luci-app-uhttpd
		echo -e "[req]\ndistinguished_name  = req_distinguished_name \nx509_extensions     = v3_req \nprompt	= no \nstring_mask         = utf8only \n" > /etc/ssl/myconfig.conf
		echo -e "[req_distinguished_name] \nC                   = US \nST                  = VA \nL                   = SomeCity" >> /etc/ssl/myconfig.conf
		echo -e "O                   = OpenWrt \nOU                  = Home Router \nCN                  = luci.openwrt \n" >> /etc/ssl/myconfig.conf
		echo -e "[v3_req] \nkeyUsage            = nonRepudiation, digitalSignature, keyEncipherment \nextendedKeyUsage    = serverAuth \nsubjectAltName      = @alt_names\n" >>/etc/ssl/myconfig.conf
		echo -e "[alt_names]\nDNS.1               = luci.openwrt\nIP.1                = 192.168.2.1\n" >> /etc/ssl/myconfig.conf
		cd /etc/ssl
		openssl req -x509 -nodes -days 730 -newkey rsa:2048 -keyout mycert.key -out mycert.crt -config myconfig.conf
		uci set uhttpd.main.cert='/etc/ssl/mycert.crt'
		uci set uhttpd.main.key='/etc/ssl/mycert.key'
		uci commit
		/etc/init.d/uhttpd restart
	;;
	"3)")
		echo
	;;
	"4)")
		echo
		is_server_awake $ip
	;;
	"5)")
		echo OpenWrt Backup
		upload_backup $ip
		sleep 1
		;;
	"6)")
		update_menu
	;;	
	"7)")
		backup_docker_menu	;;
	
	"8)")
		backup_git_menu
	;;
	
	"9)")
		backup_nas_menu
	;;
	
	"10)")
		echo "Exit"
		exit
	;;
	esac
}


function wifi_menu()
{
while [ 1 ]
do
choise=$(whiptail --title "WiFi" --menu "Make your choice" 16 100 10\
	"1)" "WiFi down" \
	"2)" "WiFi up" \
	"3)" "WiFi restart script" \
	"10)" "Exit"\
	3>&2 2>&1 1>&3)

echo $choise
	case $choise in
	"1)")
		wifi down
	;;
	"2)")
		wifi up
		;;
        "3)")
                /etc/init.d/wifi restart
                ;;	
	"10)")
		echo "Exit"
		break
	;;
	esac
    if [ $? -gt 0 ]; then # user pressed <Cancel> button
        break
    fi
done
}


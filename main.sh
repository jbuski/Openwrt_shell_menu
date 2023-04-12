#!/bin/bash

#######################################################################
# Title      :    main
# Author     :    Jacek Buski {kecajtop@gmail.com}
# Date       :    2021-09-11
# Requires   :    whiptail
# Category   :    Shell menu tools
#######################################################################

source ./backup.sh
source ./update.sh

ip=192.168.1.1

function main_menu()
{
choise=$(whiptail --title "Operative Systems" --menu "Make your choice" 16 100 10\
	"1)" "WiFi"   \
	"2)" ""  \
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
		echo
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
		backup_docker_menu	
		;;
	
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



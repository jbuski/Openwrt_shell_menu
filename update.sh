#!/bin/bash

function update_menu()
{
while [ 1 ]
do
choise=$(whiptail --title "Update" --menu "Make your choice" 16 100 10\
	"1)" "opkg update" \
	"2)" "opkg upgrade" \
	"9)" "Install requarments"\
	"10)" "Exit"\
	3>&2 2>&1 1>&3)

echo $choise
	case $choise in
	"1)")
		opkg update
	;;
	"2)")
		opkg list-upgradable | cut -f 1 -d ' ' | xargs -r opkg upgrade
		;;
        "9)")
		opkg install mc
		opkg install etherwake
		opkg install nfs-utils
		opkg install whiptail
		opkg install mosquitto-client-ssl
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

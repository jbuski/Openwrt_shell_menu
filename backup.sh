#!/bin/bash

function backup_nas_menu()
{
while [ 1 ]
do
choise=$(whiptail --title "Backup NAS" --menu "Make your choice" 16 100 10\
	"1)" "Is NAS awake?" \
	"2)" "Backup OpenWrt" \
	"3)" "Wakeup NAS Server" \
	"4)" "Shutdown NAS Server" \
	"7)" "Edit /etc/sysupgrade.conf"\
	"8)" "Create /etc/config/installed.packages"\
	"10)" "Exit"\
	3>&2 2>&1 1>&3)

echo $choise
	case $choise in
	"1)")
		echo
		is_server_awake $ip
	;;
	"2)")
		echo OpenWrt Backup
		upload_backup $ip
		sleep 1
		;;
	"3)")
		echo Wakeing up NAS Server
		wakeup_server WDMyCloudMirror
	;;
	
	"4)")
		echo Shuting Down NAS server
		shutdown_server WDMyCloudMirror
	;;
        "7)")
                nano /etc/sysupgrade.conf
        ;;
        "8)")
		opkg list-installed > /etc/config/installed.packages
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

function backup_git_menu()
{
while [ 1 ]
do
choise=$(whiptail --title "Backup GIT" --menu "Make your choice" 16 100 10\
	"5)" "GIT Download script" \
	"6)" "GIT Upload script"\
	"10)" "Exit"\
	3>&2 2>&1 1>&3)

echo $choise
	case $choise in
	"5)")
		echo GIT download
		git_download
	;;
	
	"6)")
		echo GIT upload
		git_upload
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

function backup_docker_menu()
{
while [ 1 ]
do
choise=$(whiptail --title "Backup Docker" --menu "Make your choice" 16 100 10\
	"1)" "Is NAS awake?" \
	"2)" "Backup OpenWrt" \
	"3)" "Wakeup NAS Server" \
	"4)" "Shutdown NAS Server" \
	"5)" "GIT Download script" \
	"6)" "GIT Upload script"\
	"7)" "Edit /etc/sysupgrade.conf"\
	"8)" "Create /etc/config/installed.packages"\
	"10)" "Exit"\
	3>&2 2>&1 1>&3)

echo $choise
	case $choise in
	"1)")
		echo
		is_server_awake 192.168.$ip
	;;
	"2)")
		echo OpenWrt Backup
		upload_backup $ip
		sleep 1
		;;
	"3)")
		echo Wakeing up NAS Server
		wakeup_server WDMyCloudMirror
	;;
	
	"4)")
		echo Shuting Down NAS server
		shutdown_server WDMyCloudMirror
	;;
	
	"5)")
		echo GIT download
		git_download
	;;
	
	"6)")
		echo GIT upload
		git_upload
	;;

        "7)")
                nano /etc/sysupgrade.conf
        ;;
        "8)")
		opkg list-installed > /etc/config/installed.packages
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




function backup_openwrt()
{
	umask go=
	sysupgrade -b /tmp/backup-${HOSTNAME}-$(date +%F).tar.gz
	if [ $? -eq 0 ]
	then
		echo Backup created successfully
	else
		echo Backup creation fail
	fi
}

function restore_openwrt()
{
	echo Not implemented
}

function upload_backup()
{
	ip=$1
	#ping -c 1 -W 1 $ip > /dev/null
	ping_test $ip
	if [ $? -eq 0  ]
	then
		echo Host reachable
		mount -t nfs $ip:/nfs/name /mnt/ -o nolock
		if [ $? -eq 0 ]
		then
			mac=$(echo $(uci get network.lan_eth0_1_dev.macaddr) | sed s/:/-/g)
			dir=/mnt/$mac
			echo $dir
			if [ -d $dir ]
			then
				echo Folder $dir exist
			else
				mkdir /$dir/
			fi
			echo FS mounted successfully
			backup_openwrt $ip
			cp /tmp/backup-*.tar.gz /$dir/
			rm /tmp/backup-*.tar.gz
			echo FS unmounted
			umount /mnt/
		else
			FS mount fail
		fi
	else
		echo Host is unreachable
	fi
}

function download_backup()
{
	mount -t nfs $1:/nfs/kecaj /mnt/ -o nolock
	umount /mnt/
}

function git_upload()
{
	echo "git push origin master"
	cp /etc/init.d/wifi /root/init.d/
	git commit -am "bthh50a automatic"
	git push origin master
}

function git_download()
{
		echo "git pull origin master"
		git pull origin master
}

function wakeup_server()
{
name=$1
state=0
COUNTER=0
while [  $state = "0" ]; do
     name1=$(uci get dhcp.@host[$COUNTER].name)
     state=$?
	if [ $state = "0" ]; then
		if [ $name = $name1 ]; then
		etherwake -D $(uci get dhcp.@host[$COUNTER].mac)
		echo found
		fi
	fi
	#echo The counter is $COUNTER
	let COUNTER=COUNTER+1 
done
sleep 1
}

function shutdown_server()
{
name=$1
state=0
COUNTER=0
while [ $state = "0" ]; do
	name1=$(uci get dhcp.@host[$COUNTER].name)
	state=$?
	if [ $state = "0" ]; then
		if [ $name = $name1 ]; then
			echo Found $name
			timeout 60 sshpass -p $(uci get pass.$name) ssh sshd@$(uci get dhcp.@host[$COUNTER].ip) "shutdown.sh" >/dev/null 2>&1 & >/dev/null
		fi
	fi
	#echo The counter is $COUNTER
	let COUNTER=COUNTER+1
done
}

function is_server_awake()
{
	ip=$1
	alive=/tmp/alive
	ping_test $ip
	if [ $? -eq 0  ]
	then
		echo Ping OK
		if [  -f $alive ]; then
			echo Send shutdown $ip
			shutdown_server WDMyCloudMirror
			rm $alive
		fi
	else
		echo Ping Fail
		if [ ! -f $alive ]; then
			echo Send wakeup $ip
			wakeup_server WDMyCloudMirror
			touch $alive
		fi
	fi
}

function name_to_ip()
{
	name=$1
	echo
}

function name_to_mac()
{
	name=$1
	echo
}

function ping_test()
{
	ping -c 1 -W 1 $1 > /dev/null
	return $?
}
 



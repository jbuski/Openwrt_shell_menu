#!/bin/sh

DIR=/root

source $DIR/version.sh
function setup_wifi()
{

if ! uci -q show menu.menu >/dev/null
then
	touch /etc/config/menu
	uci set menu.menu=config
	uci commit
	logger wifi.sh setup
fi


if ! uci -q show menu.menu.mqtt_server >/dev/null
then
	uci set menu.menu.mqtt_server='127.0.0.1'
	mqtt_server=$(uci get menu.menu.mqtt_server)
	uci commit
	echo Setting up default mqtt server: $mqtt_server
else
	mqtt_server=$(uci get menu.menu.mqtt_server)
	echo Mqtt server: $mqtt_server
fi

if ! uci -q show menu.menu.mqtt_login >/dev/null
then
	uci set  menu.menu.mqtt_login='mqtt'
	mqtt_login=$(uci get menu.menu.mqtt_login)
	uci commit
	echo Setting up default mqtt login: $mqtt_login
else
	mqtt_login=$(uci get menu.menu.mqtt_login)
	echo Mqtt login: $mqtt_login
fi

if ! uci -q show menu.menu.mqtt_pass >/dev/null
then
	uci set menu.menu.mqtt_pass='mqtt_pass'
	mqtt_pass=$(uci get menu.menu.mqtt_pass)
	uci commit
	echo Setting up default mqtt pass $mqtt_pass
else
	mqtt_pass=$(uci get menu.menu.mqtt_pass)
fi

if ! uci get menu.menu.intervall_wifi >/dev/null
then
	uci set menu.menu.intervall_wifi='60'
	uci commit
	echo Setting up default intervall_wifi 60
fi

if ! uci get menu.menu.ping_ip >/dev/null
then
	uci set menu.menu.ping_ip='8.8.8.8'
	ping_ip=$(uci get menu.menu.ping_ip)
	uci commit
	echo Setting up default ping_ip $ping_ip
else
	ping_ip=$(uci get menu.menu.ping_ip)
fi

if ! uci get menu.menu.toggle_wifi >/dev/null
then
	uci set menu.menu.toggle_wifi='0'
	ping_ip=$(uci get menu.menu.toggle_wifi)
	uci commit
	echo Setting up default toggle_wifi to 0
fi



mqtt_topic="$(cat /proc/sys/kernel/hostname)"
}

function loop_wifi()
{
source $DIR/main.sh
while true; do
mosquitto_pub -h $mqtt_server -P  $mqtt_pass -u $mqtt_login -p 8883 -t openwrt/$mqtt_topic/wifi/availability  -m "online"

opkgInstalled="$(opkg list-installed 2> /dev/null | wc -l)" #silencing error output
opkgUpgradable="$(opkg list-upgradable 2> /dev/null | wc -l)" #silencing error output
openwrtVersion="$(echo "$(awk -F= '$1=="DISTRIB_RELEASE" { print $2 ;}' /etc/openwrt_release)" | sed "s/'/\"/g")"

date=$(date '+%Y-%m-%d %H:%M:%S')

openwrtUptime="$(awk '{print int($1/86400)" days "int($1%86400/3600)":"int(($1%3600)/60)":"int($1%60)}' /proc/uptime)"

scriptVersion=$(script_version)
	
echo $openwrtVersion $opkgInstalled $opkgUpgradable $openwrtUptime

mosquitto_pub -h $mqtt_server -P  $mqtt_pass -u $mqtt_login -p 8883 -t openwrt/$mqtt_topic/firmware -r -m "{\"installed\":$opkgInstalled, \"upgradable\" :$opkgUpgradable, \"version\" :$openwrtVersion}"
mosquitto_pub -h $mqtt_server -P  $mqtt_pass -u $mqtt_login -p 8883 -t openwrt/$mqtt_topic/script -r -m "{\"version\" :$scriptVersion}"
mosquitto_pub -h $mqtt_server -P  $mqtt_pass -u $mqtt_login -p 8883 -t openwrt/$mqtt_topic/uptime -r -m "{\"uptime\":$openwrtUptime}"
mosquitto_pub -h $mqtt_server -P  $mqtt_pass -u $mqtt_login -p 8883 -t openwrt/$mqtt_topic/last_seen_online -r -m "{\"date\":$date}"


logger wifi loop

if ! ping -q -c 5 -W 1 $ping_ip >/dev/null; then
	logger wifi ping failed
	#wifi_down
else
	logger wifi ping successful
	#wifi_up
fi
sleep $(uci get menu.menu.intervall_wifi)
done
}

function wifi_down()
{	
	if [ $(uci get menu.menu.toggle_wifi) == 1 ]; then

		mosquitto_pub -h $mqtt_server -P  $mqtt_pass -u $mqtt_login -p 8883 -t openwrt/$mqtt_topic/wifi/status -m '{"state":"DOWN"}'

		if ifconfig | grep wlan >/dev/null; then
			#wifi down
			logger wifi down
		else
			logger wifi still down
		fi
	fi
}

function wifi_up()
{
    if [ $(uci get menu.menu.toggle_wifi) == 1 ]; then
		mosquitto_pub -h $mqtt_server -P  $mqtt_pass -u $mqtt_login -p 8883 -t openwrt/$mqtt_topic/wifi/status -m '{"state":"UP"}'
        if ! ifconfig | grep wlan >/dev/null; then
		#wifi up
		logger wifi up
		fi
	fi
}

setup_wifi
logger wifi.sh starting loop_wifi
loop_wifi

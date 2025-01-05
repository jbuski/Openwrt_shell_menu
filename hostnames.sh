#!/bin/sh

source /root/backup.sh

function setup_get_hostnames()
{
echo Setup
if ! uci -q show get_hostname.hostname>/dev/null
then
	touch /etc/config/get_hostname
	echo Creating /etc/config/get_hostname file
	uci set get_hostname.hostname=settings
	uci commit
fi

if ! uci -q show get_hostname.hostname.server >/dev/null
then
	uci set get_hostname.hostname.server='127.0.0.1'
	server=$(uci get get_hostname.hostname.server)
	uci commit
	echo Setting up default server: $server
else
	server=$(uci get get_hostname.hostname.server)
	echo Server: $server
fi

if ! uci -q show get_hostname.hostname.login >/dev/null
then
	uci set get_hostname.hostname.login='root'
	login=$(uci get get_hostname.hostname.login)
	uci commit
	echo Setting up default login: $login
else
	server=$(uci get get_hostname.hostname.login)
	echo Login: $login
fi

if ! uci -q show get_hostname.hostname.pass >/dev/null
then
	uci set get_hostname.hostname.pass='pass'
	login=$(uci get get_hostname.hostname.pass)
	uci commit
	echo Setting up default pass: $pass
else
	server=$(uci get get_hostname.hostname.pass)
	echo pass
fi

if ! uci get get_hostname.hostname.intervall >/dev/null
then
	uci set get_hostname.hostname.intervall='3600'
	uci commit
	echo Setting up default intervall 3600
else
	intervall=$(uci get get_hostname.hostname.intervall )
	echo Intervall : $intervall 
fi

if ! uci get get_hostname.hostname.enable >/dev/null
then
	uci set get_hostname.hostname.enable='1'
	uci commit
	echo Setting up default enable
else
	enable=$(uci get get_hostname.hostname.enable)
	if [ $enable == '1' ]
	then
		echo Enable: Yes
	else
		echo Enable: No
	fi
fi


}


function loop_get_hostnames()
{
echo Entering loop

	while [ $(uci get get_hostname.hostname.enable) == '1' ]; do
		echo loop
			ping_test $(uci get get_hostname.hostname.server)
	if [ $? -eq 0  ]
	then
		echo Ping OK
			timeout 60 sshpass -p $(uci get get_hostname.hostname.pass) scp -r $(uci get get_hostname.hostname.login)@$(uci get get_hostname.hostname.server):/tmp/dhcp.leases /tmp/dhcp.leases #>/dev/null 2>&1 & >/dev/null
			if [ $? -eq 0  ]
			then
				echo File copied
			else
				echo Copping fail
			fi
	else
		echo Ping Fail
	fi

		sleep $intervall 
	done
}

setup_get_hostnames

loop_get_hostnames

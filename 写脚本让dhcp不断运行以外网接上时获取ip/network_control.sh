#!/system/bin/sh
ECHO=echo

iface_ethernet=eth0

#脚本得到gataway
#gataway =$(ip route show table eth0 | grep "default" | busybox awk '{print $3}')



#####################################################
##
##
##                     思路
##   
##		  | CPE-SWITCH上电，link up, no obain ip, 查询不到IP情况下，定期去busybox udhcpc -i eth0
## eth0 UP|有IP地址，ping 3 times DNS fail, 证明外网线断开，down/up eth0
##		  |无IP地址，等待20s 获取IP地址，若还没有，可以上层出问题 down/up eth0
##
##
## eth0 down 不考虑这种情况
##
##
#####################################################
count_succ=0
count_fail=0
dwup_times=0

while [ 1 ]
do
	IF_DNUP=0
	ip=0
	IF_DNUP="$(ifconfig eth0 | grep "UP" | busybox awk '{print $1}')"
	ip="$(ifconfig eth0 | grep 'inet addr' | busybox sed 's/^.*addr://g' | sed 's/Bcast.*$//g')"
	$ECHO "#####################IF_DNUP=$IF_DNUP ip=$ip###############################"
    if [ "$IF_DNUP" == "UP" ]; then
	
		if [ "$ip" != "" ]; then
		
			ping -c 3 -I $iface_ethernet 8.8.8.8
        
			if [ "$?" == "0" ] ; then
				count_succ=`busybox expr $count_succ + 1`
				$ECHO "ping success $count_succ times"
				count_fail=0
			else
				count_fail=`busybox expr $count_fail + 1`
				$ECHO "ping fail $count_fail times"
				if [ "$count_fail" -eq 3 ]; then
					ifconfig eth0 down
					sleep 1
					ifconfig eth0 up
					sleep 15
					dwup_times=`busybox expr $dwup_times + 1`
					count_fail=0
				fi
			fi
		else
			$ECHO "Link up, no ip address, wait for 15s"
			
			if [ "$ip" == "" ]; then
				$ECHO "LinkDownUp to obain ip $ip"
				ifconfig eth0 down
				sleep 1
				ifconfig eth0 up
				sleep 15
			fi
		fi
		
	else
        $ECHO "eth0 not LinkUp or The wire is not connected" 
    fi
	
	$ECHO "DownUp_times = $dwup_times" 
    
    sleep 1

done
exit 0

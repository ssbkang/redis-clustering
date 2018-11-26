redis_nodes_ips=$(drill tasks.$REDIS_SERVICE_NAME | grep tasks.$REDIS_SERVICE_NAME | tail -n +2 | awk '{print $5}')

for ip in $redis_nodes_ips; do
    master_info=$(redis-cli -h $ip | grep ^role)
    if [ $master_info == "role:master" ]; then
        master_info=$(redis-cli -h $ip)
        break
    fi
done

echo $master_info

if [[ $SLOT == 1 && !$master_info ]] 
then
    redis-server /
elif [[ !$master_info ]]
then
    until [ "$master_info" ]; do
	echo "$REDIS_MASTER_NAME not found - sleeping"
	sleep 1
	master_info=$(redis-cli -h $REDIS_SENTINEL_IP -p $REDIS_SENTINEL_PORT sentinel get-master-addr-by-name $REDIS_MASTER_NAME)
    done
    ## join as a slave
    redis-server /redis/redis.conf --slaveof $master_ip $master_port
done
fi
done
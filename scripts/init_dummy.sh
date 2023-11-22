#!/bin/sh

# This script uses tcpreplay to replay packet capture (PCAP) files.
# /pcaps/syslog.pcap must exist.

echo "Create dummy network"
ip link add dummy0 type dummy
ifconfig dummy0 mtu 3000
ifconfig dummy0 up

echo "Listen on dummy network with zeek packet sniffer"
/usr/local/zeek/bin/zeek -i dummy0 local "Site::local_nets += {192.168.1.0/24 }" &

echo "Edit input syslog PCAP to simulate ssh attacks happening now"
myether=$(ifconfig eth0 | grep ether | awk {'print $2'})
mysubnet=$(ifconfig eth0 | grep 'inet ' | awk {'print $2'} | awk -F. {'print $1"."$2".0.0"'})
connectip=$(python3 -c "import socket;addr1 = socket.gethostbyname('connect');s = socket.socket(socket.AF_INET, socket.SOCK_STREAM); s.connect((addr1,8083));print(addr1)")
connectmac=$(arp -a | grep connect | awk {'print $4'})
input="/pcaps/syslog.pcap"
output="/pcaps/edited_syslog.pcap"

echo "my subnet - $mysubnet kafka connect ip - $connectip connect mac address $connectmac\n"

echo "creating /pcaps/edited_syslog.pcap"
/usr/bin/tcprewrite  \
 --dstipmap 192.168.1.107:$connectip \
 --srcipmap 192.168.1.0/24:$mysubnet/16 \
 --infile=$input \
 --outfile=$output \
 --enet-dmac=$connectmac \
 --fixcsum

echo "Replay zeek packet sniff from exfiltration exercise and send to Kafka via Zeek Kafka Plugin"
/usr/bin/tcpreplay -i dummy0 --loop=1000000 /pcaps/zeek_streamer.pcap &

echo "Replay the edited syslog PCAP"
/usr/bin/tcpreplay -i eth0 --loop=1000000 $output &

echo "Follow /dev/null to keep script running and container alive"
tail -f /dev/null

# Get proper sigterm signal handling in Docker
exec "$@"

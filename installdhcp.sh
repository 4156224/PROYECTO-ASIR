#INSTALAR DHCP
apt install dhcpd-isc-server -y
#CONFIGURAR FICHERO DHCP
 nano /etc/dhcp/dhcpd.conf > echo "subnet 172.116.1.0 netmask 255.255.255.0 {
  range 172.116.1.2 172.116.1.10;
  option routers 172.116.1.1;
}"



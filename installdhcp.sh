#INSTALAR DHCP
apt install dhcpd-isc-server -y
#CONFIGURAR FICHERO DHCP
 nano /etc/dhcp/dhcpd.conf > echo "subnet 172.116.1.0 netmask 255.255.255.0 {
  range 172.116.1.2 172.116.1.10;
  option routers 172.116.1.1;
}"
#MODIFICAR INTERFACES DE RED
nano /etc/network/interfaces > echo " auto enp0s3
iface enp0s3 inet static
 address 172.116.1.11
 gateway 172.116.1.1
 dns-nameservers 8.8.8.8 172.116.1.12"
 systemctl service restart networking
 


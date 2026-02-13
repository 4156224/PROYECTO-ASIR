#!/bin/bash
#SCRIPT PARA INSTALAR SERVIDORES
#--------------------------------------------------
#COMPROBAR QUE SE HA ACCEDIDO CON PRIVILEGIOS DE ADMINISTRADOR
if [ $UID -ne 0 ];then
  echo "NO SE TIENEN PRIVILEGIOS DE ADMINISTRADOR"
  exit 0
fi
#-------------------------------------------------
#INSTALAR DHCP
instalar_dhcp(){
  dhcp=$(apt install isc-dhcp-server -y)
  echo "$dhcp"
  echo " subnet 192.168.10.0 netmask 255.255.255.0 {
  range 192.168.10.20 192.168.10.100;
  options routers 192.168.10.1;
  options domain-name-servers 8.8.8.8 8.8.4.4 10.0.0.6
  }" > /etc/dhcp/dhcp.conf
#-------------------------------------------------
#INSTALAR DNS
instalar_dns(){
  dns=$(apt install bind9 -y)
  echo "$dns"
  
}
#-------------------------------------------------
#INSTALAR ROUTER
instalar_router(){
  router=$(apt install squid iptables -y)
  echo "$router"
  iptablespostrouting=$(iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o ens18 -j MASQUERADE)
  variable1=$(echo 1 > /proc/sys/net/ipv4/ip_forward)
  echo "$variable1"

}
#-------------------------------------------------
#INSTALAR APACHEBBDD
instalar_apachebbdd(){
  apachebbdd=$(apt install apache2 phpmyadmin mariadb-server -y)
  echo "$apachebbdd"
  usuario_root="root"
  passwd_root="admin"
  nuevo_usuario="administrador"
  passwd="administrador"
  host="localhost"
  #SQL
  sql="GRANT ALL PRIVILEGES ON *.* TO '$nuevo_usuario'@'$host' IDENTIFIED BY '$passwd' WITH GRANT OPTION; FLUSH PRIVILEGES;"
  #EJECUTAR SQL
  mariadb -u"$usuario_root" -p"$passwd_root" -e "$sql"
  if [ $? -eq 0 ]; then
    echo "Superusuario $nuevo_usuario creado exitosamente."
  else
    echo "Error al crear el usuario."
  fi
}
#-------------------------------------------------
#MENU DE OPCIONES
echo "***SCRIPT DE INSTALACION DE SERVIDORES***"
read -p "Introduce el tipo de servidor que quieres instalar(dhcp/dns/router/apachebbdd): "p1
if [ "$p1" == "dhcp" ];then
  instalar_dhcp
elif [ "$p1" == "dns" ];then
  instalar_dns
elif [ "$p1" == "router" ];then
  instalar_router
elif [ "$p1" == "apachebbdd" ];then
  instalar_apachebbdd
else
  echo "NO HAS INTRODUCIDO NINGUNO DE LOS SERVIDORES NOMBRADOS"
  exit 0
fi

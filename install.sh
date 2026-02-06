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
  apt install isc-dhcp-server -y
  echo " subnet 192.168.10.0 netmask 255.255.255.0 {
  range 192.168.10.20 192.168.10.100;
  options routers 192.168.10.1;
  options domain-name-servers 8.8.8.8 8.8.4.4 10.0.0.6
}" >> /etc/dhcp/dhcp.conf
#-------------------------------------------------
#INSTALAR DNS
instalar_dns(){
  apt install bind9 -y
}
#-------------------------------------------------
#INSTALAR ROUTER
instalar_router(){

}
#-------------------------------------------------
#INSTALAR APACHEBBDD
instalar_apachebbdd(){
  apt install apache2 phpmyadmin mariadb-server -y
  
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

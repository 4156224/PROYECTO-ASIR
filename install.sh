#!/bin/bash
#SCRIPT PARA INSTALAR SERVIDORES
#--------------------------------------------------
# MAQUINAS POR SERVICIOS Y ROLES ACTIVOS
# =============================================================================
#PRF="user@10.0.0.2"     # Proxy + Firewall (squid, iptables, ?nftables?)
#DHCP="user@10.0.0.3"    # Servidor DHCP (isc-dhcp-server)
#ABBDD="user@10.0.0.4"   # Web + Base de datos (apache2, mariadb)
#DNS="user@10.0.0.6"     # DNS (bind9)
#TODOS TIENEN INSTALADO SSH y los configuraremos MEDIANTE UNA MAQUINA DEBIAN ADMINISTRADORA
#USUARIO: useradmin
#PASSWORD: admin
#---------------------------------------------------
#COMPROBAR QUE SE HA ACCEDIDO CON PRIVILEGIOS DE ADMINISTRADOR
if [ $UID -ne 0 ];then
  echo "NO SE TIENEN PRIVILEGIOS DE ADMINISTRADOR"
  exit 0
fi
#-------------------------------------------------
#INSTALAR DHCP
instalar_dhcp(){
  echo "***EDITANDO INTERFACES DE RED***"
  echo "network
          version: 2
          ethernets:
            ens18:
              addresses:
                   - 10.0.0.3/8
              routes:
                - to: default
                  via: 10.0.0.2
              nameservers:
                   addresses:
                   - 10.0.0.6
            ens19:
              addresses:
                   - 192.168.10.1/24
              nameservers:
                   addresses:
                   - 10.0.0.6" > /etc/netplan/00-installer-config.yaml
  echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
  sysctl -p
  echo "***REINICIANDO INTERFACES DE RED***"
  netplan apply
  apt install isc-dhcp-server -y
  echo "***DHCP INSTALADO***"
  echo "***CONFIGURANDO FICHERO DE DHCP.CONF***"
  echo " subnet 192.168.10.0 netmask 255.255.255.0 {
  range 192.168.10.20 192.168.10.100;
  option routers 192.168.10.1;
  option subnet-mask 255.255.255.0;
  option broadcast-address 192.168.10.255;
  option domain-name-servers 8.8.8.8, 8.8.4.4, 10.0.0.6;
  }" > /etc/dhcp/dhcpd.conf
  echo "INTERFACESv4='ens19'" >> /etc/default/isc-dhcp-server
  systemctl restart isc-dhcp-server
  echo "*"
  echo "*"
  echo "*"
  echo "*"
  echo "---INSTALACION COMPLETADA---"
  }
#-------------------------------------------------
#INSTALAR DNS
instalar_dns(){
  echo "***EDITANDO INTERFACES DE RED***"
  echo "network
        version: 2
          ethernets:
            ens18:
              addresses:
                   - 10.0.0.6/8
              routes:
              - to: default
                via: 10.0.0.2
              nameservers:
                   addresses:
                   - 10.0.0.6"
             > /etc/netplan/00-installer-config.yaml
  echo "***REINICIANDO INTERFACES DE RED***"
  netplan apply
  apt install bind9 -y
  echo "***DNS INSTALADO***"
  echo "***MODIFICANDO FICHEROS DE CONFIGURACION***"
  ficheroconflocal="zone 'tienda.com' { type master; file '/etc/bind/db.tienda.com'; }; zone '0.0.10.in-addr.arpa' { type master; file '/etc/bind/db.192'; };"
    echo "$ficheroconflocal" > /etc/bind/named.conf.local
    reenviadores="options {
                      directory '/var/cache/bind';
                      forwarders{
                          8.8.8.8;
                          };
                      allow-query {any;};
                      };"
    echo "$reenviadores" > /etc/bind/named.conf.options
    cp /etc/bind/db.local /etc/bind/db.tienda.com
    cp /etc/bind/db.127 /etc/bind/db.10
    echo "*"
    echo "*"
    echo "*"
    echo "*"
    echo "---INSTALACION COMPLETADA---"
}
#-------------------------------------------------
#INSTALAR ROUTER
instalar_router(){
 echo "***EDITANDO INTERFACES DE RED***"
  echo "network
        version: 2
          ethernets:
            ens18:
              addresses:
                   - 10.0.0.2/8
              nameservers:
                   addresses:
                   - 10.0.0.6
                   - 8.8.8.8
            ens19:
              accept-ra: true
              dhcp4: true
              dhcp6: true" >> /etc/netplan/00-installer-config.yaml
  echo "***INSTALANDO IPTABLES PARA ENRUTAMIENTO***"
  apt install iptables -y
  echo "***modificando iptables y preparando forwarding***"
  echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf
  sysctl -p
  iptables -F
  iptables -t nat -F
  #RUTA HACIA LA RED INTERNA
  ip route add 192.168.10.0/24 via 10.0.0.3
  #ENRUTAMIENTO
  iptables -t nat -A POSTROUTING -s 10.0.0.0/8 -o ens19 -j MASQUERADE
  iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -o ens19 -j MASQUERADE
  #TRAFICO DE DATOS CON FORWARDING
  iptables -A FORWARD -i ens18 -o ens19 -j ACCEPT
  iptables -A FORWARD -i ens19 -o ens18 -m state --state RELATED, ESTABLISHED -j ACCEPT
  echo "***REINICIANDO INTERFACES DE RED***"
  netplan apply
  echo "***INSTALADO SQUID***"
  apt install squid -y
  echo "*"
  echo "*"
  echo "*"
  echo "*"
  echo "---INSTALACION COMPLETADA---"
}
#-------------------------------------------------
#INSTALAR APACHEBBDD
instalar_apachebbdd(){
echo "***EDITANDO INTERFACES DE RED***"
  echo "network
        version: 2
          ethernets:
            ens18:
              addresses:
                   - 10.0.0.4/8
              routes:
              - to: default
                via: 10.0.0.2
              nameservers:
                   addresses:
                   - 10.0.0.6"
             >> /etc/netplan/00-installer-config.yaml
  echo "***REINICIANDO INTERFACES DE RED***" 
  netplan apply
  apt install apache2 phpmyadmin mariadb-server -y
  echo "***BASE DE DATOS Y APACHE INSTALADO***"
  echo "***CONFIGURANDO BASE DE DATOS Y PAGINA WEB***"
  usuario_root="root"
  passwd_root="admin"
  nuevo_usuario="administrador"
  passwd="administrador"
  host="localhost"
  #SQL
  sql="GRANT ALL PRIVILEGES ON *.* TO '$nuevo_usuario'@'$host' IDENTIFIED BY '$passwd' WITH GRANT OPTION; FLUSH PRIVILEGES;"
  #EJECUTAR SQL
  mariadb -u "$usuario_root" -p "$passwd_root" -e "$sql"
  if [ $? -eq 0 ]; then
    echo "Superusuario $nuevo_usuario creado exitosamente."
  else
    echo "Error al crear el usuario."
  fi
  echo "*"
  echo "*"
  echo "*"
  echo "*"
  echo "---INSTALACION COMPLETADA---"
}
#-------------------------------------------------
#MENU DE OPCIONES
echo "***SCRIPT DE INSTALACION DE SERVIDORES***"
read -p "Introduce el tipo de servidor que quieres instalar(dhcp/dns/router/apachebbdd): " p1
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

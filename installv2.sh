#!/bin/bash
# =============================================================================
# SCRIPT ADMINISTRADOR - INSTALACIÓN DE SERVIDORES
# Ejecutar en la máquina 10.0.0.6 como useradmin (con claves SSH ya copiadas)
# =============================================================================

# Máquinas objetivo (mismo usuario y IPs que pusiste tú)
ROUTER="user@10.0.0.2"
DNS="user@10.0.0.5"
DHCP="user@10.0.0.3"
WEB="user@10.0.0.4"

# ──────────────────────────────────────────────────────────────────────────────
# Función ROUTER
# ──────────────────────────────────────────────────────────────────────────────
instalar_router() {
    local host="$ROUTER"
    echo "Configurando ROUTER + Squid → $host"

    local comando='
        set -e
        apt update
        echo "***EDITANDO INTERFACES DE RED***"
        echo "network: version: 2 ethernets: ens18: dhcp4: false addresses: - 10.0.0.2/8 nameservers: addresses: - 10.0.0.5 ens19: accept-ra: true dhcp4: true dhcp6: true" > /etc/netplan/00-installer-config.yaml
        echo "***REINICIANDO INTERFACES DE RED***"
        netplan apply
        echo "***INSTALANDO PERSISTENCIA EN IPTABLES***"
        apt install -y iptables-persistent
        echo "***INSTALANDO IPTABLES***"
        apt install -y iptables
        echo "***configurando forwarding***"
        echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf
        sysctl -p
        iptables -F
        iptables -t nat -F
        ip route add 192.168.10.0/24 via 10.0.0.3 || true
        iptables -t nat -A POSTROUTING -s 10.0.0.0/8 -o ens19 -j MASQUERADE
        iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -o ens19 -j MASQUERADE
        iptables -A FORWARD -i ens18 -o ens19 -j ACCEPT
        iptables -A FORWARD -i ens19 -o ens18 -m state --state RELATED,ESTABLISHED -j ACCEPT
        netfilter-persistent save
        echo "***INSTALANDO SQUID***"
        apt install -y squid
        echo "---INSTALACION ROUTER COMPLETADA---"
    '
    ssh "$host" bash -c "$comando"
}

# ──────────────────────────────────────────────────────────────────────────────
# Función DNS
# ──────────────────────────────────────────────────────────────────────────────
instalar_dns() {
    local host="$DNS"
    echo "Configurando DNS → $host"

    local comando='
        set -e
        apt update
        echo "***EDITANDO INTERFACES DE RED***"
        echo "network: version: 2 ethernets: ens18: dhcp4: false addresses: - 10.0.0.5/8 routes: - to: default via: 10.0.0.2 nameservers: addresses: - 127.0.0.1" > /etc/netplan/00-installer-config.yaml
        echo "***REINICIANDO INTERFACES DE RED***"
        netplan apply
        echo "***INSTALANDO BIND9***"
        apt install -y bind9
        echo "***CONFIGURANDO BIND9***"
        echo "zone \"proyecto.local\" { type master; file \"/etc/bind/proyecto.local\"; }; zone \"10.in-addr.arpa\" { type master; file \"/etc/bind/10.in-addr.arpa\"; };" > /etc/bind/named.conf.local
        echo "options { directory \"/var/cache/bind\"; forwarders{ 8.8.8.8; }; allow-query {any;}; };" > /etc/bind/named.conf.options
        echo "\$TTL 604800 @ IN SOA proyecto.local. root.proyecto.local. ( 2 604800 86400 2419200 604800) @ IN NS dns.proyecto.local. dns IN A 10.0.0.5 router IN A 10.0.0.2 dhcp IN A 10.0.0.3 apache IN A 10.0.0.4 www.incidencias.com. IN A 10.0.0.4" > /etc/bind/proyecto.local
        echo "\$TTL 604800 @ IN SOA proyecto.local. root.proyecto.local. ( 2 604800 86400 2419200 604800) @ IN NS dns.proyecto.local. 5.0.0 IN PTR dns.proyecto.local. 2.0.0 IN PTR router.proyecto.local. 3.0.0 IN PTR dhcp.proyecto.local. 4.0.0 IN PTR apache.proyecto.local." > /etc/bind/10.in-addr.arpa
        echo "***REINICIANDO BIND9***"
        systemctl restart bind9
        echo "---INSTALACION DNS COMPLETADA---"
    '
    ssh "$host" bash -c "$comando"
}

# ──────────────────────────────────────────────────────────────────────────────
# Función DHCP
# ──────────────────────────────────────────────────────────────────────────────
instalar_dhcp() {
    local host="$DHCP"
    echo "Configurando DHCP → $host"

    local comando='
        set -e
        apt update
        echo "***EDITANDO INTERFACES DE RED***"
        echo "network: version: 2 ethernets: ens18: dhcp4: false addresses: - 10.0.0.3/8 routes: - to: default via: 10.0.0.2 nameservers: addresses: - 10.0.0.5 ens19: addresses: - 192.168.10.1/24 nameservers: addresses: - 10.0.0.5" > /etc/netplan/00-installer-config.yaml
        echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf
        sysctl -p
        echo "***REINICIANDO INTERFACES DE RED***"
        netplan apply
        echo "***INSTALANDO DHCP***"
        apt install -y isc-dhcp-server
        echo "***CONFIGURANDO DHCP.CONF***"
        echo "subnet 192.168.10.0 netmask 255.255.255.0 { range 192.168.10.20 192.168.10.100; option routers 192.168.10.1; option subnet-mask 255.255.255.0; option broadcast-address 192.168.10.255; option domain-name-servers 10.0.0.5, 8.8.8.8; }" > /etc/dhcp/dhcpd.conf
        echo "INTERFACESv4=\"ens19\"" > /etc/default/isc-dhcp-server
        systemctl restart isc-dhcp-server
        echo "---INSTALACION DHCP COMPLETADA---"
    '
    ssh "$host" bash -c "$comando"
}

# ──────────────────────────────────────────────────────────────────────────────
# Función APACHE + BBDD
# ──────────────────────────────────────────────────────────────────────────────
instalar_apachebbdd() {
    local host="$WEB"
    echo "Configurando Apache + MariaDB → $host"

    local comando='
        set -e
        apt update
        echo "***EDITANDO INTERFACES DE RED***"
        echo "network: version: 2 ethernets: ens18: dhcp4: false addresses: - 10.0.0.4/8 routes: - to: default via: 10.0.0.2 nameservers: addresses: - 10.0.0.5" > /etc/netplan/00-installer-config.yaml
        echo "***REINICIANDO INTERFACES DE RED***"
        netplan apply
        echo "***INSTALANDO PAQUETES***"
        apt install -y apache2 mariadb-server mariadb-client php phpmyadmin
        echo "***CREANDO USUARIO BBDD***"
        mysql -e "GRANT ALL PRIVILEGES ON *.* TO \"administrador\"@\"localhost\" IDENTIFIED BY \"administrador\" WITH GRANT OPTION; FLUSH PRIVILEGES;"
        echo "---INSTALACION APACHE + BBDD COMPLETADA---"
    '
    ssh "$host" bash -c "$comando"
}

# ──────────────────────────────────────────────────────────────────────────────
# Menú principal (igual que tenías tú)
# ──────────────────────────────────────────────────────────────────────────────

echo ""
echo "***SCRIPT DE INSTALACION DE SERVIDORES***"
echo "Opciones disponibles: router / dns / dhcp / apachebbdd"
echo ""

read -p "Introduce el tipo de servidor que quieres instalar: " opcion

case "$opcion" in
    router)         instalar_router ;;
    dns)            instalar_dns ;;
    dhcp)           instalar_dhcp ;;
    apachebbdd)     instalar_apachebbdd ;;
    *)
        echo "NO HAS INTRODUCIDO NINGUNO DE LOS SERVIDORES NOMBRADOS"
        exit 1
        ;;
esac

echo ""
echo "Proceso terminado para: $opcion"

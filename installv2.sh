#!/bin/bash
# =============================================================================
# SCRIPT ADMINISTRADOR - INSTALACIÓN BÁSICA DE SERVIDORES
# Ejecutar en la máquina 10.0.0.6 como useradmin:
# Requiere de la configuració previa de ssh en cada máquina
# =============================================================================

# Máquinas objetivo
ROUTER="user@10.0.0.2"
DNS="user@10.0.0.5"
DHCP="user@10.0.0.3"
WEB="user@10.0.0.4"

# ──────────────────────────────────────────────────────────────────────────────
# Función ROUTER: Instalación y configuración básica de iptables
# ──────────────────────────────────────────────────────────────────────────────
instalar_router() {
    local host="$ROUTER"
    echo "===== Configurando ROUTER + Squid en $host ====="
    
    # Paso 1: update + upgrade
    echo "Paso 1: sudo apt update && upgrade"
    ssh -t "$host" "sudo apt update && sudo apt upgrade -y" || { echo "FALLO en update/upgrade"; return 1; }

    # Paso 2: configurar netplan
    echo "Paso 2: escribir y aplicar netplan"
    ssh -t "$host" "
        cat > sudo /etc/netplan/00-installer-config.yaml <<'EOF'
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: true
      dhcp6: true
      accept-ra: true
    ens19:
      dhcp4: false
      addresses: [10.0.0.2/8]
      nameservers:
        addresses: [10.0.0.5]
EOF
        sudo netplan generate || exit 1
        sudo netplan apply     || exit 1
        ip a 
    " || { echo "FALLO en netplan"; return 1; }

    # Paso 3: instalar paquetes iptables
    echo "Paso 3: instalar iptables-persistent"
    ssh -t "$host" "sudo apt install -y iptables-persistent iptables" || { echo "FALLO instalando iptables"; return 1; }

    # Paso 4: forwarding + sysctl
    echo "Paso 4: habilitar IP forwarding"
    ssh -t "$host" "
        echo 'net.ipv4.ip_forward=1' > sudo /etc/sysctl.d/99-forwarding.conf
        sudo sysctl -p /etc/sysctl.d/99-forwarding.conf
    " || { echo "FALLO en sysctl"; return 1; }

    # Paso 5: reglas iptables (el más largo, pero lo dejamos en uno)
    echo "Paso 5: aplicar reglas iptables + persistencia"
    ssh -t "$host" "
        sudo iptables -F
        sudo iptables -t nat -F
        sudo ip route add 192.168.10.0/24 via 10.0.0.3 || true
        sudo iptables -t nat -A POSTROUTING -s 10.0.0.0/8 -o ens19 -j MASQUERADE
        sudo iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -o ens19 -j MASQUERADE
        sudo iptables -A FORWARD -i ens18 -o ens19 -j ACCEPT
        sudo iptables -A FORWARD -i ens19 -o ens18 -m state --state RELATED,ESTABLISHED -j ACCEPT
        sudo netfilter-persistent save
    " || { echo "FALLO en iptables"; return 1; }

    # Paso 6: instalar squid
    echo "Paso 6: instalar squid"
    ssh -t "$host" "sudo apt install -y squid" || { echo "FALLO instalando squid"; return 1; }

    echo ""
    echo "===== ROUTER CONFIGURADO (aparentemente) ====="
    echo "Último paso: verifica manualmente en la VM:"
    echo "  - ip a → ¿ves 10.0.0.2 en ens19?"
    echo "  - iptables -L -v -n → ¿están las reglas?"
    echo "  - systemctl status squid"
}

# ──────────────────────────────────────────────────────────────────────────────
# Función DNS: Instalación bind9
# ──────────────────────────────────────────────────────────────────────────────
instalar_dns() {
    local host="$DNS"
    echo "Configurando DNS → $host"

    local comando='
        set -e
        sudo apt update
        echo "***EDITANDO INTERFACES DE RED***"
        echo "network: 
                version: 2 
                ethernets: 
                  ens18: 
                    dhcp4: false 
                    addresses: 
                         - 10.0.0.5/8 
                    routes: 
                      - to: default 
                        via: 10.0.0.2 
                    nameservers: 
                      addresses: 
                        - 127.0.0.1" >sudo /etc/netplan/00-installer-config.yaml
        echo "***REINICIANDO INTERFACES DE RED***"
        sudo netplan apply
        echo "***INSTALANDO BIND9***"
        sudo apt install -y bind9
        echo "***CONFIGURANDO BIND9***"
        echo "zone \"proyecto.local\" { type master; file \"/etc/bind/proyecto.local\"; }; zone \"10.in-addr.arpa\" { type master; file \"/etc/bind/10.in-addr.arpa\"; };" > /etc/bind/named.conf.local
        echo "options { directory \"/var/cache/bind\"; forwarders{ 8.8.8.8; }; allow-query {any;}; };" > /etc/bind/named.conf.options
        echo "\$TTL 604800 @ IN SOA proyecto.local. root.proyecto.local. ( 2 604800 86400 2419200 604800) @ IN NS dns.proyecto.local. dns IN A 10.0.0.5 router IN A 10.0.0.2 dhcp IN A 10.0.0.3 apache IN A 10.0.0.4 www.incidencias.com. IN A 10.0.0.4" > /etc/bind/proyecto.local
        echo "\$TTL 604800 @ IN SOA proyecto.local. root.proyecto.local. ( 2 604800 86400 2419200 604800) @ IN NS dns.proyecto.local. 5.0.0 IN PTR dns.proyecto.local. 2.0.0 IN PTR router.proyecto.local. 3.0.0 IN PTR dhcp.proyecto.local. 4.0.0 IN PTR apache.proyecto.local." > /etc/bind/10.in-addr.arpa
        echo "***REINICIANDO BIND9***"
        sudo systemctl restart bind9
        echo "---INSTALACION DNS COMPLETADA---"
    '
    ssh -t "$host" sudo bash -c "$comando"
}

# ──────────────────────────────────────────────────────────────────────────────
# Función DHCP: Instalación y configuración isc-dhcp-server
# ──────────────────────────────────────────────────────────────────────────────
instalar_dhcp() {
    local host="$DHCP"
    echo "Configurando DHCP → $host"

    local comando='
        set -e
        sudo apt update
        echo "***EDITANDO INTERFACES DE RED***"
        echo "network: 
                version: 2 
                ethernets: 
                  ens18: 
                    dhcp4: false 
                    addresses: 
                         - 10.0.0.3/8 
                    routes: 
                      - to: default 
                        via: 10.0.0.2 
                    nameservers: 
                        addresses: 
                             - 10.0.0.5 
                  ens19: 
                    addresses: 
                         - 192.168.10.1/24 
                    nameservers: 
                        addresses: 
                             - 10.0.0.5" > sudo /etc/netplan/00-installer-config.yaml
        echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf
        sudo sysctl -p
        echo "***REINICIANDO INTERFACES DE RED***"
        sudo netplan apply
        echo "***INSTALANDO DHCP***"
        sudo apt install isc-dhcp-server -y
        echo "***CONFIGURANDO DHCP.CONF***"
        echo "subnet 192.168.10.0 netmask 255.255.255.0 { range 192.168.10.20 192.168.10.100; option routers 192.168.10.1; option subnet-mask 255.255.255.0; option broadcast-address 192.168.10.255; option domain-name-servers 10.0.0.5, 8.8.8.8; }" > /etc/dhcp/dhcpd.conf
        echo "INTERFACESv4=\"ens19\"" > /etc/default/isc-dhcp-server
        sudo systemctl restart isc-dhcp-server
        echo "---INSTALACION DHCP COMPLETADA---"
    '
    ssh -t "$host" sudo bash -c "$comando"
}

# ──────────────────────────────────────────────────────────────────────────────
# Función APACHE + BBDD
# ──────────────────────────────────────────────────────────────────────────────
instalar_apachebbdd() {
    local host="$WEB"
    echo "Configurando Apache + MariaDB → $host"

    local comando='
        set -e
        sudo apt update
        echo "***EDITANDO INTERFACES DE RED***"
        echo "network: 
                version: 2 
                ethernets: 
                  ens18: 
                    dhcp4: false 
                    addresses: 
                         - 10.0.0.4/8 
                    routes: 
                    - to: default 
                      via: 10.0.0.2 
                    nameservers: 
                         addresses: 
                         - 10.0.0.5" > /etc/netplan/00-installer-config.yaml
        echo "***REINICIANDO INTERFACES DE RED***"
        sudo netplan apply
        echo "***INSTALANDO PAQUETES***"
        sudo apt install apache2 mariadb-server mariadb-client php phpmyadmin -y
        echo "***CREANDO USUARIO BBDD***"
        sudo mariadb -e "CREATE USER \"administrador"\@\"localhost\" identified by \"administrador"\;
        sudo mariadb -e "GRANT ALL PRIVILEGES ON *.* TO \"administrador\"@\"localhost\" WITH GRANT OPTION; FLUSH PRIVILEGES;"
        echo "---INSTALACION APACHE + BBDD COMPLETADA---"
    '
    ssh -t "$host" sudo bash -c "$comando"
}

# ──────────────────────────────────────────────────────────────────────────────
# Menú principal
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

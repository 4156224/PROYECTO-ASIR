#!/bin/bash

# Para ejecutar este script se necesita previamente haber
# configurado el acceso por ssh sin contraseña a cada uno de los servidores

# =============================================================================
# Conexion ssh para cada una de las maquinas para trabajar con todos los
# servidores a la vez
# =============================================================================
vms = ("user@10.0.0.2"
       "user@10.0.0.3" 
       "user@10.0.0.4" 
       "user@10.0.0.6")

# =============================================================================
# Maquinas por servicios y roles especificos
# =============================================================================
PRF="user@10.0.0.2"     # Proxy + Firewall (squid, iptables, ?nftables?)
DHCP="user@10.0.0.3"    # Servidor DHCP (isc-dhcp-server)
ABBDD="user@10.0.0.4"   # Web + Base de datos (apache2, mariadb)
DNS="user@10.0.0.6"     # DNS (bind9)

# =============================================================================
# Función genérica para ejecutar comando en una máquina
# =============================================================================
ejecutar_en() {
    local host="$1"
    local comando="$2"

    echo_info "Ejecutando en $host..."
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=7 "$host" "$comando"; then
        echo "Todo según lo previsto..."
    else
        echo "Algo ha salido mal...
              Revise los logs caballero"
        return 1
    fi
}

# Comando que se ejecutara en todas las maquinas gracias
# al for que tenemos a continuacion
actualizar-todos(){
  echo "====================================="
  echo "  ACTUALIZANDO TODOS LOS SERVICIOS"
  echo "====================================="
  
  co1="sudo apt update && sudo apt upgrade -y"
                                                                                                                                      
  for $vm in ${vms[@]}; do
      echo "Ejecutando en $vm..."
      ssh -o StrictHostKeyChecking=no "$vm" "$co1"
      if [ $? -eq 0 ]; then
          echo "Éxito en $vm"
      else
          echo "Error en $vm"
      fi
  done
}

# =============================================================================
# Reinicios específicos por rol / servidor
# =============================================================================

restart_proxy_firewall() {
    echo "====================================="
    echo "  REINICIANDO SERVICIOS en PROXY/FW"
    echo "====================================="

    ejecutar_en "$PRF" "sudo systemctl restart squid"          "Squid"
    ejecutar_en "$PRF" "sudo systemctl restart iptables"       "iptables (si se usa como servicio)" || true
    # Si usas nftables o ufw en vez de iptables, cámbialo aquí:
    # ejecutar_en "$PRF" "sudo systemctl restart nftables"     "nftables"
    # ejecutar_en "$PRF" "sudo ufw reload"                     "ufw"

    echo "Proxy/Firewall reinicios completados."
}

restart_dhcp() {
    echo "====================================="
    echo "  REINICIANDO SERVICIOS en DHCP"
    echo "====================================="

    ejecutar_en "$DHCP" "sudo systemctl restart isc-dhcp-server" "ISC DHCP Server"

    echo "DHCP reinicios completados."
}

restart_web_bbdd() {
    echo "====================================="
    echo "  REINICIANDO SERVICIOS en WEB + BBDD"
    echo "====================================="

    ejecutar_en "$ABBDD" "sudo systemctl restart apache2"   "Apache2"
    ejecutar_en "$ABBDD" "sudo systemctl restart mariadb"   "MariaDB"

    echo "Web + Base de datos reinicios completados."
}

restart_dns() {
    echo "====================================="
    echo "  REINICIANDO SERVICIOS en DNS"
    echo "====================================="

    ejecutar_en "$DNS" "sudo systemctl restart bind9"   "BIND9 / named"

    echo "DNS reinicios completados."
}


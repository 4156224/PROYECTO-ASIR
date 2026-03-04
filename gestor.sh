#!/usr/bin/env bash
# =============================================================================
# GESTOR SIMPLE DE SERVIDORES ASIR
# - Requiere claves SSH sin contraseña configuradas desde esta máquina
# - Usa sudo en los servidores remotos (asegúrate de que el usuario tenga sudo sin contraseña o ya cacheado)
# =============================================================================

# Hosts (ajusta las IPs si es necesario)
PRF="user@10.0.0.2"     # Proxy + Firewall (squid)
DHCP="user@10.0.0.3"    # Servidor DHCP
ABBDD="user@10.0.0.4"   # Web + Base de datos (apache2 + mariadb)
DNS="user@10.0.0.5"     # DNS (bind9)

ALL_VMS=("$PRF" "$DHCP" "$ABBDD" "$DNS")

# =============================================================================
# Función para ejecutar comandos remotos con sudo
# =============================================================================
ejecutar_en() {
    local host="$1"
    local comando="$2"

    echo "→ Ejecutando en $host..."
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$host" "sudo bash -c '$comando'"; then
        echo "OK → $host"
    else
        echo "ERROR → $host"
    fi
}

# =============================================================================
# Actualizar todos los servidores
# =============================================================================
actualizar_todos() {
    echo "====================================="
    echo " ACTUALIZANDO TODOS LOS SERVIDORES"
    echo "====================================="

    local cmd="apt update && apt upgrade -y && apt autoremove -y"

    for vm in "${ALL_VMS[@]}"; do
        ejecutar_en "$vm" "$cmd"
    done
}

# =============================================================================
# Reinicios por rol / servicio
# =============================================================================
reiniciar_proxy() {
    echo "====================================="
    echo " REINICIANDO PROXY/FIREWALL"
    echo "====================================="
    ejecutar_en "$PRF" "systemctl restart squid"
}

reiniciar_dhcp() {
    echo "====================================="
    echo " REINICIANDO DHCP"
    echo "====================================="
    ejecutar_en "$DHCP" "systemctl restart isc-dhcp-server"
}

reiniciar_web() {
    echo "====================================="
    echo " REINICIANDO WEB + BASE DE DATOS"
    echo "====================================="
    ejecutar_en "$ABBDD" "systemctl restart apache2"
    ejecutar_en "$ABBDD" "systemctl restart mariadb"
}

reiniciar_dns() {
    echo "====================================="
    echo " REINICIANDO DNS"
    echo "====================================="
    ejecutar_en "$DNS" "systemctl restart bind9"
}

# =============================================================================
# Menú principal
# =============================================================================
echo ""
echo "Gestor simple de servidores ASIR"
echo "───────────────────────────────"
echo "  1   Actualizar todos los servidores"
echo "  2   Reiniciar Proxy/Firewall"
echo "  3   Reiniciar DHCP"
echo "  4   Reiniciar Web + Base de datos"
echo "  5   Reiniciar DNS"
echo "  0   Salir"
echo ""

read -p "Elige opción (0-5): " opcion

case "$opcion" in
    1) actualizar_todos ;;
    2) reiniciar_proxy ;;
    3) reiniciar_dhcp ;;
    4) reiniciar_web ;;
    5) reiniciar_dns ;;
    0) echo "Saliendo..."; exit 0 ;;
    *) echo "Opción no válida"; exit 1 ;;
esac

echo ""
echo "Operación terminada."
